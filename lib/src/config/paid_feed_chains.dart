import 'package:publicos_core/src/core/extensions/publicos_wallets.dart';

/// The client-side half of the paid-feeds chain registry.
///
/// **What is deliberately NOT here: the `PaidFeeds` master address.**
///
/// The server sends it, per entry, in both the 403 paywall body and the channel
/// listing's `access_entries`. That is not a convenience — it is what makes the
/// design's own promise true: *"adding Base is a deploy plus one config line —
/// no migration, no contract change, no server change, no client change."* A
/// client holding its own copy of the master map would need an app release for
/// every new chain, and could silently disagree with the server about which
/// contract it just checked. See `contracts.PayableEntry` on the server side.
///
/// So what IS here is only the part a server cannot tell us and the user needs
/// to see: the human name, the native coin, and where to look a transaction up.
/// The RPC endpoint is NOT duplicated either — it resolves through
/// [PublicOSWallets.evmRpcUrlForChain], the same table the wallet and the XMTP
/// invoice renderer already use.
class PaidFeedChain {
  final int chainId;

  /// Display name, e.g. "Base". The server also sends a `chain_name` per entry;
  /// prefer this one when the chain is known and fall back to the server's for
  /// a chain this build has never heard of.
  final String name;

  /// Native coin ticker — what a `token: address(0)` feed is priced in.
  final String nativeSymbol;

  /// Base URL of a block explorer, or null when the chain has none we can link
  /// to. **PublicOS 4489 is deliberately null**: publicos.dev hosts a contract
  /// explorer, not a transaction explorer, and a link that 404s after a payment
  /// is worse than no link at all.
  final String? explorerBaseUrl;

  const PaidFeedChain({
    required this.chainId,
    required this.name,
    required this.nativeSymbol,
    this.explorerBaseUrl,
  });

  /// Every EVM chain in this set uses 18-decimal native units. ERC-20 feeds
  /// carry their own decimals, read via [PublicOSWallets.resolveTokenMeta].
  int get nativeDecimals => 18;

  /// The endpoint this build would use to read and submit on this chain, or
  /// null when it has none — in which case the chain can be *displayed* from
  /// the server's entry data but cannot be quoted or paid on.
  String? get rpcUrl => PublicOSWallets.evmRpcUrlForChain(chainId);

  bool get isReachable => rpcUrl != null;

  String? txUrl(String txHash) =>
      explorerBaseUrl == null ? null : '$explorerBaseUrl/tx/$txHash';

  String? addressUrl(String address) =>
      explorerBaseUrl == null ? null : '$explorerBaseUrl/address/$address';

  @override
  String toString() => 'PaidFeedChain($chainId, $name)';
}

/// The six chains the paid-feeds design supports, and the ordering rule the
/// server derives its walk from.
///
/// This set is a DEFAULT, not a limit. A channel's entries come from its SSP,
/// and a different host may serve a chain not listed here — [forId] returns
/// null for it and the caller falls back to the server-supplied `chain_name`.
/// What an unknown chain cannot do is be quoted or paid on, because
/// [PaidFeedChain.rpcUrl] has no endpoint for it.
class PaidFeedChains {
  PaidFeedChains._();

  /// Our own chain: the launch deploy, and always offered first because it is
  /// our node — the read costs the server nothing and the gas costs the reader
  /// nothing. The server pins it first in its walk for the same reason.
  static const int publicOSChainId = 4489;

  static const Map<int, PaidFeedChain> all = {
    publicOSChainId: PaidFeedChain(
      chainId: publicOSChainId,
      name: 'PublicOS',
      nativeSymbol: 'OX',
    ),
    8453: PaidFeedChain(
      chainId: 8453,
      name: 'Base',
      nativeSymbol: 'ETH',
      explorerBaseUrl: 'https://basescan.org',
    ),
    42161: PaidFeedChain(
      chainId: 42161,
      name: 'Arbitrum One',
      nativeSymbol: 'ETH',
      explorerBaseUrl: 'https://arbiscan.io',
    ),
    137: PaidFeedChain(
      chainId: 137,
      name: 'Polygon PoS',
      nativeSymbol: 'POL',
      explorerBaseUrl: 'https://polygonscan.com',
    ),
    1: PaidFeedChain(
      chainId: 1,
      name: 'Ethereum',
      nativeSymbol: 'ETH',
      explorerBaseUrl: 'https://etherscan.io',
    ),
    56: PaidFeedChain(
      chainId: 56,
      name: 'BNB Chain',
      nativeSymbol: 'BNB',
      explorerBaseUrl: 'https://bscscan.com',
    ),
  };

  /// The chain [chainId], or null when this build does not know it.
  static PaidFeedChain? forId(int chainId) => all[chainId];

  /// Display name for [chainId], falling back to [serverName] (what the entry
  /// carried) and finally to "Chain <id>". Never returns an empty string — a
  /// blank chain label on a pay sheet is worse than a numeric one.
  static String nameFor(int chainId, {String? serverName}) {
    final known = all[chainId]?.name;
    if (known != null) return known;
    final fromServer = serverName?.trim();
    if (fromServer != null && fromServer.isNotEmpty) return fromServer;
    return 'Chain $chainId';
  }

  /// Sort chain ids the way the server walks them: PublicOS first, then
  /// ascending. Mirrored rather than shared because the two sides derive it
  /// independently — but they must agree, or the sheet preselects a different
  /// chain than the one the server would have answered from.
  static int compareChainIds(int a, int b) {
    if (a == b) return 0;
    if (a == publicOSChainId) return -1;
    if (b == publicOSChainId) return 1;
    return a.compareTo(b);
  }
}
