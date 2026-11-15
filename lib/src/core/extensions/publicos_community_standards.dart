import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'package:publicos_core/src/core/publicos_core.dart';
import 'package:publicos_core/src/core/extensions/publicos_bsp.dart';
import 'package:publicos_core/src/utils/log.dart';
import 'package:publicos_core/src/utils/pedia_crypto.dart';
import 'package:publicos_core/src/utils/tx_utils.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart'
    show BlockNum, FilterOptions, MsgSignature, bytesToHex, ecRecover, hexToBytes, hexToInt, keccak256, publicKeyToAddress;

/// One penalty's status (`IPenaltiesMemory.Status`). Only [open] ever changes;
/// the other three are final and stay as a record.
enum PenaltyStatus { open, paid, cancelled, promoted }

/// One penalty on an account (`IPenaltiesMemory.Penalty` + its evidence text).
class Penalty {
  final BigInt id;
  final BigInt amount; // total due; the court may modify it, never below paid
  final BigInt paid; // burned so far, by payment or garnish
  final DateTime issuedAt;
  final DateTime payBefore; // set once at issue, never changes
  final PenaltyStatus status;
  final String evidence; // the court's reason

  const Penalty({
    required this.id,
    required this.amount,
    required this.paid,
    required this.issuedAt,
    required this.payBefore,
    required this.status,
    required this.evidence,
  });

  BigInt get remaining => status == PenaltyStatus.open ? amount - paid : BigInt.zero;
  bool get isOverdue => status == PenaltyStatus.open && DateTime.now().isAfter(payBefore);
}

/// Everything the app shows about an account's standing with the court:
/// what it owes, whether services are blocked, and any suspension clock.
class CommunityStanding {
  final BigInt owed; // Σ remaining over open penalties
  final bool blacklisted;
  final bool servicesBlocked; // owed > 0 || blacklisted
  final List<Penalty> penalties; // every penalty, newest first
  final DateTime? suspensionAppliesAt; // a pending 10-day notice; null = none
  final DateTime? suspendedSince; // a running suspension; null = not suspended

  const CommunityStanding({
    required this.owed,
    required this.blacklisted,
    required this.servicesBlocked,
    required this.penalties,
    required this.suspensionAppliesAt,
    required this.suspendedSince,
  });

  List<Penalty> get open => penalties.where((p) => p.status == PenaltyStatus.open).toList();
  bool get hasOverdue => penalties.any((p) => p.isOverdue);

  /// The earliest deadline among open penalties (the countdown the card shows).
  DateTime? get nextDeadline {
    final o = open;
    if (o.isEmpty) return null;
    return o.map((p) => p.payBefore).reduce((a, b) => a.isBefore(b) ? a : b);
  }
}

/// What a flag points at. The chain stores only `keccak256(prefix + url)`, or 0
/// for a whole profile, so the prefix is part of the target's identity.
enum FlagTargetKind {
  profile(''),
  post('post:'),
  comment('comment:'),
  feed('feed:'),
  media('media:');

  final String prefix;
  const FlagTargetKind(this.prefix);
}

/// A flag's status (`IFlagRegistryMemory.FlagStatus`). Expired is not stored:
/// it is [active] with the window past, see [Flag.isOpen].
enum FlagStatus { active, withdrawn, removed, cleared }

/// One flag (`IFlagRegistryMemory.Flag`).
class Flag {
  final BigInt id;
  final EthereumAddress flagger;
  final EthereumAddress owner;
  final Uint8List target; // 32 bytes, all zero = the whole profile
  final Uint8List contentHash; // optional SHA-256 of the media bytes, zero when unset
  final int category; // 0–11, see flagCategories
  final FlagStatus status;
  final DateTime createdAt;
  final DateTime expiresAt; // fixed at creation
  final String url;
  final String host; // SSP slug, '' when none was given
  final String note;

  const Flag({
    required this.id,
    required this.flagger,
    required this.owner,
    required this.target,
    required this.contentHash,
    required this.category,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.url,
    required this.host,
    required this.note,
  });

