import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:web3dart/web3dart.dart' show Web3Client;
import 'package:wallet/wallet.dart';

import 'package:publicos_core/src/core/publicos_core.dart';
import 'package:publicos_core/src/core/extensions/publicos_bsp.dart';
import 'package:publicos_core/src/core/extensions/publicos_safe.dart';
import 'package:publicos_core/src/core/extensions/publicos_settings.dart';
import 'package:publicos_core/src/core/extensions/publicos_wallets.dart';
import 'package:publicos_core/src/database/database.dart';
import 'package:publicos_core/src/models/activity_event.dart';
import 'package:publicos_core/src/models/record_model.dart';
import 'package:publicos_core/src/utils/log.dart';

/// Token-transfer notifications for the wallets the user owns.
///
/// The **second** reader on the notification bell. Its sibling
/// [PublicOSActivity] sweeps P1 *contract* events (vouch / citizenship /
/// domain / name / profile) scoped to the user's **contacts**; this one sweeps
/// ERC-20 `Transfer` events scoped to the user's **own wallets**. Two readers,
/// two event sets, two cursors — but they persist into the **same**
/// `ActivityEvents` table and surface through the same bell + notifications
/// screen, because to a user "someone vouched for you" and "you got paid" are
/// both just notifications.
///
/// ## Which wallets? — the caller decides, not Core
///
/// [sweep] takes its watched addresses as a **parameter**. Core deliberately
/// does NOT enumerate them, because "which wallets do I watch" is a *client
/// policy*, not a chain fact: the keychain's `walletEnabled` flag is literally
/// a UI toggle ("show this key in the Wallet tab"). The client composes the set
/// (personal main Safe + each org's main Safe + `walletEnabled` keychain EOAs —
/// see `publicos_client/lib/utils/own_wallets.dart`) and passes it in. This
/// mirrors [PublicOSActivity.fetchActivity], which likewise takes `accounts`.
///
/// ## Two calls per sweep, regardless of wallet count
///
/// `getLogs` can only OR *within* one topic position — but it CAN OR any number
/// of addresses at a given position. So one sweep is exactly two calls:
///
///   1. `Transfer` where `from` ∈ {all watched wallets}
///   2. `Transfer` where `to`   ∈ {all watched wallets}
///
/// Watching 3 wallets and watching 30 cost the same. That is what makes a
/// 30-second foreground cadence affordable at all. (Contrast
/// [PublicOSWallets.getRecentTransfers], which is a per-wallet *history* view
/// and so pays 2 calls per wallet.)
///
/// ## Self-transfers collapse for free
///
/// Each log is decoded **once** and its direction derived by testing `from` and
/// `to` for membership in the watched set. So a Safe → own-keychain-EOA move
/// arrives as a single [ActivityEventType.transferSelf], not a duplicate
/// send + receive pair. No dedupe hack — it falls out of ORing rather than
/// scanning per wallet.
///
/// ## Chains
///
/// Only the PublicOS network is wired. [chainId] is threaded through the whole
/// path (cursor key, row `data`, token + client resolution) so another network
/// slots in without reshaping anything — but resolving a foreign token address
/// and RPC is not built, and [sweep] throws for a non-PublicOS chain, exactly
/// like [PublicOSWallets.getRecentTransfers].
extension PublicOSWalletActivity on PublicOS {
  static const _tag = 'WalletActivity';

  /// Range guard — never an open-ended getLogs. Same discipline as
  /// [PublicOSActivity.maxRange].
  static const int maxRange = 5000;

  /// Cold-start seed: on first run scan back ~3 days, NEVER genesis, so a fresh
  /// install shows recent money movement without a full-chain walk.
  /// 30 blocks/min * 60 * 24 * 3 at 2s AuRa block time.
  static const int coldStartLookback = 129600;

  /// The chains swept today. A one-element seam: adding a chain means adding a
  /// token address + an RPC client to [_resolveChain], not reshaping the sweep.
  static List<int> get watchedChains => [PublicOS.CHAIN_ID];

  /// Cursor is **per chain** — chain 4489's progress must never be confused
  /// with another network's block height.
  static String cursorKey(int chainId) => 'wallet_last_block_$chainId';

