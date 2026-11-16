import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import 'package:wallet/wallet.dart';

import 'package:publicos_core/src/core/publicos_core.dart';
import 'package:publicos_core/src/core/extensions/publicos_bsp.dart';
import 'package:publicos_core/src/core/extensions/publicos_contacts.dart';
import 'package:publicos_core/src/core/extensions/publicos_settings.dart';
import 'package:publicos_core/src/database/database.dart';
import 'package:publicos_core/src/models/activity_event.dart';
import 'package:publicos_core/src/models/record_model.dart';
import 'package:publicos_core/src/utils/log.dart';

/// Which event to scan, on which contract, and which indexed-topic positions
/// hold the address(es) we contact-scope on.
///
/// [filterTopics] is a list of 1-based topic positions (topic[1] = first
/// indexed param). Most events carry the relevant address at topic[1]; the
/// exceptions are encoded here:
///   - `Vouched(voucher, target)` — both indexed; scan BOTH so "X vouched for
///     you" (you = target, topic[2]) surfaces even when the voucher isn't a
///     contact.
///   - `DomainPaid(payer, account, ...)` — scan topic[2] (the account whose
///     rent was paid); the payer is often a BSP, not someone we track.
/// A single getLogs call can only OR within one topic position, so each
/// position becomes its own scan; results are deduped on (txHash, logIndex).
class _ActivitySpec {
  /// Resolves the underlying DeployedContract. THROWS if the module isn't
  /// registered on the active chain (the BSP getters force-unwrap), so callers
  /// wrap it in try/catch — a null-guard won't fire.
  final DeployedContract Function() contract;
  final String eventName;
  final List<int> filterTopics;
  final String type;

  const _ActivitySpec(
    this.contract,
    this.eventName,
    this.filterTopics,
    this.type,
  );
}

/// The P1 event set: AccountManager + VouchManager + DomainManager. ~90% of
/// "a contact did something" value. P2 events (votes, claims, subs, safe) are
/// added to this list later behind the same model.
final List<_ActivitySpec> _p1Specs = [
  _ActivitySpec(() => PublicOSBsp.vouchManagerContract.self, 'Vouched', [1, 2],
      ActivityEventType.vouched),
  _ActivitySpec(() => PublicOSBsp.domainManagerContract.self, 'Citizenized', [1],
      ActivityEventType.citizenized),
  // Hidden by product decision: the
  // client doesn't surface "can change their name for free". Kept (not deleted)
  // so another consumer can re-enable it — uncomment to resume sweeping it.
  // _ActivitySpec(() => PublicOSBsp.domainManagerContract.self,
  //     'BonusNameChangeGranted', [1], ActivityEventType.bonusNameChangeGranted),
  // Hidden by product decision: the
  // client doesn't surface "paid rent — N months". Kept (not deleted) so another
  // consumer can re-enable it — uncomment to resume sweeping it.
  // _ActivitySpec(() => PublicOSBsp.domainManagerContract.self, 'DomainPaid', [2],
  //     ActivityEventType.domainPaid),
  _ActivitySpec(() => PublicOSBsp.domainManagerContract.self, 'Evicted', [1],
      ActivityEventType.evicted),
  _ActivitySpec(() => PublicOSBsp.domainManagerContract.self, 'NameChanged', [1],
      ActivityEventType.nameChanged),
  _ActivitySpec(() => PublicOSBsp.recordManagerContract.self, 'RecordSet', [1], // RecordManager emits it
      ActivityEventType.recordSet),
  // Hidden by product decision: a
  // front-door changeName already fires NameChanged; DisplayNameSet is the
  // storage-layer twin (also fires on account creation / root rename), so it's a
  // redundant/odd notification. Kept (not deleted) — uncomment to re-enable.
  // _ActivitySpec(() => PublicOSBsp.accountManagerContract.self, 'DisplayNameSet',
  //     [1], ActivityEventType.displayNameSet),
];

/// On-chain activity feed: poll P1 contract events touching the user + their
/// contacts via `eth_getLogs`, cache them, surface as a notification feed.
///
/// Generalizes the proven governance vote-poll
/// (`publicos_governance.dart` `_getVoteStartedEvents`) over a broader event
/// set, contact-scoped, with a bounded query range. Phase 1 only;
/// a Phase-B BSP indexer can later feed the same [ActivityEvent] shape.
extension PublicOSActivity on PublicOS {
  static const _tag = 'Activity';