  bool get isOpen => status == FlagStatus.active && DateTime.now().isBefore(expiresAt);
  bool get isExpired => status == FlagStatus.active && !isOpen;
  bool get isProfile => target.every((b) => b == 0);
}

/// A flagger's record (`IFlagRegistryMemory.Standing`).
class FlaggerStanding {
  final BigInt filed;
  final BigInt overturned; // flags the court removed or cleared as abuse
  final DateTime? suspendedUntil; // null = not suspended from the registry

  const FlaggerStanding({required this.filed, required this.overturned, required this.suspendedUntil});

  bool get isSuspended => suspendedUntil != null && DateTime.now().isBefore(suspendedUntil!);
}

/// What a notice asks for. The type travels INSIDE the encrypted letter.
/// The three sensitive kinds go off chain by default: the requester's address is
/// public once a notice is filed.
enum NoticeKind {
  takedown,
  lawfulOrder,
  ipClaim,
  appeal,
  abuseReport,
  privacy,
  intimateImage,
  childSafety;

  bool get offChain =>
      this == privacy || this == intimateImage || this == childSafety;

  /// Wire spelling inside the letter.
  String get wire => switch (this) {
        takedown => 'takedown',
        lawfulOrder => 'lawful_order',
        ipClaim => 'ip_claim',
        appeal => 'appeal',
        abuseReport => 'abuse_report',
        privacy => 'privacy',
        intimateImage => 'intimate_image',
        childSafety => 'child_safety',
      };
}

/// The outcome of [PublicOSCommunityStandards.sendNotice].
class NoticeSent {
  /// 0 when the letter was sent off chain.
  final BigInt noticeId;
  final bool onChain;

  /// The SSP's receipt: status 1 = Received.
  final int status;
  final DateTime at;

  /// On chain only: the receipt's signer matched the SSP's notice key and it
  /// was posted with `pushUpdate`.
  final bool receiptPosted;

  const NoticeSent({
    required this.noticeId,
    required this.onChain,
    required this.status,
    required this.at,
    required this.receiptPosted,
  });
}

/// Community standards: the app side of the court. Penalties (PenaltiesManager /
/// PenaltiesMemory), the 10-day SuspensionNotice, and flags (FlagRegistry).
/// Notices: an encrypted letter to an SSP's notice key, optionally filed on
/// the FlagRegistry board (see the NOTICES section).
/// Court verbs (issue, modify, blacklist, lift, removeFlag, clearTarget,
/// suspendFlagger) are not here: they are root / admin calls, made by script
/// or courthouse votes.
extension PublicOSCommunityStandards on PublicOS {
  static const _tag = 'CommunityStandards';

  ///*********************************************
  /// PENALTIES — reads
  ///*********************************************

  /// What [account] owes right now (O(1) on chain).
  static Future<BigInt> owed(EthereumAddress account) =>
      PublicOSBsp.penaltiesManagerContract.owed((account: account));

  /// `owed > 0 || blacklisted`: subscriptions refuse the account while true.
  static Future<bool> servicesBlocked(EthereumAddress account) =>
      PublicOSBsp.penaltiesManagerContract.servicesBlocked((account: account));

  static Future<bool> isBlacklisted(EthereumAddress account) =>
      PublicOSBsp.penaltiesMemoryContract.blacklisted((arg0: account));

  /// The pay window new penalties get (stored deadlines never move).
  static Future<Duration> payWindow() async {
    final s = await PublicOSBsp.penaltiesManagerContract.payWindow();
    return Duration(seconds: s.toInt());
  }

  /// One penalty by its per-account [id] (ids count from 0).
  static Future<Penalty> getPenalty(EthereumAddress account, BigInt id) async {
    final mem = PublicOSBsp.penaltiesMemoryContract;
    final results = await Future.wait([
      mem.penalty((a: account, id: id)),
      mem.evidence((a: account, id: id)),
    ]);
    // Struct Penalty { amount; paid; issuedAt; payBefore; Status status } comes back positional.
    final f = results[0] as List<dynamic>;
    return Penalty(
      id: id,
      amount: f[0] as BigInt,
      paid: f[1] as BigInt,
      issuedAt: _time(f[2] as BigInt),
      payBefore: _time(f[3] as BigInt),
      status: PenaltyStatus.values[(f[4] as BigInt).toInt()],
      evidence: results[1] as String,
    );
  }

