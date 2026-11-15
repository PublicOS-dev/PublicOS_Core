import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:publicos_core/src/core/core.dart';
import 'package:publicos_core/src/utils/log.dart';
import 'package:publicos_core/src/utils/eip712_consent.dart' as eip712;
import 'package:publicos_core/src/utils/ed25519.dart' as ed;
import 'package:publicos_core/src/utils/base58.dart' as b58;
import 'package:publicos_core/src/utils/solana_metadata.dart' as solmeta;
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart' show keccak256, EthPrivateKey;
import 'package:web3dart/web3dart.dart' as w3
    show FilterOptions, BlockNum, FilterEvent, Web3Client;
import 'package:wallet/wallet.dart';

/// A token's symbol + decimals, for formatting raw on-chain amounts.
class TokenMeta {
  final String symbol;
  final int decimals;
  const TokenMeta(this.symbol, this.decimals);

  @override
  String toString() => 'TokenMeta($symbol, $decimals)';
}

/// An ERC-20 transfer decoded from EVM calldata.
class Erc20Transfer {
  /// The token contract address (the call's `to`).
  final String token;

  /// Recipient of the tokens.
  final String recipient;

  /// Raw on-chain amount — needs the token's decimals to format.
  final BigInt rawAmount;

  const Erc20Transfer({
    required this.token,
    required this.recipient,
    required this.rawAmount,
  });

  @override
  String toString() =>
      'Erc20Transfer(token: $token, to: $recipient, raw: $rawAmount)';
}

/// A historical token transfer, decoded from a `Transfer` event log. Unlike
/// [Erc20Transfer] (a single tx's calldata), this carries both parties, the
/// block, and the time — the shape a transaction-history list needs.
class TokenTransfer {
  final EthereumAddress from;
  final EthereumAddress to;

  /// Raw on-chain amount — divide by the token's decimals to format (OX = 18).
  final BigInt rawAmount;
  final int blockNumber;
  final DateTime timestamp;
  final String txHash;
  final int logIndex;

  const TokenTransfer({
    required this.from,
    required this.to,
    required this.rawAmount,
    required this.blockNumber,
    required this.timestamp,
    required this.txHash,
    required this.logIndex,
  });

  /// True when [account] is the sender (an outgoing transfer for that wallet).
  bool isOutgoing(EthereumAddress account) =>
      from.eip55With0x == account.eip55With0x;

  @override
  String toString() => 'TokenTransfer(${from.eip55With0x} → '
      '${to.eip55With0x}, raw: $rawAmount, blk: $blockNumber)';
}

/// Multi-protocol wallet directory extension for PublicOS.
///
/// Wraps `WalletDirectoryManager` (additional wallets across eip155 / solana /
/// cardano / bitcoin) and exposes a typed `Wallet` model + CAIP-10 codec.
///
/// The main Safe is auto-prepended at index 0 by the contract's `getWallets()`
/// view, so callers always see one unified list.
extension PublicOSWallets on PublicOS {
  static const _tag = 'Wallets';

  // Genesis-seeded protocols (from WalletDirectoryMemory constructor).
  // Future protocols are added via DAO vote → setProtocolRegistered.
  static const String protoEvm = 'eip155';
  static const String protoSolana = 'solana';
  static const String protoCardano = 'cardano';
  static const String protoBitcoin = 'bitcoin';

  // ─── Solana link verification (client-side; chain stores these CLAIMED) ───
  // The chain cannot verify a foreign curve, so Solana entries are stored
  // CLAIMED with the ed25519 proof opaque. Verification lives here (and at the
  // contact icon that calls it) so any client can verify how it wants; Core
  // just exposes the records + this primitive.

  /// Verify a raw Ed25519 signature over [message] by [publicKey] (32 bytes,
  /// [signature] 64 bytes). Low-level — see [verifySolanaWalletLink] for the
  /// full link check.
  static bool verifySolSignature({
    required Uint8List publicKey,
    required Uint8List message,
    required Uint8List signature,
  }) =>
      ed.ed25519Verify(publicKey, message, signature);

  /// Canonical PublicOS Solana link message — BYTE-IDENTICAL to the signing
  /// website. [accountEip55] = EIP-55 `0x…`; [pubkeyBase58] = the Solana key.
  /// UTF-8, `\n` joins, single space after each colon, no trailing newline.
  static String solanaLinkMessage({
    required String accountEip55,
    required String pubkeyBase58,
  }) =>
      'PublicOS: link this Solana wallet to my account.\n'
      '\n'
      'Account: $accountEip55\n'
      'Solana: $pubkeyBase58\n'
      'Version: 1';

  /// Does this Solana [wallet] entry carry a valid link proof for [account]?
  /// Rebuilds the canonical message from on-chain data (account + pubkey) and
  /// verifies the stored ed25519 proof — the contact-icon "is it really linked?"
  /// check for CLAIMED Solana entries the chain couldn't verify. Returns false
  /// for non-Solana entries or malformed proofs.
  static bool verifySolanaWalletLink({
    required EthereumAddress account,
    required Wallet wallet,
  }) {
    if (wallet.protocol != protoSolana) return false;
    final proof = wallet.proof;
    if (proof == null || proof.length != 64) return false;
    // Non-EVM addressData = UTF-8 of the display address (Solana: base58 pubkey),
    // per this file's Wallet convention + toCaip10/parseCaip10.
    final String pubkeyBase58;
    final Uint8List pubkey;
    try {
      pubkeyBase58 = utf8.decode(wallet.addressData);
      pubkey = b58.base58Decode(pubkeyBase58);
    } catch (_) {
      return false;
    }
    if (pubkey.length != 32) return false;
    final message = solanaLinkMessage(
      accountEip55: account.eip55With0x,
      pubkeyBase58: pubkeyBase58,
    );
    return ed.ed25519Verify(
      pubkey,
      Uint8List.fromList(utf8.encode(message)),
      proof,
    );
  }

  /// base58 (Solana) codec passthroughs — for decoding a pasted link bundle
  /// (pubkey + signature) into bytes before building a [Wallet].
  static Uint8List base58Decode(String s) => b58.base58Decode(s);
  static String base58Encode(Uint8List bytes) => b58.base58Encode(bytes);

