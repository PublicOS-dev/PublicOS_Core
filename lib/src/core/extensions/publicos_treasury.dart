import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:wallet/wallet.dart';
import 'package:publicos_core/src/core/publicos_core.dart';
import 'package:publicos_core/src/contracts/SubsManager.g.dart' show PreviewSettle;
import 'package:publicos_core/src/core/extensions/publicos_bsp.dart';
import 'package:publicos_core/src/core/extensions/publicos_settings.dart';
import 'package:publicos_core/src/core/extensions/publicos_ssp.dart';
import 'package:publicos_core/src/models/record_model.dart';
import 'package:publicos_core/src/utils/eip712_consent.dart' as eip712;
import 'package:publicos_core/src/contracts/Accumulator.g.dart';
import 'package:publicos_core/src/utils/log.dart';

/// Domain-rights economy parameters, read from DomainMemory. The **domain**
/// fee is recurring and char-length-priced:
/// privates pay by length (citizens free at >= [freeTierMinChars]); the cost is
/// split burn/stipend. BSP and SSP are INDEPENDENT goods — see [ServiceInfo].
class DomainInfo {
  final BigInt priceTier3; // 3-char (premium, everyone pays)
  final BigInt priceTier4; // 4-char (premium)
  final BigInt priceTier5; // exactly 5 (private-only; citizens free 5+)
  final BigInt priceTier6Plus; // 6+ (private-only)
  final BigInt freeTierMinChars;
  final BigInt discountBps; // per-additional-month discount
  final BigInt domainPeriod; // seconds per period (e.g. 30 days)
  final BigInt maxDomainMonths;

  DomainInfo({
    required this.priceTier3,
    required this.priceTier4,
    required this.priceTier5,
    required this.priceTier6Plus,
    required this.freeTierMinChars,
    required this.discountBps,
    required this.domainPeriod,
    required this.maxDomainMonths,
  });

  double get priceTier3Tokens => priceTier3.toDouble() / 1e18;
  double get priceTier4Tokens => priceTier4.toDouble() / 1e18;
  double get priceTier5Tokens => priceTier5.toDouble() / 1e18;
  double get priceTier6PlusTokens => priceTier6Plus.toDouble() / 1e18;

  /// Discount in percentage (basis points / 100).
  double get discountPercent => discountBps.toDouble() / 100;
}

/// Service-subscription parameters for one axis (0 = BSP, 1 = SSP) under subs_v2
/// ("pay as served"): ONE fee per period, accrued per second to whoever is the
/// provider during that second; minted for a citizen, drawn from the private's
/// one balance; nothing accrues while the provider is below its min-subscriber
/// gate. `period` and `dormancy` are chain-wide.
class ServiceInfo {
  final BigInt feePerPeriod; // the fee, per `period` seconds (both lanes)
  final BigInt period; // seconds per period (e.g. 30 days)
  final BigInt minSubscribers; // the gate: count >= this → the provider earns
  final BigInt dormancy; // seconds without use after which accrual pauses

  ServiceInfo({
    required this.feePerPeriod,
    required this.period,
    required this.minSubscribers,
    required this.dormancy,
  });

  double get feeTokens => feePerPeriod.toDouble() / 1e18;
  /// Fee per second, the rate `coveredUntil` is computed at.
  double get feePerSecondTokens => period == BigInt.zero ? 0 : feeTokens / period.toDouble();
}

/// One account's subs_v2 record: the shared balance (both axes draw from it),
/// the accrual checkpoint and the last-seen day. `checkpoint == 0` = never
/// subscribed. [sponsored] is the part of
/// the balance a third party put in with `SubsManager.fund`: providers and
/// listed services spend it first and `withdraw` never returns it to the
/// Safe, so `balance - sponsored` is the most the account could take back
/// before the settle a withdraw runs first (the exact figure is
/// [PublicOSTreasury.withdrawable]).
class SubsAccount {
  final BigInt balance;
  final BigInt checkpoint;
  final BigInt lastSeen;
  final BigInt sponsored;
  SubsAccount({required this.balance, required this.checkpoint, required this.lastSeen, required this.sponsored});
  bool get neverSubscribed => checkpoint == BigInt.zero;
  double get balanceTokens => balance.toDouble() / 1e18;
  double get sponsoredTokens => sponsored.toDouble() / 1e18;
}