  /// Every penalty on [account], newest first. With [openOnly] the walk starts
  /// at `head` (no open penalty sits below it, invariant I3).
  static Future<List<Penalty>> getPenalties(EthereumAddress account, {bool openOnly = false}) async {
    final mem = PublicOSBsp.penaltiesMemoryContract;
    final count = (await mem.count((a: account))).toInt();
    final from = openOnly ? (await mem.head((arg0: account))).toInt() : 0;
    final all = await Future.wait([
      for (var i = from; i < count; i++) getPenalty(account, BigInt.from(i)),
    ]);
    final list = openOnly ? all.where((p) => p.status == PenaltyStatus.open).toList() : all;
    return list.reversed.toList();
  }

  /// The whole standing in one read: debt, blacklist, penalties, suspension.
  static Future<CommunityStanding> getStanding(EthereumAddress account) async {
    final results = await Future.wait([
      owed(account),
      isBlacklisted(account),
      getPenalties(account),
      suspensionAppliesAt(account),
      suspendedSince(account),
    ]);
    final o = results[0] as BigInt;
    final b = results[1] as bool;
    return CommunityStanding(
      owed: o,
      blacklisted: b,
      servicesBlocked: o > BigInt.zero || b,
      penalties: results[2] as List<Penalty>,
      suspensionAppliesAt: results[3] as DateTime?,
      suspendedSince: results[4] as DateTime?,
    );
  }

  /// [getStanding] for the active session's account; null when signed out.
  static Future<CommunityStanding?> getMyStanding() async {
    final me = PublicOS.myPublicosAddress;
    if (me == null) {
      Log.w(_tag, 'No current account');
      return null;
    }
    return getStanding(EthereumAddress.fromHex(me));
  }

  ///*********************************************
  /// PENALTIES — writes (any client)
  ///*********************************************

