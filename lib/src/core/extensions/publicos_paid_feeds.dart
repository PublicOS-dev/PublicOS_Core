import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:publicos_core/src/config/paid_feed_chains.dart';
import 'package:publicos_core/src/contracts/PaidFeedsMemory.g.dart';
import 'package:publicos_core/src/contracts/PaidFeedsManager.g.dart';
import 'package:publicos_core/src/core/publicos_core.dart';
import 'package:publicos_core/src/core/extensions/publicos_ssp.dart';
import 'package:publicos_core/src/core/extensions/publicos_wallets.dart';
import 'package:publicos_core/src/models/feed_server/feed_server_models.dart';
import 'package:publicos_core/src/utils/log.dart';
import 'package:publicos_core/src/utils/tx_utils.dart';
import 'package:wallet/wallet.dart' show EthereumAddress, EtherAmount;
import 'package:web3dart/web3dart.dart';

/// One chain an SSP will honour for paid feeds — the server's answer to "what
/// may I enable?".
///
/// This is NOT [PaidFeedChain], and the difference matters. [PaidFeedChain] is
/// what this build knows about a chain (label, native ticker, explorer); this
/// is what a particular SERVER supports, including the ledger address. Only the
/// server can answer the second, so the owner UI's picker is built from a list
/// of these, never from `PaidFeedChains.all`.
class PaidFeedServerChain {
  final int chainId;

  /// The operator's label. Prefer [displayName], which lets this build's own
  /// name win for a chain it knows.
  final String serverName;

  /// The `PaidFeedsMemory` on this chain, as this server resolves it.
  final String contract;

  /// Native ticker, when the operator configured one. Falls back to this
  /// build's registry.
  final String? nativeSymbol;

  const PaidFeedServerChain({
    required this.chainId,
    required this.serverName,
    required this.contract,
    this.nativeSymbol,
  });

  factory PaidFeedServerChain.fromJson(Map<String, dynamic> json) =>
      PaidFeedServerChain(
        chainId: (json['chain_id'] as num?)?.toInt() ?? 0,
        serverName: json['name'] as String? ?? '',
        contract: json['contract'] as String? ?? '',
        nativeSymbol: json['native_symbol'] as String?,
      );

  String get displayName =>
      PaidFeedChains.nameFor(chainId, serverName: serverName);

  String get symbol =>
      PaidFeedChains.forId(chainId)?.nativeSymbol ?? nativeSymbol ?? '';

  /// True when this build can actually transact here: the server gave us an
  /// address and we have an endpoint for the chain. A server may legitimately
  /// support a chain this app has no RPC for — it can be listed, but not used.
  bool get isUsable =>
      contract.isNotEmpty &&
      (PaidFeedChains.forId(chainId)?.isReachable ?? false);

  /// The entry an owner would store on a channel after registering [planId]
  /// here. Always `payable: true` — it is the plan they just created.
  ChannelAccessEntry entryFor(int planId) => ChannelAccessEntry(
        chainId: chainId,
        feedId: planId,
        contract: contract,
        chainName: serverName,
        payable: true,
      );

  @override
  String toString() => 'PaidFeedServerChain($chainId, $serverName, $contract)';
}

/// One token a plan accepts, and what it costs per period in that token.
class PlanPrice {
  /// `null` ⇒ this chain's native coin.
  final String? token;

  /// Price per period, in the smallest unit of [token] (wei when native).
  final BigInt price;

  /// Symbol + decimals for display. Null only when an unknown ERC-20 refused to
  /// answer `decimals()`, in which case a sheet must show the raw amount rather
  /// than guess a scale.
  final TokenMeta? meta;

  const PlanPrice({required this.token, required this.price, this.meta});

  bool get isNative => token == null;

  @override
  String toString() => 'PlanPrice(${token ?? "native"}: $price)';
}

/// A plan's on-chain terms, as the pay sheet needs to show them.
class PaidFeedPlan {
  final int chainId;
  final int planId;

  /// May change terms and issue comps. **Immutable in the contract** — there is
  /// no transfer function, by design.
  final String registrant;

  /// Where the money goes. Deliberately separable from the publishing identity.
  ///
  /// Note this is the address the contract STORED, which may not be the one the
  /// owner typed: on a chain with an account resolver configured, naming a
  /// PublicOS account resolves to its Safe at registration time.
  final String payout;

  /// Seconds of access bought per unit price.
  final Duration period;

  /// False when the registrant has closed the plan to NEW subscriptions.
  /// Existing entitlements are unaffected.
  final bool open;

  /// False when the id does not exist on this ledger at all.
  final bool exists;

  /// Every token this plan accepts, with its price. **May be empty** — a
  /// registrant can remove the last price, which is a slower way of closing.
  final List<PlanPrice> prices;

  const PaidFeedPlan({
    required this.chainId,
    required this.planId,
    required this.registrant,
    required this.payout,
    required this.period,
    required this.open,
    required this.exists,
    this.prices = const [],
  });