/// Grant info returned by GrantsManager.getGrant() (shape unchanged from the old
/// GrantManager — pull-model grants now mint into the Accumulator).
class GrantInfo {
  final EthereumAddress recipient;
  final BigInt amount;
  final BigInt intervalSeconds;
  final BigInt lastProcessed;
  final bool active;

  GrantInfo({
    required this.recipient,
    required this.amount,
    required this.intervalSeconds,
    required this.lastProcessed,
    required this.active,
  });

  double get amountTokens => amount.toDouble() / 1e18;

  bool get isRecurring => intervalSeconds > BigInt.zero;

  DateTime? get lastProcessedDateTime {
    if (lastProcessed == BigInt.zero) return null;
    return DateTime.fromMillisecondsSinceEpoch(lastProcessed.toInt() * 1000);
  }
}

/// What the unified [PublicOSTreasury.claim] would pay an account, plus its
/// domain-compliance context. Replaces the old DividendInfo: the single
/// Accumulator pool pays provider earnings + the per-capita Citizen Stipend in
/// one `claim()`. The welcome bonus is credited into `claimable` at
/// citizenship grant (Accumulator.onCitizenize), so it surfaces inside
/// [directPart] — it is no longer a separate preview leg. Outstanding fines
/// are withheld at claim time and reported as [garnished]; [total] is already
/// net of them.
class ClaimInfo {
  final BigInt total; // direct + stipend, net of garnishment
  final BigInt directPart; // provider earnings + grant/bonus credits
  final BigInt stipendPart; // accrued Citizen Stipend
  final BigInt garnished; // withheld against outstanding fines
  final bool isCitizen;
  final BigInt domainPaidUntil;
  final bool domainCompliant;

  ClaimInfo({
    required this.total,
    required this.directPart,
    required this.stipendPart,
    required this.garnished,
    required this.isCitizen,
    required this.domainPaidUntil,
    required this.domainCompliant,
  });

  double get totalTokens => total.toDouble() / 1e18;
  bool get hasClaimable => total > BigInt.zero;

  /// NEVER sentinel (~year 3000) ⟺ a free-tier citizen / seeded root. Such an
  /// account is permanently compliant and never evictable.
  bool get isFreeForever => domainPaidUntil > BigInt.from(32503680000 - 1);

  DateTime? get domainPaidUntilDateTime {
    if (domainPaidUntil == BigInt.zero || isFreeForever) return null;
    return DateTime.fromMillisecondsSinceEpoch(domainPaidUntil.toInt() * 1000);
  }
}

/// Treasury extension for PublicOS — domain rights, BSP/SSP service subs, the
/// unified claim pool, grants, and token balance.
extension PublicOSTreasury on PublicOS {
  static const _tag = 'Treasury';

  ///*********************************************
  /// TOKEN
  ///*********************************************

