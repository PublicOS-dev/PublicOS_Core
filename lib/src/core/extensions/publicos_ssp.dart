import 'dart:convert';
import 'dart:math' show Random, min;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show compute;
import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:web3dart/web3dart.dart'
    show keccak256, sign, ecRecover, publicKeyToAddress, bytesToHex, MsgSignature;
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:publicos_core/src/core/publicos_core.dart';
import 'package:publicos_core/src/core/exceptions/ssp_gate_exception.dart';
import 'package:publicos_core/src/core/extensions/publicos_bsp.dart';
import 'package:publicos_core/src/database/database.dart' as db;
import 'package:publicos_core/src/models/feed_server/feed_server_models.dart';
import 'package:publicos_core/src/utils/channel_url.dart' show serverOf;
import 'package:publicos_core/src/utils/log.dart';
import 'package:publicos_core/src/utils/pedia_crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the server behind a URL is a registered SSP on chain.
/// `unknown` = the chain could not say;
/// only `unregistered` is ever marked.
enum SspRegistration { registered, unregistered, unknown }

/// A feed server entry for UI display.
class FeedServerEntry {
  final String label;
  final String url;

  /// 'ssp' or 'custom'
  final String source;
  final String? sspSlug;
  final int? feedServerId;
  final bool isActive;

  FeedServerEntry({
    required this.label,
    required this.url,
    required this.source,
    this.sspSlug,
    this.feedServerId,
    required this.isActive,
  });
}

/// SSP (Social Service Provider) connection layer.
///
/// Owns the connection to the user's feed server — subscription lookup,
/// custom server CRUD, active URL resolution, transport/signing helpers,
/// media storage, and account-wide access control (features provided by
/// the server itself, not per-channel).
///
/// Channel content operations (channels, posts, comments, reactions, etc.)
/// live in `publicos_channels.dart` and call through to this extension's
/// public transport methods (`signMessage`, `createApiRequest`, `makeRequest`).
extension PublicOSSsp on PublicOS {
  static const _tag = 'SSP';

  // ==========================================================================
  // SUBSCRIPTION RESOLUTION (chain → SSP URL)
  // ==========================================================================

  /// Resolve the active SSP URL for the current account from the SSP sub memory.
  /// Returns null if no subscription or RPC unreachable. Under the domain-rights
  /// economy SSP assignment lives on the subs_v2 SubsMemory (slugOf, axis 1).
  static Future<String?> getSSPServerAddress() async {
    try {
      final address = PublicOS.myPublicosAddress != null ? EthereumAddress.fromHex(PublicOS.myPublicosAddress!) : null;
      if (address == null) return null;

      final slug = await PublicOSBsp.subsMemoryContract.slugOf((axis: BigInt.one, a: address));
      if (slug.isEmpty) return null;

      final serverData = await PublicOSBsp.socialServerRegistryMemoryContract
          .getSocialServerBySlug((slug: slug));
      final exists = serverData[0] as bool;
      if (!exists) return null;

      final apiUrl = serverData[3] as String;
      return apiUrl.isNotEmpty ? apiUrl : null;
    } catch (e) {
      Log.d(_tag, 'SSP server resolution failed: $e');
      return null;
    }
  }

  /// Full SSP info (slug, title, apiUrl) for the current user's active
  /// subscription — used by UI badges and labels.
  static Future<({String slug, String title, String apiUrl})?>
      getSSPServerInfo() async {
    try {
      final address = PublicOS.myPublicosAddress != null ? EthereumAddress.fromHex(PublicOS.myPublicosAddress!) : null;
      if (address == null) return null;

      final String slug = await PublicOSBsp.subsMemoryContract.slugOf((axis: BigInt.one, a: address));
      if (slug.isEmpty) return null;

      final serverData = await PublicOSBsp.socialServerRegistryMemoryContract
          .getSocialServerBySlug((slug: slug));
      final exists = serverData[0] as bool;
      if (!exists) return null;

      final title = serverData[2] as String;
      final apiUrl = serverData[3] as String;
      if (apiUrl.isEmpty) return null;

      return (slug: slug, title: title, apiUrl: apiUrl);
    } catch (e) {
      Log.d(_tag, 'SSP info resolution failed: $e');
      return null;
    }
  }

  // ==========================================================================
  // CUSTOM FEED SERVER CRUD (database)
  // ==========================================================================

  /// Add a new custom feed server for the current user. First server added
  /// becomes the default automatically.
  static Future<FeedServer?> addFeedServer(String serverAddress,
      {String? name}) async {
    try {
      if (PublicOS.myPublicosAddress == null) {
        Log.w(_tag, 'Cannot add server: no authenticated user');
        return null;
      }

      final sessionAddress =
          PublicOS.myPublicosAddress!;
      final now = DateTime.now().millisecondsSinceEpoch;

      final existing = await PublicOS.database.customSelect(
        'SELECT * FROM feed_servers WHERE feed_server_address = ? AND session_address = ?',
        variables: [
          Variable.withString(serverAddress),
          Variable.withString(sessionAddress),
        ],
        readsFrom: {PublicOS.database.feedServers},
      ).get();

      if (existing.isNotEmpty) {
        final row = existing.first;
        return FeedServer(
          id: row.read<int>('id'),
          feedServerAddress: row.read<String>('feed_server_address'),
          name: row.read<String?>('name'),
          isDefault: row.read<bool>('is_default'),
          sessionAddress: row.read<String>('session_address'),
          createdAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('created_at')),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('updated_at')),
        );
      }

      final allForSession = await PublicOS.database.getFeedServersForSession(sessionAddress);
      final isDefault = allForSession.isEmpty;

      final serverId = await PublicOS.database.into(PublicOS.database.feedServers).insert(
            db.FeedServersCompanion(
              feedServerAddress: Value(serverAddress),
              name: Value(name),
              isDefault: Value(isDefault),
              sessionAddress: Value(sessionAddress),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      Log.i(_tag, 'Added server: $serverAddress (id: $serverId)');

      return FeedServer(
        id: serverId,
        feedServerAddress: serverAddress,
        name: name,
        isDefault: isDefault,
        sessionAddress: sessionAddress,
        createdAt: DateTime.fromMillisecondsSinceEpoch(now),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      );
    } catch (e) {
      Log.e(_tag, 'addFeedServer error: $e');
      return null;
    }
  }

  /// Get all custom feed servers for the current user.
  static Future<List<FeedServer>> getFeedServers() async {
    try {
      if (PublicOS.myPublicosAddress == null) return [];
      final sessionAddress =
          PublicOS.myPublicosAddress!;

      final results = await PublicOS.database.customSelect(
        'SELECT * FROM feed_servers WHERE session_address = ? ORDER BY is_default DESC, created_at ASC',
        variables: [Variable.withString(sessionAddress)],
        readsFrom: {PublicOS.database.feedServers},
      ).get();

      return results
          .map((row) => FeedServer(
                id: row.read<int>('id'),
                feedServerAddress: row.read<String>('feed_server_address'),
                name: row.read<String?>('name'),
                isDefault: row.read<bool>('is_default'),
                sessionAddress: row.read<String>('session_address'),
                createdAt:
                    DateTime.fromMillisecondsSinceEpoch(row.read<int>('created_at')),
                updatedAt:
                    DateTime.fromMillisecondsSinceEpoch(row.read<int>('updated_at')),
              ))
          .toList();
    } catch (e) {
      Log.e(_tag, 'getFeedServers error: $e');
      return [];
    }
  }

  /// Remove a custom feed server.
  static Future<bool> removeFeedServer(int serverId) async {
    try {
      if (PublicOS.myPublicosAddress == null) return false;
      final sessionAddress =
          PublicOS.myPublicosAddress!;

      final deleted = await (PublicOS.database
              .delete(PublicOS.database.feedServers)
            ..where((f) =>
                f.id.equals(serverId) & f.sessionAddress.equals(sessionAddress)))
          .go();

      return deleted > 0;
    } catch (e) {
      Log.e(_tag, 'removeFeedServer error: $e');
      return false;
    }
  }

  /// Set a custom feed server as the default.
  static Future<bool> setDefaultFeedServer(int serverId) async {
    try {
      if (PublicOS.myPublicosAddress == null) return false;
      final sessionAddress =
          PublicOS.myPublicosAddress!;
      final now = DateTime.now().millisecondsSinceEpoch;

      await (PublicOS.database.update(PublicOS.database.feedServers)
            ..where((f) => f.sessionAddress.equals(sessionAddress)))
          .write(db.FeedServersCompanion(
        isDefault: const Value(false),
        updatedAt: Value(now),
      ));

      final updated = await (PublicOS.database.update(PublicOS.database.feedServers)
            ..where((f) =>
                f.id.equals(serverId) & f.sessionAddress.equals(sessionAddress)))
          .write(db.FeedServersCompanion(
        isDefault: const Value(true),
        updatedAt: Value(now),
      ));

      return updated > 0;
    } catch (e) {
      Log.e(_tag, 'setDefaultFeedServer error: $e');
      return false;
    }
  }