  // ---------------------------------------------------------------------------
  // Orchestration
  // ---------------------------------------------------------------------------

  /// Sweep every chain in [watchedChains] for transfers touching [wallets],
  /// persist them, and return the resulting unread count for the bell badge.
  ///
  /// Safe to call on a short timer: with an up-to-date cursor a pass scans only
  /// the ~15 blocks minted since the last one, in 2 getLogs calls. Never throws.
  static Future<int> sweep({required List<EthereumAddress> wallets}) async =>
      (await _runSweep(wallets: wallets)).unread;

  /// Like [sweep], but also returns the events newly FETCHED this pass, newest
  /// first. The background worker (publicos_client::runChainNotificationSync)
  /// uses these to decide what to pop as OS notifications; the in-app feed and
  /// badge use [sweep].
  static Future<List<ActivityEvent>> sweepCollectingNew({
    required List<EthereumAddress> wallets,
  }) async =>
      (await _runSweep(wallets: wallets)).fresh;

  static Future<({int unread, List<ActivityEvent> fresh})> _runSweep({
    required List<EthereumAddress> wallets,
  }) async {
    final fresh = <ActivityEvent>[];
    final sessionAddr = PublicOS.sessionBlockchainAddress;
    if (!PublicOS.isAuthenticated || sessionAddr == null) {
      return (unread: 0, fresh: fresh);
    }
    if (wallets.isEmpty) {
      // No wallets to watch (fresh install racing the Safe/keychain load).
      // Leave every cursor alone so the range is retried, don't burn it.
      return (
        unread: await PublicOS.database.getUnreadActivityCount(sessionAddr),
        fresh: fresh,
      );
    }

    for (final chainId in watchedChains) {
      try {
        fresh.addAll(await _sweepChain(
          wallets: wallets,
          chainId: chainId,
          sessionAddr: sessionAddr,
        ));
      } catch (e) {
        // One chain failing must not stop the others.
        Log.e(_tag, 'sweep failed on chain $chainId: $e');
      }
    }

    // Newest-first: a multi-window backfill concatenates older windows first,
    // so the caller's throttle/cap would otherwise keep the OLDEST events.
    fresh.sort((a, b) {
      final byBlock = b.blockNumber.compareTo(a.blockNumber);
      return byBlock != 0 ? byBlock : b.logIndex.compareTo(a.logIndex);
    });

    return (
      unread: await PublicOS.database.getUnreadActivityCount(sessionAddr),
      fresh: fresh,
    );
  }

  /// One chain's windowed walk: fetch → persist → **then** advance the cursor,
  /// per window.
  ///
  /// The cursor only ever moves past blocks that were scanned successfully. A
  /// failed window halts this chain WITHOUT advancing, so the next sweep
  /// resumes from it. This is the same rule as [PublicOSActivity],
  /// deliberately: a sweep that swallows per-window
  /// failures and writes `cursor = head + 1` regardless lets an RPC that rate-
  /// limits partway through permanently seal a gap. An empty window and a
  /// failed window are NOT the same thing.
  static Future<List<ActivityEvent>> _sweepChain({
    required List<EthereumAddress> wallets,
    required int chainId,
    required String sessionAddr,
  }) async {
    final fresh = <ActivityEvent>[];
    final chain = _resolveChain(chainId);
    if (chain == null) {
      // Token module not resolved yet (BSP still booting). Not an error.
      return fresh;
    }

    final head = await (chain.client ?? PublicOS.web3Client).getBlockNumber();
    var fromBlock = await _readCursor(chainId);
    if (fromBlock <= 0) {
      fromBlock = head - coldStartLookback;
      if (fromBlock < 0) fromBlock = 0;
    }
    if (fromBlock > head) return fresh;

    for (var lo = fromBlock; lo <= head; lo += maxRange) {
      final hi = (lo + maxRange - 1) > head ? head : (lo + maxRange - 1);
      final List<ActivityEvent> events;
      try {
        events = await fetchTransfers(
          wallets: wallets,
          token: chain.token,
          chainId: chainId,
          fromBlock: lo,
          toBlock: hi,
          client: chain.client,
        );
      } catch (e) {
        Log.w(_tag, 'chain $chainId sweep halted at window $lo-$hi: $e');
        break; // do NOT advance the cursor — resume here next pass
      }

      if (events.isNotEmpty) {
        await PublicOS.database.insertActivityEvents(
          events.map((e) => _toCompanion(e, sessionAddr)).toList(),
        );
        fresh.addAll(events);
        Log.i(
          _tag,
          'chain $chainId: ${events.length} transfers '
          '($lo-$hi, ${wallets.length} wallets)',
        );
      }
      // insertOrIgnore on {txHash, logIndex, sessionAddress} is the backstop if
      // a boundary block is re-seen.
      await _writeCursor(chainId, hi + 1);
    }
    return fresh;
  }