  /// Get ERC20 token balance for an address (Safe address)
  static Future<BigInt> getTokenBalance(EthereumAddress address) async {
    try {
      return await PublicOSBsp.publicOSTokenContract.balanceOf(
        (account: address),
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting token balance: $e');
      rethrow;
    }
  }

  /// Get total supply of the ERC20 token
  static Future<BigInt> getTokenTotalSupply() async {
    try {
      return await PublicOSBsp.publicOSTokenContract.totalSupply();
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting total supply: $e');
      rethrow;
    }
  }

  /// Check if an account is frozen
  static Future<bool> isAccountFrozen(EthereumAddress address) async {
    try {
      return await PublicOSBsp.publicOSTokenContract.frozen(
        (arg0: address),
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error checking frozen status: $e');
      rethrow;
    }
  }

  ///*********************************************
  /// DOMAIN RIGHTS (reads DomainMemory + DomainManager)
  ///*********************************************

  /// Read the domain-rights parameters (the 4 length-tier prices, the free-tier
  /// threshold, the multi-month discount, and the period bounds) from DomainMemory.
  static Future<DomainInfo> getDomainInfo() async {
    try {
      final results = await Future.wait([
        PublicOSBsp.domainMemoryContract.priceTier3(),
        PublicOSBsp.domainMemoryContract.priceTier4(),
        PublicOSBsp.domainMemoryContract.priceTier5(),
        PublicOSBsp.domainMemoryContract.priceTier6Plus(),
        PublicOSBsp.domainMemoryContract.freeTierMinChars(),
        PublicOSBsp.domainMemoryContract.discountBpsPerMonth(),
        PublicOSBsp.domainMemoryContract.domainPeriod(),
        PublicOSBsp.domainMemoryContract.maxDomainMonths(),
      ]);
      return DomainInfo(
        priceTier3: results[0],
        priceTier4: results[1],
        priceTier5: results[2],
        priceTier6Plus: results[3],
        freeTierMinChars: results[4],
        discountBps: results[5],
        domainPeriod: results[6],
        maxDomainMonths: results[7],
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting domain info: $e');
      rethrow;
    }
  }

  /// The total domain cost to hold `account`'s current name for `months` periods
  /// (length tier × months × multi-month discount). Returns 0 for a free-tier
  /// citizen. Domain pricing is account-specific because it keys on name length.
  static Future<BigInt> quoteDomain(EthereumAddress account, int months) async {
    try {
      return await PublicOSBsp.domainManagerContract.quoteDomain(
        (account: account, months: BigInt.from(months)),
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error quoting domain: $e');
      rethrow;
    }
  }

  /// The timestamp until which `account`'s domain is paid. NEVER (~year 3000) for
  /// a free-tier citizen / seeded root. This is the consensus rent-gate slot.
  static Future<BigInt> getDomainPaidUntil(EthereumAddress account) async {
    try {
      return await PublicOSBsp.domainMemoryContract.domainPaidUntil(
        (account: account),
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting domain paid until: $e');
      rethrow;
    }
  }

  /// True iff `account`'s domain is currently compliant (domainPaidUntil > now,
  /// incl. the NEVER sentinel). This is exactly what the consensus gate checks.
  static Future<bool> isDomainCompliant(EthereumAddress account) async {
    try {
      return await PublicOSBsp.domainMemoryContract.isDomainCompliant(
        (account: account),
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error checking domain compliance: $e');
      rethrow;
    }
  }

  /// The post-lapse "reserved" grace, in seconds, a holder keeps their name
  /// after `domainPaidUntil` passes before it becomes evictable by others (e.g.
  /// ~2 days). Add it to `domainPaidUntil` to get the reserved-until deadline.
  static Future<BigInt> getDomainEvictionGracePeriod() async {
    try {
      return await PublicOSBsp.domainMemoryContract.evictionGracePeriod();
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting domain eviction grace period: $e');
      rethrow;
    }
  }

  /// Pay the recurring domain fee for `months` periods (self-pay; msg.sender is
  /// the account's own session). A free-tier (5+) citizen is charged nothing and
  /// stamped NEVER. Returns the transaction hash on success.
  static Future<String?> payDomain(int months) async {
    try {
      if (!PublicOS.isAuthenticated ||
          PublicOS.currentBlockchainPrivateKey == null) {
        Log.w(_tag, 'Not authenticated or no credentials');
        return null;
      }

      Log.d(_tag, 'Paying domain ($months months) for self...');
      final txHash = await PublicOSBsp.domainManagerContract.payDomain(
        (months: BigInt.from(months)),
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );
      Log.i(_tag, 'Domain paid, tx: $txHash');
      return txHash;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error paying domain: $e');
      rethrow;
    }
  }

  ///*********************************************
  /// BSP / SSP SUBSCRIPTIONS — subs_v2, "pay as served" (one manager, one memory, two axes)
  ///
  /// What changed from v1 (months prepaid per axis, two lanes, two clocks):
  ///   · one balance per account, both axes draw from it; the fee accrues per
  ///     SECOND to whoever is the provider that second and is paid when anyone
  ///     calls `settle` (the SSP keepers do; one settle pays both providers)
  ///   · a citizen's share is MINTED to the provider; a private's share is drawn
  ///     from the balance — "privates always pay", but nothing accrues while the
  ///     provider sits below its min-subscriber gate (served, not charged)
  ///   · subscribe(axis, slug, topUp): join, switch (slug != current, effective
  ///     NOW, paid to the second) or top up only (slug == "" keeps the current);
  ///     leave(axis); withdraw(amount) returns unsettled balance to the MainSafe
  ///   · no months, no extend, no citizen lock: `coveredUntil` is what the app shows
  ///     (private: when the balance runs out at the current rate, or dormancy;
  ///     citizen: dormancy only — "covered while you use it")
  ///   · dormancy: after `dormancy` seconds without use accrual pauses by itself,
  ///     the next use resumes it (the app's "seen" ping), nothing to re-subscribe
  ///*********************************************

  /// Axis ids, as the contracts count them.
  static final BigInt bspAxis = BigInt.zero;
  static final BigInt sspAxis = BigInt.one;

  /// One axis's parameters: fee / period, the gate, the dormancy window.
  static Future<ServiceInfo> getServiceInfo(BigInt axis) async {
    try {
      final mem = PublicOSBsp.subsMemoryContract;
      final results = await Future.wait([
        mem.fee((axis: axis)),
        mem.period(),
        mem.minSubscribers((axis: axis)),
        mem.dormancy(),
      ]);
      return ServiceInfo(feePerPeriod: results[0], period: results[1], minSubscribers: results[2], dormancy: results[3]);
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting service info (axis $axis): $e');
      rethrow;
    }
  }

  static Future<ServiceInfo> getBspServiceInfo() => getServiceInfo(bspAxis);
  static Future<ServiceInfo> getSspServiceInfo() => getServiceInfo(sspAxis);

  /// Current subscriber count for a slug on an axis.
  static Future<BigInt> getSubscriberCount(BigInt axis, String slug) async {
    try {
      return await PublicOSBsp.subsMemoryContract.subscriberCount((axis: axis, slug: slug));
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting subscriber count ($axis/$slug): $e');
      rethrow;
    }
  }

  static Future<BigInt> getBspSubscriberCount(String slug) => getSubscriberCount(bspAxis, slug);
  static Future<BigInt> getSspSubscriberCount(String slug) => getSubscriberCount(sspAxis, slug);

  /// True iff this provider is past its gate (count >= minSubscribers): it earns
  /// from its subscribers; below it nothing is minted and nothing is charged.
  static Future<bool> isProviderPaid(BigInt axis, String slug) async {
    try {
      return await PublicOSBsp.subsManagerContract.isProviderPaid((axis: axis, slug: slug));
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error checking provider gate ($axis/$slug): $e');
      rethrow;
    }
  }

  static Future<bool> isBspPaid(String slug) => isProviderPaid(bspAxis, slug);
  static Future<bool> isSspPaid(String slug) => isProviderPaid(sspAxis, slug);

  /// Combined view for a provider card: subscriber count, the gate threshold, and
  /// whether the gate lets payments flow. UI: "12 / 15 subscribers — 3 more to earn".
  static Future<({BigInt count, BigInt threshold, bool paid})> getGateStatus(BigInt axis, String slug) async {
    try {
      final results = await Future.wait([
        PublicOSBsp.subsMemoryContract.subscriberCount((axis: axis, slug: slug)),
        PublicOSBsp.subsMemoryContract.minSubscribers((axis: axis)),
      ]);
      final paid = await PublicOSBsp.subsManagerContract.isProviderPaid((axis: axis, slug: slug));
      return (count: results[0], threshold: results[1], paid: paid);
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting gate status ($axis/$slug): $e');
      rethrow;
    }
  }

  static Future<({BigInt count, BigInt threshold, bool paid})> getBspGateStatus(String slug) => getGateStatus(bspAxis, slug);
  static Future<({BigInt count, BigInt threshold, bool paid})> getSspGateStatus(String slug) => getGateStatus(sspAxis, slug);

  /// The slug an account is assigned to on an axis ("" = none).
  static Future<String> assignedSlug(BigInt axis, EthereumAddress account) async {
    try {
      return await PublicOSBsp.subsMemoryContract.slugOf((axis: axis, a: account));
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error reading assigned slug ($axis): $e');
      rethrow;
    }
  }

  /// THE predicate: is this account served on this axis right now. Same read the
  /// SSP gate, the BSP gate and Quests make — no lane branch in the client.
  static Future<bool> isActive(BigInt axis, EthereumAddress account) async {
    try {
      return await PublicOSBsp.subsManagerContract.isActive((axis: axis, a: account));
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error reading isActive ($axis): $e');
      rethrow;
    }
  }

  static Future<bool> isBspActive(EthereumAddress account) => isActive(bspAxis, account);
  static Future<bool> isSspActive(EthereumAddress account) => isActive(sspAxis, account);

  /// What the app shows: unix seconds until which the account is covered. 0 =
  /// never subscribed. Private: when the balance runs out at the current rate
  /// (or dormancy, if sooner). Citizen: dormancy only.
  static Future<BigInt> coveredUntil(EthereumAddress account) async {
    try {
      return await PublicOSBsp.subsManagerContract.coveredUntil((a: account));
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error reading coveredUntil: $e');
      rethrow;
    }
  }

  /// The account's subs record (shared balance, checkpoint, last seen) plus
  /// the sponsored part of that balance (`SubsMemory.sponsored`, tail-appended
  /// in the arch_v2 pass).
  static Future<SubsAccount> getSubsAccount(EthereumAddress account) async {
    try {
      final r = await PublicOSBsp.subsMemoryContract.getAccount((a: account));
      // (balance uint128, checkpoint uint64, lastSeen uint64) — tuple or struct-like list.
      final List<dynamic> f = r is List ? r : (r as dynamic).toList();
      final sponsored = await PublicOSBsp.subsMemoryContract.sponsored((arg0: account));
      return SubsAccount(balance: f[0] as BigInt, checkpoint: f[1] as BigInt, lastSeen: f[2] as BigInt, sponsored: sponsored);
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error reading subs account: $e');
      rethrow;
    }
  }

  /// What `withdraw` would let the account take right now: the balance after
  /// the settle a withdraw runs first, minus whatever of the sponsored part
  /// that settle leaves (`SubsManager.withdrawable`). The sheets cap the
  /// amount field at this, not at `balance - accrued`.
  static Future<BigInt> withdrawable(EthereumAddress account) async {
    try {
      return await PublicOSBsp.subsManagerContract.withdrawable((a: account));
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error reading withdrawable: $e');
      rethrow;
    }
  }

  /// What `settle` would pay right now (toBsp, toSsp, minted = citizen lane).
  static Future<PreviewSettle> previewSettle(EthereumAddress account) async {
    try {
      return await PublicOSBsp.subsManagerContract.previewSettle((a: account));
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error previewing settle: $e');
      rethrow;
    }
  }

  /// How much balance N periods of one axis cost at today's fee — the top-up a
  /// private deposits to be covered that long (there are no prepaid months any
  /// more; the balance just lasts `balance / rate`). Kept under the v1 names so
  /// the sheets' steppers keep working: months are periods here.
  static Future<BigInt> quoteBalance(BigInt axis, int periods) async {
    try {
      final fee = await PublicOSBsp.subsMemoryContract.fee((axis: axis));
      return fee * BigInt.from(periods);
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error quoting balance ($axis x $periods): $e');
      rethrow;
    }
  }

  static Future<BigInt> quoteBspSub(int months) => quoteBalance(bspAxis, months);
  static Future<BigInt> quoteSspSub(int months) => quoteBalance(sspAxis, months);

  /// subscribe(axis, slug, topUp): join / switch to `slug` (effective now) and/or
  /// deposit `topUp` OX from the MainSafe into the shared balance. `slug` ""
  /// keeps the current provider (top-up only). A citizen passes 0.
  static Future<String?> subscribe(BigInt axis, String slug, {BigInt? topUp}) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
        Log.w(_tag, 'Not authenticated or no credentials');
        return null;
      }
      final deposit = topUp ?? BigInt.zero;
      Log.d(_tag, 'subscribe(axis $axis, "$slug", topUp ${deposit.toDouble() / 1e18} OX)...');
      final txHash = await PublicOSBsp.subsManagerContract.subscribe(
        (axis: axis, slug: slug, topUp: deposit),
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );
      Log.i(_tag, 'subscribed, tx: $txHash');
      return txHash;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error subscribing ($axis/$slug): $e');
      rethrow;
    }
  }

  /// v1-shaped doors kept for the sheets: join `slug` and deposit `months`
  /// periods' worth of balance (0 months = join only, the citizen case).
  static Future<String?> subscribeBsp(String slug, int months) async =>
      subscribe(bspAxis, slug, topUp: months > 0 ? await quoteBalance(bspAxis, months) : BigInt.zero);
  static Future<String?> subscribeSsp(String slug, int months) async =>
      subscribe(sspAxis, slug, topUp: months > 0 ? await quoteBalance(sspAxis, months) : BigInt.zero);

  /// Deposit into the shared balance without changing providers.
  static Future<String?> topUpBalance(BigInt amount) => subscribe(bspAxis, '', topUp: amount);

  /// Re-stamp "seen today" by hand: `subscribe` with no slug and no deposit
  /// settles and sets `lastSeen` to today, which is exactly what ends a
  /// dormancy (60 d without use) and restarts accrual. The stand-in for the
  /// daily signed `Seen` ping until the clients send it;
  /// Services shows it as RESUME on an inactive service.
  static Future<String?> touch() => subscribe(bspAxis, '', topUp: BigInt.zero);

  /// Leave an axis's provider now (settles to the second first).
  static Future<String?> leave(BigInt axis) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) return null;
      final txHash = await PublicOSBsp.subsManagerContract.leave((axis: axis), credentials: PublicOS.currentBlockchainPrivateKey!);
      Log.i(_tag, 'left axis $axis, tx: $txHash');
      return txHash;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error leaving axis $axis: $e');
      rethrow;
    }
  }