  /// Range guard: never query an open-ended range. The node has no
  /// `JsonRpc.MaxLogRange` cap, so a genesis-to-head scan would amplify
  /// ~53,000x. Step in <=5000-block windows (~2.7 hrs at 2s blocks).
  static const int maxRange = 5000;

  /// Cold-start seed: on first run, scan back ~3 days, NEVER from genesis.
  /// 30 blocks/min * 60 * 24 * 3 at 2s AuRa block time.
  static const int coldStartLookback = 129600;

  static const String _lastBlockKey = 'activity_last_checked_block';

  // ---------------------------------------------------------------------------
  // Orchestration — call sweep() from the client poll timer.
  // ---------------------------------------------------------------------------

  /// Run one activity sweep: from the stored last-checked block (or the
  /// cold-start seed) to chain head, one bounded window at a time — fetch,
  /// persist, THEN advance the cursor past that window. The cursor only ever
  /// moves past blocks that were scanned successfully; a failed window halts
  /// the sweep and the next sweep resumes from it (never skip past an
  /// unscanned range — that's how gaps get sealed). Returns the resulting
  /// unread count for the bell badge. Safe to fold into the existing 10-min
  /// explorer timer.
  static Future<int> sweep() async => (await _runSweep()).unread;

  /// Like [sweep], but also returns the events newly FETCHED this pass (in
  /// chain order). The background chain-notification worker
  /// (publicos_client::runChainNotificationSync) uses these to decide what to
  /// pop as OS notifications; the in-app feed/badge keep using [sweep].
  static Future<List<ActivityEvent>> sweepCollectingNew() async =>
      (await _runSweep()).fresh;

  /// Shared sweep body. Persists new events and advances the cursor exactly as
  /// before; additionally accumulates the freshly-fetched events so callers
  /// that want to notify on them don't need a second query. The cursor only
  /// moves past successfully-scanned windows; a failed window halts the sweep.
  static Future<({int unread, List<ActivityEvent> fresh})> _runSweep() async {
    final fresh = <ActivityEvent>[];
    if (!PublicOS.isAuthenticated || PublicOS.sessionBlockchainAddress == null) {
      return (unread: 0, fresh: fresh);
    }
    final sessionAddr = PublicOS.sessionBlockchainAddress!;
    try {
      final head = await PublicOS.web3Client.getBlockNumber();
      var fromBlock = await _readLastBlock();
      if (fromBlock <= 0) {
        fromBlock = head - coldStartLookback;
        if (fromBlock < 0) fromBlock = 0;
      }

      if (fromBlock <= head) {
        final accounts = await _accountSet();
        if (accounts.isEmpty) {
          // Fresh install before contacts restore: leave the cursor alone so
          // the range is retried next sweep, don't mark it seen.
          return (
            unread: await PublicOS.database.getUnreadActivityCount(sessionAddr),
            fresh: fresh,
          );
        }
        for (var lo = fromBlock; lo <= head; lo += maxRange) {
          final hi = (lo + maxRange - 1) > head ? head : (lo + maxRange - 1);
          final List<ActivityEvent> events;
          try {
            events = await fetchActivity(
              fromBlock: lo,
              toBlock: hi,
              accounts: accounts,
            );
          } catch (e) {
            // Window failed (rate limit, timeout, node refusal). Halt WITHOUT
            // advancing the cursor — the next sweep resumes from `lo`.
            Log.w(_tag, 'sweep halted at window $lo-$hi: $e');
            break;
          }
          if (events.isNotEmpty) {
            await PublicOS.database.insertActivityEvents(
              events.map((e) => _toCompanion(e, sessionAddr)).toList(),
            );
            fresh.addAll(events);
            Log.i(_tag, 'sweep: ${events.length} events '
                '($lo-$hi, ${accounts.length} accounts)');
          }
          // Dedupe on the unique key is the backstop if a boundary block is
          // re-seen.
          await _writeLastBlock(hi + 1);
        }
      }

      return (
        unread: await PublicOS.database.getUnreadActivityCount(sessionAddr),
        fresh: fresh,
      );
    } catch (e) {
      Log.e(_tag, 'sweep failed: $e');
      return (unread: await getUnreadCount(), fresh: fresh);
    }
  }