  // ---------------------------------------------------------------------------
  // Fetch — pure getLogs poll (no persistence). Exposed for tests / Phase B.
  // ---------------------------------------------------------------------------

  /// Scan [fromBlock]..[toBlock] on [token] for `Transfer`s touching any of
  /// [wallets]. Two getLogs calls (from-position, to-position), merged and
  /// deduped on `(txHash, logIndex)`.
  ///
  /// THROWS if any underlying RPC call fails — an empty window and a failed
  /// window are different things, and the caller ([_sweepChain]) needs to tell
  /// them apart to decide whether the cursor may advance. (Contrast
  /// [PublicOSWallets.getRecentTransfers], which is best-effort because a
  /// partial history list is still useful; a partial *sweep* would seal a gap.)
  static Future<List<ActivityEvent>> fetchTransfers({
    required List<EthereumAddress> wallets,
    required EthereumAddress token,
    required int chainId,
    required int fromBlock,
    required int toBlock,
    Web3Client? client,
  }) async {
    // Membership set for the direction test — lowercased, since topic-derived
    // addresses and stored addresses differ in checksum casing.
    final mine = <String>{
      for (final w in wallets) w.eip55With0x.toLowerCase(),
    };
    final topics = wallets.map<String>(PublicOSWallets.addressTopic).toList();

    // getLogs ORs only WITHIN a topic position, so `from` and `to` are two
    // calls — but ALL wallets ride in each. 2 calls, any number of wallets.
    final logs = [
      ...await PublicOSWallets.transferLogs(
        token: token,
        fromBlock: fromBlock,
        toBlock: toBlock,
        topicPos: 1,
        addressTopics: topics,
        client: client,
      ),
      ...await PublicOSWallets.transferLogs(
        token: token,
        fromBlock: fromBlock,
        toBlock: toBlock,
        topicPos: 2,
        addressTopics: topics,
        client: client,
      ),
    ];

    // A self-transfer matches BOTH calls and so appears twice here — the dedupe
    // key collapses it to one log, which is then decoded once and typed
    // `transferSelf`. This is why the user never gets a send AND a receive for
    // moving their own money.
    final byId = <String, ActivityEvent>{};
    final tsCache = <int, int>{};
    // wallet address -> owning account (or null). Negative-cached, so a repeat
    // non-PublicOS counterparty is never re-queried.
    final ownerCache = <String, String?>{};
    for (final log in logs) {
      final t = await PublicOSWallets.decodeTransferLog(
        log,
        tsCache,
        client: client,
      );
      if (t == null) continue;

      final fromMine = mine.contains(t.from.eip55With0x.toLowerCase());
      final toMine = mine.contains(t.to.eip55With0x.toLowerCase());
      if (!fromMine && !toMine) continue; // shouldn't happen; the filter said so

      final String eventType;
      final EthereumAddress wallet; // which of MY wallets this is about
      if (fromMine && toMine) {
        eventType = ActivityEventType.transferSelf;
        wallet = t.from;
      } else if (toMine) {
        eventType = ActivityEventType.transferIn;
        wallet = t.to;
      } else {
        eventType = ActivityEventType.transferOut;
        wallet = t.from;
      }

      // The OTHER end. Resolve it to a PublicOS account so the client can name
      // it ("alice sent you 5 OX") and show its avatar. Null for a self-move.
      final other = eventType == ActivityEventType.transferSelf
          ? null
          : (toMine ? t.from : t.to);
      final otherAccount =
          other == null ? null : await ownerAccountOf(other, ownerCache);

      byId['${t.txHash}:${t.logIndex}'] = ActivityEvent(
        eventType: eventType,
        // actor is ALWAYS `from`, target ALWAYS `to`. Direction lives in the
        // slug, not in which field holds whose address.
        actor: t.from.eip55With0x,
        target: t.to.eip55With0x,
        blockNumber: t.blockNumber,
        logIndex: t.logIndex,
        txHash: t.txHash,
        timestamp: t.timestamp.millisecondsSinceEpoch,
        data: {
          'chainId': chainId,
          'token': token.eip55With0x,
          // BigInt has no JSON representation — string, parsed back client-side.
          'rawAmount': t.rawAmount.toString(),
          // Which of the user's wallets this concerns, so the client can label
          // it ("main", the org's name, the key's label) without re-deriving.
          'wallet': wallet.eip55With0x,
          // The counterparty's PublicOS ACCOUNT (not their wallet), or absent
          // when the other end isn't a registered Safe — a bare EOA, a
          // contract, or `address(0)` on a mint/burn. The client keys its
          // avatar + display-name lookup off this: no account ⇒ no icon.
          if (otherAccount != null) 'counterpartyAccount': otherAccount,
        },
      );
    }

    return byId.values.toList();
  }