  // ==========================================================================
  // ACTIVE SERVER RESOLUTION (used by channels + media)
  // ==========================================================================

  // =========================================================================
  // ACTIVE SSP CACHE (via SecureStorage, per account)
  //
  // One JSON blob per session: {"endpoint": "...", "source": "ssp" | "custom"}
  // — mirror of the BSP unified cache. Default/public feed server is NEVER
  // cached: on fallback, the cache is cleared. initSSP consults the cache
  // first and branches on source to decide whether chain verification is
  // needed ('ssp' verifies via rentMemoryContract.assignedSSP, 'custom'
  // trusts the local blob).
  // =========================================================================

  static String _activeSspKey(String sessionAddr) => 'active_ssp_$sessionAddr';

  /// Read the cached active SSP selection for the current account.
  static Future<({String endpoint, String source})?> getCachedActiveSsp() async {
    if (PublicOS.sessionBlockchainAddress == null) return null;
    final raw = await PublicOS.secureStorage
        .read(key: _activeSspKey(PublicOS.sessionBlockchainAddress!));
    if (raw == null || raw.isEmpty) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final endpoint = j['endpoint'] as String?;
      final source = j['source'] as String?;
      if (endpoint == null || endpoint.isEmpty) return null;
      if (source != 'ssp' && source != 'custom') return null;
      return (endpoint: endpoint, source: source!);
    } catch (_) {
      return null;
    }
  }

  /// Write the cached active SSP selection. [source] must be 'ssp' or
  /// 'custom' — default fallback must use [clearCachedActiveSsp].
  static Future<void> setCachedActiveSsp(String endpoint, String source) async {
    if (PublicOS.sessionBlockchainAddress == null) return;
    if (source != 'ssp' && source != 'custom') {
      Log.w(_tag, 'setCachedActiveSsp called with unexpected source="$source" — '
          'ignoring. Use clearCachedActiveSsp() to express "no selection".');
      return;
    }
    final blob = jsonEncode({'endpoint': endpoint, 'source': source});
    await PublicOS.secureStorage.write(
      key: _activeSspKey(PublicOS.sessionBlockchainAddress!),
      value: blob,
    );
  }

  /// Clear the cached active SSP selection. Used on fallback-to-default or
  /// when a cached 'ssp' entry's subscription is detected as gone.
  static Future<void> clearCachedActiveSsp() async {
    if (PublicOS.sessionBlockchainAddress == null) return;
    await PublicOS.secureStorage
        .delete(key: _activeSspKey(PublicOS.sessionBlockchainAddress!));
  }

  /// Resolve the active feed server URL for the current user.
  /// Priority: cached selection (if still valid) → SSP subscription → default
  /// custom → first custom.
  static Future<String?> getActiveFeedServerUrl() async {
    // 1. Cached selection (unified {endpoint, source} blob)
    final cached = await getCachedActiveSsp();
    if (cached != null) {
      if (cached.source == 'ssp') {
        // Verify the subscription still exists before trusting.
        final sspUrl = await getSSPServerAddress();
        if (sspUrl == cached.endpoint) return cached.endpoint;
        // Stale — clear and fall through.
        Log.i(_tag, 'Cached SSP cleared — no matching on-chain subscription');
        await clearCachedActiveSsp();
      } else {
        // 'custom' — authoritative via local DB.
        final servers = await getFeedServers();
        if (servers.any((s) => s.feedServerAddress == cached.endpoint)) {
          return cached.endpoint;
        }
        // Custom entry was deleted from the DB — clear the stale cache.
        await clearCachedActiveSsp();
      }
    }

    // 2. SSP subscription
    final sspUrl = await getSSPServerAddress();
    if (sspUrl != null) return sspUrl;

    // 3. First custom / default
    final servers = await getFeedServers();
    if (servers.isEmpty) return null;
    final def = servers.where((s) => s.isDefault).firstOrNull;
    return (def ?? servers.first).feedServerAddress;
  }

  /// Switch the user's active feed server. Persists per account.
  ///
  /// [source] must be one of 'ssp' / 'custom' / 'default'. 'default' clears
  /// the cache (default/public fallback is never cached).
  static Future<void> switchToFeedServer(String url, String source) async {
    if (PublicOS.sessionBlockchainAddress == null) return;
    if (source == 'default') {
      await clearCachedActiveSsp();
    } else {
      await setCachedActiveSsp(url, source);
    }
    Log.i(_tag, 'Switched feed server to: $url ($source)');
  }

  /// Build the complete server list for UI display: SSP subscription entry
  /// (if subscribed) + custom entries. Marks the active one.
  static Future<List<FeedServerEntry>> buildFeedServerList() async {
    final entries = <FeedServerEntry>[];
    final activeUrl = await getActiveFeedServerUrl();

    // 1. SSP subscription entry
    try {
      final sspInfo = await getSSPServerInfo();
      if (sspInfo != null) {
        entries.add(FeedServerEntry(
          label: sspInfo.title.isNotEmpty ? sspInfo.title : sspInfo.slug,
          url: sspInfo.apiUrl,
          source: 'ssp',
          sspSlug: sspInfo.slug,
          isActive: activeUrl == sspInfo.apiUrl,
        ));
      }
    } catch (e) {
      Log.d(_tag, 'SSP info unavailable for list: $e');
    }

    // 2. Custom entries
    final customServers = await getFeedServers();
    for (final fs in customServers) {
      if (entries.any((e) => e.url == fs.feedServerAddress)) continue;
      entries.add(FeedServerEntry(
        label: fs.name ?? fs.feedServerAddress,
        url: fs.feedServerAddress,
        source: 'custom',
        feedServerId: fs.id,
        isActive: activeUrl == fs.feedServerAddress,
      ));
    }

    return entries;
  }

  /// Internal: get the FeedServer row for the active URL.
  /// Returns a synthetic entry (id: -1) for SSP subscription-resolved URLs.
  static Future<FeedServer?> getCurrentFeedServer() async {
    final activeUrl = await getActiveFeedServerUrl();
    if (activeUrl == null) return null;

    final sessionAddr =
        PublicOS.myPublicosAddress ?? '';

    final sspUrl = await getSSPServerAddress();
    if (activeUrl == sspUrl) {
      return FeedServer(
        id: -1,
        feedServerAddress: sspUrl!,
        name: 'SSP Server',
        isDefault: false,
        sessionAddress: sessionAddr,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    final servers = await getFeedServers();
    return servers.where((s) => s.feedServerAddress == activeUrl).firstOrNull ??
        (servers.isEmpty ? null : servers.first);
  }

  // ==========================================================================
  // SERVER URL BUILDERS
  // ==========================================================================

  static Future<String> getJsonChannelUrl(int accountId, String slug,
      {String? serverAddress}) async {
    final baseUrl =
        serverAddress ?? (await getCurrentFeedServer())?.feedServerAddress ?? '';
    return '$baseUrl/api/$accountId/channels/$slug/json';
  }

  static Future<String> getRssChannelUrl(int accountId, String slug,
      {String? serverAddress}) async {
    final baseUrl =
        serverAddress ?? (await getCurrentFeedServer())?.feedServerAddress ?? '';
    return '$baseUrl/api/$accountId/channels/$slug/rss';
  }

  static Future<String> getAtomChannelUrl(int accountId, String slug,
      {String? serverAddress}) async {
    final baseUrl =
        serverAddress ?? (await getCurrentFeedServer())?.feedServerAddress ?? '';
    return '$baseUrl/api/$accountId/channels/$slug/atom';
  }

  // ==========================================================================
  // HEALTH CHECK
  // ==========================================================================

  /// Is the active feed server reachable?
  static Future<FeedServerApiResponse<bool>> checkServerHealth() async {
    try {
      final response = await makeRequest('GET', '/health');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FeedServerApiResponse.success(data['status'] == 'ok');
      } else {
        return FeedServerApiResponse.error(
            {'code': 'UNHEALTHY', 'message': 'Server is not healthy'});
      }
    } catch (e) {
      return FeedServerApiResponse.error(
          {'code': 'CONNECTION_FAILED', 'message': e.toString()});
    }
  }

  // ==========================================================================
  // TRANSPORT + SIGNING (public — used by publicos_channels.dart)
  // ==========================================================================

  /// Recover the Ethereum address that produced an EIP-191 signature over
  /// [message]. Returns `0x…`-prefixed lowercase address on success, null on
  /// any failure (malformed signature, invalid recovery, etc.).
  ///
  /// Symmetric to [signMessage] — same prefix (`\x19Ethereum Signed Message:\n`
  /// + length) and same keccak256 hashing. Use this to verify any signature
  /// produced by PublicOS clients (post signatures, vote signatures, etc.)
  /// on the device, without round-tripping to the server.
  static String? recoverEip191Signer(String message, String signatureHex) {
    try {
      final messageBytes = utf8.encode(message);
      final prefix = '\x19Ethereum Signed Message:\n${messageBytes.length}';
      final prefixBytes = utf8.encode(prefix);
      final fullMessage =
          Uint8List.fromList([...prefixBytes, ...messageBytes]);
      final messageHash = keccak256(fullMessage);

      final sig = signatureHex.startsWith('0x')
          ? signatureHex.substring(2)
          : signatureHex;
      if (sig.length != 130) return null;

      final r = BigInt.parse(sig.substring(0, 64), radix: 16);
      final s = BigInt.parse(sig.substring(64, 128), radix: 16);
      var v = int.parse(sig.substring(128, 130), radix: 16);
      // Signers in our stack emit 27/28, but accept 0/1 for interop.
      if (v < 27) v += 27;

      final publicKey = ecRecover(messageHash, MsgSignature(r, s, v));
      final addressBytes = publicKeyToAddress(publicKey);
      return '0x${bytesToHex(addressBytes)}';
    } catch (_) {
      return null;
    }
  }

  /// EIP-191 signature over a message string using the current blockchain key.
  /// The home SSP's base URL from a BACKGROUND isolate (the 15-min worker's
  /// inbox pull), resolved as the main app does:
  /// the cached active-SSP blob in secure storage first, else
  /// `slugOf(1, A)` → registry `apiUrl` on chain with the client
  /// `ensureChainIsolateReady()` built. Null = no home known: skip the pull.
  static Future<String?> homeForIsolate() async {
    try {
      final cached = await getCachedActiveSsp();
      if (cached != null && cached.source == 'ssp') return cached.endpoint;
    } catch (e) {
      Log.d(_tag, 'homeForIsolate: cache read failed: $e');
    }
    try {
      return await getSSPServerAddress();
    } catch (e) {
      Log.d(_tag, 'homeForIsolate: chain resolve failed: $e');
      return null;
    }
  }

  static String signMessage(String message) {
    try {
      return _signHex(_privateKeyHex(), message);
    } catch (e) {
      Log.e(_tag, 'signMessage error: $e');
      throw Exception('Failed to sign message: $e');
    }
  }

  /// [signMessage] off the UI thread. secp256k1 in Dart takes
  /// tens of milliseconds on a phone (more in a debug build), and a sign
  /// that runs inside a gesture callback freezes whatever is animating (a
  /// double-tap heart stalls while the like signs). The key is read
  /// here; only the hex and the message cross to the worker.
  static Future<String> signMessageAsync(String message) async {
    final keyHex = _privateKeyHex();
    try {
      return await compute(_signHexEntry, [keyHex, message]);
    } catch (e) {
      Log.e(_tag, 'signMessage error: $e');
      throw Exception('Failed to sign message: $e');
    }
  }

  static String _privateKeyHex() {
    final key = PublicOS.currentBlockchainPrivateKey;
    if (key == null) {
      throw Exception('No blockchain private key available for signing');
    }
    return key.privateKeyInt.toRadixString(16).padLeft(64, '0');
  }

  static String _signHexEntry(List<String> args) => _signHex(args[0], args[1]);

  /// EIP-191 sign of [message] with the key in [privateKeyHex]. Pure: reads
  /// nothing of [PublicOS], so it runs in an isolate as well as inline.
  static String _signHex(String privateKeyHex, String message) {
    {
      final messageBytes = utf8.encode(message);
      final prefix = '\x19Ethereum Signed Message:\n${messageBytes.length}';
      final prefixBytes = utf8.encode(prefix);

      final fullMessage = Uint8List.fromList([...prefixBytes, ...messageBytes]);
      final messageHash = keccak256(fullMessage);

      final privateKeyBytes = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        privateKeyBytes[i] =
            int.parse(privateKeyHex.substring(i * 2, i * 2 + 2), radix: 16);
      }

      final signature = sign(messageHash, privateKeyBytes);
      final r = signature.r;
      final s = signature.s;
      final v = signature.v;
      final vEthereum = v < 27 ? v + 27 : v;

      final signatureHex = '0x${r.toRadixString(16).padLeft(64, '0')}'
          '${s.toRadixString(16).padLeft(64, '0')}'
          '${vEthereum.toRadixString(16).padLeft(2, '0')}';

      return signatureHex;
    }
  }

  // CSPRNG used for envelope nonces. Each request gets a fresh 16 random
  // bytes (32 hex chars) to satisfy the server's PK-collision replay table.
  static final Random _nonceRng = Random.secure();

  /// 32 hex chars / 16 random bytes from `Random.secure()`. Server-side
  /// uniqueness is enforced via PRIMARY KEY on `nonce_used.nonce`; reusing
  /// a nonce across two parallel calls trips `ENVELOPE_REPLAY`.
  static String generateNonce() {
    final bytes = List<int>.generate(16, (_) => _nonceRng.nextInt(256));
    final sb = StringBuffer();
    for (final b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }

  /// Compute the canonical envelope `target` string the server validates.
  ///
  /// Format: `"<METHOD> <host><path>"` — strips query string (server
  /// compares `c.Request.URL.Path` only) and includes a non-default port
  /// in the host. Comparison on the server is case-insensitive.
  static String computeTarget(String method, String fullUrl) {
    final uri = Uri.parse(fullUrl);
    final defaultPort =
        (uri.scheme == 'https' && (uri.port == 443 || uri.port == 0)) ||
            (uri.scheme == 'http' && (uri.port == 80 || uri.port == 0));
    final host = defaultPort ? uri.host : '${uri.host}:${uri.port}';
    return '${method.toUpperCase()} $host${uri.path}';
  }

  /// Resolve the active feed-server base URL (with explicit override or
  /// the chain-resolved SSP default). Returns empty string when no server
  /// is configured — callers must error.
  static Future<String> resolveBaseUrl(String? serverAddress) async {
    return serverAddress ??
        (await getCurrentFeedServer())?.feedServerAddress ??
        '';
  }

  /// Maps get alphabetical keys at every depth (Go `json.Marshal`'s order);
  /// lists keep their order; scalars pass through.
  static dynamic _deepSorted(dynamic v) {
    if (v is Map) {
      final keys = v.keys.map((k) => k.toString()).toList()..sort();
      return <String, dynamic>{for (final k in keys) k: _deepSorted(v[k])};
    }
    if (v is List) return v.map(_deepSorted).toList();
    return v;
  }

  /// The canonical JSON a signed object is signed over: keys sorted at every
  /// depth, lists in order, no whitespace, no HTML escaping (Dart's
  /// `jsonEncode` adds none). The signed bytes are this string as UTF-8
  /// (spec § Signatures); every hash in the format is SHA-256 over them.
  static String canonicalJson(Object? value) => jsonEncode(_deepSorted(value));

  /// SHA-256 of [bytes], lowercase hex: a media object's `sha256`.
  static String sha256Hex(List<int> bytes) =>
      crypto.sha256.convert(bytes).toString();

  /// Build a signed API request envelope (envelope v2: nonce + target).
  ///
  /// Auto-adds `account_address`, alphabetizes data + envelope keys to
  /// match the server's `createMessage` byte-for-byte (Go `json.Marshal`
  /// sorts top-level keys), then EIP-191-signs the canonical JSON.
  ///
  /// [target] must be the path-only URL the request will hit, in the
  /// form returned by [computeTarget]. Most callers should go through
  /// [signedRequest] / [signedRequestAtUrl] / [buildSignedEnvelope] —
  /// they compute target + dispatch in one shot. Direct callers (e.g.
  /// the multipart upload path) construct target via [computeTarget].
  static FeedServerApiRequest createApiRequest(
      String action, Map<String, dynamic> data, String target) {
    final e = _envelope(action, data, target);
    return e.signed(signMessage(e.messageJson));
  }

  /// [createApiRequest] with the sign off the UI thread
  /// ([signMessageAsync]); the two common signed paths use it.
  static Future<FeedServerApiRequest> createApiRequestAsync(
      String action, Map<String, dynamic> data, String target) async {
    final e = _envelope(action, data, target);
    return e.signed(await signMessageAsync(e.messageJson));
  }

  static _Envelope _envelope(
      String action, Map<String, dynamic> data, String target) {
    if (PublicOS.myPublicosAddress == null) {
      throw Exception('No publicos address available for API request');
    }
    if (PublicOS.currentBlockchainPrivateKey == null) {
      throw Exception('No blockchain private key available for signing');
    }
    if (target.isEmpty) {
      throw Exception('createApiRequest target must not be empty');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final nonce = generateNonce();
    final accountAddress = PublicOS.myPublicosAddress!;
    final sessionAddress =
        PublicOS.currentBlockchainPrivateKey!.address.eip55With0x;

    // Single alphabetical sort over data + account_address. Partial sort
    // (account_address pinned first, user keys sorted around it) would
    // mismatch Go's json.Marshal for any user key that sorts before
    // 'account_address'.
    final allData = <String, dynamic>{
      'account_address': accountAddress,
      ...data,
    };
    // DEEP sort: Go's json.Marshal sorts map keys at EVERY
    // level, so a nested map (e.g. put_notif_target's `kinds`) must be
    // sorted too, or the signed bytes differ and the server answers 401
    // BAD_SIGNATURE. Lists keep their order (Go keeps slice order).
    final dataSorted = _deepSorted(allData) as Map<String, dynamic>;

    // Envelope canonicalization: alphabetical action / data / nonce /
    // session / target / timestamp matches server's createMessage in
    // internal/auth/signature.go. Field order is load-bearing — Go's
    // json.Marshal of a map sorts top-level keys, and the signature
    // recovers against that exact byte sequence.
    final requestData = {
      'action': action,
      'data': dataSorted,
      'nonce': nonce,
      'session': sessionAddress, // sorts after nonce
      'target': target,
      'timestamp': timestamp,
    };

    return _Envelope(
      messageJson: jsonEncode(requestData),
      timestamp: timestamp,
      action: action,
      data: dataSorted,
      session: sessionAddress,
      nonce: nonce,
      target: target,
    );
  }

  /// Send a signed JSON-body request to the active SSP. Resolves base
  /// URL, computes envelope target from method + endpoint, builds + signs
  /// the v2 envelope, dispatches via [makeRequest]. The common path for
  /// every channel / post / moderation call.
  static Future<http.Response> signedRequest({
    required String method,
    required String endpoint,
    required String action,
    Map<String, dynamic>? data,
    String? serverAddress,
  }) async {
    final baseUrl = await resolveBaseUrl(serverAddress);
    if (baseUrl.isEmpty) {
      throw Exception('No server available');
    }
    final target = computeTarget(method, '$baseUrl$endpoint');
    final apiRequest =
        await createApiRequestAsync(action, data ?? const {}, target);
    final response = await makeRequest(method, endpoint,
        body: apiRequest.toJson(), serverAddress: baseUrl);
    _maybeThrowSspGate(response);
    return response;
  }

  /// Send a signed JSON-body request to an absolute URL (no base-URL
  /// resolution). Use for paths captured upstream as full URLs (e.g.
  /// `post.commentsUrl` — comment / reaction / reply endpoints) where
  /// the base URL is already baked in.
  ///
  /// Supports body on GET/DELETE/PUT/POST via `http.Request`.
  static Future<http.Response> signedRequestAtUrl({
    required String method,
    required String url,
    required String action,
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    // [SIGNEDREQ] timing (debug: signed reads can stall 10–30 s on
    // desktop before reaching nginx; remove once the slow step is known).
    final sw = Stopwatch()..start();
    final target = computeTarget(method, url);
    final apiRequest =
        await createApiRequestAsync(action, data ?? const {}, target);
    final signMs = sw.elapsedMilliseconds;
    final req = http.Request(method.toUpperCase(), Uri.parse(url));
    req.headers['Content-Type'] = 'application/json';
    // Extra headers. Added for HTTP conditional GET (`If-None-Match` /
    // `If-Modified-Since`) on signed feed reads — the SIGNED path is how we read
    // PublicOS channels, so without this the cache could only ever revalidate
    // external RSS. Applied after Content-Type so a caller cannot clobber the
    // envelope's own content type by accident.
    if (headers != null) req.headers.addAll(headers);
    req.body = jsonEncode(apiRequest.toJson());
    Log.d(_tag, '[SIGNEDREQ] $action sign=${signMs}ms → sending $url');
    final stream = await req.send();
    final headersMs = sw.elapsedMilliseconds;
    final response = await http.Response.fromStream(stream);
    Log.d(_tag,
        '[SIGNEDREQ] $action ${response.statusCode} sign=${signMs}ms headers=${headersMs}ms total=${sw.elapsedMilliseconds}ms $url');
    _maybeThrowSspGate(response);
    return response;
  }

  /// If [response] is a 403/500 with an SSP gate error code, throws an
  /// [SSPGateException]. No-op otherwise. Used by [signedRequest],
  /// [signedRequestAtUrl], and the multipart upload path so callers can
  /// route on type via `on SSPGateException catch (e)`.
  static void _maybeThrowSspGate(http.Response response) {
    if (response.statusCode != 403 && response.statusCode != 500) return;
    Map<String, dynamic>? body;
    try {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) body = raw;
    } catch (_) {
      return;
    }
    if (body == null) return;
    final err = body['error'];
    if (err is! Map<String, dynamic>) return;
    final ex = SSPGateException.tryFromErrorMap(response.statusCode, err);
    if (ex != null) throw ex;
  }

  /// Build a signed envelope without dispatching. Returns the envelope
  /// and the absolute URL it was signed for. For callers that need to
  /// dispatch via a non-standard transport (multipart upload).
  static Future<({FeedServerApiRequest envelope, String url})>
      buildSignedEnvelope({
    required String method,
    required String endpoint,
    required String action,
    Map<String, dynamic>? data,
    String? serverAddress,
  }) async {
    final baseUrl = await resolveBaseUrl(serverAddress);
    if (baseUrl.isEmpty) {
      throw Exception('No server available');
    }
    final url = '$baseUrl$endpoint';
    final target = computeTarget(method, url);
    final envelope = createApiRequest(action, data ?? const {}, target);
    return (envelope: envelope, url: url);
  }

  /// Dispatch an HTTP request to the active feed server.
  /// If [serverAddress] is null, uses the active feed server URL.
  static Future<http.Response> makeRequest(String method, String endpoint,
      {Map<String, dynamic>? body, String? serverAddress}) async {
    String baseUrl = serverAddress ??
        (await getCurrentFeedServer())?.feedServerAddress ??
        '';
    if (baseUrl.isEmpty) {
      throw Exception('No server available');
    }

    final url = Uri.parse('$baseUrl$endpoint');

    try {
      late http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          if (body != null) {
            final request = http.Request('GET', url);
            request.headers['Content-Type'] = 'application/json';
            request.body = jsonEncode(body);
            final streamedResponse =
                await request.send().timeout(PublicOS.serverRequestTimeout);
            response = await http.Response.fromStream(streamedResponse);
          } else {
            response =
                await http.get(url).timeout(PublicOS.serverRequestTimeout);
          }
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body != null ? jsonEncode(body) : null,
          ).timeout(PublicOS.serverRequestTimeout);
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body != null ? jsonEncode(body) : null,
          ).timeout(PublicOS.serverRequestTimeout);
          break;
        case 'DELETE':
          response = await http.delete(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body != null ? jsonEncode(body) : null,
          ).timeout(PublicOS.serverRequestTimeout);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
      return response;
    } catch (e) {
      Log.e(_tag, 'HTTP $method $endpoint — $e');
      throw Exception('Server request failed: $e');
    }
  }

  // ==========================================================================
  // MEDIA STORAGE (user's files on their SSP — used by chat, posts, profile)
  // ==========================================================================

  /// Upload raw file bytes to the user's SSP. Used by chat attachments,
  /// post images, profile pics, and any other file the app wants to host.
  ///
  /// The server validates file size, MIME, and the user's quota. Returns
  /// a [MediaFile] with its public URL on success, plus the SHA-256 and byte
  /// size of the bytes sent ([MediaFile.sha256], [MediaFile.fileSize]), so a
  /// composer signs the file it has without downloading it back.
  static Future<FeedServerApiResponse<MediaFile>> uploadMedia(
    Uint8List fileBytes,
    String filename, {
    String? serverAddress,
    String? mimeType,
    UploadProgress? onProgress,
  }) async {
    final sw = Stopwatch()..start();
    final sizeBytes = fileBytes.length;
    final sizeKb = (sizeBytes / 1024).toStringAsFixed(1);
    final sizeMb = (sizeBytes / 1024 / 1024).toStringAsFixed(2);
    final detectedMime = mimeType ?? _sniffMime(fileBytes, filename);
    final logTag = "name='$filename' size=${sizeBytes}B (${sizeKb}KB / ${sizeMb}MB) mime=$detectedMime";

    try {
      if (!PublicOS.isAuthenticated ||
          PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error(
            {'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final endpoint = '/api/$accountAddress/media/upload';

      final baseUrl = await resolveBaseUrl(serverAddress);
      if (baseUrl.isEmpty) {
        return FeedServerApiResponse.error(
            {'code': 'NO_SERVER', 'message': 'No server available'});
      }

      final fullUrl = '$baseUrl$endpoint';
      final target = computeTarget('POST', fullUrl);
      final apiRequest = createApiRequest('upload_media', const {}, target);

      final url = Uri.parse(fullUrl);
      Log.i(_tag, 'uploadMedia START → $url | $logTag');

      final request = http.MultipartRequest('POST', url);

      // Auth as form fields (multipart can't use JSON body). Server's
      // parseSignedRequestFromForm reads nonce + target alongside the
      // timestamp/action/client/signature/data fields.
      request.fields['timestamp'] = apiRequest.timestamp.toString();
      request.fields['action'] = apiRequest.action;
      request.fields['session'] = apiRequest.session;
      request.fields['nonce'] = apiRequest.nonce;
      request.fields['target'] = apiRequest.target;
      request.fields['signature'] = apiRequest.signature;
      request.fields['data'] = jsonEncode(apiRequest.data);

      // Send the sniffed MIME so server-side validation + Content-Type
      // sniffing line up with what was actually picked. Falling back to
      // octet-stream caused the server to either reject by MIME or guess.
      final mimeParts = detectedMime.split('/');
      request.files.add(_filePart(fileBytes, filename, mimeParts, onProgress));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Try to decode JSON. Non-JSON bodies (HTML error pages from a proxy,
      // 404s from a server that doesn't have the media handler mounted,
      // 502s from Cloudflare/etc.) are common when an SSP isn't fully
      // deployed — surface them as a structured error instead of letting
      // the FormatException bubble up as a stack trace.
      Map<String, dynamic>? decoded;
      try {
        final raw = jsonDecode(response.body);
        if (raw is Map<String, dynamic>) decoded = raw;
      } catch (_) {
        Log.e(_tag,
            'uploadMedia FAIL non-JSON | HTTP ${response.statusCode} | '
            'elapsed=${sw.elapsedMilliseconds}ms | $logTag | '
            'body[0..120]: ${response.body.substring(0, response.body.length.clamp(0, 120))}');
        return FeedServerApiResponse.error({
          'code': 'BAD_RESPONSE',
          'message': _explainNonJsonStatus(response.statusCode, sizeBytes),
        });
      }

      if (response.statusCode == 201 && decoded != null && decoded['file'] != null) {
        Log.i(_tag,
            'uploadMedia OK ← HTTP 201 | elapsed=${sw.elapsedMilliseconds}ms | $logTag');
        return FeedServerApiResponse.success(
            MediaFile.fromJson(decoded['file'] as Map<String, dynamic>)
                .copyWith(sha256: sha256Hex(fileBytes), fileSize: sizeBytes));
      } else {
        final err = decoded?['error'];
        // Surface SSP gate failures as a typed throw so the snackbar
        // dispatcher in publicos_client can route on type. Multipart path
        // doesn't go through signedRequest, so we parse here directly.
        final gateEx = SSPGateException.tryFromErrorMap(
            response.statusCode, err is Map<String, dynamic> ? err : null);
        if (gateEx != null) throw gateEx;
        Log.e(_tag,
            'uploadMedia FAIL ← HTTP ${response.statusCode} | '
            'elapsed=${sw.elapsedMilliseconds}ms | $logTag | error=$err');
        return FeedServerApiResponse.error(
            (err is Map<String, dynamic>) ? err : {
              'code': 'UPLOAD_FAILED',
              'message': 'Upload failed (HTTP ${response.statusCode})',
            });
      }
    } on SSPGateException {
      // Re-throw past the generic catch so the typed exception reaches
      // the caller's snackbar dispatcher.
      rethrow;
    } catch (e) {
      Log.e(_tag,
          'uploadMedia THREW after ${sw.elapsedMilliseconds}ms | $logTag | $e');
      return FeedServerApiResponse.error(
          {'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Best-effort MIME inference. First tries magic bytes (covers HEIC from
  /// iPhone Photos, JPEG, PNG, GIF, WEBP), then falls back to extension.
  static String _sniffMime(Uint8List bytes, String filename) {
    if (bytes.length >= 12) {
      // JPEG: FF D8 FF
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return 'image/jpeg';
      }
      // PNG: 89 50 4E 47 0D 0A 1A 0A
      if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
        return 'image/png';
      }
      // GIF: "GIF87a" or "GIF89a"
      if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
        return 'image/gif';
      }
      // WEBP: "RIFF" .. "WEBP"
      if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
          bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
        return 'image/webp';
      }
      // HEIC/HEIF: "ftyp" at offset 4, brand at offset 8
      if (bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70) {
        final brand = String.fromCharCodes(bytes.sublist(8, 12));
        if (brand == 'heic' || brand == 'heix' || brand == 'mif1' || brand == 'msf1') {
          return 'image/heic';
        }
        if (brand == 'mp42' || brand == 'isom' || brand == 'qt  ') {
          return 'video/mp4';
        }
        // An audio-only MP4 container (m4a).
        if (brand == 'M4A ' || brand == 'M4B ') {
          return 'audio/mp4';
        }
      }
      // Audio (PublicOS Feed v1 `audio`): the four types every
      // SSP allow-lists. An mp3 with an ID3 tag, or a bare frame sync.
      if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
        return 'audio/mpeg';
      }
      if (bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0 && (bytes[1] & 0x06) != 0) {
        return 'audio/mpeg';
      }
      // WAV: "RIFF" .. "WAVE"
      if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
          bytes[8] == 0x57 && bytes[9] == 0x41 && bytes[10] == 0x56 && bytes[11] == 0x45) {
        return 'audio/wav';
      }
      // Ogg: "OggS"
      if (bytes[0] == 0x4F && bytes[1] == 0x67 && bytes[2] == 0x67 && bytes[3] == 0x53) {
        return 'audio/ogg';
      }
    }
    // Extension fallback
    final ext = filename.toLowerCase().split('.').last;
    const extMap = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'heic': 'image/heic',
      'heif': 'image/heic',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'webm': 'video/webm',
      'm4v': 'video/x-m4v',
      'mp3': 'audio/mpeg',
      'm4a': 'audio/mp4',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'oga': 'audio/ogg',
    };
    return extMap[ext] ?? 'application/octet-stream';
  }

  /// Maps a raw HTTP status to a user-readable explanation, with size
  /// context when relevant. The user can act on this without reading
  /// HTTP-spec docs.
  static String _explainNonJsonStatus(int status, int sizeBytes) {
    final sizeMb = (sizeBytes / 1024 / 1024).toStringAsFixed(1);
    switch (status) {
      case 404:
        return 'Server has no media endpoint (HTTP 404). Your active SSP may not be running an up-to-date build.';
      case 413:
        return 'File too large for server (HTTP 413). $sizeMb MB exceeded the upload limit.';
      case 502:
      case 503:
      case 504:
        return 'SSP gateway error (HTTP $status). Often a proxy size limit hit at $sizeMb MB, or the upstream is down. Try a smaller image to confirm.';
      case 500:
        return 'SSP internal error (HTTP 500). Check the server logs.';
      default:
        return 'Server returned non-JSON (HTTP $status). The media endpoint may not be deployed on this SSP.';
    }
  }

  /// List the current user's media files and quota.
  static Future<FeedServerApiResponse<MediaListResponse>> listMedia(
      {String? serverAddress}) async {
    try {
      if (!PublicOS.isAuthenticated ||
          PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error(
            {'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await signedRequest(
        method: 'GET',
        endpoint: '/api/$accountAddress/media',
        action: 'list_media',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return FeedServerApiResponse.success(
            MediaListResponse.fromJson(responseData));
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ??
            {'code': 'UNKNOWN', 'message': 'List failed'});
      }
    } catch (e) {
      Log.e(_tag, 'listMedia error: $e');
      return FeedServerApiResponse.error(
          {'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Delete a media file by its server-side ID.
  static Future<FeedServerApiResponse<bool>> deleteMedia(int id,
      {String? serverAddress}) async {
    try {
      if (!PublicOS.isAuthenticated ||
          PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error(
            {'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await signedRequest(
        method: 'DELETE',
        endpoint: '/api/$accountAddress/media/$id',
        action: 'delete_media',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        return FeedServerApiResponse.success(true);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ??
            {'code': 'UNKNOWN', 'message': 'Delete failed'});
      }
    } catch (e) {
      Log.e(_tag, 'deleteMedia error: $e');
      return FeedServerApiResponse.error(
          {'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// The multipart file part for both upload doors. Without [onProgress] it
  /// is byte-identical to the old `MultipartFile.fromBytes`; with it, the
  /// bytes go out as a counting stream in 64 KiB chunks and [onProgress] is
  /// called with (sent, total) per chunk. The count is bytes handed to the
  /// socket, not bytes the server acknowledged — close enough for a ring.
  static http.MultipartFile _filePart(
    Uint8List fileBytes,
    String filename,
    List<String> mimeParts,
    UploadProgress? onProgress,
  ) {
    final contentType = MediaType(
      mimeParts.length == 2 ? mimeParts[0] : 'application',
      mimeParts.length == 2 ? mimeParts[1] : 'octet-stream',
    );
    if (onProgress == null) {
      return http.MultipartFile.fromBytes('file', fileBytes,
          filename: filename, contentType: contentType);
    }
    const chunk = 64 * 1024;
    Stream<List<int>> counting() async* {
      for (var i = 0; i < fileBytes.length; i += chunk) {
        final end = min(i + chunk, fileBytes.length);
        yield Uint8List.sublistView(fileBytes, i, end);
        onProgress(end, fileBytes.length);
      }
    }

    return http.MultipartFile('file', counting(), fileBytes.length,
        filename: filename, contentType: contentType);
  }

  /// Move a file between the two doors on the SSP that holds it.
  /// The composer uploads to the door
  /// of the feed selected at pick time; when the user posts to a feed of the
  /// other privacy, each such file is moved BEFORE the post is signed and the
  /// returned [MovedMedia.url] is what goes into the post. [url] is the
  /// file's current URL (`/media/<name>` or `/pedia/<id>.<ext>`); the server
  /// reads the source door off it. The old copy is deleted on the server
  /// unless another live post of this account still uses it there.
  ///
  /// `ROUTE_MISSING` = the SSP answered a bare 404 with no JSON error: an
  /// older build without the route. Callers fall back to re-uploading the
  /// bytes through the other door.
  static Future<FeedServerApiResponse<MovedMedia>> moveMedia({
    required String url,
    required bool toPrivate,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error(
            {'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await signedRequest(
        method: 'POST',
        endpoint: '/api/$accountAddress/media/move',
        action: 'move_media',
        data: {'url': url, 'to': toPrivate ? 'private' : 'public'},
        serverAddress: serverAddress,
      );
      Map<String, dynamic>? decoded;
      try {
        final raw = jsonDecode(response.body);
        if (raw is Map<String, dynamic>) decoded = raw;
      } catch (_) {}
      if (response.statusCode == 200 && decoded != null) {
        Log.i(_tag, 'moveMedia OK ← ${decoded['url']} deleted_old=${decoded['deleted_old']}');
        return FeedServerApiResponse.success(MovedMedia.fromJson(decoded));
      }
      if (response.statusCode == 404 && decoded?['error'] == null) {
        return FeedServerApiResponse.error({
          'code': 'ROUTE_MISSING',
          'message': 'This server cannot move media between doors',
        });
      }
      Log.e(_tag, 'moveMedia FAIL ← HTTP ${response.statusCode} | $url');
      return FeedServerApiResponse.error(decoded?['error'] ??
          {'code': 'MOVE_FAILED', 'message': 'HTTP ${response.statusCode}'});
    } on SSPGateException {
      rethrow;
    } catch (e) {
      Log.e(_tag, 'moveMedia error: $e');
      return FeedServerApiResponse.error(
          {'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  static final Map<String, SspLimits> _limitsCache = {};

  /// The text caps the SSP at [serverAddress] (default: the active feed
  /// server) enforces on posts and comments: `GET /api/limits`, public, no
  /// envelope. Cached per server for
  /// the life of the process; [refresh] bypasses the cache. null when the
  /// host is unreachable or an older build without the route, in which case
  /// the composer applies no cap and the server's 413 remains the backstop.
  static Future<SspLimits?> fetchLimits(
      {String? serverAddress, bool refresh = false}) async {
    final base = await resolveBaseUrl(serverAddress);
    if (base.isEmpty) return null;
    if (!refresh && _limitsCache.containsKey(base)) return _limitsCache[base];
    try {
      final response = await http
          .get(Uri.parse('$base/api/limits'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        Log.d(_tag, 'fetchLimits: ${response.statusCode} from $base');
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      final limits = SspLimits.fromJson(decoded);
      _limitsCache[base] = limits;
      return limits;
    } catch (e) {
      Log.w(_tag, 'fetchLimits failed: $e');
      return null;
    }
  }

  /// An SSP's house rules + privacy notice at the fixed path every server
  /// serves, `GET <apiUrl>/privacy_and_agreements`, public, no envelope.
  /// [apiUrl] is the registry's
  /// `apiUrl` for the server the user is about to subscribe to. Not cached:
  /// the sheet that shows it opens once per subscribe. `notPublished` = the
  /// server answered but has no valid rules file (404 / 500 / bad body);
  /// `unreachable` = no answer. The app shows the rules, or says which of the
  /// two happened, and the user decides.
  static Future<({SspRules? rules, SspRulesStatus status})> fetchRules(String apiUrl) async {
    final base = apiUrl.endsWith('/') ? apiUrl.substring(0, apiUrl.length - 1) : apiUrl;
    try {
      final response = await http
          .get(Uri.parse('$base/privacy_and_agreements'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        Log.d(_tag, 'fetchRules: ${response.statusCode} from $base');
        return (rules: null, status: SspRulesStatus.notPublished);
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final rules = decoded is Map<String, dynamic> ? SspRules.fromJson(decoded) : null;
      return rules == null
          ? (rules: null, status: SspRulesStatus.notPublished)
          : (rules: rules, status: SspRulesStatus.published);
    } catch (e) {
      Log.w(_tag, 'fetchRules failed: $e');
      return (rules: null, status: SspRulesStatus.unreachable);
    }
  }

  // ==========================================================================
  // SSP REGISTRATION BY HOST
  //
  // "Is the server this feed comes from a registered SSP?" The chain answers
  // it in ONE call because the registry's apiUrl is canonical and unique:
  // `getSocialServerSlugByApiUrl(scheme://lowercase-host[:port])` → the slug,
  // or "" for a server on the open internet. Decided once per server, kept
  // 7 days (SSPs are not expected to change often), the
  // cards only display. Three answers, never two: `registered`,
  // `unregistered`, and `unknown` when the chain could not say (offline, a
  // chain older than the index); the mark is for `unregistered` ONLY, doubt
  // shows nothing (the signature-mark rule: mark the bad case, verified).
  // ==========================================================================

  static const Duration sspRegistrationTtl = Duration(days: 7);
  static const String _sspRegPrefsKey = 'ssp_registration_by_host_v1';

  /// In-flight + settled per canonical server, for the life of the process.
  static final Map<String, Future<SspRegistration>> _sspRegMemo = {};

  /// The registry key for [url]: `scheme://host[:port]`, lower-cased, no
  /// path, exactly what a canonical apiUrl is on chain. null when [url] has
  /// no scheme or authority.
  static String? canonicalSspUrlOf(String url) {
    final base = serverOf(url);
    return base?.toLowerCase();
  }

  /// Registration of the server that serves [url] (a feed, channel or post
  /// URL). Memoised per server; the persisted answer is reused for
  /// [sspRegistrationTtl]; a fresh chain read otherwise. Never throws.
  static Future<SspRegistration> sspRegistrationOf(String url) {
    final canon = canonicalSspUrlOf(url);
    if (canon == null) return Future.value(SspRegistration.unknown);
    return _sspRegMemo[canon] ??= _resolveSspRegistration(canon);
  }

  /// The settled answer for [url] if this process already has one, else
  /// null (the caller shows nothing and may await [sspRegistrationOf]).
  static SspRegistration? sspRegistrationIfKnown(String url) {
    final canon = canonicalSspUrlOf(url);
    if (canon == null) return SspRegistration.unknown;
    return _sspRegSettled[canon];
  }

  static final Map<String, SspRegistration> _sspRegSettled = {};

  static Future<SspRegistration> _resolveSspRegistration(String canon) async {
    // 0. Which registry answers. Every answer is stored WITH the registry
    // address it came from, and only reused while that is still the
    // registry: a genesis deploys a new one, so a verdict from the old chain
    // (or from the gap before the servers were re-registered) is never
    // trusted on the new one. Otherwise an "unregistered" cached during
    // that gap would show the open-internet mark on every post for 7 days.
    // Entries with no `reg` miss once and are re-asked.
    String? reg;
    try {
      if (PublicOSBsp.socialServerRegistryMemoryAddress == null) {
        await PublicOSBsp.resolveModuleAddresses();
      }
      reg = PublicOSBsp.socialServerRegistryMemoryAddress?.eip55With0x
          .toLowerCase();
    } catch (e) {
      Log.d(_tag, 'sspRegistration: registry resolve failed: $e');
    }

    // 1. The 7-day cache.
    SharedPreferences? prefs;
    Map<String, dynamic> stored = {};
    try {
      prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sspRegPrefsKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) stored = decoded;
      }
      final hit = stored[canon];
      if (reg != null &&
          hit is Map &&
          hit['reg'] == reg &&
          hit['at'] is int &&
          hit['slug'] is String) {
        final at = DateTime.fromMillisecondsSinceEpoch((hit['at'] as int) * 1000);
        if (DateTime.now().difference(at) < sspRegistrationTtl) {
          final v = (hit['slug'] as String).isEmpty
              ? SspRegistration.unregistered
              : SspRegistration.registered;
          _sspRegSettled[canon] = v;
          return v;
        }
      }
    } catch (e) {
      Log.d(_tag, 'sspRegistration: cache read failed: $e');
    }

    // 2. One chain call. Any failure (no client, an older chain without the
    // view, a timeout) is `unknown`, not cached, so the next look retries.
    String? slug;
    try {
      if (reg == null) throw StateError('registry address unresolved');
      slug = await PublicOSBsp.socialServerRegistryMemoryContract
          .getSocialServerSlugByApiUrl((apiUrl: canon))
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      Log.d(_tag, 'sspRegistration: chain read failed for $canon: $e');
      _sspRegMemo.remove(canon); // let a later look try again
      return SspRegistration.unknown;
    }
    final verdict =
        slug.isEmpty ? SspRegistration.unregistered : SspRegistration.registered;
    _sspRegSettled[canon] = verdict;

    // 3. Persist.
    try {
      stored[canon] = {
        'slug': slug,
        'at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'reg': reg,
      };
      await (prefs ?? await SharedPreferences.getInstance())
          .setString(_sspRegPrefsKey, jsonEncode(stored));
    } catch (e) {
      Log.d(_tag, 'sspRegistration: cache write failed: $e');
    }
    return verdict;
  }

  /// Forget every cached registration (a test hook, or after a genesis).
  static Future<void> clearSspRegistrationCache() async {
    _sspRegMemo.clear();
    _sspRegSettled.clear();
    try {
      (await SharedPreferences.getInstance()).remove(_sspRegPrefsKey);
    } catch (_) {}
  }

  // ==========================================================================
  // PRIVATE MEDIA (/pedia/ — the second door)
  //
  // Upload lands in the user's PRIVATE library and returns a stable
  // unguessable /pedia/<id> URL the composer places into the post body
  // BEFORE signing (the URL is just content bytes — the signing path is
  // untouched). Reads are envelope-authenticated per fetch and the response
  // is ECIES ciphertext sealed to THIS device's keychain EOA; PediaCrypto
  // opens it. The server links owned refs at post time so the media inherits
  // the post's gating — no URL policing anywhere, client included.
  // ==========================================================================

  /// Upload the poster (first frame, JPEG) of one of the caller's own PUBLIC
  /// videos. The client
  /// extracts the frame from the file it just uploaded; the SSP only stores
  /// it beside the video and serves it at `<video url>/poster`
  /// (my_rss_server `media_poster.go`). [filename] is the stored name, i.e.
  /// the last path segment of the video URL. Best-effort by design: callers
  /// fire it after a successful video upload and ignore failures — readers
  /// fall back to the old poster flow on a 404.
  static Future<bool> uploadMediaPoster(
    String filename,
    Uint8List jpegBytes, {
    String? serverAddress,
  }) =>
      _uploadPoster('media/poster', 'upload_media_poster',
          {'filename': filename}, filename, jpegBytes, serverAddress);

  /// The PRIVATE twin of [uploadMediaPoster]: the poster of one of the
  /// caller's own `/pedia/` videos. [id] is the last path segment of the
  /// pedia URL (the extension is fine, the server strips it). Served at
  /// `<pedia url>/poster` through the same read gate as the video and
  /// sealed per reader, so the fetch hooks decrypt it like the video.
  static Future<bool> uploadPediaPoster(
    String id,
    Uint8List jpegBytes, {
    String? serverAddress,
  }) =>
      _uploadPoster('pedia/poster', 'upload_pedia_poster', {'id': id}, id,
          jpegBytes, serverAddress);

  static Future<bool> _uploadPoster(String route, String action,
      Map<String, dynamic> data, String name, Uint8List jpegBytes,
      String? serverAddress) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return false;
      }
      final accountAddress = PublicOS.myPublicosAddress!;
      final baseUrl = await resolveBaseUrl(serverAddress);
      if (baseUrl.isEmpty) return false;
      final fullUrl = '$baseUrl/api/$accountAddress/$route';
      final target = computeTarget('POST', fullUrl);
      final apiRequest = createApiRequest(action, data, target);

      final request = http.MultipartRequest('POST', Uri.parse(fullUrl));
      request.fields['timestamp'] = apiRequest.timestamp.toString();
      request.fields['action'] = apiRequest.action;
      request.fields['session'] = apiRequest.session;
      request.fields['nonce'] = apiRequest.nonce;
      request.fields['target'] = apiRequest.target;
      request.fields['signature'] = apiRequest.signature;
      request.fields['data'] = jsonEncode(apiRequest.data);
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        jpegBytes,
        filename: '$name.poster.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
      final response = await http.Response.fromStream(await request.send());
      final ok = response.statusCode == 200;
      Log.i(_tag,
          '$action ${ok ? 'OK' : 'FAIL'} ← HTTP ${response.statusCode} | $name (${jpegBytes.length}B)');
      return ok;
    } catch (e) {
      Log.w(_tag, '$action error for $name: $e');
      return false;
    }
  }

  /// Fixed rule for a video's poster URL, both doors: `<video url>/poster`
  /// (my_rss_server `GET /media/:filename/poster` public, `GET /pedia/:id/poster`
  /// sealed per reader; 404 = no poster).
  static String posterUrlFor(String videoUrl) => '$videoUrl/poster';

  /// Upload file bytes to the user's PRIVATE library. Mirrors [uploadMedia]
  /// (same multipart envelope-as-form-fields shape, same MIME sniff) against
  /// the pedia door. The returned [PediaFile.url] is the stable signable
  /// address — the file is owner-only until a post references it.
  static Future<FeedServerApiResponse<PediaFile>> uploadPedia(
    Uint8List fileBytes,
    String filename, {
    String? serverAddress,
    String? mimeType,
    UploadProgress? onProgress,
  }) async {
    final sw = Stopwatch()..start();
    final sizeBytes = fileBytes.length;
    final detectedMime = mimeType ?? _sniffMime(fileBytes, filename);
    final logTag = "name='$filename' size=${sizeBytes}B mime=$detectedMime";

    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error(
            {'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final endpoint = '/api/$accountAddress/pedia/upload';
      final baseUrl = await resolveBaseUrl(serverAddress);
      if (baseUrl.isEmpty) {
        return FeedServerApiResponse.error(
            {'code': 'NO_SERVER', 'message': 'No server available'});
      }

      final fullUrl = '$baseUrl$endpoint';
      final target = computeTarget('POST', fullUrl);
      final apiRequest = createApiRequest('upload_pedia', const {}, target);

      final url = Uri.parse(fullUrl);
      Log.i(_tag, 'uploadPedia START → $url | $logTag');

      final request = http.MultipartRequest('POST', url);
      request.fields['timestamp'] = apiRequest.timestamp.toString();
      request.fields['action'] = apiRequest.action;
      request.fields['session'] = apiRequest.session;
      request.fields['nonce'] = apiRequest.nonce;
      request.fields['target'] = apiRequest.target;
      request.fields['signature'] = apiRequest.signature;
      request.fields['data'] = jsonEncode(apiRequest.data);

      final mimeParts = detectedMime.split('/');
      request.files.add(_filePart(fileBytes, filename, mimeParts, onProgress));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      Map<String, dynamic>? decoded;
      try {
        final raw = jsonDecode(response.body);
        if (raw is Map<String, dynamic>) decoded = raw;
      } catch (_) {
        Log.e(_tag,
            'uploadPedia FAIL non-JSON | HTTP ${response.statusCode} | $logTag');
        return FeedServerApiResponse.error({
          'code': 'BAD_RESPONSE',
          'message': _explainNonJsonStatus(response.statusCode, sizeBytes),
        });
      }

      if (response.statusCode == 201 &&
          decoded != null &&
          decoded['file'] != null) {
        Log.i(_tag,
            'uploadPedia OK ← HTTP 201 | elapsed=${sw.elapsedMilliseconds}ms | $logTag');
        // Hashed over the plain bytes, before sealing (spec § Media hashes).
        return FeedServerApiResponse.success(
            PediaFile.fromJson(decoded['file'] as Map<String, dynamic>)
                .copyWith(sha256: sha256Hex(fileBytes), fileSize: sizeBytes));
      } else {
        final err = decoded?['error'];
        final gateEx = SSPGateException.tryFromErrorMap(
            response.statusCode, err is Map<String, dynamic> ? err : null);
        if (gateEx != null) throw gateEx;
        Log.e(_tag,
            'uploadPedia FAIL ← HTTP ${response.statusCode} | $logTag | error=$err');
        return FeedServerApiResponse.error((err is Map<String, dynamic>)
            ? err
            : {
                'code': 'UPLOAD_FAILED',
                'message': 'Upload failed (HTTP ${response.statusCode})',
              });
      }
    } on SSPGateException {
      rethrow;
    } catch (e) {
      Log.e(_tag,
          'uploadPedia THREW after ${sw.elapsedMilliseconds}ms | $logTag | $e');
      return FeedServerApiResponse.error(
          {'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// List the current user's PRIVATE library (with the shared quota block).
  /// The Manage Server UI merges these into the one media list with a
  /// PRIVATE badge.
  static Future<FeedServerApiResponse<PediaListResponse>> listPedia(
      {String? serverAddress}) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error(
            {'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await signedRequest(
        method: 'GET',
        endpoint: '/api/$accountAddress/pedia',
        action: 'list_pedia',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return FeedServerApiResponse.success(
            PediaListResponse.fromJson(responseData));
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ??
            {'code': 'UNKNOWN', 'message': 'List failed'});
      }
    } catch (e) {
      Log.e(_tag, 'listPedia error: $e');
      return FeedServerApiResponse.error(
          {'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Delete a private file by its 32-hex id. Posts referencing it are
  /// untouched (signed content is verbatim forever) — their URL just 404s
  /// and readers see a deleted-media placeholder.
  static Future<FeedServerApiResponse<bool>> deletePedia(String id,
      {String? serverAddress}) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error(
            {'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await signedRequest(
        method: 'DELETE',
        endpoint: '/api/$accountAddress/pedia/$id',
        action: 'delete_pedia',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        return FeedServerApiResponse.success(true);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ??
            {'code': 'UNKNOWN', 'message': 'Delete failed'});
      }
    } catch (e) {
      Log.e(_tag, 'deletePedia error: $e');
      return FeedServerApiResponse.error(
          {'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Fetch + decrypt one `/pedia/` URL — THE reader path.
  ///
  /// Signs a `pedia_read` envelope (JSON body on GET, the feed-read
  /// precedent), receives ciphertext sealed to this device's keychain EOA,
  /// and opens it with [PediaCrypto]. Authorization is live on the server —
  /// owner always passes; anyone else needs a live post whose channel ladder
  /// admits them.
  ///
  /// Returns the plaintext bytes, or `null` when the media is gone or this
  /// reader isn't allowed (the server answers 404 for both — callers render
  /// the deleted-media placeholder after one feed-refresh retry).
  static Future<Uint8List?> fetchPediaBytes(String url) async {
    try {
      final key = PublicOS.currentBlockchainPrivateKey;
      if (key == null) {
        Log.e(_tag, 'fetchPediaBytes: no keychain key loaded');
        return null;
      }
      final response = await signedRequestAtUrl(
        method: 'GET',
        url: url,
        action: 'pedia_read',
      );
      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        Log.e(_tag,
            'fetchPediaBytes FAIL ← HTTP ${response.statusCode} | $url');
        return null;
      }
      return PediaCrypto.decrypt(response.bodyBytes, key.privateKey);
    } catch (e) {
      Log.e(_tag, 'fetchPediaBytes error | $url | $e');
      return null;
    }
  }

  /// The zero-package `requestAuth` callback.
  ///
  /// Called by a media widget when a plain fetch answered `401` +
  /// `WWW-Authenticate: PublicOS-Envelope` — or up front under `preAuth`.
  /// Signs a `pedia_read` envelope to EXACTLY [url] and returns the JSON
  /// body to attach to the retry. A PROVIDER, not data: envelopes are
  /// single-use (nonce) and ±5-minute bound, so the widget re-invokes this
  /// per actual fetch/retry — never caches the result.
  ///
  /// Returns null when no keychain key is loaded; the widget then just keeps
  /// its plain 401 (→ placeholder), same as an anonymous reader.
  static String? pediaRequestAuth(String url) {
    try {
      if (PublicOS.myPublicosAddress == null ||
          PublicOS.currentBlockchainPrivateKey == null) {
        return null;
      }
      final target = computeTarget('GET', url);
      final apiRequest = createApiRequest('pedia_read', const {}, target);
      return jsonEncode(apiRequest.toJson());
    } catch (e) {
      Log.e(_tag, 'pediaRequestAuth error | $url | $e');
      return null;
    }
  }

  /// The zero-package `responseTransform` callback.
  ///
  /// Response-driven decryption: a body marked `X-Publicos-Sealed` is ECIES
  /// ciphertext sealed to this device's keychain EOA — open it; anything
  /// else passes through untouched. Never keyed on URL shape (another SSP
  /// implementation may gate any URL it likes). Throws when a sealed body
  /// fails to open (tampered / wrong key / no key) — the widget treats that
  /// as a failed load, never renders ciphertext.
  static Uint8List pediaResponseTransform(
      Uint8List bytes, Map<String, String> headers) {
    final sealed =
        headers['x-publicos-sealed'] ?? headers['X-Publicos-Sealed'];
    if (sealed == null) return bytes;
    final key = PublicOS.currentBlockchainPrivateKey;
    if (key == null) {
      throw StateError('sealed response but no keychain key loaded');
    }
    return PediaCrypto.decrypt(bytes, key.privateKey);
  }

  // ==========================================================================
  // ACCOUNT-WIDE ACCESS CONTROL (server-level, applies across all channels)
  // ==========================================================================

  /// Add an address to the account-wide read whitelist.
  static Future<FeedServerApiResponse<void>> addAccountWhitelist({
    required String address,
    String? expiresAt,
    String? serverAddress,
  }) async {
    return _authedRequest(
      action: 'add_account_whitelist',
      method: 'POST',
      endpoint: (account) => '/api/$account/whitelist',
      data: {
        'address': address,
        if (expiresAt != null) 'expires_at': expiresAt,
      },
      serverAddress: serverAddress,
    );
  }

  /// Remove an address from the account-wide whitelist.
  static Future<FeedServerApiResponse<void>> removeAccountWhitelist({
    required String address,
    String? serverAddress,
  }) async {
    return _authedRequest(
      action: 'remove_account_whitelist',
      method: 'DELETE',
      endpoint: (account) => '/api/$account/whitelist/$address',
      data: const {},
      serverAddress: serverAddress,
    );
  }

  /// List account-wide whitelist entries.
  static Future<FeedServerApiResponse<List<WhitelistEntry>>> listAccountWhitelist(
      {String? serverAddress}) async {
    return _authedListRequest(
      action: 'list_account_whitelist',
      endpoint: (account) => '/api/$account/whitelist',
      serverAddress: serverAddress,
      parse: (body) {
        final list = body is List ? body : (body['whitelist'] as List? ?? []);
        return list
            .map((e) => WhitelistEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  /// Add an address as an account-wide approved poster.
  static Future<FeedServerApiResponse<void>> addAccountPoster({
    required String address,
    String? expiresAt,
    String? serverAddress,
  }) async {
    return _authedRequest(
      action: 'add_account_poster',
      method: 'POST',
      endpoint: (account) => '/api/$account/posters',
      data: {
        'address': address,
        if (expiresAt != null) 'expires_at': expiresAt,
      },
      serverAddress: serverAddress,
    );
  }

  /// Remove an address from the account-wide posters.
  static Future<FeedServerApiResponse<void>> removeAccountPoster({
    required String address,
    String? serverAddress,
  }) async {
    return _authedRequest(
      action: 'remove_account_poster',
      method: 'DELETE',
      endpoint: (account) => '/api/$account/posters/$address',
      data: const {},
      serverAddress: serverAddress,
    );
  }

  /// List account-wide approved posters.
  static Future<FeedServerApiResponse<List<PostPermissionEntry>>> listAccountPosters(
      {String? serverAddress}) async {
    return _authedListRequest(
      action: 'list_account_posters',
      endpoint: (account) => '/api/$account/posters',
      serverAddress: serverAddress,
      parse: (body) {
        return (body['posters'] as List? ?? [])
            .map((e) => PostPermissionEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  /// Add an address to the account-wide ban list.
  static Future<FeedServerApiResponse<void>> addAccountBan({
    required String address,
    String? reason,
    String? serverAddress,
  }) async {
    return _authedRequest(
      action: 'add_account_ban',
      method: 'POST',
      endpoint: (account) => '/api/$account/bans',
      data: {
        'address': address,
        if (reason != null) 'reason': reason,
      },
      serverAddress: serverAddress,
    );
  }

  /// Remove an address from the account-wide ban list.
  static Future<FeedServerApiResponse<void>> removeAccountBan({
    required String address,
    String? serverAddress,
  }) async {
    return _authedRequest(
      action: 'remove_account_ban',
      method: 'DELETE',
      endpoint: (account) => '/api/$account/bans/$address',
      data: const {},
      serverAddress: serverAddress,
    );
  }

  /// List account-wide banned addresses.
  static Future<FeedServerApiResponse<List<BanEntry>>> listAccountBans(
      {String? serverAddress}) async {
    return _authedListRequest(
      action: 'list_account_bans',
      endpoint: (account) => '/api/$account/bans',
      serverAddress: serverAddress,
      parse: (body) {
        return (body['bans'] as List? ?? [])
            .map((e) => BanEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  /// Generic authed request helper for void-returning operations.
  static Future<FeedServerApiResponse<void>> _authedRequest({
    required String action,
    required String method,
    required String Function(String account) endpoint,
    required Map<String, dynamic> data,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated ||
          PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error(
            {'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({
          'code': 'UNAUTHORIZED',
          'message': 'No blockchain private key available'
        });
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await signedRequest(
        method: method,
        endpoint: endpoint(accountAddress),
        action: action,
        data: data,
        serverAddress: serverAddress,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return FeedServerApiResponse.success(null);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(
            errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error(
          {'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Generic authed GET helper for list-returning operations.
  static Future<FeedServerApiResponse<T>> _authedListRequest<T>({
    required String action,
    required String Function(String account) endpoint,
    required T Function(dynamic body) parse,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated ||
          PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error(
            {'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({
          'code': 'UNAUTHORIZED',
          'message': 'No blockchain private key available'
        });
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await signedRequest(
        method: 'GET',
        endpoint: endpoint(accountAddress),
        action: action,
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FeedServerApiResponse.success(parse(data));
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(
            errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error(
          {'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }
}

/// A v2 envelope before its signature: what [PublicOSSsp.createApiRequest]
/// builds, signed inline or off the UI thread.
class _Envelope {
  final String messageJson;
  final int timestamp;
  final String action;
  final Map<String, dynamic> data;
  final String session;
  final String nonce;
  final String target;
  const _Envelope({
    required this.messageJson,
    required this.timestamp,
    required this.action,
    required this.data,
    required this.session,
    required this.nonce,
    required this.target,
  });

  FeedServerApiRequest signed(String signature) => FeedServerApiRequest(
        timestamp: timestamp,
        action: action,
        data: data,
        session: session,
        nonce: nonce,
        target: target,
        signature: signature,
      );
}