  /// True when a reader can actually buy this right now.
  bool get isPurchasable => exists && open && prices.isNotEmpty;

  /// The price in one token, or null when that token is not accepted.
  PlanPrice? priceIn(String? token) {
    for (final p in prices) {
      if (p.token == null && token == null) return p;
      if (p.token != null &&
          token != null &&
          p.token!.toLowerCase() == token.toLowerCase()) {
        return p;
      }
    }
    return null;
  }

  @override
  String toString() =>
      'PaidFeedPlan(chain: $chainId, plan: $planId, tokens: ${prices.length}, open: $open)';
}

/// What a subscription would cost, resolved before the user commits to it.
///
/// Carries EVERY figure the Confirm screen needs, including the second
/// transaction an ERC-20 payment requires — an approve the user is not told
/// about is a surprise wallet prompt mid-payment.
class PaidFeedQuote {
  final PaidFeedPlan plan;

  /// The token this quote is for — one of [PaidFeedPlan.prices].
  final PlanPrice price;
  final int periods;

  /// `price × periods`, in the token's smallest unit.
  final BigInt cost;

  /// When access would lapse if this were confirmed now. Extends from the
  /// existing expiry when the beneficiary is already subscribed — the contract
  /// never restarts a subscription, so neither does the preview.
  final DateTime expiresAt;

  /// ERC-20 only: the payer's current allowance to the Manager.
  final BigInt? allowance;

  /// ERC-20 only: true when an `approve` must land BEFORE `subscribe`.
  final bool needsApproval;

  /// Estimated gas for `subscribe`, and for the `approve` when one is needed.
  /// Null when estimation failed — show "network fee unknown", never zero.
  final BigInt? subscribeGas;
  final BigInt? approveGas;

  /// Wei per gas at quote time, for turning the gas figures into a fee.
  final BigInt? gasPrice;

  const PaidFeedQuote({
    required this.plan,
    required this.price,
    required this.periods,
    required this.cost,
    required this.expiresAt,
    this.allowance,
    this.needsApproval = false,
    this.subscribeGas,
    this.approveGas,
    this.gasPrice,
  });

  /// Total native fee for every transaction this purchase requires. Null when
  /// any component is unknown — a partial fee shown as if complete is worse
  /// than an honest "unknown".
  BigInt? get totalGasFee {
    final p = gasPrice;
    if (p == null || subscribeGas == null) return null;
    if (needsApproval && approveGas == null) return null;
    final gas = subscribeGas! + (needsApproval ? approveGas! : BigInt.zero);
    return gas * p;
  }
}

/// The reader's entitlement to a channel, resolved across every entry it lists.
class PaidFeedEntitlement {
  /// Null when nothing was found — the reader has never paid.
  final DateTime? paidUntil;

  /// Which entry answered. Null when [paidUntil] is null.
  final ChannelAccessEntry? via;

  const PaidFeedEntitlement({this.paidUntil, this.via});

  bool get isActive =>
      paidUntil != null && paidUntil!.isAfter(DateTime.now().toUtc());

  /// Had a subscription, and it ran out — the copy says "renew", not
  /// "subscribe".
  bool get hasLapsed => paidUntil != null && !isActive;
}

/// Paid feeds — the client half.
///
/// **The ledger is two contracts.** An access entry names the **Memory**: the
/// storage half, whose address an SSP records on a channel and never changes.
/// The **Manager** holds the logic and is swappable, so it is DISCOVERED at
/// call time via `memory.manager()` rather than stored anywhere. Reads go to
/// the Memory; writes go to the Manager.
///
/// Nothing here goes through `PublicOSBsp.resolveModuleAddresses`: the ledger is
/// ecosystem-blind and lives on chains where no ModuleRegistry exists. The
/// Memory address arrives per entry from the SSP, and the endpoint from
/// [PublicOSWallets.evmRpcUrlForChain].
///
/// The in-app EOA is already a valid key on every EVM chain, so this adds no key
/// management — only a per-chain provider and gas estimation.
class PublicOSPaidFeeds {
  PublicOSPaidFeeds._();

  static const _tag = 'PublicOSPaidFeeds';

  /// One client per foreign chain, built lazily and kept for the session.
  ///
  /// Chain 4489 is deliberately NOT cached — [PublicOS.web3Client] is swapped by
  /// RPC failover, so a cached copy would keep talking to an endpoint the rest
  /// of the app has already given up on.
  static final Map<int, Web3Client> _foreignClients = {};

  /// memoryAddress(lowercased)@chainId → manager address. Session-scoped: a
  /// manager swap is rare, and a stale entry surfaces as a reverted write
  /// rather than a wrong one (the old manager loses its onlyManager rights the
  /// instant the Memory repoints).
  static final Map<String, String> _managerCache = {};