  /// Reverse-resolve a WALLET address to the PublicOS account that owns it, so
  /// the client can show the counterparty's username + avatar. Null when the
  /// address belongs to no account.
  ///
  /// **Two disjoint directories, so two lookups** — a main Safe is NEVER in the
  /// wallet directory (`WalletDirectoryManager._storeWallet` hard-reverts
  /// "Cannot add own main Safe explicitly"; `getWallets` merely *virtually*
  /// prepends it), and a linked EOA is never in `SafeMemory`. So:
  ///
  ///   1. `SafeManager.getSafeOwnerAccount` — the dominant case by far, because
  ///      **OX lives in main Safes** (an EOA can't hold it; a send is
  ///      `SafeAuth.executeCall`).
  ///   2. only on a miss → `WalletDirectory.getOwnerByAddress` — a linked EOA.
  ///
  /// **Cost: one `eth_call` per DISTINCT NEW counterparty, not per poll.** It
  /// runs at decode time (only for freshly-fetched logs) and memoises — with
  /// **negative caching**, so a repeat non-PublicOS address never re-queries. A
  /// steady-state poll fetches zero logs and therefore makes zero calls. This
  /// is why it can't be `fetchContact` (4-7 chain calls) — that must never sit
  /// behind a 30-second timer.
  ///
  /// Null for:
  ///   * `address(0)` — a **mint** (credit) or **burn** (debit). Both are
  ///     ordinary here: citizen stipends are minted, and the domain split
  ///     burns 90%.
  ///   * a bare EOA / non-Safe contract that nobody has linked.
  /// The client renders those with **no avatar** — the intended rule.
  /// Public so the wallet's transaction-history view can resolve the same
  /// counterparties. That view renders [PublicOSWallets.getRecentTransfers]
  /// ([TokenTransfer]), which carries no `counterpartyAccount` — only the
  /// sweep's [ActivityEvent] does. Rather than re-implement the two-registry
  /// lookup (and its zero-address trap) at the call site, callers reuse this and
  /// pass their own [cache] to keep the memo across a screen's lifetime.
  static Future<String?> ownerAccountOf(
    EthereumAddress wallet,
    Map<String, String?> cache,
  ) async {
    final key = wallet.eip55With0x.toLowerCase();
    if (cache.containsKey(key)) return cache[key]; // incl. negative cache

    String? account;
    if (!_isZero(wallet)) {
      try {
        // 1. Main Safe (where OX actually lives).
        final owner = await PublicOSSafe.getSafeOwnerAccount(wallet);
        if (owner != null && !_isZero(owner)) {
          account = owner.eip55With0x;
        } else {
          // 2. Linked EOA in the wallet directory — a DIFFERENT registry, not a
          //    fallback for a flaky call. Both views return the ZERO ADDRESS
          //    (not null) when they don't know the address.
          final linked = await PublicOSWallets.getOwnerByAddress(
            protocol: PublicOSWallets.protoEvm,
            addressData: Uint8List.fromList(wallet.value),
          );
          if (linked != null && !_isZero(linked)) account = linked.eip55With0x;
        }
      } catch (e) {
        // Best-effort ONLY here, and deliberately so: a failed *name* lookup
        // must not fail the sweep. The transfer is still a valid, notifiable
        // fact — it just renders without an avatar. This is the one place in
        // the sweep that swallows, because it is cosmetic, not load-bearing.
        Log.w(_tag, 'owner lookup failed for ${wallet.eip55With0x}: $e');
      }
    }
    cache[key] = account; // cache the null too — don't re-query a stranger
    return account;
  }