  // ─── Solana NFT: resolve / ownership / enumerate (public official RPC) ───
  // Ownership = pure SPL Token (getTokenAccountsByOwner). Metadata = read the
  // Metaplex Token-Metadata on-chain account directly (no Metaplex SDK/service;
  // see solana_metadata.dart). Free public RPC, no API key. Caveat: raw RPC
  // does NOT see compressed NFTs (cNFTs) at all — they have no SPL token account
  // and no Metaplex metadata PDA, so resolve/ownership/enumerate all miss them.
  // Manual-mint does NOT cover them either (resolveSolanaNftData returns null;
  // there isn't even a mint to paste, only an asset ID). cNFTs are readable only
  // via a DAS indexer (getAsset/getAssetsByOwner), which is off the public RPC.
  static const String solanaRpcUrl = 'https://api.mainnet-beta.solana.com';
  static const String _solanaTokenProgram =
      'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA';

  // ─── Foreign-EVM RPCs (read-only) ──────────────────────────────────────────
  // Keyed by chainId. Two consumers: (1) the (deferred) foreign-Safe branch of
  // verifyWallet → eth_call isValidSignature on the Safe's home chain; (2)
  // transaction / token reads for rendering XMTP walletSendCalls + transaction
  // References (decimals()/symbol(), eth_getTransactionByHash). EOAs never need
  // this (ecrecover is chain-agnostic, verified on 4489). publicnode endpoints
  // (same set as NFT resolution, verified live).
  static const Map<int, String> foreignEvmRpc = {
    1: 'https://ethereum-rpc.publicnode.com', // Ethereum Mainnet
    10: 'https://optimism-rpc.publicnode.com', // Optimism
    137: 'https://polygon-bor-rpc.publicnode.com', // Polygon
    8453: 'https://base-rpc.publicnode.com', // Base
    42161: 'https://arbitrum-one-rpc.publicnode.com', // Arbitrum One
    999: 'https://rpc.hyperliquid.xyz/evm', // Hyperliquid HyperEVM mainnet (HYPE gas)
    // Added for paid feeds — the only chain in that
    // design's set that was not already here. Everything else it needs (1, 137,
    // 8453, 42161) was, which is why paid feeds has NO second RPC table: it
    // resolves endpoints through [evmRpcUrlForChain] like every other consumer.
    56: 'https://bsc-rpc.publicnode.com', // BNB Chain
  };

  /// RPC endpoint for [chainId]: the live (failover-aware) PublicOS RPC for
  /// chain 4489, else the static public endpoint in [foreignEvmRpc]. Null for an
  /// unsupported chain.
  static String? evmRpcUrlForChain(int chainId) => chainId == PublicOS.CHAIN_ID
      ? PublicOS.activeRpcUrl
      : foreignEvmRpc[chainId];

  static Future<dynamic> _solanaRpc(String method, List<dynamic> params) async {
    try {
      final r = await http.post(
        Uri.parse(solanaRpcUrl),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'jsonrpc': '2.0', 'id': 1, 'method': method, 'params': params}),
      ).timeout(const Duration(seconds: 10));
      return (jsonDecode(r.body) as Map<String, dynamic>)['result'];
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Solana RPC $method failed: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EVM transaction / token decoding
  // Used to render XMTP walletSendCalls (invoices) + transactionReference
  // (receipts): an ERC-20 transfer's amount lives in the calldata, not `value`,
  // and the raw amount is meaningless without the token's decimals.
  // ═══════════════════════════════════════════════════════════════════════════

  // ERC-20 selectors.
  static const String _selTransfer = 'a9059cbb'; // transfer(address,uint256)
  static const String _selTransferFrom = '23b872dd'; // transferFrom(address,address,uint256)
  static const String _selDecimals = '313ce567'; // decimals()
  static const String _selSymbol = '95d89b41'; // symbol()

  // chainId → (lowercased token address → meta). Common stablecoins so the 99%
  // case formats instantly with no network call; unknown tokens fall back to an
  // on-chain decimals()/symbol() read.
  static const Map<int, Map<String, TokenMeta>> _knownTokens = {
    1: {
      '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48': TokenMeta('USDC', 6),
      '0xdac17f958d2ee523a2206206994597c13d831ec7': TokenMeta('USDT', 6),
      '0x6b175474e89094c44da98b954eedeac495271d0f': TokenMeta('DAI', 18),
    },
    10: {
      '0x0b2c639c533813f4aa9d7837caf62653d097ff85': TokenMeta('USDC', 6),
      '0x94b008aa00579c1307b0ef2c499ad98a8ce58e58': TokenMeta('USDT', 6),
    },
    137: {
      '0x3c499c542cef5e3811e1192ce70d8cc03d5c3359': TokenMeta('USDC', 6),
      '0xc2132d05d31c914a87c6611c10748aeb04b58e8f': TokenMeta('USDT', 6),
    },
    8453: {
      '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913': TokenMeta('USDC', 6),
      '0x50c5725949a6f0c72e6c4a641f24049a917db0cb': TokenMeta('DAI', 18),
    },
    42161: {
      '0xaf88d065e77c8cc2239327c5edb3a432268e5831': TokenMeta('USDC', 6),
      '0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9': TokenMeta('USDT', 6),
    },
  };

  static final Map<String, TokenMeta> _tokenMetaCache = {};

  /// Token metadata **without any network call** — registry, then the session
  /// cache [resolveTokenMeta] fills, then the runtime-resolved OX token.
  /// Null when the token isn't known locally.
  ///
  /// Exists for callers that are **synchronous and hot** — notably
  /// `PublicOSConversations.formatMessagePreview`, which runs once per message
  /// in the notification sweep loop and therefore cannot `await` an on-chain
  /// `decimals()`/`symbol()` read. Such callers must degrade gracefully (drop
  /// the amount, keep the sentence) rather than block.
  ///
  /// **OX is special**: its address is resolved at runtime from the
  /// ModuleRegistry (the chain mints it), so it cannot sit in a `const` map —
  /// hence the explicit check rather than a `_knownTokens[4489]` entry.
  static TokenMeta? tokenMetaSync(int chainId, String tokenAddress) {
    final addr = tokenAddress.toLowerCase();

    final known = _knownTokens[chainId]?[addr];
    if (known != null) return known;

    final cached = _tokenMetaCache['$chainId:$addr'];
    if (cached != null) return cached;

    if (chainId == PublicOS.CHAIN_ID) {
      final ox = PublicOSBsp.publicOSTokenAddress;
      if (ox != null && ox.eip55With0x.toLowerCase() == addr) {
        return const TokenMeta('OX', 18);
      }
    }
    return null;
  }