  static Web3Client? clientFor(int chainId) {
    if (chainId == PublicOS.CHAIN_ID) return PublicOS.web3Client;
    final cached = _foreignClients[chainId];
    if (cached != null) return cached;
    final url = PublicOSWallets.evmRpcUrlForChain(chainId);
    if (url == null) {
      Log.w(_tag, 'no RPC endpoint for chain $chainId');
      return null;
    }
    final client = Web3Client(url, http.Client());
    _foreignClients[chainId] = client;
    return client;
  }

  /// Drop cached clients and manager lookups. Called on sign-out.
  static Future<void> disposeClients() async {
    final clients = _foreignClients.values.toList();
    _foreignClients.clear();
    _managerCache.clear();
    for (final c in clients) {
      try {
        await c.dispose();
      } catch (_) {}
    }
  }

  /// Forget a cached manager address — call after a known swap.
  static void invalidateManager(int chainId, String memoryAddress) {
    _managerCache.remove('${memoryAddress.toLowerCase()}@$chainId');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Contract handles
  // ═══════════════════════════════════════════════════════════════════════════

  /// The Memory (storage) binding for a chain + address. This is what an access
  /// entry names, and every READ goes here.
  static PaidFeedsMemory? memoryFor(int chainId, String contract) {
    if (contract.isEmpty) return null;
    final client = clientFor(chainId);
    if (client == null) return null;
    return PaidFeedsMemory(
      address: EthereumAddress.fromHex(contract),
      client: client,
      chainId: chainId,
    );
  }

  static PaidFeedsMemory? _memFor(ChannelAccessEntry entry) =>
      memoryFor(entry.chainId, entry.contract);

  /// The Manager (logic) binding, DISCOVERED from the Memory. Every WRITE goes
  /// here.
  ///
  /// Discovered rather than configured on purpose: the Manager is the half that
  /// gets replaced, and a client holding its own copy of that address would send
  /// writes to a contract that lost its rights at the moment of the swap.
  static Future<PaidFeedsManager?> managerFor(int chainId, String contract) async {
    final client = clientFor(chainId);
    if (client == null) return null;

    final key = '${contract.toLowerCase()}@$chainId';
    var addr = _managerCache[key];
    if (addr == null) {
      final mem = memoryFor(chainId, contract);
      if (mem == null) return null;
      try {
        final resolved = await mem.manager();
        addr = resolved.eip55With0x;
        if (addr == _zeroAddress) {
          Log.w(_tag, 'ledger $contract on $chainId has no manager set');
          return null;
        }
        _managerCache[key] = addr;
      } catch (e) {
        Log.e(_tag, 'manager() failed on $chainId/$contract: $e');
        return null;
      }
    }
    return PaidFeedsManager(
      address: EthereumAddress.fromHex(addr),
      client: client,
      chainId: chainId,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // What the SERVER supports — ask, never assume
  // ═══════════════════════════════════════════════════════════════════════════

  /// The chains this SSP will honour for paid feeds.
  ///
  /// **Always ask the server; never offer [PaidFeedChains.all] as the choice
  /// list.** Which chains exist is operator config, so a different host may
  /// serve a different set — and the answer carries the ledger ADDRESS, which
  /// this package deliberately does not hold. An owner UI that offered its own
  /// list would let someone enable a chain their host cannot check, which gates
  /// every reader forever while reporting "you never paid".
  ///
  /// Returns an EMPTY list when the server does not offer paid feeds — a real
  /// state, not an error.
  static Future<List<PaidFeedServerChain>> supportedChains(
      {String? serverAddress}) async {
    final base = serverAddress ?? await PublicOSSsp.getActiveFeedServerUrl();
    if (base == null) return const [];
    try {
      final res = await http
          .get(Uri.parse(
              '${base.replaceAll(RegExp(r'/+$'), '')}/api/paid_feeds/chains'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        // Includes the 404 an older server answers, which means exactly the
        // same thing to a caller: nothing on offer here.
        Log.d(_tag, 'supportedChains: ${res.statusCode} from $base');
        return const [];
      }
      final body = jsonDecode(res.body);
      if (body is! Map || body['chains'] is! List) return const [];
      return [
        for (final row in body['chains'] as List)
          if (row is Map<String, dynamic>) PaidFeedServerChain.fromJson(row),
      ];
    } catch (e) {
      Log.w(_tag, 'supportedChains failed: $e');
      return const [];
    }
  }

  /// The ledger this server currently uses for [chainId], or null when it does
  /// not serve that chain.
  static PaidFeedServerChain? currentChain(
          int chainId, List<PaidFeedServerChain> chains) =>
      chains.where((c) => c.chainId == chainId).firstOrNull;

  /// Whether [entry] points at the ledger this server is using TODAY.
  ///
  /// False means the entry is **outdated, not broken**: the operator moved
  /// their ledger and this channel still
  /// names the previous one. Such an entry is still HONOURED for entitlement —
  /// the gate calls whatever address the row holds — but it can no longer be
  /// re-saved, because the allowlist only accepts the current address. The
  /// owner UI's job is to surface that and offer to move it.
  ///
  /// Returns false for a chain the server does not serve at all, which is the
  /// same practical state: nothing to sell here any more.
  static bool isCurrentContract(
      ChannelAccessEntry entry, List<PaidFeedServerChain> chains) {
    final chain = currentChain(entry.chainId, chains);
    if (chain == null || chain.contract.isEmpty || entry.contract.isEmpty) {
      return false;
    }
    return chain.contract.toLowerCase() == entry.contract.toLowerCase();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Identity
  // ═══════════════════════════════════════════════════════════════════════════

  /// Every address the SERVER will ask the chain about for this reader: the
  /// resolved PublicOS account and the raw signing EOA.
  ///
  /// The gate takes the max across both, which is what makes a bare EOA a
  /// first-class reader — no PublicOS account required to pay for and read.
  static List<String> readIdentities() {
    final out = <String>[];
    void add(String? a) {
      final v = a?.trim();
      if (v == null || v.isEmpty) return;
      if (out.any((e) => e.toLowerCase() == v.toLowerCase())) return;
      out.add(v);
    }

    add(PublicOS.myPublicosAddress);
    add(PublicOS.sessionBlockchainAddress);
    return out;
  }

  /// The address a payment should credit, and the one a pay sheet must state in
  /// full before Confirm.
  ///
  /// Defaults to the PublicOS account when there is one, because that is the
  /// identity that reads on EVERY device — crediting a single device key leaves
  /// the user's other devices locked out of a feed they paid for.
  ///
  /// **Paying the wrong address is unrecoverable.** No refund, and deliberately
  /// no transfer mechanism, so the only remedy is the registrant's goodwill
  /// `grant`. That is why this is a named function in Core rather than a default
  /// buried in a widget.
  static String? defaultBeneficiary() =>
      PublicOS.myPublicosAddress ?? PublicOS.sessionBlockchainAddress;

  // ═══════════════════════════════════════════════════════════════════════════
  // Reads — all against the Memory
  // ═══════════════════════════════════════════════════════════════════════════

  /// A plan's terms, with every accepted token priced and labelled. Null when
  /// the chain could not be reached; check [PaidFeedPlan.exists] for a bad id.
  static Future<PaidFeedPlan?> planFor(ChannelAccessEntry entry) async {
    final mem = _memFor(entry);
    if (mem == null) return null;
    try {
      final id = BigInt.from(entry.feedId);
      final p = await mem.plans((id: id));
      if (!p.exists) {
        return PaidFeedPlan(
          chainId: entry.chainId,
          planId: entry.feedId,
          registrant: _zeroAddress,
          payout: _zeroAddress,
          period: Duration.zero,
          open: false,
          exists: false,
        );
      }

      final tokens = await mem.acceptedTokens((id: id));
      final prices = <PlanPrice>[];
      for (final t in tokens) {
        final addr = t.eip55With0x;
        final isNative = t == EthereumAddress.fromHex(_zeroAddress);
        final price = await mem.priceOf((arg0: id, arg1: t));
        if (price == BigInt.zero) continue; // defensive: not actually accepted
        prices.add(PlanPrice(
          token: isNative ? null : addr,
          price: price,
          meta: isNative
              ? TokenMeta(
                  PaidFeedChains.forId(entry.chainId)?.nativeSymbol ?? '', 18)
              : await PublicOSWallets.resolveTokenMeta(entry.chainId, addr),
        ));
      }

      return PaidFeedPlan(
        chainId: entry.chainId,
        planId: entry.feedId,
        registrant: p.registrant.eip55With0x,
        payout: p.payout.eip55With0x,
        period: Duration(seconds: p.period.toInt()),
        open: p.open,
        exists: true,
        prices: prices,
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'planFor(chain ${entry.chainId}, plan ${entry.feedId}): $e');
      return null;
    }
  }

  /// When [who]'s access to one entry lapses. Null when never paid or the chain
  /// did not answer — a caller cannot distinguish those two, and deliberately
  /// need not: an entry that cannot answer is the next entry's turn, exactly as
  /// on the server.
  static Future<DateTime?> paidUntil(
      ChannelAccessEntry entry, String who) async {
    final mem = _memFor(entry);
    if (mem == null) return null;
    try {
      final until = await mem.paidUntil((
        arg0: BigInt.from(entry.feedId),
        arg1: EthereumAddress.fromHex(who),
      ));
      if (until == BigInt.zero) return null;
      return DateTime.fromMillisecondsSinceEpoch(until.toInt() * 1000,
          isUtc: true);
    } catch (e) {
      Log.w(_tag, 'paidUntil(chain ${entry.chainId}, plan ${entry.feedId}): $e');
      return null;
    }
  }

  /// The reader's entitlement across every entry a channel lists — the paywall
  /// screen's preflight, so it opens knowing "subscribed via Base, expires 14
  /// Mar" rather than asking the user to guess.
  ///
  /// Walks in the server's order (PublicOS first, then ascending) and
  /// short-circuits on the first LIVE timestamp, so an entitled reader on our
  /// own chain never touches a foreign RPC. Keeps walking past expired ones,
  /// because the highest lapsed value is what turns "subscribe" into "renew".
  ///
  /// Every entry is asked, retired ids included — that is how a reader who paid
  /// into a plan whose registrant was lost keeps their access.
  static Future<PaidFeedEntitlement> entitlement(
    List<ChannelAccessEntry> entries, {
    List<String>? identities,
  }) async {
    final who = identities ?? readIdentities();
    if (who.isEmpty || entries.isEmpty) return const PaidFeedEntitlement();

    final ordered = [...entries]
      ..sort((a, b) => PaidFeedChains.compareChainIds(a.chainId, b.chainId));

    final now = DateTime.now().toUtc();
    DateTime? bestLapsed;
    ChannelAccessEntry? lapsedVia;

    for (final entry in ordered) {
      for (final address in who) {
        final until = await paidUntil(entry, address);
        if (until == null) continue;
        if (until.isAfter(now)) {
          return PaidFeedEntitlement(paidUntil: until, via: entry);
        }
        if (bestLapsed == null || until.isAfter(bestLapsed)) {
          bestLapsed = until;
          lapsedVia = entry;
        }
      }
    }
    return PaidFeedEntitlement(paidUntil: bestLapsed, via: lapsedVia);
  }

  /// The plan ids [registrant] currently owns on one ledger.
  ///
  /// Exists because `register()` returns the new id as a RETURN VALUE, which an
  /// EOA transaction cannot read — an owner who missed the receipt has no other
  /// on-chain route back to it. Also the source for "select an existing plan"
  /// in the owner flow.
  static Future<List<int>> plansOf(
      int chainId, String contract, String registrant) async {
    final mem = memoryFor(chainId, contract);
    if (mem == null) return const [];
    try {
      final ids = await mem.plansOf((who: EthereumAddress.fromHex(registrant)));
      return ids.map((e) => e.toInt()).toList();
    } catch (e) {
      Log.e(_tag, 'plansOf(chain $chainId): $e');
      return const [];
    }
  }

  /// What a payout address will actually resolve to, and whether it can receive
  /// money at all — the same answer `register` will give.
  ///
  /// **Preflight this before letting an owner register.** A PublicOS account has
  /// no payable receive, so naming one as payout would register cleanly and
  /// then revert every reader's payment with "payout failed" — a mistake made by
  /// the owner, billed to strangers, weeks later. On a chain with a resolver
  /// configured the account is silently turned into its Safe; without one the
  /// address is refused here rather than in production.
  static Future<({String resolved, bool reachable})?> resolvePayout(
      int chainId, String contract, String payout) async {
    final mgr = await managerFor(chainId, contract);
    final client = clientFor(chainId);
    if (mgr == null || client == null) return null;
    try {
      // SIMULATED, not read: `checkPayout` cannot be `view` because the probe
      // is a real CALL (a Safe's receive() emits, and LOG is forbidden under
      // STATICCALL — the bug this whole guard was rewritten for). The generated
      // binding therefore treats it as a write, so we eth_call it by hand to
      // get the answer without sending anything.
      //
      // Asking the contract rather than re-implementing resolve+probe here is
      // deliberate: this must return exactly what registration will decide, and
      // two copies of that logic would drift.
      final result = await client.callRaw(
        contract: mgr.self.address,
        // Encoded through the binding's OWN abi rather than a hardcoded
        // selector — same rule as the subscribe gas estimate.
        data: mgr.self
            .function('checkPayout')
            .encodeCall([EthereumAddress.fromHex(payout)]),
        sender: EthereumAddress.fromHex(
            PublicOS.sessionBlockchainAddress ?? _zeroAddress),
      );
      final hex = result.replaceFirst(RegExp('^0x'), '');
      if (hex.length < 128) return null; // (address, bool) = two words
      return (
        resolved: EthereumAddress.fromHex('0x${hex.substring(24, 64)}')
            .eip55With0x,
        reachable: BigInt.parse(hex.substring(64, 128), radix: 16) != BigInt.zero,
      );
    } catch (e) {
      Log.e(_tag, 'resolvePayout($payout on $chainId): $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Quote — everything the Confirm screen must show before it commits
  // ═══════════════════════════════════════════════════════════════════════════

  /// Price the purchase in one token, including the ERC-20 approve when needed.
  ///
  /// [token] null means the chain's native coin. Pass one of the plan's accepted
  /// tokens; anything else returns null rather than quoting a price the contract
  /// would refuse.
  ///
  /// This is also the double-charge guard the server relies on: it reads terms
  /// and expiry LIVE from the chain the reader is about to pay on, which is why
  /// the gate needs no separate "chain unreachable" verdict — a chain too sick
  /// to answer here cannot sell anything either, and this returns null.
  static Future<PaidFeedQuote?> quote(
    ChannelAccessEntry entry, {
    String? token,
    int periods = 1,
    String? beneficiary,
    String? payer,
  }) async {
    if (periods < 1) return null;
    final plan = await planFor(entry);
    if (plan == null || !plan.exists) return null;

    final price = plan.priceIn(token);
    if (price == null) return null; // not an accepted token

    final who = beneficiary ?? defaultBeneficiary();
    final from = payer ?? PublicOS.sessionBlockchainAddress;
    final cost = price.price * BigInt.from(periods);

    // Extend from the existing expiry, never restart — mirrors subscribe().
    final now = DateTime.now().toUtc();
    final current = who == null ? null : await paidUntil(entry, who);
    final start = (current != null && current.isAfter(now)) ? current : now;
    final expiresAt = start.add(plan.period * periods);

    final mgr = await managerFor(entry.chainId, entry.contract);

    BigInt? allowance;
    var needsApproval = false;
    BigInt? approveGas;
    if (!price.isNative && from != null && mgr != null) {
      final spender = mgr.self.address.eip55With0x;
      allowance = await erc20Allowance(
        chainId: entry.chainId,
        token: price.token!,
        owner: from,
        spender: spender,
      );
      needsApproval = allowance == null || allowance < cost;
      if (needsApproval) {
        approveGas = await _estimate(
          chainId: entry.chainId,
          from: from,
          to: price.token!,
          data: _encodeApprove(spender, cost),
        );
      }
    }

    // `subscribe` cannot be estimated honestly before an ERC-20 approve exists —
    // the node simulates the transferFrom and it reverts. Skipping it there is
    // more truthful than reporting a failed estimate as zero.
    BigInt? subscribeGas;
    if (from != null && who != null && mgr != null && !needsApproval) {
      subscribeGas = await _estimateBytes(
        chainId: entry.chainId,
        from: from,
        to: mgr.self.address.eip55With0x,
        // Encoded through the binding's OWN abi, not a hardcoded selector: the
        // calldata priced here must be the calldata later signed, and two
        // hand-kept copies drift the moment a signature changes.
        data: mgr.self.function('subscribe').encodeCall([
          BigInt.from(entry.feedId),
          EthereumAddress.fromHex(who),
          BigInt.from(periods),
          EthereumAddress.fromHex(price.token ?? _zeroAddress),
        ]),
        value: price.isNative ? cost : BigInt.zero,
      );
    }

    BigInt? gasPrice;
    try {
      gasPrice = (await clientFor(entry.chainId)?.getGasPrice())?.getInWei;
    } catch (e) {
      Log.w(_tag, 'gasPrice(chain ${entry.chainId}): $e');
    }

    return PaidFeedQuote(
      plan: plan,
      price: price,
      periods: periods,
      cost: cost,
      expiresAt: expiresAt,
      allowance: allowance,
      needsApproval: needsApproval,
      subscribeGas: subscribeGas,
      approveGas: approveGas,
      gasPrice: gasPrice,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Reader-side writes — all against the Manager
  // ═══════════════════════════════════════════════════════════════════════════

  /// Pay for [beneficiary] — NOT for the signing wallet — in [token].
  ///
  /// That decoupling is the point: pay from any wallet on any supported chain,
  /// credit the identity that reads. Gifting falls out for free. [beneficiary]
  /// defaults to [defaultBeneficiary]; a caller that lets a user override it is
  /// responsible for showing the address in full first, because crediting the
  /// wrong one is unrecoverable.
  ///
  /// For an ERC-20 plan, call [erc20Approve] first — the exact-amount
  /// `transferFrom` reverts without an allowance. [quote] reports that in
  /// [PaidFeedQuote.needsApproval].
  static Future<String?> subscribe(
    ChannelAccessEntry entry, {
    String? token,
    int periods = 1,
    String? beneficiary,
  }) async {
    final credentials = PublicOS.currentBlockchainPrivateKey;
    if (credentials == null) {
      Log.w(_tag, 'subscribe: no credentials');
      return null;
    }
    final who = beneficiary ?? defaultBeneficiary();
    if (who == null) {
      Log.w(_tag, 'subscribe: no beneficiary');
      return null;
    }
    final mgr = await managerFor(entry.chainId, entry.contract);
    if (mgr == null) return null;

    final plan = await planFor(entry);
    final price = plan?.priceIn(token);
    if (price == null) {
      Log.w(_tag, 'subscribe: plan does not accept ${token ?? "native"}');
      return null;
    }
    final cost = price.price * BigInt.from(periods);

    try {
      // The native branch sends the EXACT amount — the contract has no refund
      // path and rejects anything else. The ERC-20 branch must send zero value
      // or it reverts on "native not accepted".
      return await mgr.subscribe(
        (
          id: BigInt.from(entry.feedId),
          beneficiary: EthereumAddress.fromHex(who),
          periods: BigInt.from(periods),
          token: EthereumAddress.fromHex(price.token ?? _zeroAddress),
        ),
        credentials: credentials,
        transaction: Transaction(
          value: price.isNative ? EtherAmount.inWei(cost) : EtherAmount.zero(),
        ),
      );
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'subscribe failed: $e');
      rethrow;
    }
  }

  /// Wait for a paid-feed transaction on ITS OWN chain.
  ///
  /// Between signing and confirmation a re-read still legitimately returns 403 —
  /// the payment has not happened yet. The screen for that gap is "confirming
  /// your payment", never a second paywall bounce.
  static Future<bool> waitForTx(int chainId, String txHash,
      {Duration timeout = const Duration(seconds: 90)}) {
    return TxUtils.waitForReceipt(
      txHash,
      label: 'paid_feeds@$chainId',
      client: clientFor(chainId),
      timeout: timeout,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Owner-side writes — all against the Manager
  // ═══════════════════════════════════════════════════════════════════════════

  /// Register a plan. Returns the transaction hash; the NEW PLAN ID must be read
  /// back with [planIdFromTx], because `register()` returns it as a return value
  /// and an EOA transaction cannot read one.
  ///
  /// [prices] maps token → price per period; a null key means the native coin.
  /// Every price must be > 0 — a zero price makes `subscribe` free AND
  /// unbounded. A free channel has NO access entries, never a plan priced zero.
  ///
  /// **Preflight [resolvePayout] first.** Registration refuses a payout that
  /// cannot receive value, and telling the owner that before they sign is the
  /// entire point of the check.
  static Future<String?> register({
    required int chainId,
    required String contract,
    required String payout,
    required Duration period,
    required Map<String?, BigInt> prices,
  }) async {
    final credentials = PublicOS.currentBlockchainPrivateKey;
    final mgr = await managerFor(chainId, contract);
    if (credentials == null || mgr == null || prices.isEmpty) return null;
    try {
      return await mgr.register(
        (
          payout: EthereumAddress.fromHex(payout),
          period: BigInt.from(period.inSeconds),
          tokens: [
            for (final t in prices.keys)
              EthereumAddress.fromHex(t ?? _zeroAddress)
          ],
          prices: prices.values.toList(),
        ),
        credentials: credentials,
      );
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'register failed: $e');
      rethrow;
    }
  }

  /// The plan id a confirmed [register] created, decoded from the Memory's
  /// `PlanRegistered` log. Null when the receipt is not in yet, the tx reverted,
  /// or no such log is present.
  ///
  /// Note the event comes from the MEMORY, not the Manager — storage emits it,
  /// so the log's address is the ledger the entry will name.
  static Future<int?> planIdFromTx(
      int chainId, String contract, String txHash) async {
    final mem = memoryFor(chainId, contract);
    if (mem == null) return null;
    final receipt = await TxUtils.waitForReceiptObject(
      txHash,
      label: 'paid_feeds:register@$chainId',
      client: clientFor(chainId),
    );
    if (receipt == null || receipt.status != true) return null;
    try {
      final event = mem.self.event('PlanRegistered');
      final signature = '0x${bytesToHex(event.signature)}'.toLowerCase();
      for (final log in receipt.logs) {
        final topics = log.topics;
        if (topics == null || topics.isEmpty) continue;
        if (topics.first?.toLowerCase() != signature) continue;
        final decoded = event.decodeResults(topics, log.data ?? '0x');
        if (decoded.isNotEmpty && decoded.first is BigInt) {
          return (decoded.first as BigInt).toInt();
        }
      }
    } catch (e) {
      Log.e(_tag, 'planIdFromTx decode failed: $e');
    }
    return null;
  }

  /// Update a plan's terms. Registrant only.
  static Future<String?> setTerms({
    required int chainId,
    required String contract,
    required int planId,
    required String payout,
    required Duration period,
    bool open = true,
  }) async {
    final credentials = PublicOS.currentBlockchainPrivateKey;
    final mgr = await managerFor(chainId, contract);
    if (credentials == null || mgr == null) return null;
    try {
      return await mgr.setTerms(
        (
          id: BigInt.from(planId),
          payout: EthereumAddress.fromHex(payout),
          period: BigInt.from(period.inSeconds),
          open: open,
        ),
        credentials: credentials,
      );
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'setTerms failed: $e');
      rethrow;
    }
  }

  /// Add, change or REMOVE (price 0) one accepted token on a plan.
  /// Registrant only.
  static Future<String?> setPrice({
    required int chainId,
    required String contract,
    required int planId,
    String? token,
    required BigInt price,
  }) async {
    final credentials = PublicOS.currentBlockchainPrivateKey;
    final mgr = await managerFor(chainId, contract);
    if (credentials == null || mgr == null) return null;
    try {
      return await mgr.setPrice(
        (
          id: BigInt.from(planId),
          token: EthereumAddress.fromHex(token ?? _zeroAddress),
          price: price,
        ),
        credentials: credentials,
      );
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'setPrice failed: $e');
      rethrow;
    }
  }

  /// The comp mechanism: give [beneficiary] access until [until], free.
  /// Registrant only, and it only ever RAISES an expiry.
  ///
  /// This is also the only remedy when someone pays to the wrong address.
  static Future<String?> grant({
    required int chainId,
    required String contract,
    required int planId,
    required String beneficiary,
    required DateTime until,
  }) async {
    final credentials = PublicOS.currentBlockchainPrivateKey;
    final mgr = await managerFor(chainId, contract);
    if (credentials == null || mgr == null) return null;
    try {
      return await mgr.grant(
        (
          id: BigInt.from(planId),
          beneficiary: EthereumAddress.fromHex(beneficiary),
          until: BigInt.from(until.toUtc().millisecondsSinceEpoch ~/ 1000),
        ),
        credentials: credentials,
      );
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'grant failed: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ERC-20 — allowance + approve
  //
  // Hand-encoded rather than bound: these are two functions on a STRANGER's
  // contract, and the registrant chooses the token. Generating a binding would
  // mean adopting some particular ERC-20 implementation's ABI as canonical,
  // when what we actually depend on is the two selectors below.
  // ═══════════════════════════════════════════════════════════════════════════

  static const String _zeroAddress =
      '0x0000000000000000000000000000000000000000';
  static const String _selAllowance = 'dd62ed3e'; // allowance(address,address)
  static const String _selApprove = '095ea7b3'; // approve(address,uint256)

  static String _pad(String hexNo0x) => hexNo0x.padLeft(64, '0');

  static String _word(String address) =>
      _pad(address.replaceFirst(RegExp('^0x'), '').toLowerCase());

  static String _encodeApprove(String spender, BigInt amount) =>
      '0x$_selApprove${_word(spender)}${_pad(amount.toRadixString(16))}';

  /// How much [owner] has approved [spender] to move. Null when the read failed,
  /// which [quote] treats as "approval needed" — the safe direction, since a
  /// redundant approve costs gas but a missing one reverts the payment.
  static Future<BigInt?> erc20Allowance({
    required int chainId,
    required String token,
    required String owner,
    required String spender,
  }) async {
    final client = clientFor(chainId);
    if (client == null) return null;
    try {
      final result = await client.callRaw(
        contract: EthereumAddress.fromHex(token),
        data: _hexToBytes('0x$_selAllowance${_word(owner)}${_word(spender)}'),
      );
      final hex = result.replaceFirst(RegExp('^0x'), '');
      if (hex.isEmpty) return null;
      return BigInt.parse(hex, radix: 16);
    } catch (e) {
      Log.w(_tag, 'allowance(chain $chainId, token $token): $e');
      return null;
    }
  }

  /// Approve the plan's MANAGER to move [amount] of [token].
  ///
  /// The spender is the Manager, because that is what calls `transferFrom` — and
  /// it is discovered, not passed in, so a caller cannot approve the wrong
  /// contract. The amount is exactly the purchase, never an unlimited allowance:
  /// this is a stranger's token on a chain we do not control, and an infinite
  /// approval outlives the transaction that needed it.
  static Future<String?> erc20Approve({
    required int chainId,
    required String contract,
    required String token,
    required BigInt amount,
  }) async {
    final credentials = PublicOS.currentBlockchainPrivateKey;
    final client = clientFor(chainId);
    final mgr = await managerFor(chainId, contract);
    if (credentials == null || client == null || mgr == null) return null;
    try {
      return await client.sendTransaction(
        credentials,
        Transaction(
          to: EthereumAddress.fromHex(token),
          data: _hexToBytes(
              _encodeApprove(mgr.self.address.eip55With0x, amount)),
        ),
        chainId: chainId,
      );
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'approve failed: $e');
      rethrow;
    }
  }

  static Future<BigInt?> _estimate({
    required int chainId,
    required String from,
    required String to,
    required String data,
    BigInt? value,
  }) =>
      _estimateBytes(
        chainId: chainId,
        from: from,
        to: to,
        data: _hexToBytes(data),
        value: value,
      );

  static Future<BigInt?> _estimateBytes({
    required int chainId,
    required String from,
    required String to,
    required Uint8List data,
    BigInt? value,
  }) async {
    final client = clientFor(chainId);
    if (client == null) return null;
    try {
      return await client.estimateGas(
        sender: EthereumAddress.fromHex(from),
        to: EthereumAddress.fromHex(to),
        data: data,
        value: value == null ? null : EtherAmount.inWei(value),
      );
    } catch (e) {
      // A failed estimate is information, not an error: it usually means the
      // call would revert. Report it as "unknown" and let the caller decide.
      Log.w(_tag, 'estimateGas(chain $chainId → $to): $e');
      return null;
    }
  }

  static Uint8List _hexToBytes(String hex) {
    final h = hex.replaceFirst(RegExp('^0x'), '');
    final out = Uint8List(h.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(h.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }
}