  /// Newest-first cached activity for the current session (for the screen).
  static Future<List<ActivityEvent>> getStored({int limit = 200}) async {
    final sessionAddr = PublicOS.sessionBlockchainAddress;
    if (sessionAddr == null) return [];
    final rows =
        await PublicOS.database.getActivityEvents(sessionAddr, limit: limit);
    return rows.map(_fromRow).toList();
  }

  /// Unread count for the current session (drives the bell badge).
  static Future<int> getUnreadCount() async {
    final sessionAddr = PublicOS.sessionBlockchainAddress;
    if (sessionAddr == null) return 0;
    return PublicOS.database.getUnreadActivityCount(sessionAddr);
  }

  /// Mark all activity read for the current session (call on screen open).
  static Future<void> markAllRead() async {
    final sessionAddr = PublicOS.sessionBlockchainAddress;
    if (sessionAddr == null) return;
    await PublicOS.database.markAllActivityRead(sessionAddr);
  }

  /// Developer utility: wipe all cached chain-activity (the notifications feed)
  /// for the current session AND reset the sweep cursor to genesis, so the next
  /// background sweep re-scans the current chain from the start instead of
  /// resuming behind a stale (pre-redeploy) block height that would otherwise
  /// freeze the feed. Use after a chain redeploy when the app wasn't
  /// reinstalled and old-chain notifications linger. Returns rows deleted.
  /// Insert one event unless (txHash, logIndex, session) is already stored.
  /// Returns true when it was new. The sweep keeps its bulk path; this is the
  /// single-row door the social push and the inbox pull use:
  /// idempotent on the notification id, so a push
  /// that already popped is "not new" when the 15-min pull sees it again.
  static Future<bool> storeIfNew(ActivityEvent e) async {
    final session = PublicOS.sessionBlockchainAddress;
    if (session == null) return false;
    try {
      return await PublicOS.database
          .insertActivityEventIfNew(_toCompanion(e, session));
    } catch (err) {
      Log.e(_tag, 'storeIfNew failed: $err');
      return false;
    }
  }

  static Future<int> clearStored() async {
    final sessionAddr = PublicOS.sessionBlockchainAddress;
    if (sessionAddr == null) return 0;
    final deleted =
        await PublicOS.database.deleteActivityEventsForSession(sessionAddr);
    await _writeLastBlock(0); // re-scan the current chain from the start
    Log.i(_tag, 'cleared $deleted activity rows + reset sweep cursor');
    return deleted;
  }

  // ---------------------------------------------------------------------------
  // Fetch — pure getLogs poll (no persistence). Exposed for tests / Phase B.
  // ---------------------------------------------------------------------------