  /// Pay down [account]'s penalties by [amount] from the CALLER's MainSafe
  /// (the fee paradigm: the session key calls, the manager burns from the
  /// MainSafe). Any account, oldest penalty first, partial allowed; the
  /// contract takes at most what is owed. An org key is refused: orgs pay by
  /// a PAY_PENALTIES vote ([PublicOSGovernance]).
  static Future<bool> payPenalties(EthereumAddress account, BigInt amount) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication required');
      return false;
    }
    try {
      final txHash = await PublicOSBsp.penaltiesManagerContract.payPenalties(
        (account: account, amount: amount),
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );
      return await TxUtils.waitForReceipt(txHash, label: 'payPenalties($amount)');
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'payPenalties failed: $e');
      return false;
    }
  }

  /// Promote every overdue open penalty of [account] (anyone may; never a
  /// citizen, who pays through claims). They close as a log entry and the
  /// account goes on the 10-day suspension notice.
  static Future<bool> promoteOverdue(EthereumAddress account) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication required');
      return false;
    }
    try {
      final txHash = await PublicOSBsp.penaltiesManagerContract.promoteOverdue(
        (account: account),
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );
      return await TxUtils.waitForReceipt(txHash, label: 'promoteOverdue');
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'promoteOverdue failed: $e');
      return false;
    }
  }

  ///*********************************************
  /// SUSPENSION NOTICE — the 10-day clock on an account
  /// (not a FlagRegistry notice; see the glossary trap)
  ///*********************************************

  /// When a pending notice suspends [account]; null when none is pending.
  static Future<DateTime?> suspensionAppliesAt(EthereumAddress account) async {
    final at = await PublicOSBsp.suspensionNoticeContract.appliesAt((arg0: account));
    return at == BigInt.zero ? null : _time(at);
  }

  /// When the running suspension began; null when [account] is not suspended
  /// (the last episode ended, or there never was one).
  static Future<DateTime?> suspendedSince(EthereumAddress account) async {
    final ep = await PublicOSBsp.suspensionNoticeContract.suspensionEpisode((account: account));
    if (ep.from == BigInt.zero || ep.to != BigInt.zero) return null;
    return _time(ep.from);
  }

  /// Run a notice that has reached its date (anyone may; a keeper's job).
  static Future<bool> processSuspension(EthereumAddress account) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication required');
      return false;
    }
    try {
      final txHash = await PublicOSBsp.suspensionNoticeContract.process(
        (account: account),
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );
      return await TxUtils.waitForReceipt(txHash, label: 'SuspensionNotice.process');
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'processSuspension failed: $e');
      return false;
    }
  }

  ///*********************************************
  /// FLAGS — FlagRegistry (any individual, privates included; orgs act
  /// through a member)
  ///*********************************************

  /// Category ids enabled at deploy (0–11). The chain stores only the number;
  /// the court can enable new ids, and an id never changes meaning. Privacy,
  /// intimate images and child safety are never flags: they go to a notice.
  static const flagCategories = <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

  /// Max bytes the contract accepts.
  static const flagUrlMaxBytes = 2048;
  static const flagNoteMaxBytes = 280;

  /// Page size for the paged per-target / per-flagger / per-host lists.
  static const _page = 50;

  /// The on-chain target: `keccak256(prefix + url)` with the URL exactly as
  /// served, or 32 zero bytes for a whole profile.
  static Uint8List flagTarget(FlagTargetKind kind, [String url = '']) {
    if (kind == FlagTargetKind.profile) return Uint8List(32);
    return keccak256(Uint8List.fromList(utf8.encode('${kind.prefix}$url')));
  }

  /// One flag by its global id (ids start at 1).
  static Future<Flag> getFlag(BigInt id) async {
    // Struct Flag { flagger; owner; target; contentHash; category; status;
    // createdAt; expiresAt; url; host; note } comes back positional.
    final f = await PublicOSBsp.flagRegistryMemoryContract.getFlag((id: id)) as List<dynamic>;
    return Flag(
      id: id,
      flagger: f[0] as EthereumAddress,
      owner: f[1] as EthereumAddress,
      target: f[2] as Uint8List,
      contentHash: f[3] as Uint8List,
      category: (f[4] as BigInt).toInt(),
      status: FlagStatus.values[(f[5] as BigInt).toInt()],
      createdAt: _time(f[6] as BigInt),
      expiresAt: _time(f[7] as BigInt),
      url: f[8] as String,
      host: f[9] as String,
      note: f[10] as String,
    );
  }

  /// The open flags on a target, oldest first. Walks the target's whole list
  /// in pages (it grows by at most one entry per distinct flagger).
  static Future<List<Flag>> getOpenFlags(EthereumAddress owner, Uint8List target) async {
    final mgr = PublicOSBsp.flagRegistryManagerContract;
    final total = (await mgr.targetFlagCount((owner: owner, target: target))).toInt();
    final ids = <BigInt>[];
    for (var from = 0; from < total; from += _page) {
      ids.addAll(await mgr.activeFlags(
          (owner: owner, target: target, from: BigInt.from(from), limit: BigInt.from(_page))));
    }
    return Future.wait(ids.map(getFlag));
  }

  /// How many open flags a target has; with [category], only that one.
  static Future<int> openFlagCount(EthereumAddress owner, Uint8List target, {int? category}) async {
    final mgr = PublicOSBsp.flagRegistryManagerContract;
    final total = (await mgr.targetFlagCount((owner: owner, target: target))).toInt();
    if (category == null) {
      var n = 0;
      for (var from = 0; from < total; from += _page) {
        n += (await mgr.activeFlags(
                (owner: owner, target: target, from: BigInt.from(from), limit: BigInt.from(_page))))
            .length;
      }
      return n;
    }
    var n = BigInt.zero;
    for (var from = 0; from < total; from += _page) {
      n += await mgr.activeCount((
        owner: owner,
        target: target,
        category: BigInt.from(category),
        from: BigInt.from(from),
        limit: BigInt.from(_page),
      ));
    }
    return n.toInt();
  }

  /// [flagger]'s latest flag on this target, open or closed; null when they
  /// never flagged it. One OPEN flag per person per target; after it closes,
  /// a new one only once [reflagCooldown] has passed since it was filed
  /// (see [canFlagAgainAt]).
  static Future<Flag?> getFlagBy(EthereumAddress flagger, EthereumAddress owner, Uint8List target) async {
    final id = await PublicOSBsp.flagRegistryMemoryContract
        .lastFlagId((flagger: flagger, owner: owner, target: target));
    return id == BigInt.zero ? null : getFlag(id);
  }

  /// How long after filing a flag the same person may flag the same target
  /// again, once that flag is closed (court-set, 7–365 days; default 90).
  static Future<Duration> reflagCooldown() async {
    final s = await PublicOSBsp.flagRegistryManagerContract.reflagCooldown();
    return Duration(seconds: s.toInt());
  }

  /// When the flagger of [f] may flag its target again: never while [f] is
  /// open, else its filing time + [cooldown].
  static DateTime? canFlagAgainAt(Flag f, Duration cooldown) =>
      f.isOpen ? null : f.createdAt.add(cooldown);

  /// [getFlagBy] for the active session's account.
  static Future<Flag?> getMyFlagOn(EthereumAddress owner, Uint8List target) async {
    final me = PublicOS.myPublicosAddress;
    if (me == null) return null;
    return getFlagBy(EthereumAddress.fromHex(me), owner, target);
  }

  /// Every flag [flagger] ever filed, newest first.
  static Future<List<Flag>> getFlagsBy(EthereumAddress flagger) async {
    final mem = PublicOSBsp.flagRegistryMemoryContract;
    final ids = <BigInt>[];
    while (true) {
      final page = await mem.flaggerFlagIds(
          (flagger: flagger, from: BigInt.from(ids.length), limit: BigInt.from(_page)));
      ids.addAll(page);
      if (page.length < _page) break;
    }
    final flags = await Future.wait(ids.map(getFlag));
    return flags.reversed.toList();
  }

  /// Every flag ever filed on [owner]'s content or profile, newest first, with
  /// its current status. Storage keeps no per-owner list, so this reads the
  /// `Flagged` event log (`owner` is its third indexed topic) and then each
  /// flag. Only the owner is meant to see these.
  static Future<List<Flag>> getFlagsOn(EthereumAddress owner) async {
    final contract = PublicOSBsp.flagRegistryManagerContract.self;
    final event = contract.event('Flagged');
    final paddedOwner = '0x${owner.eip55With0x.substring(2).padLeft(64, '0')}'.toLowerCase();
    final head = await PublicOS.web3Client.getBlockNumber();
    final logs = await PublicOS.web3Client.getLogs(FilterOptions(
      address: contract.address,
      fromBlock: const BlockNum.exact(0),
      toBlock: BlockNum.exact(head),
      topics: [
        [bytesToHex(event.signature, include0x: true)],
        [], // id
        [], // flagger
        [paddedOwner],
      ],
    ));
    final ids = <BigInt>{
      for (final l in logs)
        if (l.topics != null && l.topics!.length > 1) hexToInt(l.topics![1]!),
    };
    final flags = await Future.wait(ids.map(getFlag));
    flags.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return flags;
  }

  /// Every flag filed against content on the SSP [host] (its slug), newest
  /// first. The host reads these and decides what to do with its content.
  static Future<List<Flag>> getHostFlags(String host) async {
    final mem = PublicOSBsp.flagRegistryMemoryContract;
    final ids = <BigInt>[];
    while (true) {
      final page = await mem.hostFlagIds((host: host, from: BigInt.from(ids.length), limit: BigInt.from(_page)));
      ids.addAll(page);
      if (page.length < _page) break;
    }
    final flags = await Future.wait(ids.map(getFlag));
    return flags.reversed.toList();
  }

  /// [account]'s record as a flagger: filed, overturned, suspended until.
  static Future<FlaggerStanding> getFlaggerStanding(EthereumAddress account) async {
    // Struct Standing { filed; overturned; suspendedUntil } comes back positional.
    final s = await PublicOSBsp.flagRegistryMemoryContract.standingOf((account: account)) as List<dynamic>;
    final until = s[2] as BigInt;
    return FlaggerStanding(
      filed: s[0] as BigInt,
      overturned: s[1] as BigInt,
      suspendedUntil: until == BigInt.zero ? null : _time(until),
    );
  }

  /// How long new flags stay open (court-set, 7–365 days; default 30).
  static Future<Duration> flagWindow() async {
    final s = await PublicOSBsp.flagRegistryManagerContract.flagWindow();
    return Duration(seconds: s.toInt());
  }

  static Future<bool> isCategoryEnabled(int category) =>
      PublicOSBsp.flagRegistryManagerContract.isCategoryEnabled((id: BigInt.from(category)));

  /// File a public flag on [owner]'s content (or the whole profile). [host] is
  /// the SSP slug serving it, '' when off-network; [note] ≤ 280 bytes.
  /// Refused for an org key, a flagger suspended from the registry, an open
  /// flag of theirs on the same target or one inside the re-flag cooldown, a
  /// disabled category, or an unregistered host.
  static Future<bool> flag({
    required EthereumAddress owner,
    required FlagTargetKind kind,
    String url = '',
    String host = '',
    required int category,
    String note = '',
    Uint8List? contentHash,
  }) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication required');
      return false;
    }
    try {
      final txHash = await PublicOSBsp.flagRegistryManagerContract.flag(
        (
          owner: owner,
          target: flagTarget(kind, url),
          url: url,
          contentHash: contentHash ?? Uint8List(32),
          host: host,
          category: BigInt.from(category),
          note: note,
        ),
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );
      return await TxUtils.waitForReceipt(txHash, label: 'flag(${kind.name}, $category)');
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'flag failed: $e');
      return false;
    }
  }

  /// Withdraw the caller's open flag on a target. The same person may flag it
  /// again once [reflagCooldown] has passed since the flag was filed.
  static Future<bool> unflag(EthereumAddress owner, Uint8List target) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication required');
      return false;
    }
    try {
      final txHash = await PublicOSBsp.flagRegistryManagerContract.unflag(
        (owner: owner, target: target),
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );
      return await TxUtils.waitForReceipt(txHash, label: 'unflag');
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'unflag failed: $e');
      return false;
    }
  }

  ///*********************************************
  /// NOTICES — an encrypted letter to an SSP
  ///*********************************************

  /// The SSP's `notice_key` pointer: its uncompressed public key as 0x-hex,
  /// or null when the SSP takes no notices yet.
  static Future<String?> noticeKeyOf(String slug) async {
    try {
      final v = await PublicOSBsp.socialServerRegistryManagerContract
          .getSocialServerPointer((slug: slug, pointerType: 'notice_key'));
      final k = v.trim();
      return k.isEmpty ? null : k;
    } catch (e) {
      Log.w(_tag, 'notice_key read failed for $slug: $e');
      return null;
    }
  }

  /// Send a notice to the SSP [host] (its registry slug) at [apiUrl].
  ///
  /// The letter (JSON: v, type, host, about, text, from, sentAt) is sealed
  /// with ECIES to the host's notice key; only the host's operator can open
  /// it. Then:
  ///  - ordinary kinds: `fileNotice(host, keccak256(salt ‖ ciphertext))` on
  ///    chain, POST the letter to `/api/notices`, check the signed receipt
  ///    recovers to the notice key, and post it with `pushUpdate`;
  ///  - [NoticeKind.offChain] kinds: the same letter with `noticeId` 0,
  ///    nothing on chain.
  /// The chain half is bookkeeping and public evidence, never a condition of
  /// the host's duty to comply. Returns null on failure ([PublicOS.lastError]).
  static Future<NoticeSent?> sendNotice({
    required String host,
    required String apiUrl,
    required NoticeKind kind,
    required String text,
    String about = '',
  }) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      PublicOS.lastError = 'Authentication required';
      return null;
    }
    final keyHex = await noticeKeyOf(host);
    if (keyHex == null) {
      PublicOS.lastError = 'This SSP does not accept notices yet.';
      return null;
    }
    try {
      final letter = utf8.encode(jsonEncode({
        'v': 1,
        'type': kind.wire,
        'host': host,
        'about': about,
        'text': text,
        'from': PublicOS.myPublicosAddress,
        'sentAt': DateTime.now().toUtc().toIso8601String(),
      }));
      final sealed = PediaCrypto.encrypt(Uint8List.fromList(letter), hexToBytes(keyHex));
      final rnd = Random.secure();
      final salt = Uint8List.fromList(List<int>.generate(32, (_) => rnd.nextInt(256)));
      final commitment = keccak256(Uint8List.fromList([...salt, ...sealed]));

      // 1. File on chain (ordinary kinds only).
      var noticeId = BigInt.zero;
      if (!kind.offChain) {
        final c = PublicOSBsp.flagRegistryManagerContract;
        final txHash = await c.fileNotice(
          (host: host, commitment: commitment),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        );
        final receipt = await TxUtils.waitForReceiptObject(txHash, label: 'fileNotice');
        if (receipt == null || !(receipt.status ?? false)) {
          PublicOS.lastError ??= 'fileNotice: transaction failed';
          return null;
        }
        final ev = c.self.event('NoticeFiled');
        final evSig = bytesToHex(ev.signature, include0x: true).toLowerCase();
        for (final log in receipt.logs) {
          final topics = log.topics;
          if (topics == null || topics.isEmpty || topics.first?.toLowerCase() != evSig) continue;
          if (log.address != c.self.address) continue;
          noticeId = ev.decodeResults(topics.cast<String>(), log.data ?? '0x')[0] as BigInt;
          break;
        }
        if (noticeId == BigInt.zero) {
          PublicOS.lastError = 'fileNotice: mined but no NoticeFiled event';
          return null;
        }
      }

      // 2. Deliver the letter.
      final r = await http
          .post(
            Uri.parse('${apiUrl.replaceAll(RegExp(r'/+$'), '')}/api/notices'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'chainId': PublicOS.CHAIN_ID,
              'noticeId': noticeId.toInt(),
              'salt': bytesToHex(salt, include0x: true),
              'ciphertext': base64.encode(sealed),
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (r.statusCode != 200) {
        PublicOS.lastError = 'The SSP refused the notice (${r.statusCode}): ${r.body}';
        Log.w(_tag, 'notice POST to $host: ${r.statusCode} ${r.body}');
        return null;
      }
      final rec = jsonDecode(r.body) as Map<String, dynamic>;
      final status = (rec['status'] as num).toInt();
      final at = BigInt.from((rec['at'] as num).toInt());
      final sigBytes = hexToBytes(rec['sig'] as String);

      // 3. On chain: check the receipt's signer is the notice key, then post it.
      var posted = false;
      if (!kind.offChain) {
        final digest = await PublicOSBsp.flagRegistryManagerContract
            .noticeDigest((id: noticeId, status: BigInt.from(status), at: at));
        final signer = publicKeyToAddress(ecRecover(
            digest,
            MsgSignature(
              _bytesToBigInt(sigBytes.sublist(0, 32)),
              _bytesToBigInt(sigBytes.sublist(32, 64)),
              sigBytes[64],
            )));
        final expected = publicKeyToAddress(hexToBytes(keyHex).sublist(1));
        if (bytesToHex(signer) != bytesToHex(expected)) {
          Log.w(_tag, 'notice $noticeId: receipt not signed by the notice key; not posted');
        } else {
          final tx = await PublicOSBsp.flagRegistryManagerContract.pushUpdate(
            (id: noticeId, status: BigInt.from(status), at: at, sig: sigBytes),
            credentials: PublicOS.currentBlockchainPrivateKey!,
          );
          posted = await TxUtils.waitForReceipt(tx, label: 'pushUpdate(receipt)');
        }
      }
      return NoticeSent(
        noticeId: noticeId,
        onChain: !kind.offChain,
        status: status,
        at: _time(at),
        receiptPosted: posted,
      );
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'sendNotice failed: $e');
      return null;
    }
  }

  static BigInt _bytesToBigInt(List<int> b) =>
      b.fold(BigInt.zero, (acc, x) => (acc << 8) | BigInt.from(x));

  static DateTime _time(BigInt seconds) =>
      DateTime.fromMillisecondsSinceEpoch(seconds.toInt() * 1000);
}