  /// Format a raw amount for a **preview line**, or null when the result cannot
  /// be trusted.
  ///
  /// Returns null (rather than a number) when the value renders as zero. That
  /// is the guard for the documented **receipt "0 OX" bug**: `metadata.amount`
  /// is sender-supplied, and a non-conformant sender stamps the *human* value
  /// (`4.0`) alongside `decimals: 18` — which divides down to ~0. A preview must
  /// never confidently announce a payment of zero; the caller falls back to the
  /// amount-less sentence ("sent you a payment") instead.
  static String? previewAmountText(BigInt raw, int decimals, String? symbol) {
    if (raw <= BigInt.zero || decimals < 0) return null;
    final sym = (symbol != null && symbol.trim().isNotEmpty) ? symbol.trim() : null;
    final text = formatTokenAmount(raw, decimals, symbol: sym);
    // formatTokenAmount caps display at 6 fraction digits, so anything under
    // 1e-6 collapses to a bare "0".
    final numeric = sym == null ? text : text.split(' ').first;
    if ((double.tryParse(numeric) ?? 0) == 0) return null;
    return text;
  }

  /// Parse a chain id that may arrive as hex (`"0x2105"`, the EIP-5792 shape a
  /// `walletSendCalls` carries) or as a decimal string (what a
  /// `transactionReference.networkId` usually carries). Null if neither.
  static int? parseChainId(String? raw) {
    final t = raw?.trim();
    if (t == null || t.isEmpty) return null;
    if (t.startsWith('0x') || t.startsWith('0X')) {
      return int.tryParse(t.substring(2), radix: 16);
    }
    return int.tryParse(t);
  }

  /// Raw JSON-RPC call on an EVM [chainId]. Returns the `result` field or null.
  static Future<dynamic> _evmRpc(
      int chainId, String method, List<dynamic> params) async {
    final url = evmRpcUrlForChain(chainId);
    if (url == null) return null;
    try {
      final r = await http
          .post(
            Uri.parse(url),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(
                {'jsonrpc': '2.0', 'id': 1, 'method': method, 'params': params}),
          )
          .timeout(const Duration(seconds: 10));
      final decoded = jsonDecode(r.body);
      if (decoded is! Map) return null;
      if (decoded['error'] != null) {
        Log.w(_tag, 'EVM RPC $method error: ${decoded['error']}');
        return null;
      }
      return decoded['result'];
    } catch (e) {
      Log.e(_tag, 'EVM RPC $method failed: $e');
      return null;
    }
  }

  static Future<String?> _ethCallRaw(
      int chainId, String to, String data) async {
    final res = await _evmRpc(chainId, 'eth_call', [
      {'to': to, 'data': data},
      'latest',
    ]);
    return res is String ? res : null;
  }

  /// Decode an ERC-20 transfer / transferFrom from EVM calldata. [tokenAddress]
  /// is the call's `to` (the token contract). Returns null if [data] isn't a
  /// recognised transfer.
  static Erc20Transfer? decodeErc20Transfer(String tokenAddress, String? data) {
    if (data == null) return null;
    final hex = data.startsWith('0x') ? data.substring(2) : data;
    if (hex.length < 8) return null;
    final selector = hex.substring(0, 8).toLowerCase();
    final params = hex.substring(8);
    try {
      if (selector == _selTransfer && params.length >= 128) {
        return Erc20Transfer(
          token: tokenAddress,
          recipient: '0x${params.substring(24, 64)}',
          rawAmount: BigInt.parse(params.substring(64, 128), radix: 16),
        );
      }
      if (selector == _selTransferFrom && params.length >= 192) {
        return Erc20Transfer(
          token: tokenAddress,
          recipient: '0x${params.substring(88, 128)}',
          rawAmount: BigInt.parse(params.substring(128, 192), radix: 16),
        );
      }
    } catch (e) {
      Log.w(_tag, 'decodeErc20Transfer failed: $e');
    }
    return null;
  }

  /// Resolve a token's symbol + decimals. Static registry first (instant), then
  /// an on-chain decimals()/symbol() read (cached for the session). Null if it
  /// can't be resolved.
  static Future<TokenMeta?> resolveTokenMeta(
      int chainId, String tokenAddress) async {
    final addr = tokenAddress.toLowerCase();
    final known = _knownTokens[chainId]?[addr];
    if (known != null) return known;

    final cacheKey = '$chainId:$addr';
    final cached = _tokenMetaCache[cacheKey];
    if (cached != null) return cached;

    final decRes = await _ethCallRaw(chainId, tokenAddress, '0x$_selDecimals');
    final decimals = _hexToInt(decRes);
    if (decimals == null) return null;
    final symRes = await _ethCallRaw(chainId, tokenAddress, '0x$_selSymbol');
    final symbol = _abiDecodeString(symRes) ?? '';

    final meta = TokenMeta(symbol, decimals);
    _tokenMetaCache[cacheKey] = meta;
    return meta;
  }

  /// Fetch an on-chain transaction by hash and decode it as an ERC-20 transfer
  /// (the common payment shape). Returns null if not found / not a transfer.
  static Future<Erc20Transfer?> fetchTxTransfer(
      int chainId, String txHash) async {
    if (txHash.isEmpty) return null;
    final tx = await _evmRpc(chainId, 'eth_getTransactionByHash', [txHash]);
    if (tx is! Map) return null;
    final to = tx['to'] as String?; // token contract for an ERC-20 transfer
    final input = tx['input'] as String?; // calldata
    if (to == null || input == null) return null;
    return decodeErc20Transfer(to, input);
  }

