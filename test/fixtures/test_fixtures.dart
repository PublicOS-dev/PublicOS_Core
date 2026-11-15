// Test fixtures for PublicOS Core 1.0 scenario tests.
//
// Provides:
//   - In-memory SecureStorage mock (intercepts FlutterSecureStorage channel)
//   - LocalAuthentication mock (returns true)
//   - PathProvider mock (in-memory tmp dir)
//   - jmsl account loader (reads the local deploy's key file)
//   - Friend generator (creates fresh keys, stores in mock secureStorage)
//   - Test database (in-memory drift)
//
// Usage in test files:
//   setUpAll(() async => await TestFixtures.bootstrap());
//   tearDownAll(() async => await TestFixtures.teardown());
//
//   final jmsl = await TestFixtures.loadJmslFromManager();
//   await PublicOS.init();
//   ...

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:crypto/crypto.dart' show sha256;
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http show Client, post;
import 'package:local_auth/local_auth.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:web3dart/web3dart.dart' show EthPrivateKey, Web3Client, keccakUtf8;

/// jmsl's session key: the same file the local deploy (`deploy.ts`) signs with, so the
/// fixture and the chain it tests always agree.
/// It is only ever used against the local hardhat node ([fallbackLocalRpc]).
/// The path comes from the environment variable `PUBLICOS_TEST_KEY_FILE`.
final _jmslKeyPath = Platform.environment['PUBLICOS_TEST_KEY_FILE'] ?? '';

class TestFixtures {
  // In-memory store backing the SecureStorage mock
  static final Map<String, String> _secureStore = <String, String>{};

  // Cached jmsl secrets (loaded from manager)
  static String? _jmslSessionPrivateKeyHex;
  static EthereumAddress? _jmslSessionAddress;
  static EthereumAddress? _jmslAccountAddress;
  static String? _localRpcUrl;

  // Test database instance (kept here so teardown can close it)
  static AppDatabase? _testDb;