  ///*********************************************
  /// THE DAILY "SEEN" PING — what keeps a subscription out of dormancy
  ///
  /// subs_v2 pauses accrual and flips `isActive` false after `dormancy` (60 d)
  /// with no proof of use. Proof of use is an EIP-712 `Seen(account, day)`
  /// signed by a session key of the account; the SSP keeps the newest per
  /// account (`POST /api/subs/seen`) and its sweep relays it inside
  /// `SubsManager.settle(account, day, sig)` — the app never pays gas for it.
  /// Privacy rule: the ping carries a UTC DAY NUMBER, never
  /// a time; it is signed at most once per day, and the relay happens in the
  /// sweep's own schedule, so not even the tx time is the user's.
  /// Wired once, in Core: `PublicOS.initSSP()` fires [pingSeenIfDue], so both
  /// apps get it with no app code.
  ///*********************************************

  /// Settings key holding the last UTC day a ping was accepted.
  static const String seenPingSettingKey = 'subs_seen_day';

  /// Today's UTC day number (unix seconds ÷ 86400) — what the contract expects.
  static int utcDayNow() => DateTime.now().toUtc().millisecondsSinceEpoch ~/ 86400000;

  /// Sign `Seen(account, day)` with the active session key. The digest is the
  /// contract's own (`seenDigest`, EIP-712 "PublicOS"/"1"), the signature the
  /// raw 65-byte r‖s‖v the contract recovers.
  static Future<Uint8List> signSeen(EthereumAddress account, int day) async {
    final key = PublicOS.currentBlockchainPrivateKey;
    if (key == null) throw StateError('no session key to sign the ping');
    final digest = await PublicOSBsp.subsManagerContract
        .seenDigest((a: account, day: BigInt.from(day)));
    return eip712.signDigest(digest, key);
  }