  /// The raw ERC-20 transfer amount carried by a transaction — handles BOTH a
  /// direct `token.transfer()` and a transfer wrapped in a Safe `executeCall`
  /// (the inner transfer's `a9059cbb` selector still appears in the calldata, so
  /// we locate it and read the trailing [recipient][amount] words). Returns null
  /// if no transfer is found.
  ///
  /// Used by transaction RECEIPTS, where the amount must come from the tx
  /// itself: the sender-supplied `metadata.amount` is advisory (and historically
  /// wrong), and the native `value` is 0 for an ERC-20 transfer.
  static Future<BigInt?> fetchTxTransferRawAmount(
      int chainId, String txHash) async {
    if (txHash.isEmpty) return null;
    final tx = await _evmRpc(chainId, 'eth_getTransactionByHash', [txHash]);
    if (tx is! Map) return null;
    final input = tx['input'] as String?;
    if (input == null) return null;
    final hex =
        (input.startsWith('0x') ? input.substring(2) : input).toLowerCase();
    final idx = hex.indexOf(_selTransfer); // direct (offset 0) or Safe-wrapped
    if (idx < 0) return null;
    final after = hex.substring(idx + 8);
    if (after.length < 128) return null;
    try {
      // [recipient: 32 bytes][amount: 32 bytes]
      return BigInt.parse(after.substring(64, 128), radix: 16);
    } catch (_) {
      return null;
    }
  }

  /// Format a raw on-chain [rawAmount] with [decimals] into a human string,
  /// optionally suffixed with [symbol]. BigInt math throughout (no float drift).
  /// e.g. (1000000, 6, symbol: 'USDC') → '1 USDC'.
  static String formatTokenAmount(BigInt rawAmount, int decimals,
      {String? symbol}) {
    String text;
    if (decimals <= 0) {
      text = rawAmount.toString();
    } else {
      final divisor = BigInt.from(10).pow(decimals);
      final whole = rawAmount ~/ divisor;
      final frac = rawAmount.remainder(divisor);
      if (frac == BigInt.zero) {
        text = whole.toString();
      } else {
        var fracStr =
            frac.toString().padLeft(decimals, '0').replaceAll(RegExp(r'0+$'), '');
        if (fracStr.length > 6) fracStr = fracStr.substring(0, 6); // display cap
        text = '$whole.$fracStr';
      }
    }
    return (symbol != null && symbol.isNotEmpty) ? '$text $symbol' : text;
  }

  // ─── Transfer history (token event-log read) ──────────────────────────────

  /// ERC-20 `Transfer(address,address,uint256)` signature — the canonical
  /// topic[0], identical for every ERC-20 (incl. the OX token).
  ///
  /// Public because [PublicOSWalletActivity] builds the same filter for its
  /// notification sweep. The `Transfer`-log machinery below ([addressTopic],
  /// [transferLogs], [decodeTransferLog]) is the shared primitive both readers
  /// sit on — this extension owns the *history list* read, the other owns the
  /// *incremental notification sweep*.
  static const transferTopic0 =
      '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef';

  /// Left-pad an address into a 32-byte getLogs topic.
  static String addressTopic(EthereumAddress a) =>
      '0x${a.without0x.toLowerCase().padLeft(64, '0')}';

  /// getLogs block-range per scan window. The node imposes no range cap today
  /// (a full genesis→head getLogs returns in one call), and transfers are
  /// sparse + concentrated in early blocks, so a *wide* window is right: the
  /// whole young chain is one scan. The loop still splits if the chain ever
  /// outgrows this — but the real scaling answer is a BSP indexer (Phase B),
  /// not a narrower window (which would just miss old activity).
  static const int _txWindow = 500000;

  /// Recent token transfers touching [address] on [chainId], newest-first.
  ///
  /// Reads chain logs directly (no indexer): a Transfer-event `eth_getLogs`
  /// scan on the network's token contract, OR-matching [address] in BOTH the
  /// `from` and `to` topic slots, walked back from head in <=[_txWindow]-block
  /// windows, stopping once [limit] is reached. [lookbackBlocks] `<= 0` (the
  /// default) scans the WHOLE chain (genesis→head) — necessary because
  /// transfers are sparse and a wallet's latest activity can be thousands of
  /// blocks old; pass a positive value only to deliberately bound the scan.
  ///
  /// Only the PublicOS network is wired today; [chainId] is the seam for other
  /// networks later (each needs its own RPC endpoint + token address), so it is
  /// required at the call site even though a non-PublicOS chain throws.
  static Future<List<TokenTransfer>> getRecentTransfers(
    EthereumAddress address, {
    required int chainId,
    int lookbackBlocks = 0,
    int limit = 25,
  }) async {
    if (chainId != PublicOS.CHAIN_ID) {
      throw UnimplementedError(
          'getRecentTransfers: chain $chainId not supported yet (PublicOS only)');
    }
    final token = PublicOSBsp.publicOSTokenAddress;
    if (token == null) return [];

    final addrTopics = [addressTopic(address)];

    final Map<String, TokenTransfer> byId = {};
    final tsCache = <int, int>{};
    try {
      final head = await PublicOS.web3Client.getBlockNumber();
      final floor = (lookbackBlocks <= 0 || head - lookbackBlocks < 0)
          ? 0
          : head - lookbackBlocks;
      for (var hi = head; hi >= floor && byId.length < limit; hi -= _txWindow) {
        final lo = (hi - _txWindow + 1) < floor ? floor : (hi - _txWindow + 1);
        // getLogs can only OR within one topic position, so `from` (topic1) and
        // `to` (topic2) are separate scans, then merged + deduped.
        final logs = [
          ...await transferLogs(
              token: token,
              fromBlock: lo,
              toBlock: hi,
              topicPos: 1,
              addressTopics: addrTopics),
          ...await transferLogs(
              token: token,
              fromBlock: lo,
              toBlock: hi,
              topicPos: 2,
              addressTopics: addrTopics),
        ];
        for (final log in logs) {
          final t = await decodeTransferLog(log, tsCache);
          if (t != null) byId['${t.txHash}:${t.logIndex}'] = t;
        }
        if (lo == floor) break;
      }
    } catch (e) {
      // Best-effort: return whatever we gathered before the RPC hiccup.
      Log.w(_tag, 'getRecentTransfers scan halted: $e');
    }

    final list = byId.values.toList()
      ..sort((a, b) {
        final byBlock = b.blockNumber.compareTo(a.blockNumber);
        return byBlock != 0 ? byBlock : b.logIndex.compareTo(a.logIndex);
      });
    return list.length > limit ? list.sublist(0, limit) : list;
  }