  /// Initialize bindings + install all plugin mocks. Call once per test file
  /// in `setUpAll()`.
  static Future<void> bootstrap() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // TestWidgetsFlutterBinding installs an HttpOverrides that returns 400
    // for every request. Override it back to null so real HTTP works (we
    // need to talk to the local PublicOS node + feed server in tests).
    HttpOverrides.global = null;
    _installSecureStorageMock();
    _installLocalAuthMock();
    _installPathProviderMock();
    _installSharedPreferencesMock();
    _installNotificationsMock();
    _installWorkmanagerMock();
  }

  /// Reset state between tests.
  static Future<void> teardown() async {
    _secureStore.clear();
    // Drop cached manager secrets so the next file re-loads them
    _jmslSessionPrivateKeyHex = null;
    _jmslSessionAddress = null;
    _jmslAccountAddress = null;
    _localRpcUrl = null;
    if (_testDb != null) {
      await _testDb!.close();
      _testDb = null;
    }
    // Reset core static state
    PublicOS.isInitialized = false;
    PublicOS.isAuthenticated = false;
    PublicOS.myPublicosAddress = null;
    PublicOS.sessionBlockchainAddress = null;
    PublicOS.currentBlockchainPrivateKey = null;
    PublicOS.currentBlockchainDbKey = null;
    PublicOS.web3Connected = false;
    PublicOS.sspConnected = false;
    PublicOS.xmtpConnected = false;
    PublicOS.activeRpcUrl = PublicOS.PUBLIC_RPC_URL;
    PublicOS.activeRpcSource = 'public';
    PublicOS.rpcOverrideUrl = null;
    PublicOS.chainClockSkew = Duration.zero;
    PublicOS.activeSspUrl = PublicOS.DEFAULT_SSP_URL;
    PublicOS.activeSspSource = 'default';
    PublicOS.sspOverrideUrl = null;
    PublicOS.lastError = null;
  }

  /// Load jmsl's session key from [_jmslKeyPath] (the local deploy's key file).
  /// Stores the key in the mock secureStorage under the canonical
  /// `account_${address}_*` keys so [PublicOSAccounts.restoreSession] can find them.
  ///
  /// Looks up the on-chain account address via `getAccountAddressForSession`
  /// — this requires the BSP/RPC to already be initialized. Call after
  /// `PublicOS.init()`.
  ///
  /// Returns the on-chain PublicOS account address for jmsl.
  static Future<EthereumAddress> loadJmslFromManager() async {
    if (_jmslAccountAddress != null) return _jmslAccountAddress!;

    final file = File(_jmslKeyPath);
    if (!await file.exists()) {
      throw StateError('jmsl key file not found at $_jmslKeyPath (the local deploy reads the same file).');
    }

    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final pkHex = json['privateKey'] as String?;
    if (pkHex == null) {
      throw StateError('No privateKey in $_jmslKeyPath');
    }
    _localRpcUrl = null; // always the local hardhat node (fallbackLocalRpc)

    final sessionKey = EthPrivateKey.fromHex(pkHex);
    _jmslSessionPrivateKeyHex = pkHex;
    _jmslSessionAddress = sessionKey.address;

    // Look up the on-chain account address for this session.
    // This requires web3 to be live — we use the local RPC override directly.
    final accountAddress =
        await PublicOSAccounts.getAccountAddressForSession(sessionKey.address);
    if (accountAddress == null) {
      throw StateError(
        'jmsl session not linked to an account on-chain. '
        'Is the local node at ${PublicOS.rpcOverrideUrl ?? fallbackLocalRpc} reachable, with the contracts deployed and the registry resolved?',
      );
    }

    _jmslAccountAddress = accountAddress;

    // Generate a synthetic DB key for tests (not the real one).
    final dbKey = Uint8List.fromList(List<int>.filled(32, 0x42));

    // Store under the canonical key pattern that restoreSession reads.
    final addrHex = accountAddress.eip55With0x;
    _secureStore['account_${addrHex}_private_key'] = base64Encode(utf8.encode(pkHex));
    _secureStore['account_${addrHex}_encryption_key'] = base64Encode(dbKey);
    _secureStore['account_${addrHex}_sessionAddress'] = sessionKey.address.eip55With0x;
    _secureStore['account_${addrHex}_displayName'] = 'jmsl';
    _secureStore['selected_publicos_AccountAddress'] = addrHex;

    return accountAddress;
  }

  /// jmsl's session EOA address (the EOA whose key is in the manager secrets).
  /// Available after [loadJmslFromManager] returns.
  static EthereumAddress? get jmslSessionAddress => _jmslSessionAddress;

  /// jmsl's PublicOS on-chain account address.
  /// Available after [loadJmslFromManager] returns.
  static EthereumAddress? get jmslAccountAddress => _jmslAccountAddress;

  /// Local RPC URL from the manager secrets file (e.g. `http://127.0.0.1:8545`).
  static String? get localRpcUrl => _localRpcUrl;

  /// Generate a fresh test friend with a random EOA + DB key. Stores under
  /// the canonical secureStorage pattern. Returns the session EOA address.
  /// (This friend is NOT yet activated on-chain — that happens via
  /// `createAccount` in S4.)
  /// The private key of the last [generateFriend] call — the scenario tests
  /// sign the friend's CreateAccountConsent with it (createAccountWithLocalKey).
  static EthPrivateKey? lastFriendKey;

  static Future<EthereumAddress> generateFriend({String label = 'friend'}) async {
    final random = math.Random.secure();
    final pk = EthPrivateKey.createRandom(random);
    lastFriendKey = pk;
    final pkHex = pk.privateKeyInt.toRadixString(16).padLeft(64, '0');
    final dbKey =
        Uint8List.fromList(List.generate(32, (_) => random.nextInt(256)));

    // Store under temp account keys (will be transferred on activation)
    _secureStore['account_temporaryAccount_private_key'] =
        base64Encode(utf8.encode('0x$pkHex'));
    _secureStore['account_temporaryAccount_encryption_key'] = base64Encode(dbKey);
    _secureStore['temporaryAccountSessionAddress'] = pk.address.eip55With0x;

    return pk.address;
  }

  /// Replace `PublicOS.init()` for tests: install in-memory DB, initialize
  /// the `late` service fields (secureStorage, localAuth, httpClient), and
  /// set `isInitialized = true`. Call after [bootstrap].
  static Future<void> initCoreForTesting() async {
    PublicOS.secureStorage = const FlutterSecureStorage();
    PublicOS.localAuth = LocalAuthentication();
    PublicOS.httpClient = http.Client();
    _testDb = AppDatabase(NativeDatabase.memory());
    PublicOS.database = _testDb!;
    // Initialize web3Client to a stub. Tests will swap it via setRpcOverride.
    PublicOS.web3Client = Web3Client(PublicOS.PUBLIC_RPC_URL, PublicOS.httpClient);
    PublicOS.isInitialized = true;
  }

  /// Install only the test database (sub-step if you need finer control).
  static Future<AppDatabase> installTestDatabase() async {
    _testDb = AppDatabase(NativeDatabase.memory());
    PublicOS.database = _testDb!;
    return _testDb!;
  }

  /// Default local node URL used by tests when the manager secrets file is
  /// missing or doesn't define one. The local PublicOS chain.
  static const fallbackLocalRpc = 'http://127.0.0.1:8545'; // a hardhat node (never a shared node, never 4489's public RPC)

  /// One-shot setup that walks the full init flow with jmsl loaded:
  ///   bootstrap → initCoreForTesting → debugAuth → setRpcOverride →
  ///   loadJmslFromManager → initBSP → initSSP.
  ///
  /// Returns the on-chain jmsl account address. Skips the test (via
  /// `markTestSkipped`) and returns null if the local node is unreachable.
  ///
  /// Does NOT call initXMTP — pass `withXmtp: true` to also start that.
  static Future<EthereumAddress?> setupWithJmsl({bool withXmtp = false}) async {
    await initCoreForTesting();

    PublicOS.debugNoAuthNeeded = true;
    final authed = await PublicOSAuth.authenticate();
    if (!authed) {
      throw StateError('Auth failed even with debugNoAuthNeeded=true');
    }

    PublicOS.setRpcOverride(fallbackLocalRpc, 'local');
    final reachable = await PublicOS.testRpcUrl(fallbackLocalRpc);
    if (!reachable) {
      markTestSkipped('Local PublicOS node at $fallbackLocalRpc unreachable');
      return null;
    }
    PublicOS.setWeb3Connected(true);

    // The local chain's clock may already be ahead of the wall clock (earlier
    // scenarios step over cooldowns with evm_increaseTime); measure the skew so
    // consent deadlines signed here are still in the chain's future.
    final head = await PublicOS.web3Client.getBlockInformation(blockNumber: 'latest');
    final skew = head.timestamp.difference(DateTime.now());
    PublicOS.chainClockSkew = skew.isNegative ? Duration.zero : skew;

    // A fresh local deploy keeps the ModuleRegistry anchor (deterministic from
    // the deployer key + nonce) but every downstream module lands on a NEW
    // address, so resolve them from the registry BEFORE the first chain read;
    // the hardcoded fallbacks in PublicOSBsp are the LIVE chain's.
    await PublicOSBsp.resolveModuleAddresses();

    final jmslAccount = await loadJmslFromManager();

    // Stage 1 — restore session. Must run before initBSP so the BSP
    // stage sees an active session and can resolve subscriptions.
    final restored = await PublicOSAccounts.restoreSession(jmslAccount);
    if (!restored) {
      throw StateError('restoreSession failed for jmsl');
    }

    // Stage 2 — BSP (modules + RPC + polling).
    final bspOk = await PublicOS.initBSP();
    if (!bspOk) {
      throw StateError('initBSP failed for jmsl');
    }

    await PublicOS.initSSP();

    if (withXmtp) {
      await PublicOS.initXMTP();
    }

    return jmslAccount;
  }


  // ──────────────────────────────────────────────────────────────────────────
  // LOCAL-WORLD HELPERS (the scenario
  // suite runs against a FRESH hardhat deploy, so it seeds what it needs
  // instead of assuming the live chain's state: vouches, records, channels,
  // the org-creation cooldown).
  // ──────────────────────────────────────────────────────────────────────────

  /// Hardhat only: move the chain clock forward and mine a block
  /// (`evm_increaseTime` + `evm_mine`). Used to step over on-chain cooldowns
  /// (org creation) and vote periods without waiting in real time.
  static Future<void> advanceChainTime(Duration by) async {
    final url = Uri.parse(PublicOS.rpcOverrideUrl ?? fallbackLocalRpc);
    Future<void> rpc(String method, List<dynamic> params) async {
      final res = await http.post(url,
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': method, 'params': params}));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['error'] != null) {
        throw StateError('$method failed: ${body['error']}');
      }
    }
    await rpc('evm_increaseTime', [by.inSeconds]);
    await rpc('evm_mine', []);
    // Keep Core's wall-clock consent deadlines ahead of the moved chain clock.
    PublicOS.chainClockSkew += by;
  }

  /// Ensure the active account has at least one profile record on chain
  /// (writes `profile.bio` through RecordManager when the profile is empty).
  /// Returns the records after the write.
  static Future<List<Record>> ensureProfileRecord(EthereumAddress account,
      {String key = 'profile.bio', String value = 'local scenario bio'}) async {
    final existing = await PublicOSContacts.getAllUserRecordsOrThrow(account);
    if (existing.isNotEmpty) return existing;
    final ok = await PublicOSContacts.setRecord(Record.asProfile(
      key: key,
      value: value,
      expiration: DateTime.now().add(const Duration(days: 3650)),
    ));
    if (!ok) throw StateError('ensureProfileRecord: setRecord failed: ${PublicOS.lastError}');
    return PublicOSContacts.getAllUserRecordsOrThrow(account);
  }

  /// Ensure the active account publishes at least one CHANNEL (a router record
  /// of subtype channel pointing at a feed URL). The URL is never fetched by
  /// the follow / mute scenarios — only its record key and owner matter.
  static Future<void> ensureChannelRecord(EthereumAddress account,
      {String key = 'router.news', String name = 'news'}) async {
    final current = await PublicOSFollows.resolveProfileChannels(account);
    if (current.isNotEmpty) return;
    final ok = await PublicOSContacts.setRecord(Record.asRouter(
      key: key,
      value: 'https://feeds.local/api/${account.eip55With0x}/channels/$name/json',
      routerSubtype: RouterSubtype.channel,
      name: name,
      expiration: DateTime.now().add(const Duration(days: 3650)),
    ));
    if (!ok) throw StateError('ensureChannelRecord: setRecord failed: ${PublicOS.lastError}');
    // The resolver refreshes a stale contact; force the refresh so the new
    // record is visible to the caller right away.
    final fresh = await PublicOSContacts.fetchContact(account, requireRecords: true);
    await PublicOSContacts.saveContact(fresh);
  }

  /// Step over the org-creation cooldown of [account] on the local chain.
  static Future<void> skipOrgCreationCooldown(EthereumAddress account) async {
    final cd = await PublicOSAccounts.getOrgCreationCooldown(account);
    final next = cd.nextAllowedAt;
    if (next != null && next.isAfter(cd.chainNow)) {
      await advanceChainTime(next.difference(cd.chainNow) + const Duration(minutes: 1));
    }
  }


  // ──────────────────────────────────────────────────────────────────────────
  // ACTORS — the civic-flow scenarios (s16+) need many keys that are the SAME
  // across test files (each file is a fresh process with an empty mock
  // keystore, but the chain state carries over). A label derives a key.
  // ──────────────────────────────────────────────────────────────────────────

  /// Deterministic scenario key: sha256('publicos-scenario:' + label).
  /// Local devnet only — never use on a real chain.
  static EthPrivateKey actorKey(String label) {
    final digest = sha256.convert(utf8.encode('publicos-scenario:$label')).bytes;
    return EthPrivateKey(Uint8List.fromList(digest));
  }

  /// Install [key] for [account] in the mock keystore under the canonical
  /// `account_<addr>_*` entries so [PublicOSAccounts.restoreSession] finds it.
  static void installAccountKey(EthereumAddress account, EthPrivateKey key,
      {String displayName = ''}) {
    final addrHex = account.eip55With0x;
    final pkHex = '0x${key.privateKeyInt.toRadixString(16).padLeft(64, '0')}';
    _secureStore['account_${addrHex}_private_key'] = base64Encode(utf8.encode(pkHex));
    _secureStore['account_${addrHex}_encryption_key'] =
        base64Encode(Uint8List.fromList(List.generate(32, (i) => i)));
    _secureStore['account_${addrHex}_sessionAddress'] = key.address.eip55With0x;
    _secureStore['account_${addrHex}_displayName'] = displayName;
  }

  /// Switch the live session to [account] signing with [key] (restoreSession +
  /// initBSP, exactly what the apps do on a session swap). Returns the account.
  static Future<EthereumAddress> actAs(EthereumAddress account, EthPrivateKey key,
      {String displayName = ''}) async {
    installAccountKey(account, key, displayName: displayName);
    // The node quotes a gas price even on this zero-gas chain, and web3dart
    // prices the tx from the quote: a fresh key needs a balance here (never on
    // 4489, where the price is 0).
    await fund(key.address, ether: 10);
    final ok = await PublicOSAccounts.restoreSession(account);
    if (!ok) throw StateError('actAs: restoreSession failed for ${account.eip55With0x}');
    final bsp = await PublicOS.initBSP();
    if (!bsp) throw StateError('actAs: initBSP failed for ${account.eip55With0x}');
    return account;
  }

  /// Back to jmsl (after [setupWithJmsl] ran once in this process).
  static Future<EthereumAddress> actAsJmsl() async {
    final key = EthPrivateKey.fromHex(_jmslSessionPrivateKeyHex!);
    return actAs(_jmslAccountAddress!, key, displayName: 'jmsl');
  }

  /// The account behind the actor [label]: resolved from chain when it already
  /// exists (an earlier file created it), else created now — sponsored by the
  /// CURRENT session (jmsl, the genesis citizen: root/admin bypass of the
  /// invite gate). The new account's first session is the actor key, so the
  /// creator stays who it was. Returns the account address.
  static Future<EthereumAddress> ensureAccount(String label) async {
    final key = actorKey(label);
    final existing = await PublicOSAccounts.getAccountAddressForSession(key.address);
    if (existing != null) return existing;
    final ok = await PublicOSAccounts.createAccountWithLocalKey(
      displayName: 'sc_${label.replaceAll(RegExp(r'[^a-z0-9]'), '')}',
      newSessionKey: key,
    );
    if (!ok) throw StateError('ensureAccount($label): ${PublicOS.lastError}');
    final created = await PublicOSAccounts.getAccountAddressForSession(key.address);
    if (created == null) throw StateError('ensureAccount($label): not resolvable after create');
    await fund(key.address, ether: 10); // devnet gas, see actAs
    return created;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DEVNET PRIMITIVES (hardhat JSON-RPC)
  // ──────────────────────────────────────────────────────────────────────────

  static Future<dynamic> _rpc(String method, List<dynamic> params) async {
    final url = Uri.parse(PublicOS.rpcOverrideUrl ?? fallbackLocalRpc);
    final res = await http.post(url,
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': method, 'params': params}));
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['error'] != null) throw StateError('$method failed: ${body['error']}');
    return body['result'];
  }

  /// Give [address] a native balance (`hardhat_setBalance`).
  static Future<void> fund(EthereumAddress address, {double ether = 100}) async {
    final wei = BigInt.from(ether * 1e6) * BigInt.from(10).pow(12);
    await _rpc('hardhat_setBalance', [address.eip55With0x, '0x${wei.toRadixString(16)}']);
  }

  /// The root org's MainSafe — what `onlyRoot` resolves to after the alpha
  /// deploy's hand-off (PUBLICOS_ROOT_ORG → the org account → its Safe).
  static Future<EthereumAddress> rootOrgSafe() async {
    final registry = ModuleRegistry(
        address: PublicOSBsp.moduleRegistryAddress,
        client: PublicOS.web3Client,
        chainId: PublicOS.CHAIN_ID);
    final org = await registry.getModuleAddress((moduleType: keccakUtf8('PUBLICOS_ROOT_ORG')));
    final safe = await PublicOSSafe.getMainSafeAddress(org);
    if (safe == null) throw StateError('rootOrgSafe: no MainSafe for ${org.eip55With0x}');
    return EthereumAddress.fromHex(safe);
  }

  /// Send a call AS root (the root org Safe), the devnet way: impersonate the
  /// Safe and let the node sign (`hardhat_impersonateAccount` +
  /// `eth_sendTransaction`). Production does this through a root-org vote or
  /// the GuardianModule; this exists so a scenario can set the world up.
  static Future<String> rootCall(EthereumAddress to, Uint8List data) async {
    final safe = await rootOrgSafe();
    await _rpc('hardhat_impersonateAccount', [safe.eip55With0x]);
    await fund(safe, ether: 1);
    final hash = await _rpc('eth_sendTransaction', [
      {
        'from': safe.eip55With0x,
        'to': to.eip55With0x,
        'data': '0x${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}',
        'gas': '0x2dc6c0',
      }
    ]) as String;
    await _rpc('hardhat_stopImpersonatingAccount', [safe.eip55With0x]);
    return hash;
  }


  /// Publish a NEW version of [kind] as root (text is free-form). Returns the
  /// version now current.
  static Future<BigInt> publishAgreement(int kind, String text) async {
    final am = PublicOSBsp.agreementManagerContract;
    final publish = am.self.function('publish');
    // Hardhat's clock is wall time + the accumulated offset, not the last
    // block's timestamp (which may be minutes old): mine first, then read.
    await _rpc('evm_mine', []);
    final now = (await PublicOS.web3Client.getBlockInformation(blockNumber: 'latest')).timestamp;
    // The next block's timestamp is max(latest + 1, wall clock + the devnet
    // offset), so a validFrom one second ahead can already be 'in the past':
    // publish an hour ahead and step the clock past it. A kind's first version
    // may bind at once; every later one needs 7 days of notice
    // (AgreementManager.MIN_ANNOUNCE_AHEAD), so add those.
    final first = await am.currentVersion((kind: BigInt.from(kind))) == BigInt.zero;
    final ahead = first ? const Duration(hours: 1) : const Duration(days: 7, hours: 1);
    final validFrom = BigInt.from(now.millisecondsSinceEpoch ~/ 1000 + ahead.inSeconds);
    await rootCall(PublicOSBsp.agreementManagerAddress!,
        publish.encodeCall([BigInt.from(kind), text, validFrom]));
    await advanceChainTime(ahead + const Duration(seconds: 1));
    return am.currentVersion((kind: BigInt.from(kind)));
  }

  /// Publish v1 of the three agreement texts (protocol 1, operator 2,
  /// citizen 3) as root when none is published yet. Returns the current
  /// versions by kind afterwards.
  static Future<Map<int, BigInt>> ensureAgreementsPublished() async {
    final am = PublicOSBsp.agreementManagerContract;
    final out = <int, BigInt>{};
    for (final kind in [1, 2, 3]) {
      var v = await am.currentVersion((kind: BigInt.from(kind)));
      if (v == BigInt.zero) {
        // Each kind gets its OWN validFrom, read after the previous publish moved
        // the clock an hour on. One validFrom shared by the loop was already in
        // the past for kinds 2 and 3 — invisible on a reused chain (nothing left
        // to publish), fatal on a fresh one.
        v = await publishAgreement(kind, 'scenario agreement v1 (kind $kind)');
      }
      out[kind] = v;
    }
    return out;
  }

  // ──────────────────────────────────────────────────────────────────────
  // PLUGIN MOCKS
  // ──────────────────────────────────────────────────────────────────────

  static void _installSecureStorageMock() {
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestWidgetsFlutterBinding.ensureInitialized()
        .defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'read':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          return _secureStore[args['key'] as String];
        case 'write':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          _secureStore[args['key'] as String] = args['value'] as String;
          return null;
        case 'delete':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          _secureStore.remove(args['key'] as String);
          return null;
        case 'deleteAll':
          _secureStore.clear();
          return null;
        case 'readAll':
          return Map<String, String>.from(_secureStore);
        case 'containsKey':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          return _secureStore.containsKey(args['key'] as String);
      }
      return null;
    });
  }

  static void _installLocalAuthMock() {
    const channel = MethodChannel('plugins.flutter.io/local_auth');
    TestWidgetsFlutterBinding.ensureInitialized()
        .defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'isDeviceSupported':
          return true;
        case 'deviceSupportsBiometrics':
          return true;
        case 'getEnrolledBiometrics':
          return <String>['fingerprint'];
        case 'authenticate':
          return true;
      }
      return null;
    });
  }

  static void _installPathProviderMock() {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestWidgetsFlutterBinding.ensureInitialized()
        .defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      // Return a temp directory; tests don't actually write to it because
      // we use NativeDatabase.memory() instead.
      final tmp = Directory.systemTemp.path;
      return tmp;
    });
  }

  static void _installSharedPreferencesMock() {
    const channel = MethodChannel('plugins.flutter.io/shared_preferences');
    final store = <String, Object>{};
    TestWidgetsFlutterBinding.ensureInitialized()
        .defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'getAll':
          return Map<String, Object>.from(store);
        case 'setBool':
        case 'setInt':
        case 'setDouble':
        case 'setString':
        case 'setStringList':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          store[args['key'] as String] = args['value'] as Object;
          return true;
        case 'remove':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          store.remove(args['key'] as String);
          return true;
        case 'clear':
          store.clear();
          return true;
      }
      return null;
    });
  }

  static void _installNotificationsMock() {
    const channel =
        MethodChannel('dexterous.com/flutter/local_notifications');
    TestWidgetsFlutterBinding.ensureInitialized()
        .defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      // No-op all notification calls in tests.
      return null;
    });
  }

  static void _installWorkmanagerMock() {
    const channel = MethodChannel('be.tramckrijte.workmanager/foreground_channel_work_manager');
    TestWidgetsFlutterBinding.ensureInitialized()
        .defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      return null;
    });
  }

}