  static bool _isZero(EthereumAddress a) =>
      a.eip55With0x.toLowerCase() ==
      '0x0000000000000000000000000000000000000000';

  // ---------------------------------------------------------------------------
  // Cursor
  // ---------------------------------------------------------------------------

  /// Seed every watched chain's cursor to head. Called when the user ENABLES
  /// chain notifications, so the first sweep after opt-in only surfaces
  /// transfers that happen *after* opt-in — no cold-start burst of old
  /// payments. Runs on the main isolate (web3Client already up). Best-effort.
  static Future<void> seedCursorToHead() async {
    for (final chainId in watchedChains) {
      try {
        final chain = _resolveChain(chainId);
        final head =
            await (chain?.client ?? PublicOS.web3Client).getBlockNumber();
        await _writeCursor(chainId, head + 1);
        Log.i(_tag, 'chain $chainId cursor seeded to head $head');
      } catch (e) {
        Log.w(_tag, 'chain $chainId cursor seed failed: $e');
      }
    }
  }

  /// Developer utility: reset every cursor to genesis so the next sweep
  /// re-scans from the cold-start window. Pairs with
  /// [PublicOSActivity.clearStored], which wipes the shared table (including
  /// these rows — they live in the same `ActivityEvents`).
  static Future<void> resetCursors() async {
    for (final chainId in watchedChains) {
      await _writeCursor(chainId, 0);
    }
    Log.i(_tag, 'wallet sweep cursors reset');
  }

  static Future<int> _readCursor(int chainId) async {
    try {
      final rec = await PublicOSSettings.getSetting(cursorKey(chainId));
      return int.tryParse(rec?.value ?? '') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> _writeCursor(int chainId, int block) async {
    try {
      final key = cursorKey(chainId);
      await PublicOSSettings.setSetting(
        key,
        Record.asSettings(
          key: key,
          value: block.toString(),
          isSystem: true,
          expiration: DateTime.now().add(const Duration(days: 3650)),
        ),
      );
    } catch (e) {
      Log.w(_tag, 'cursor write failed (chain $chainId): $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Chain resolution — the foreign-chain seam
  // ---------------------------------------------------------------------------

  /// Resolve a chain's token contract + RPC client.
  ///
  /// Today only the PublicOS network: its token address comes from the
  /// ModuleRegistry (via BSP) and its client is the live failover-aware global
  /// one, so [_Chain.client] is null (meaning "use `PublicOS.web3Client`").
  /// Returns null when the token module isn't resolved yet — BSP still booting,
  /// not an error.
  ///
  /// A foreign chain would return a token address from the client's chain
  /// registry plus a transient `Web3Client(chain.rpcUrl)` — the shape the send
  /// sheet already uses for non-OX balance reads. That means Core would need
  /// the chain passed IN (same argument as `wallets`), which is why this throws
  /// rather than guessing.
  static _Chain? _resolveChain(int chainId) {
    if (chainId != PublicOS.CHAIN_ID) {
      throw UnimplementedError(
        'wallet sweep: chain $chainId not supported yet (PublicOS only)',
      );
    }
    final token = PublicOSBsp.publicOSTokenAddress;
    if (token == null) return null;
    return _Chain(token: token, client: null);
  }

  // ---------------------------------------------------------------------------
  // Drift mapping
  // ---------------------------------------------------------------------------

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
}

/// A resolved chain: where the token lives and which client reaches it.
/// [client] null means the global PublicOS network client.
class _Chain {
  final EthereumAddress token;
  final Web3Client? client;
  const _Chain({required this.token, this.client});
}