  /// One Transfer `getLogs` call, OR-matching ANY of [addressTopics] at
  /// [topicPos] (1 = `from`, 2 = `to`); intervening positions are left "any".
  ///
  /// getLogs can only OR *within* one topic position, so `from` and `to` are
  /// always two separate calls — but any number of addresses can ride in one
  /// call at a given position. That is what makes the notification sweep cost
  /// **2 calls regardless of how many wallets are watched**; the per-wallet
  /// history read below just happens to pass a single-element list.
  ///
  /// [client] defaults to the PublicOS network client. Pass a transient
  /// `Web3Client` to read another chain (the foreign-chain seam).
  static Future<List<w3.FilterEvent>> transferLogs({
    required EthereumAddress token,
    required int fromBlock,
    required int toBlock,
    required int topicPos,
    required List<String> addressTopics,
    w3.Web3Client? client,
  }) {
    final topics = <List<String?>>[
      [transferTopic0],
    ];
    while (topics.length < topicPos) {
      topics.add(const <String?>[]);
    }
    topics.add(addressTopics);
    return (client ?? PublicOS.web3Client).getLogs(w3.FilterOptions(
      address: token,
      fromBlock: w3.BlockNum.exact(fromBlock),
      toBlock: w3.BlockNum.exact(toBlock),
      topics: topics,
    ));
  }

  /// Decode a Transfer log — topics[1]=from, topics[2]=to, data=value — and
  /// stamp it with its block time. Returns null on any malformed log.
  ///
  /// Shared with [PublicOSWalletActivity]'s sweep. Note the sweep decodes each
  /// log exactly ONCE and derives direction by testing `from`/`to` against its
  /// watched set — which is why a wallet-to-wallet move of the user's own funds
  /// yields a single event rather than a duplicate send + receive pair.
  ///
  /// [client] defaults to the PublicOS network client (foreign-chain seam).
  static Future<TokenTransfer?> decodeTransferLog(
      w3.FilterEvent log, Map<int, int> tsCache,
      {w3.Web3Client? client}) async {
    try {
      final topics = log.topics;
      final data = log.data;
      if (topics == null || topics.length < 3 || data == null) return null;
      final t1 = topics[1];
      final t2 = topics[2];
      if (t1 == null || t2 == null) return null;
      final hex = data.startsWith('0x') ? data.substring(2) : data;
      final value = hex.isEmpty
          ? BigInt.zero
          : BigInt.parse(hex.substring(0, hex.length < 64 ? hex.length : 64),
              radix: 16);
      final blockNum = log.blockNum ?? 0;
      final tsMs = await _blockTs(blockNum, tsCache, client: client);
      return TokenTransfer(
        from: _addrFromTopic(t1),
        to: _addrFromTopic(t2),
        rawAmount: value,
        blockNumber: blockNum,
        timestamp: DateTime.fromMillisecondsSinceEpoch(tsMs),
        txHash: log.transactionHash ?? '',
        logIndex: log.logIndex ?? 0,
      );
    } catch (e) {
      Log.w(_tag, 'decode transfer log failed: $e');
      return null;
    }
  }

  static EthereumAddress _addrFromTopic(String topic) {
    final h = topic.startsWith('0x') ? topic.substring(2) : topic;
    return EthereumAddress.fromHex(h.substring(h.length - 40));
  }

  /// Block timestamp (ms epoch), cached per block within one scan.
  static Future<int> _blockTs(int blockNum, Map<int, int> cache,
      {w3.Web3Client? client}) async {
    final c = cache[blockNum];
    if (c != null) return c;
    final block = await (client ?? PublicOS.web3Client).getBlockInformation(
      blockNumber: '0x${blockNum.toRadixString(16)}',
    );
    final ms = block.timestamp.millisecondsSinceEpoch;
    cache[blockNum] = ms;
    return ms;
  }

  static int? _hexToInt(String? hex) {
    if (hex == null) return null;
    final h = hex.startsWith('0x') ? hex.substring(2) : hex;
    if (h.isEmpty) return null;
    return int.tryParse(h, radix: 16);
  }

  /// Decode an ABI-encoded `string` return (offset/length/data); falls back to
  /// treating it as a right-padded bytes32 (some legacy tokens like MKR).
  static String? _abiDecodeString(String? hex) {
    if (hex == null) return null;
    final h = hex.startsWith('0x') ? hex.substring(2) : hex;
    if (h.isEmpty) return null;
    try {
      if (h.length >= 128) {
        final length = int.parse(h.substring(64, 128), radix: 16);
        if (length > 0 && h.length >= 128 + length * 2) {
          return _utf8FromHex(h.substring(128, 128 + length * 2));
        }
      }
      // bytes32 fallback: trim trailing zero bytes.
      final trimmed = h.replaceAll(RegExp(r'(00)+$'), '');
      return trimmed.isEmpty ? null : _utf8FromHex(trimmed);
    } catch (_) {
      return null;
    }
  }

  static String _utf8FromHex(String hex) {
    final bytes = <int>[];
    for (var i = 0; i + 1 < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return utf8.decode(bytes, allowMalformed: true).trim();
  }

  /// Resolve a Solana NFT [mintBase58] to its off-chain metadata JSON
  /// (`image`/`name`/`attributes`/…) via the Metaplex Token-Metadata account →
  /// `uri` → fetch. Returns null if there's no metadata account or fetch fails.
  static Future<Map<String, dynamic>?> resolveSolanaNftData(
      String mintBase58) async {
    try {
      final pda = solmeta.metadataPda(mintBase58);
      final acc = await _solanaRpc('getAccountInfo', [
        pda,
        {'encoding': 'base64'}
      ]);
      final value = acc is Map ? acc['value'] : null;
      if (value == null) return null;
      final data = base64.decode((value['data'] as List)[0] as String);
      final meta = solmeta.parseSolanaMetadata(data);
      if (meta.uri.isEmpty || !meta.uri.startsWith('http')) {
        // On-chain name/symbol but no off-chain JSON (e.g. a fungible token).
        return {'name': meta.name, 'symbol': meta.symbol};
      }
      final resp = await http
          .get(Uri.parse(meta.uri))
          .timeout(const Duration(seconds: 10));
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      return json;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'resolveSolanaNftData failed: $e');
      return null;
    }
  }