  /// Once per UTC day, hand the active SSP a signed ping. Idempotent and
  /// silent: a miss costs nothing today (dormancy is 60 days away) and the
  /// next call retries. Skips when the account is not served by an SSP (the
  /// server would refuse with SSP_NOT_SUBSCRIBED). Returns true when today is
  /// covered — already pinged, or stored just now.
  static Future<bool> pingSeenIfDue() async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) return false;
      final hex = PublicOS.myPublicosAddress;
      if (hex == null || hex.isEmpty) return false;
      final day = utcDayNow();
      final last = await PublicOSSettings.getSetting(seenPingSettingKey);
      if (int.tryParse(last?.value ?? '') == day) return true;
      final ssp = await PublicOSSsp.getActiveFeedServerUrl();
      if (ssp == null || ssp.isEmpty) return false;
      final account = EthereumAddress.fromHex(hex);
      if (!await isActive(sspAxis, account)) return false;
      final sig = await signSeen(account, day);
      final sigHex = '0x${sig.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
      final r = await http
          .post(
            Uri.parse('${ssp.replaceAll(RegExp(r'/+$'), '')}/api/subs/seen'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'account': account.eip55With0x, 'day': day, 'signature': sigHex}),
          )
          .timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) {
        Log.w(_tag, 'seen ping refused by $ssp: ${r.statusCode} ${r.body}');
        return false;
      }
      await PublicOSSettings.setSetting(
        seenPingSettingKey,
        Record.asSettings(
          key: seenPingSettingKey,
          value: day.toString(),
          isSystem: true,
          expiration: DateTime.now().add(const Duration(days: 3650)),
        ),
      );
      Log.i(_tag, 'seen ping stored for UTC day $day');
      return true;
    } catch (e) {
      Log.w(_tag, 'seen ping skipped: $e');
      return false;
    }
  }

  /// Take unsettled balance back to the MainSafe (settles first; the rest never left).
  static Future<String?> withdrawBalance(BigInt amount) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) return null;
      final txHash = await PublicOSBsp.subsManagerContract.withdraw((amount: amount), credentials: PublicOS.currentBlockchainPrivateKey!);
      Log.i(_tag, 'withdrew ${amount.toDouble() / 1e18} OX, tx: $txHash');
      return txHash;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error withdrawing balance: $e');
      rethrow;
    }
  }

  ///*********************************************
  /// THE UNIFIED CLAIM POOL (Accumulator)
  ///
  /// One pool, one claim(): provider earnings + per-capita Citizen Stipend,
  /// pulled in a single transaction net of any fine garnishment. The welcome
  /// bonus is credited at citizenship grant (onCitizenize) and rides along in
  /// the direct leg.
  ///*********************************************

  /// Total amount [claim] would pay `account` right now (direct + stipend + bonus).
  static Future<BigInt> getClaimable(EthereumAddress account) async {
    try {
      final preview = await PublicOSBsp.accumulatorContract.previewClaim(
        (account: account),
      );
      return preview.total;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting claimable: $e');
      rethrow;
    }
  }

  /// Full claim breakdown for `account` (each pull leg) plus its domain-compliance
  /// context (citizen status + domainPaidUntil + compliant).
  static Future<ClaimInfo> getClaimInfo(EthereumAddress account) async {
    try {
      final results = await Future.wait([
        PublicOSBsp.accumulatorContract.previewClaim((account: account)),
        PublicOSBsp.citizenshipManagerContract.isCitizen((account: account)),
        PublicOSBsp.domainMemoryContract.domainPaidUntil((account: account)),
        PublicOSBsp.domainMemoryContract.isDomainCompliant((account: account)),
      ]);
      final preview = results[0] as PreviewClaim;
      return ClaimInfo(
        total: preview.total,
        directPart: preview.directPart,
        stipendPart: preview.stipendPart,
        garnished: preview.garnished,
        isCitizen: results[1] as bool,
        domainPaidUntil: results[2] as BigInt,
        domainCompliant: results[3] as bool,
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting claim info: $e');
      rethrow;
    }
  }

  /// Claim info for the current user.
  static Future<ClaimInfo?> getCurrentUserClaimInfo() async {
    final accountAddress = PublicOS.myPublicosAddress != null
        ? EthereumAddress.fromHex(PublicOS.myPublicosAddress!)
        : null;
    if (accountAddress == null) {
      Log.w(_tag, 'No current account');
      return null;
    }
    return getClaimInfo(accountAddress);
  }

  /// Pull everything the economy owes the current user in one tx: provider
  /// earnings + accrued Citizen Stipend, net of any fine garnishment.
  /// Returns the transaction hash on success.
  static Future<String?> claim() async {
    try {
      if (!PublicOS.isAuthenticated ||
          PublicOS.currentBlockchainPrivateKey == null) {
        Log.w(_tag, 'Not authenticated or no credentials');
        return null;
      }

      Log.d(_tag, 'Claiming from the Accumulator pool...');
      final txHash = await PublicOSBsp.accumulatorContract.claim(
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );
      Log.i(_tag, 'Claimed, tx: $txHash');
      return txHash;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error claiming: $e');
      rethrow;
    }
  }

  ///*********************************************
  /// GRANTS (via GrantsManager — pull-model into the Accumulator)
  ///*********************************************

  /// Get grant details by ID
  static Future<GrantInfo> getGrant(int grantId) async {
    try {
      final result = await PublicOSBsp.grantsManagerContract.getGrant(
        (grantId: BigInt.from(grantId)),
      );
      // Result is a tuple: (address recipient, uint256 amount, uint256 intervalSeconds, uint256 lastProcessed, bool active)
      final data = result as List<dynamic>;
      return GrantInfo(
        recipient: data[0] as EthereumAddress,
        amount: data[1] as BigInt,
        intervalSeconds: data[2] as BigInt,
        lastProcessed: data[3] as BigInt,
        active: data[4] as bool,
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting grant: $e');
      rethrow;
    }
  }

  /// Get total grant count
  static Future<BigInt> getGrantCount() async {
    try {
      return await PublicOSBsp.grantsManagerContract.getGrantCount();
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting grant count: $e');
      rethrow;
    }
  }
}