  /// Scan the P1 contracts for events touching [accounts] between
  /// [fromBlock]..[toBlock], in <=[maxRange] windows. Returns deduped,
  /// newest-first [ActivityEvent]s. Does not persist. THROWS if any
  /// underlying RPC call (getLogs / block timestamp) fails — an empty window
  /// and a failed window are different things; callers decide how far the
  /// sweep cursor may advance.
  static Future<List<ActivityEvent>> fetchActivity({
    required int fromBlock,
    required int toBlock,
    required List<EthereumAddress> accounts,
  }) async {
    if (accounts.isEmpty || fromBlock > toBlock) return [];

    final topicAddrs = accounts
        .map((a) => '0x${a.eip55With0x.substring(2).padLeft(64, '0')}')
        .toList();
    final byKey = <String, ActivityEvent>{}; // dedupe on txHash:logIndex
    final blockTs = <int, int>{}; // blockNumber -> ms epoch (per-sweep cache)

    for (var lo = fromBlock; lo <= toBlock; lo += maxRange) {
      final hi = (lo + maxRange - 1) > toBlock ? toBlock : (lo + maxRange - 1);
      for (final spec in _p1Specs) {
        DeployedContract contract;
        try {
          contract = spec.contract();
        } catch (_) {
          // Module not registered on this chain — skip the event entirely.
          continue;
        }
        for (final pos in spec.filterTopics) {
          final logs = await _scan(contract, spec.eventName, lo, hi, pos, topicAddrs);
          for (final log in logs) {
            final key = '${log.transactionHash}:${log.logIndex}';
            if (byKey.containsKey(key)) continue;
            final ts = await _blockTimestamp(log.blockNum, blockTs);
            final ev = _decode(spec, contract, log, ts);
            if (ev != null) byKey[key] = ev;
          }
        }
      }
    }

    final list = byKey.values.toList()
      ..sort((a, b) {
        final c = b.blockNumber.compareTo(a.blockNumber);
        return c != 0 ? c : b.logIndex.compareTo(a.logIndex);
      });
    return list;
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// One getLogs call: filter on the event signature (topic[0]) and the
  /// account OR-list at [topicPos]. Unconstrained positions before [topicPos]
  /// are left null. Mirrors the governance vote-poll filter shape.
  static Future<List<FilterEvent>> _scan(
    DeployedContract contract,
    String eventName,
    int lo,
    int hi,
    int topicPos,
    List<String> topicAddrs,
  ) async {
    try {
      final event = contract.event(eventName);
      // web3dart serializes each inner list as `isEmpty ? null : list`, so an
      // empty inner list means "any" at that topic position.
      final topics = <List<String?>>[
        [bytesToHex(event.signature, include0x: true)], // topic[0]: event sig
      ];
      while (topics.length < topicPos) {
        topics.add(const <String?>[]); // intervening positions: any
      }
      topics.add(topicAddrs); // OR-match accounts at topicPos

      final filter = FilterOptions(
        address: contract.address,
        fromBlock: BlockNum.exact(lo),
        toBlock: BlockNum.exact(hi),
        topics: topics,
      );
      return await PublicOS.web3Client.getLogs(filter);
    } catch (e) {
      Log.w(_tag, 'getLogs $eventName[topic$topicPos] $lo-$hi failed: $e');
      rethrow;
    }
  }

  /// Resolve a block's timestamp (ms epoch), caching per block within a sweep.
  /// THROWS if the block can't be fetched — insertOrIgnore means a row
  /// stamped with a fallback time would never be corrected.
  static Future<int> _blockTimestamp(int? blockNum, Map<int, int> cache) async {
    if (blockNum == null) return DateTime.now().millisecondsSinceEpoch;
    final cached = cache[blockNum];
    if (cached != null) return cached;
    try {
      final block = await PublicOS.web3Client.getBlockInformation(
        blockNumber: '0x${blockNum.toRadixString(16)}',
      );
      final ms = block.timestamp.millisecondsSinceEpoch;
      cache[blockNum] = ms;
      return ms;
    } catch (e) {
      Log.w(_tag, 'block timestamp $blockNum failed: $e');
      rethrow;
    }
  }

  /// Decode a raw log into an [ActivityEvent] per its event type. Returns null
  /// on any decode failure (logged, skipped).
  static ActivityEvent? _decode(
    _ActivitySpec spec,
    DeployedContract contract,
    FilterEvent log,
    int ts,
  ) {
    try {
      final d =
          contract.event(spec.eventName).decodeResults(log.topics!, log.data!);
      String actor;
      String? target;
      final data = <String, dynamic>{};

      switch (spec.type) {
        case ActivityEventType.vouched:
          actor = (d[0] as EthereumAddress).eip55With0x;
          target = (d[1] as EthereumAddress).eip55With0x;
          break;
        case ActivityEventType.citizenized:
          actor = (d[0] as EthereumAddress).eip55With0x;
          data['dueDate'] = (d[1] as BigInt).toString();
          break;
        case ActivityEventType.bonusNameChangeGranted:
          actor = (d[0] as EthereumAddress).eip55With0x;
          break;
        case ActivityEventType.domainPaid:
          actor = (d[1] as EthereumAddress).eip55With0x; // account paid for
          data['payer'] = (d[0] as EthereumAddress).eip55With0x;
          data['months'] = (d[2] as BigInt).toString();
          data['cost'] = (d[3] as BigInt).toString();
          data['paidUntil'] = (d[6] as BigInt).toString();
          break;
        case ActivityEventType.evicted:
          actor = (d[0] as EthereumAddress).eip55With0x;
          data['junkName'] = d[1] as String;
          break;
        case ActivityEventType.nameChanged:
          actor = (d[0] as EthereumAddress).eip55With0x;
          data['oldName'] = d[1] as String;
          data['newName'] = d[2] as String;
          break;
        case ActivityEventType.recordSet:
          actor = (d[0] as EthereumAddress).eip55With0x;
          data['key'] = d[2] as String;
          data['recordType'] = (d[4] as BigInt).toInt();
          // customType == record.subtype on write: 'tab'/'channel' for ROUTER,
          // 'identity'/'text'/'social'/'card'/'status' for PROFILE. Lets the
          // client distinguish tabs (ROUTER+'tab') and cards without re-deriving.
          data['customType'] = d[5] as String;
          break;
        case ActivityEventType.displayNameSet:
          actor = (d[0] as EthereumAddress).eip55With0x;
          data['oldName'] = d[1] as String; // oldDisplayName
          data['newName'] = d[2] as String; // newDisplayName
          break;
        default:
          return null;
      }

      return ActivityEvent(
        eventType: spec.type,
        actor: actor,
        target: target,
        blockNumber: log.blockNum ?? 0,
        logIndex: log.logIndex ?? 0,
        txHash: log.transactionHash ?? '',
        timestamp: ts,
        data: data,
      );
    } catch (e) {
      Log.w(_tag, 'decode ${spec.eventName} failed: $e');
      return null;
    }
  }

  /// Self address + every contact with an on-chain account, deduped.
  static Future<List<EthereumAddress>> _accountSet() async {
    final set = <String, EthereumAddress>{};
    final selfHex = PublicOS.sessionBlockchainAddress;
    if (selfHex != null) {
      try {
        final self = EthereumAddress.fromHex(selfHex);
        set[self.eip55With0x.toLowerCase()] = self;
      } catch (_) {}
    }
    final contacts = await PublicOSContacts.getStoredContacts();
    for (final c in contacts) {
      final a = c.publicosAddress;
      if (a != null) set[a.eip55With0x.toLowerCase()] = a;
    }
    return set.values.toList();
  }

  static Future<int> _readLastBlock() async {
    try {
      final rec = await PublicOSSettings.getSetting(_lastBlockKey);
      return int.tryParse(rec?.value ?? '') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> _writeLastBlock(int block) async {
    try {
      await PublicOSSettings.setSetting(
        _lastBlockKey,
        Record.asSettings(
          key: _lastBlockKey,
          value: block.toString(),
          isSystem: true,
        ),
      );
    } catch (e) {
      Log.w(_tag, 'persist lastCheckedBlock failed: $e');
    }
  }

  static ActivityEventsCompanion _toCompanion(
      ActivityEvent e, String sessionAddr) {
    return ActivityEventsCompanion.insert(
      eventType: e.eventType,
      actor: e.actor,
      target: Value(e.target),
      blockNumber: e.blockNumber,
      logIndex: e.logIndex,
      txHash: e.txHash,
      timestamp: e.timestamp,
      data: Value(e.dataJson),
      sessionAddress: sessionAddr,
    );
  }

  static ActivityEvent _fromRow(ActivityEventRow row) {
    return ActivityEvent(
      eventType: row.eventType,
      actor: row.actor,
      target: row.target,
      blockNumber: row.blockNumber,
      logIndex: row.logIndex,
      txHash: row.txHash,
      timestamp: row.timestamp,
      data: row.data.isEmpty
          ? const {}
          : (jsonDecode(row.data) as Map).cast<String, dynamic>(),
      isRead: row.isRead,
    );
  }

  // ---------------------------------------------------------------------------
  // Background chain-notification worker support
  //
  // The 15-min Workmanager task (publicos_client::runChainNotificationSync)
  // runs the sweep in a fresh isolate and pops OS notifications for fresh
  // on-chain events. All read-only against the public RPC.
  // ---------------------------------------------------------------------------

  /// Seed the sweep cursor to chain head. Called when the user ENABLES chain
  /// notifications so the first background sweep only surfaces events that
  /// happen after opt-in — no cold-start dump of ~3 days of history as a
  /// notification burst. Runs on the main isolate (web3Client already up).
  /// Best-effort: a failure just leaves the cursor where it was.
  static Future<void> seedCursorToHead() async {
    try {
      final head = await PublicOS.web3Client.getBlockNumber();
      await _writeLastBlock(head + 1);
      Log.i(_tag, 'seedCursorToHead: cursor set to ${head + 1}');
    } catch (e) {
      Log.w(_tag, 'seedCursorToHead failed: $e');
    }
  }

  /// Bring a fresh background isolate to the point where a read-only activity
  /// sweep + OS-popup works: creds loaded, web3Client on the public RPC,
  /// module addresses resolved (vouch/domain are null until then and the
  /// sweep force-unwraps them), DB opened, local-notifications plugin
  /// initialized, statics wired. Returns the session address, or null if no
  /// account/keys are present (caller bails).
  ///
  /// Distinct from [PublicOS.ensureBackgroundIsolateReady] (the XMTP/message
  /// path) — the chain sweep needs web3 + ModuleRegistry resolution, not an
  /// XMTP client.
  static Future<String?> ensureChainIsolateReady() async {
    WidgetsFlutterBinding.ensureInitialized();
    const secureStorage = FlutterSecureStorage();

    final lastUserAddress =
        await secureStorage.read(key: 'selected_publicos_AccountAddress');
    if (lastUserAddress == null || lastUserAddress.isEmpty) return null;
    final lastSessionAddress = await secureStorage.read(
      key: 'selected_publicos_SessionAddress_$lastUserAddress',
    );
    if (lastSessionAddress == null || lastSessionAddress.isEmpty) return null;

    // web3 — the public RPC is fine for a read-only getLogs sweep (no BSP
    // upgrade needed in the bg isolate).
    PublicOS.web3Client = Web3Client(PublicOS.activeRpcUrl, http.Client());
    PublicOS.sessionBlockchainAddress = lastSessionAddress;
    PublicOS.isAuthenticated = true;

    // The worker's social
    // half pulls the home inbox with a SIGNED request, so this isolate also
    // needs the two statics the main-isolate restore sets
    // (publicos_accounts.dart::restoreSession): the account address and the
    // session key. The chain half's wallet sweep reads `myPublicosAddress`
    // too, so "Received OX" only fires from the background when it is set.
    // Best effort: a missing key leaves the statics null and the
    // signed pull skips, the chain sweep still runs.
    PublicOS.myPublicosAddress = lastUserAddress;
    try {
      final privB64 = await secureStorage.read(
          key: 'account_${lastUserAddress}_private_key');
      if (privB64 != null && privB64.isNotEmpty) {
        PublicOS.currentBlockchainPrivateKey =
            EthPrivateKey.fromHex(utf8.decode(base64Decode(privB64)));
      }
    } catch (e) {
      Log.w(_tag, 'ensureChainIsolateReady: session key not loaded: $e');
    }

    // Resolve vouch/domain/account manager addresses from ModuleRegistry —
    // the sweep's _p1Specs force-unwrap vouchManager/domainManager.
    await PublicOSBsp.resolveModuleAddresses();

    // DB — resolveDbFile() so this isolate hits the same SQLite file as the
    // main app's PublicOS.database.
    final dbFile = await AppDatabase.resolveDbFile();
    PublicOS.database = AppDatabase(NativeDatabase(dbFile));

    // Notifications plugin (own channel, see [showActivityNotification]).
    final notifications = FlutterLocalNotificationsPlugin();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    await notifications.initialize(initSettings);
    PublicOS.notificationsPlugin = notifications;
    PublicOS.notificationsInitialized = true;

    return lastSessionAddress;
  }

  /// Android channel for on-chain activity notifications (separate from the
  /// messages channel so the user can mute one without the other).
  static const String activityChannelId = 'publicos_activity';

  /// Pop one OS notification for an on-chain event. Generic title/body — the
  /// caller (publicos_client) builds the sentence from its own taxonomy. Use a
  /// distinct [id] per event so they stack instead of replacing each other.
  static Future<void> showActivityNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!PublicOS.notificationsInitialized ||
        PublicOS.notificationsPlugin == null) {
      return;
    }
    const androidDetails = AndroidNotificationDetails(
      activityChannelId,
      'Chain activity',
      channelDescription: 'On-chain events touching you and your contacts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
    await PublicOS.notificationsPlugin!
        .show(id, title, body, details, payload: payload);
  }
}