  /// Whether [ownerBase58] currently holds [mintBase58] (amount == 1). Pure SPL
  /// Token, no Metaplex.
  static Future<bool> accountOwnsSolanaMint(
      String ownerBase58, String mintBase58) async {
    final res = await _solanaRpc('getTokenAccountsByOwner', [
      ownerBase58,
      {'mint': mintBase58},
      {'encoding': 'jsonParsed'}
    ]);
    final accts = (res is Map ? res['value'] as List? : null) ?? const [];
    for (final a in accts) {
      final amt =
          a['account']?['data']?['parsed']?['info']?['tokenAmount']?['amount'];
      if (amt == '1') return true;
    }
    return false;
  }

  /// The owner's NFT mints (heuristic: decimals 0, amount 1) via raw
  /// `getTokenAccountsByOwner` on the SPL Token program. Misses compressed NFTs
  /// (cNFTs) — those need a DAS indexer; no current path (grid or manual-mint)
  /// resolves them.
  static Future<List<String>> listOwnedSolanaNfts(String ownerBase58) async {
    final res = await _solanaRpc('getTokenAccountsByOwner', [
      ownerBase58,
      {'programId': _solanaTokenProgram},
      {'encoding': 'jsonParsed'}
    ]);
    final accts = (res is Map ? res['value'] as List? : null) ?? const [];
    final mints = <String>[];
    for (final a in accts) {
      final info = a['account']?['data']?['parsed']?['info'];
      final ta = info?['tokenAmount'];
      if (ta?['decimals'] == 0 && ta?['amount'] == '1') {
        final mint = info?['mint'] as String?;
        if (mint != null) mints.add(mint);
      }
    }
    return mints;
  }

  /// Get the auto-merged wallet list for an account.
  /// Index 0 is the account's main Safe (chainId = current chain),
  /// remaining entries are stored additional wallets.
  static Future<List<Wallet>> getWallets(EthereumAddress account) async {
    try {
      final raw = await PublicOSBsp.walletDirectoryManagerContract.getWallets(
        (account: account),
      );
      return _decodeWalletList(raw);
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting wallets: $e');
      return const [];
    }
  }

  /// Get only the stored additional wallets (no main Safe prepend).
  static Future<List<Wallet>> getStoredWallets(EthereumAddress account) async {
    try {
      final raw = await PublicOSBsp.walletDirectoryManagerContract.getStoredWallets(
        (account: account),
      );
      return _decodeWalletList(raw);
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting stored wallets: $e');
      return const [];
    }
  }

  /// Reverse lookup: which account claims this `(protocol, addressData)` pair.
  /// Returns the zero address if not claimed by anyone.
  static Future<EthereumAddress?> getOwnerByAddress({
    required String protocol,
    required Uint8List addressData,
  }) async {
    try {
      return await PublicOSBsp.walletDirectoryManagerContract.getOwnerByAddress(
        (protocol: encodeProtocol(protocol), addressData: addressData),
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getOwnerByAddress: $e');
      return null;
    }
  }

  /// Add a wallet to the caller's account directory, proving ownership.
  ///
  /// WalletDirectory v2: `wallet.proof` must carry the signature over the
  /// [linkWalletDigest] (EOA: a 65-byte secp256k1 sig from the wallet's key,
  /// see [signLinkWalletEoa]; local-chain Safe: the Safe-wrapped owner sig;
  /// foreign Safe / non-EVM: the foreign proof, stored CLAIMED). `deadline` is
  /// the unix-seconds bound that was signed — enforced on-chain for the EOA and
  /// local-Safe paths, advisory for the claimed tiers.
  ///
  /// Returns the tx hash on success.
  static Future<String?> addWallet(Wallet wallet, {required BigInt deadline}) async {
    if (PublicOS.currentBlockchainPrivateKey == null) {
      throw Exception('Authentication required');
    }
    try {
      return await PublicOSBsp.walletDirectoryManagerContract.addWallet(
        (wallet: wallet._toTuple(), deadline: deadline),
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error addWallet: $e');
      return null;
    }
  }

  /// Remove a wallet by its `(walletKey, chainId)` pair.
  static Future<String?> removeWallet({
    required Uint8List walletKey,
    required int chainId,
  }) async {
    if (PublicOS.currentBlockchainPrivateKey == null) {
      throw Exception('Authentication required');
    }
    try {
      return await PublicOSBsp.walletDirectoryManagerContract.removeWallet(
        (walletKey: walletKey, chainId: BigInt.from(chainId)),
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error removeWallet: $e');
      return null;
    }
  }

  /// Update the human-readable label of a wallet entry.
  static Future<String?> updateWalletLabel({
    required Uint8List walletKey,
    required int chainId,
    required String newLabel,
  }) async {
    if (PublicOS.currentBlockchainPrivateKey == null) {
      throw Exception('Authentication required');
    }
    try {
      return await PublicOSBsp.walletDirectoryManagerContract.updateWalletLabel(
        (walletKey: walletKey, chainId: BigInt.from(chainId), newLabel: newLabel),
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error updateWalletLabel: $e');
      return null;
    }
  }

  /// Update the `walletType` classification of a wallet entry (NONE/EOA/SAFE).
  static Future<String?> updateWalletType({
    required Uint8List walletKey,
    required int chainId,
    required WalletType newType,
  }) async {
    if (PublicOS.currentBlockchainPrivateKey == null) {
      throw Exception('Authentication required');
    }
    try {
      return await PublicOSBsp.walletDirectoryManagerContract.updateWalletType(
        (walletKey: walletKey, chainId: BigInt.from(chainId), newType: BigInt.from(newType.index)),
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error updateWalletType: $e');
      return null;
    }
  }

  /// View — the per-account wallet cap (DAO-managed, default 50).
  static Future<int> getMaxWalletsPerAccount() async {
    final v = await PublicOSBsp.walletDirectoryManagerContract.getMaxWalletsPerAccount();
    return v.toInt();
  }

  /// View — whether a protocol name is currently in the DAO-gated registry.
  static Future<bool> isProtocolRegistered(String protocol) async {
    return PublicOSBsp.walletDirectoryManagerContract.isProtocolRegistered(
      (protocol: encodeProtocol(protocol)),
    );
  }

  // ============================================================
  // Ownership proof (WalletDirectory v2 — "verification absorbed")
  // ============================================================

  /// Build the EIP-712 `LinkWallet` digest the wallet must sign to prove it is
  /// owned by [account]. Domain is bound to the WalletDirectoryManager on the
  /// current chain (4489), so the signature can't be replayed elsewhere.
  ///
  /// The same digest is consumed two ways:
  ///   - EOA: signed directly by the wallet's secp256k1 key ([signLinkWalletEoa]).
  ///   - Safe: wrapped by the Safe (SafeMessage) and signed by its owners — the
  ///     client produces that wrapped signature; on-chain `isValidSignature`
  ///     re-derives the same wrapped hash from this digest.
  ///
  /// For an EOA pass `walletChainId: 0` (chain-agnostic); for a Safe pass its
  /// home chainId.
  static Uint8List linkWalletDigest({
    required EthereumAddress account,
    required String protocol,
    required Uint8List walletAddress,
    required int walletChainId,
    required BigInt deadline,
  }) {
    final wdm = PublicOSBsp.walletDirectoryManagerAddress;
    if (wdm == null) {
      throw StateError('WalletDirectoryManager address not resolved');
    }
    final domainSep = eip712.domainSeparator(
      chainId: PublicOS.CHAIN_ID,
      verifyingContract: wdm,
    );
    final structHash = eip712.linkWalletStructHash(
      account: account,
      protocol: encodeProtocol(protocol),
      walletAddress: walletAddress,
      walletChainId: walletChainId,
      deadline: deadline,
    );
    return eip712.finalDigest(domainSep: domainSep, structHash: structHash);
  }

  /// Sign the [linkWalletDigest] with an EOA private key (the wallet being
  /// linked). Returns the 65-byte signature to place in `Wallet.proof`. Use for
  /// the same-device case where the user controls the EOA key directly (e.g.
  /// linking their own login key). External wallets sign the digest in their own
  /// app and the client fills `proof` from there.
  static Uint8List signLinkWalletEoa({
    required EthereumAddress account,
    required Uint8List walletAddress,
    required BigInt deadline,
    required EthPrivateKey eoaKey,
  }) {
    final digest = linkWalletDigest(
      account: account,
      protocol: protoEvm,
      walletAddress: walletAddress,
      walletChainId: 0, // EOA is chain-agnostic
      deadline: deadline,
    );
    return eip712.signDigest(digest, eoaKey);
  }

  /// True when the chain proved this entry's ownership at write time (EOA
  /// ecrecover or a local-chain Safe ERC-1271). v1 badge driver.
  ///
  /// CLAIMED entries (foreign Safe / non-EVM) are NOT re-verified here yet —
  /// off-chain re-verification (foreign-Safe home-chain RPC + ed25519 + BIP-322)
  /// is a follow-up gated on verifier-lib pinning. Until then render CLAIMED as
  /// "claimed (unverified)".
  static bool isOnchainVerified(Wallet w) =>
      w.verification == Verification.onchainVerified;

  /// The set of addresses an account provably owns, for NFT-ownership / ENS
  /// enrichment: `sessions ∪ on-chain-verified EVM directory wallets`. The
  /// account's main Safe is included automatically (getWallets prepends it as a
  /// verified eip155 entry). Replaces the old on-chain `getOwnedAddresses` merge
  /// — recomposed from the WalletDirectory instead of the `_linkedAddresses` lane.
  static Future<List<EthereumAddress>> ownedAddresses(
    EthereumAddress account,
  ) async {
    final seen = <String>{};
    final out = <EthereumAddress>[];
    void add(EthereumAddress a) {
      if (seen.add(_hex(a.value).toLowerCase())) out.add(a);
    }

    try {
      final sessions = await PublicOSBsp.accountMemoryContract
          .getAccountSessions((accountAddress: account));
      for (final c in sessions) {
        add(c);
      }
    } catch (e) {
      Log.w(_tag, 'ownedAddresses: client read failed: $e');
    }

    try {
      final wallets = await getWallets(account);
      for (final w in wallets) {
        if (w.protocol == protoEvm &&
            w.verification == Verification.onchainVerified &&
            w.addressData.length == 20) {
          add(EthereumAddress(w.addressData));
        }
      }
    } catch (e) {
      Log.w(_tag, 'ownedAddresses: wallet read failed: $e');
    }

    return out;
  }

  // ============================================================
  // Codecs
  // ============================================================

  /// Encode a protocol name as `bytes32(bytes("name"))` — right-padded ASCII.
  /// Mirrors the contract's `bytes32(bytes("eip155"))` storage convention.
  static Uint8List encodeProtocol(String name) {
    final out = Uint8List(32);
    final bytes = utf8.encode(name);
    if (bytes.length > 32) {
      throw ArgumentError('protocol name too long: $name (${bytes.length} bytes)');
    }
    out.setRange(0, bytes.length, bytes);
    return out;
  }

  /// Decode a `bytes32(bytes("name"))` back to its UTF-8 protocol name,
  /// stripping trailing zero padding.
  static String decodeProtocol(Uint8List protocolBytes) {
    int end = protocolBytes.length;
    while (end > 0 && protocolBytes[end - 1] == 0) {
      end--;
    }
    return utf8.decode(protocolBytes.sublist(0, end));
  }

  /// Compute the directory's `walletKey = keccak256(abi.encodePacked(protocol, addressData))`.
  /// Required as the lookup key for `removeWallet` / `updateWalletLabel` / `updateWalletType`.
  /// Not meaningful for the auto-prepended main Safe (use `isMainSafe` to skip it).
  static Uint8List computeWalletKey({
    required String protocol,
    required Uint8List addressData,
  }) {
    final protoBytes = encodeProtocol(protocol);
    final concat = Uint8List(protoBytes.length + addressData.length)
      ..setRange(0, protoBytes.length, protoBytes)
      ..setRange(protoBytes.length, protoBytes.length + addressData.length, addressData);
    return keccak256(concat);
  }

  /// CAIP-10 encode `(protocol, addressData, chainId)` → `eip155:1:0x...`.
  /// Reference selection by protocol:
  ///   - eip155: decimal chainId
  ///   - solana / cardano / bitcoin: chainId carries a protocol-specific
  ///     reference index (0 = mainnet by convention). The address is
  ///     base58 / bech32 / etc. — Core does not normalize, callers pass the
  ///     human form in `addressData` (UTF-8 bytes).
  static String toCaip10({
    required String protocol,
    required Uint8List addressData,
    required int chainId,
  }) {
    final reference = chainId.toString();
    if (protocol == protoEvm) {
      final addr = '0x${_hex(addressData)}';
      return '$protocol:$reference:$addr';
    }
    final addr = utf8.decode(addressData);
    return '$protocol:$reference:$addr';
  }

  /// Inverse of [toCaip10]. Returns null on parse failure.
  static ({String protocol, Uint8List addressData, int chainId})? parseCaip10(String s) {
    final parts = s.split(':');
    if (parts.length != 3) return null;
    final protocol = parts[0];
    final reference = int.tryParse(parts[1]);
    if (reference == null) return null;
    final addressStr = parts[2];
    Uint8List addressData;
    if (protocol == protoEvm) {
      final hex = addressStr.startsWith('0x') ? addressStr.substring(2) : addressStr;
      if (hex.length != 40) return null;
      addressData = _hexToBytes(hex);
    } else {
      addressData = Uint8List.fromList(utf8.encode(addressStr));
    }
    return (protocol: protocol, addressData: addressData, chainId: reference);
  }

  // ============================================================
  // Internal helpers
  // ============================================================

  static List<Wallet> _decodeWalletList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((row) {
      final r = row as List;
      return Wallet(
        protocol: PublicOSWallets.decodeProtocol(r[0] as Uint8List),
        addressData: r[1] as Uint8List,
        chainId: (r[2] as BigInt).toInt(),
        label: r[3] as String,
        walletType: WalletType.values[(r[4] as BigInt).toInt()],
        proof: r[5] as Uint8List,
        verification: Verification.values[(r[6] as BigInt).toInt()],
      );
    }).toList(growable: false);
  }

  static String _hex(Uint8List b) {
    final sb = StringBuffer();
    for (final byte in b) {
      sb.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }

  static Uint8List _hexToBytes(String hex) {
    final out = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }
}

/// Wallet entry returned by `WalletDirectoryManager.getWallets`.
class Wallet {
  /// Protocol name (e.g. `eip155`, `solana`, `cardano`, `bitcoin`).
  final String protocol;

  /// Raw address bytes — for EVM this is the 20-byte address, for non-EVM
  /// chains the human-readable address (base58 / bech32) UTF-8 encoded.
  final Uint8List addressData;

  /// Chain identifier — semantics vary by protocol (decimal chainId for EVM,
  /// 0 = mainnet by convention for others).
  final int chainId;

  /// Human label set by the user.
  final String label;

  /// Classification (NONE/EOA/SAFE). Drives the add-time verification dispatch.
  final WalletType walletType;

  /// Ownership proof — the signature over [PublicOSWallets.linkWalletDigest].
  /// Empty for the auto-prepended main Safe and legacy/claimed entries with no
  /// stored proof. The contract verifies it at write time on the on-chain tier
  /// (EOA / local Safe) and stores it untouched on the claimed tier.
  final Uint8List? proof;

  /// Add-time ownership verdict set by the contract (not caller-trusted).
  final Verification verification;

  const Wallet({
    required this.protocol,
    required this.addressData,
    required this.chainId,
    required this.label,
    required this.walletType,
    this.proof,
    this.verification = Verification.claimed,
  });

  /// CAIP-10 representation suitable for QR codes and external interop.
  String toCaip10() => PublicOSWallets.toCaip10(
        protocol: protocol,
        addressData: addressData,
        chainId: chainId,
      );

  /// True when this row is the auto-prepended main Safe (index 0 of getWallets).
  bool get isMainSafe => walletType == WalletType.safe && protocol == PublicOSWallets.protoEvm;

  /// Directory lookup key for `removeWallet` / `updateWalletLabel` / `updateWalletType`.
  /// Not meaningful for the main Safe — guard with `isMainSafe`.
  Uint8List get walletKey =>
      PublicOSWallets.computeWalletKey(protocol: protocol, addressData: addressData);

  /// EIP-55 hex string for an EVM wallet. Throws for non-eip155 protocols.
  String get addressHex {
    if (protocol != PublicOSWallets.protoEvm) {
      throw StateError('addressHex is only defined for eip155 wallets');
    }
    final sb = StringBuffer('0x');
    for (final b in addressData) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }

  /// Tuple form expected by web3dart for `addWallet` calldata. Field order +
  /// count MUST match `IWalletDirectoryMemory.Wallet` (7 fields). `verification`
  /// is sent but the contract overrides it from the dispatch verdict.
  List<dynamic> _toTuple() => [
        PublicOSWallets.encodeProtocol(protocol),
        addressData,
        BigInt.from(chainId),
        label,
        BigInt.from(walletType.index),
        proof ?? Uint8List(0),
        BigInt.from(verification.index),
      ];
}

/// Mirrors `enum IWalletDirectoryMemory.WalletType { NONE, EOA, SAFE }`.
enum WalletType { none, eoa, safe }

/// Mirrors `enum IWalletDirectoryMemory.Verification { CLAIMED, ONCHAIN_VERIFIED, ATTESTED }`.
/// `attested` is reserved for the future off-chain validator; not produced on-chain in v1.
enum Verification { claimed, onchainVerified, attested }
