import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide Message;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:publicos_core/src/models/message.dart';
import 'package:publicos_core/src/models/contact.dart';
import 'package:publicos_core/src/core/extensions/publicos_accounts.dart';
import 'package:publicos_core/src/core/extensions/publicos_channels.dart';
import 'package:publicos_core/src/core/extensions/publicos_conversations.dart';
import 'package:publicos_core/src/core/extensions/publicos_keychain.dart';
import 'package:publicos_core/src/core/extensions/publicos_database.dart';
import 'package:publicos_core/src/core/extensions/publicos_ssp.dart';
import 'package:publicos_core/src/core/extensions/publicos_treasury.dart';
import 'package:publicos_core/src/core/extensions/publicos_bsp.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:publicos_core/src/utils/log.dart';
import 'package:publicos_core/src/database/database.dart' show AppDatabase;
import 'package:drift/native.dart' show NativeDatabase;
import 'package:web3dart/web3dart.dart';
import 'package:xmtp_plugin/codecs.dart';
import 'package:xmtp_plugin/xmtp_plugin.dart';
import 'package:http/http.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert'; // For utf8, base64Encode, base64Decode

/// What a background isolate needs to decrypt a push or run the message
/// sweep: built once per isolate by [PublicOS.ensureBackgroundIsolateReady].
typedef BgIsolateHandles = ({
  XmtpPlugin xmtpClient,
  AppDatabase database,
  String sessionAddress,
  String myInboxId,
});

/// Core class containing all state and service instances for the PublicOS system.
/// All properties are static to provide global access and centralized state management.
class PublicOS {
  // Private constructor to prevent instantiation
  PublicOS._();

  ///*********************************************
  /// STATIC CONSTANTS
  ///*********************************************

  // Protocol-agnostic Keychain Storage Prefixes
  static const String keychainKeyPrefix = 'keychain_key_'; // The private key itself
  static const String keychainMetadataPrefix = 'keychain_metadata_'; // Key metadata (label, address, etc.)
  static const String keychainIndexPrefix = 'keychain_index_'; // List of key labels per user

  // Protocol-specific Storage Key Prefixes
  static const String xmtpDbKeyPrefix = 'xmtp_db_key_'; // XMTP-specific encrypted DB key per keychain key
  static const String xmtpSelectedKeyPrefix = 'xmtp_selected_key_'; // Currently selected keychain key for XMTP
  static const String xmtpLastKeyPrefix = 'xmtp_last_key_'; // Last used keychain key for XMTP

  /// Public RPC node — always available, rate-limited fallback
  static const String PUBLIC_RPC_URL = 'https://rpc.publicos.dev';

  /// Default SSP (feed server) endpoint — always available, the platform default.
  static const String DEFAULT_SSP_URL = 'https://feeds.publicos.dev';

  /// Currently active RPC URL (starts as public, upgraded post-auth)
  static String activeRpcUrl = PUBLIC_RPC_URL;

  /// Source of the currently active RPC ('public', 'bsp', 'custom', 'local')
  static String activeRpcSource = 'public';

  /// Whether the active RPC was reachable at last check.
  /// Emitted on [web3Status] when it changes.
  static bool web3Connected = false;

  /// When set, initBSP() skips all RPC resolution and uses this URL.
  /// Used by consumers (e.g. manager) that need all accounts on a specific endpoint.
  static String? rpcOverrideUrl;
  static String? _rpcOverrideSource;

  /// Currently active SSP (feed server) URL.
  static String activeSspUrl = DEFAULT_SSP_URL;

  /// Source of the active SSP ('default', 'ssp', 'custom', 'override').
  /// ('ssp' replaces the prior 'subscription' tag — symmetric with 'bsp'
  /// on the RPC side.)
  static String activeSspSource = 'default';

  /// Whether the active SSP was reachable at last check.
  /// Emitted on [sspStatus] when it changes.
  static bool sspConnected = false;

  /// When set, initSSP() skips all resolution and uses this URL.
  static String? sspOverrideUrl;
  static String? _sspOverrideSource;

  /// Whether an XMTP key is loaded and the message stream is active.
  /// Emitted on [xmtpStatus] when it changes.
  static bool xmtpConnected = false;

  /// Broadcast status streams. UI layers (e.g. desktop status bar) listen
  /// to these for live subsystem indicators.
  static final web3Status = StreamController<bool>.broadcast();
  static final sspStatus = StreamController<bool>.broadcast();
  static final xmtpStatus = StreamController<bool>.broadcast();

  /// Emit a new status value and update the backing flag.
  static void _setWeb3Connected(bool value) {
    if (web3Connected == value) return;
    web3Connected = value;
    web3Status.add(value);
  }

  static void _setSspConnected(bool value) {
    if (sspConnected == value) return;
    sspConnected = value;
    sspStatus.add(value);
  }

  static void _setXmtpConnected(bool value) {
    if (xmtpConnected == value) return;
    xmtpConnected = value;
    xmtpStatus.add(value);
  }

  /// Internal helpers for extensions to update status without exposing the
  /// controllers directly (avoids accidental external .add calls).
  static void setWeb3Connected(bool value) => _setWeb3Connected(value);
  static void setSspConnected(bool value) => _setSspConnected(value);
  static void setXmtpConnected(bool value) => _setXmtpConnected(value);

  /// Lock all RPC resolution to a specific URL. initBSP() will use this
  /// unconditionally until clearRpcOverride() is called.
  static void setRpcOverride(String url, String source) {
    rpcOverrideUrl = url;
    _rpcOverrideSource = source;
    switchWeb3Client(url, source);
    Log.i('Core', 'RPC override set: $url ($source)');
  }

  /// Remove the RPC override. Next initBSP() will resolve normally.
  static void clearRpcOverride() {
    rpcOverrideUrl = null;
    _rpcOverrideSource = null;
    Log.i('Core', 'RPC override cleared');
  }

  /// Lock SSP resolution to a specific URL. initSSP() will use this
  /// unconditionally until clearSspOverride() is called.
  static void setSspOverride(String url, String source) {
    sspOverrideUrl = url;
    _sspOverrideSource = source;
    activeSspUrl = url;
    activeSspSource = source;
    Log.i('Core', 'SSP override set: $url ($source)');
  }

  /// Remove the SSP override. Next initSSP() will resolve normally.
  static void clearSspOverride() {
    sspOverrideUrl = null;
    _sspOverrideSource = null;
    Log.i('Core', 'SSP override cleared');
  }

  /// Chain configuration
  static const int CHAIN_ID = 4489;

  /// Local devnet only. Consent deadlines (`CreateAccountConsent`,
  /// `SessionConsent`) are wall-clock based; a hardhat node whose clock was
  /// moved forward (`evm_increaseTime`) would reject them as expired. The test
  /// fixture adds what it advanced here; production never sets it.
  static Duration chainClockSkew = Duration.zero;

  ///*********************************************
  /// SERVICE INSTANCES
  ///*********************************************

  /// Core services
  static late FlutterSecureStorage secureStorage;
  static late LocalAuthentication localAuth;
  static late AppDatabase database;
  static late Web3Client web3Client;
  /// Nullable — only created when `initXMTP()` is called. RSS-only or
  /// chain-only apps never pay the cost of creating it.
  static XmtpPlugin? xmtpClient;
  static late Client httpClient;

  /// Notifications
  static FlutterLocalNotificationsPlugin? notificationsPlugin;
  static bool notificationsInitialized = false;

  ///*********************************************
  /// STATE MANAGEMENT
  ///*********************************************

  /// Authentication and initialization state
  static bool isAuthenticated = false;
  static bool isInitialized = false;
  static bool debugNoAuthNeeded = false;

  /// Whether the app is currently in the foreground (set by client lifecycle)
  static bool _isForeground = false;
  static bool get isForeground => _isForeground;
  static Future<void> setForeground(bool value) async {
    _isForeground = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_in_foreground', value);
  }

  /// Pending deep link for cold start navigation (handled by Explorer)
  static Map<String, dynamic>? pendingDeepLink;

  /// Account state.
  ///
  /// After 1.0, the full Contact object is NOT cached in memory. Only the
  /// session pointers ([myPublicosAddress] and [sessionBlockchainAddress])
  /// are cached. Any code that needs display name, records, avatar, etc.
  /// reads from the database via
  /// `PublicOSContacts.getContact(EthereumAddress.fromHex(myPublicosAddress!))`.
  ///
  /// Write-through pattern: on-chain writes (setRecord, etc.) call the
  /// contract, then re-fetch the contact from chain and save to DB. UI code
  /// re-reads via `getContact()` to see the update on its next read.

  /// Current user's on-chain PublicOS account address (EIP55 hex string).
  /// Set during [initBSP] after the session→account link is verified.
  /// This is the minimum identifier cache — everything else lives in the DB.
  static String? myPublicosAddress;

  static String? sessionBlockchainAddress; // User's primary on-chain session address
  static EthPrivateKey? currentBlockchainPrivateKey; // User's primary on-chain private key
  static Uint8List? currentBlockchainDbKey; // DB key associated with the primary on-chain identity

  // XMTP specific keys for the ACTIVE XMTP client
  static EthPrivateKey? currentXMTPPrivateKey; // Dedicated private key for the active XMTP client instance
  static String? clientXmtpAddress; // Address of the active XMTP client
  static String? clientXmtpInboxId; // Inbox ID of the active XMTP client (on-chain pointer)

  static Uint8List? currentXmtpDbKey; // DB key for the active XMTP client's local encrypted store
  static String? currentXmtpKeyLabel; // Label for the currently active XMTP key

  /// The PREFERRED web key's label -- `null` or `'session'` means the session key.
  ///
  /// **Preferred, not authoritative.**
  /// It grants a website nothing. Permission to see and sign with a key is a
  /// per-site SET, held in `ConnectedSites`; this pointer decides only which of
  /// the keys a site was already granted comes first in `eth_accounts` -- i.e.
  /// which one a dApp treats as the identity.
  ///
  /// Making it both, crossed with a per-(site, key) grant table, produces
  /// states no user can reason about: a grant that exists but
  /// "does not apply" because it was made with a key that is not the selected
  /// one. Do not read this as "the key that signs".
  static String? webSelectedKey;

  /// Message streams and state
  static StreamSubscription? xmtpSubscription;
  static final messageStreamController = StreamController<Message>.broadcast();
  static Stream<Message> get messageStream => messageStreamController.stream;

  /// Broadcast of the signed-in user's [Contact], emitted by
  /// `PublicOSContacts.fetchContact` whenever it refreshes our own profile
  /// (avatar / membership / records change). App-level "self changed" signal,
  /// alongside [myPublicosAddress]. Live self-surfaces (explorer icon, wallet
  /// self-card, browser self-header) subscribe once via the client's
  /// AppStateNotifier and repaint. This is a **domain-event** stream — it
  /// carries the Contact and is consumed directly (like [messageStream]), not a
  /// "please reload" ping.
  static final _selfContactUpdates = StreamController<Contact>.broadcast();
  static Stream<Contact> get selfContactUpdates => _selfContactUpdates.stream;
  static void emitSelfContactUpdate(Contact contact) =>
      _selfContactUpdates.add(contact);

  static bool isSending = false;
  static List<Map<String, dynamic>> messageCache = [];

  /// Error state
  static String? lastError;

  /// Notification tap handler — set by the client app to handle navigation
  /// Callback receives (type, identifier) e.g. ('message', 'conversationTopic')
  /// and, when the popup was built by [notificationPayload] with an account
  /// signed in, the account it was for: the
  /// client drops a tap meant for another account.
  static void Function(String type, String identifier, {String? account})?
      onNotificationTapped;

  /// Fired every time the XMTP client successfully initializes (boot, key
  /// switch, key import). Used by publicos_client to publish the active
  /// XMTP identity to the iOS App Group so the Notification Service Extension
  /// can wake and decrypt. No-op for non-iOS platforms.
  static void Function()? onXmtpClientReady;

  /// Fired when the XMTP client state is cleared (logout, account swap).
  static void Function()? onXmtpClientCleared;

  /// Optional override for the XMTP installation DB directory (iOS only,
  /// passed to `XmtpPlugin.initializeClient`). When set, every XMTP client
  /// opened by this process — main client, temp clients in keychain flows —
  /// places its SQLCipher DB under this path. publicos_client sets this to
  /// the iOS App Group container so a Notification Service Extension can
  /// open the same DB to decrypt push payloads.
  ///
  /// Set this BEFORE the first XMTP client init (boot path: right after
  /// PublicOS.initialize() succeeds, before initXMTP).
  static String? xmtpDbDirectory;

  /// Optional override for the drift contacts DB file (`publicos.sqlite`).
  /// Setting this property writes through to `AppDatabase.dbPathOverride`.
  /// publicos_client uses this to relocate the DB into an iOS App Group
  /// container so the Notification Service Extension can read it.
  ///
  /// Set this BEFORE any `AppDatabase()` construction.
  static String? get driftDbPath => AppDatabase.dbPathOverride;
  static set driftDbPath(String? value) => AppDatabase.dbPathOverride = value;

  ///*********************************************
  /// XMTP SESSION RE-INITIALIZATION
  ///*********************************************

  /// Re-initializes the XMTP client with a new private key.
  ///
  /// This method cancels any existing XMTP subscriptions, disposes of the old client,
  /// creates a new XMTP client instance, registers default codecs, and updates
  /// the current XMTP private key, client address, and DB key.
  ///
  /// An optional [existingDbKey] can be provided to reuse a DB key,
  /// for example when loading a previously saved session. If null, a new DB key is generated.
  ///
  /// Important: This method does NOT re-establish the XMTP message stream.
  /// The calling UI component or a dedicated service should handle stream
  /// re-subscription as needed.
  static Future<void> reinitializeXmtpClientWithKeys(EthPrivateKey newPrivateKey, String? label, {Uint8List? existingDbKey}) async {
    Log.i('Core', 'Re-initializing XMTP client.');

    // 1. Cancel existing XMTP subscription
    if (xmtpSubscription != null) {
      await xmtpSubscription!.cancel();
      xmtpSubscription = null;
      Log.d('Core', 'Existing XMTP subscription cancelled.');
    }

    // 2. Close the old client FIRST — release its sqlite connection. Replacing
    // the Dart instance is not enough: on Windows the native client's
    // background workers keep the .db3 open, which makes the plugin's
    // stale-inboxId "delete DB and retry" a silent no-op.
    // closeClient is a no-op when nothing is open; web doesn't implement it.
    try {
      final closed = await xmtpClient?.closeClient() ?? false;
      Log.d('Core', 'Previous XMTP client closed (wasOpen=$closed).');
    } catch (e) {
      Log.w('Core', 'closeClient before reinit failed (ignored): $e');
    }
    Log.d('Core', 'Replacing existing XMTP client instance.');

    // 3. Create a new XmtpPlugin() instance
    xmtpClient = XmtpPlugin();
    Log.d('Core', 'New XMTP client instance created.');

    // 4. Register default codecs (single source of truth)
    _registerDefaultXmtpCodecs(xmtpClient!);
    Log.d('Core', 'Default XMTP codecs registered.');

    // 5. Update XMTP state variables
    currentXMTPPrivateKey = newPrivateKey;
    currentXMTPPrivateKey = newPrivateKey; // Storing the same key for clarity in its role
    // The clientXmtpAddress will be set after client initialization
    Log.d('Core', 'currentXMTPPrivateKey updated.');

    // 6. Use existing DB key or generate new one for XMTP
    if (existingDbKey != null) {
      currentXmtpDbKey = existingDbKey;
      Log.d('Core', 'Using existing XMTP DB key.');
    } else {
      currentXmtpDbKey = Uint8List.fromList(List<int>.generate(32, (i) => Random.secure().nextInt(256)));
      Log.d('Core', 'Generated new XMTP DB key.');
    }

    // 7. Initialize XMTP client with the new private key and current DB key
    final initializedAddress = await xmtpClient!.initializeClient(
      newPrivateKey.privateKey,
      currentXmtpDbKey!,
      dbDirectory: xmtpDbDirectory,
    );
    Log.d('Core', 'XMTP client initialized with new key.');

    // 8. Update clientXmtpAddress and currentXmtpKeyLabel
    clientXmtpAddress = initializedAddress;
    currentXmtpKeyLabel = label;
    clientXmtpInboxId = await xmtpClient!.getClientInboxId();
    _setXmtpConnected(true);
    // clientXmtpInboxId is not set here, it's fetched/set separately.
    Log.d('Core', 'clientXmtpAddress updated to $clientXmtpAddress.');
    Log.d('Core', 'currentXmtpKeyLabel updated to $currentXmtpKeyLabel.');

    onXmtpClientReady?.call();

    Log.i('Core', 'XMTP client re-initialized successfully with new keys.');
  }

  /// Clears the current XMTP client state, cancelling subscriptions and nullifying related variables.
  static Future<void> clearXmtpClientState() async {
    Log.d('Core', 'Clearing XMTP client state.');
    if (xmtpSubscription != null) {
      await xmtpSubscription!.cancel();
      xmtpSubscription = null;
      Log.d('Core', 'XMTP subscription cancelled.');
    }
    // Create a new, clean XmtpPlugin instance. The old one will be garbage
    // collected. Register codecs on the fresh instance so it can be used
    // immediately if needed.
    xmtpClient = XmtpPlugin();
    _registerDefaultXmtpCodecs(xmtpClient!);
    Log.d('Core', 'New blank XMTP client instance created and codecs registered.');

    currentXMTPPrivateKey = null;
    clientXmtpAddress = null;
    clientXmtpInboxId = null;
    currentXmtpDbKey = null;
    currentXmtpKeyLabel = null;
    _setXmtpConnected(false);
    Log.d('Core', 'XMTP state variables nullified.');

    onXmtpClientCleared?.call();
  }

  ///*********************************************
  /// CORE INITIALIZATION — 4-STAGE
  ///*********************************************
  ///
  /// The core initializes in four independent stages, each with its own
  /// concern and failure mode. Consumer apps call the stages they need:
  ///
  ///   1. init()        — infrastructure (DB, secure storage, RPC bootstrap)
  ///   2. initBSP(acc) — load account keys, verify on chain, resolve RPC
  ///   3. initSSP()     — resolve feed server
  ///   4. initXMTP()    — load last XMTP key, start message stream
  ///
  /// Stages 2–4 are independent and can run in parallel (2–4 is fine, or
  /// 3 and 4 after 2). Each emits on its respective `*Status` stream.
  ///
  /// Legacy `initialize()` is kept as a thin wrapper over `init()` for
  /// backward compatibility during migration.

  /// **Stage 1 — Infrastructure.**
  /// Boot secure storage, local auth, HTTP client, database, and create a
  /// Web3Client pointing at the public RPC. No account, no messaging.
  /// Failure mode: database init failure is fatal (returns false). RPC
  /// unreachable is logged and `web3Connected` is set to false, init continues.
  static Future<bool> init() async {
    if (isInitialized) return true;

    try {
      Log.i('Core', '[init] starting');
      secureStorage = const FlutterSecureStorage();
      localAuth = LocalAuthentication();
      httpClient = Client();

      if (!await PublicOSDatabase.initializeDatabase()) {
        throw Exception('Failed to initialize database');
      }
      Log.d('Core', '[init] database ready');

      // Public RPC bootstrap (non-blocking)
      await _initializeWeb3();

      // Notifications (non-blocking, best-effort)
      await initializeNotifications();

      // One-shot migration for the avatarBase64-in-prefs OOM
      // (see PublicOSConversations.scrubLegacyNotifHistory). Cheap; no-op
      // on devices that already scrubbed or never had legacy entries.
      await PublicOSConversations.scrubLegacyNotifHistory();

      // TEMPORARY — delete this call and
      // `AppDatabase.scrubLegacyUnknownInboxLabels` once existing installs have
      // run it once. Rewrites the old 'unknown' inbox label on non-PublicOS
      // contacts to the empty string those stubs now store.
      try {
        final fixed = await database.scrubLegacyUnknownInboxLabels();
        if (fixed > 0) {
          Log.i('Core',
              '[init] scrubbed the legacy unknown inbox label on $fixed contacts');
        }
      } catch (e) {
        Log.w('Core', '[init] unknown-label scrub failed: $e');
      }

      isInitialized = true;
      Log.i('Core', '[init] complete — web3Connected=$web3Connected');
      return true;
    } catch (e) {
      lastError = e.toString();
      Log.e('Core', '[init] failed: $e');
      return false;
    }
  }

  /// Legacy name. Calls [init]. Kept so older consumers compile.
  static Future<bool> initialize() => init();

  /// **Stage 2 — BSP (blockchain infrastructure).**
  ///
  /// Resolves module addresses from `ModuleRegistry`, starts the polling
  /// timer, and — if a session is active — swings the active web3 client
  /// onto the caller's BSP RPC based on their subscription.
  ///
  /// The pipeline order for a consumer app logging in is:
  ///
  ///     1. PublicOSAccounts.restoreSession(address)  ← load keys, verify
  ///                                                    on chain, save own
  ///                                                    contact
  ///     2. PublicOS.initBSP()                        ← this function
  ///     3. PublicOS.initSSP()
  ///     4. PublicOS.initXMTP()
  ///
  /// `initBSP` reads `myPublicosAddress` (set by step 1) to decide whether
  /// to resolve a subscription. It does **not** load keys, fetch contacts,
  /// or do anything session-related itself.
  ///
  /// Apps that don't need a session (e.g. an admin tool on startup) can
  /// skip step 1 and call `initBSP()` directly — it'll resolve modules,
  /// start polling, and leave the RPC on whatever `init()` set up (override
  /// URL or public fallback). When `myPublicosAddress` is null, no
  /// subscription lookup happens — that's it, nothing else.
  ///
  /// When `myPublicosAddress` is set, subscription resolution runs via
  /// `upgradeRpcPostAuth()` in order: rpcOverride → cached BSP → fresh
  /// chain → custom RPCs → public. A failed upgrade stays on the current
  /// RPC and logs a warning — chain-down mode is acceptable.
  ///
  /// Returns true on success (including the no-session path). Returns
  /// false only on catastrophic init errors.
  static Future<bool> initBSP() async {
    if (!isInitialized) {
      Log.w('Core', '[initBSP] called before init() — aborting');
      return false;
    }

    Log.i('Core', '[initBSP] starting');

    try {
      // 1. Resolve module addresses via ModuleRegistry. All downstream
      //    chain reads depend on these being populated. Timeout falls
      //    back to the hardcoded defaults in PublicOSBsp.
      await PublicOSBsp.resolveModuleAddresses();

      // 2. Start the periodic re-resolution timer so mid-session
      //    redeploys propagate within an hour without a restart.
      PublicOSBsp.startPolling();

      // 3. No session → nothing to subscribe. Stay on whatever init()
      //    routed us to (override URL or public fallback). Apps without
      //    an active account (an admin tool's bootstrap, pre-login UI)
      //    hit this path.
      if (myPublicosAddress == null) {
        _setWeb3Connected(web3Connected);
        Log.i('Core',
            '[initBSP] no active session — staying on $activeRpcUrl ($activeRpcSource)');
        return true;
      }

      // 4. Session live → try to swing the RPC onto the user's BSP RPC
      //    via their on-chain subscription. upgradeRpcPostAuth's order:
      //    rpcOverride → cached BSP → fresh chain → custom → public.
      //    Any failure is logged and we stay on the current RPC.
      try {
        await upgradeRpcPostAuth();
      } catch (e) {
        Log.w('Core', '[initBSP] RPC upgrade failed (staying on $activeRpcUrl): $e');
      }

      _setWeb3Connected(web3Connected);
      Log.i('Core',
          '[initBSP] complete — rpc=$activeRpcUrl ($activeRpcSource) connected=$web3Connected');
      return true;
    } catch (e) {
      lastError = e.toString();
      Log.e('Core', '[initBSP] failed: $e');
      return false;
    }
  }

  /// **Stage 3 — SSP (social/feed server).**
  /// Resolve which feed server to use for channel/feed operations.
  /// Resolution order: override → custom (from DB) → SSP subscription
  /// (if chain connected) → default (feeds.publicos.dev).
  ///
  /// Sets [activeSspUrl], [activeSspSource], and emits [sspStatus].
  /// Safe to call even without an active account (defaults to platform URL).
  static Future<bool> initSSP() async {
    Log.i('Core', '[initSSP] starting');
    // subs_v2: the daily "seen" ping rides the SSP init — fire-and-forget, a
    // few seconds behind so the SSP has resolved; the ping itself is once per
    // UTC day and silent on any miss (PublicOSTreasury.pingSeenIfDue).
    Future<void>.delayed(const Duration(seconds: 6), PublicOSTreasury.pingSeenIfDue);

    // 1. Override
    if (sspOverrideUrl != null) {
      activeSspUrl = sspOverrideUrl!;
      activeSspSource = _sspOverrideSource ?? 'override';
      final reachable = await _testSspUrl(activeSspUrl);
      _setSspConnected(reachable);
      Log.i('Core', '[initSSP] override: $activeSspUrl ($activeSspSource) '
          'connected=$reachable');
      return reachable;
    }

    // 2. Cached active SSP (unified {endpoint, source} blob).
    //    Source-aware verification mirrors upgradeRpcPostAuth step 1:
    //      source == 'ssp'    → verify assignedSSP(account) non-empty, clear
    //                           the cache if the subscription is gone.
    //      source == 'custom' → trust local DB.
    if (sessionBlockchainAddress != null) {
      final cached = await PublicOSSsp.getCachedActiveSsp();
      if (cached != null) {
        bool trustCache = true;
        if (cached.source == 'ssp' && web3Connected) {
          try {
            final addr = EthereumAddress.fromHex(myPublicosAddress!);
            final slug = await PublicOSBsp.subsMemoryContract.slugOf((axis: BigInt.one, a: addr));
            if (slug.isEmpty) {
              Log.i('Core', '[initSSP] cached SSP cleared — no subscription');
              await PublicOSSsp.clearCachedActiveSsp();
              trustCache = false;
            }
          } catch (e) {
            Log.w('Core', '[initSSP] SSP verification failed, keeping cache: $e');
          }
        }
        if (trustCache && await _testSspUrl(cached.endpoint)) {
          activeSspUrl = cached.endpoint;
          activeSspSource = cached.source;
          _setSspConnected(true);
          Log.i('Core',
              '[initSSP] cached: $activeSspUrl ($activeSspSource)');
          return true;
        }
      }
    }

    // 3. SSP subscription from chain (cold path — no cached selection, or
    //    the cache was invalidated above).
    if (web3Connected) {
      try {
        final sspUrl = await PublicOSSsp.getSSPServerAddress();
        if (sspUrl != null && sspUrl.isNotEmpty) {
          if (await _testSspUrl(sspUrl)) {
            activeSspUrl = sspUrl;
            activeSspSource = 'ssp';
            _setSspConnected(true);
            // Cache the resolved subscription for next startup.
            await PublicOSSsp.setCachedActiveSsp(sspUrl, 'ssp');
            Log.i('Core', '[initSSP] subscription: $activeSspUrl');
            return true;
          }
        }
      } catch (e) {
        Log.w('Core', '[initSSP] subscription resolution failed: $e');
      }
    }

    // 4. Custom servers from DB (first reachable wins). Only reached when
    //    there's no cached selection and no active subscription.
    if (sessionBlockchainAddress != null) {
      try {
        final servers = await database.getFeedServersForSession(sessionBlockchainAddress!);
        for (final s in servers) {
          if (await _testSspUrl(s.feedServerAddress)) {
            activeSspUrl = s.feedServerAddress;
            activeSspSource = 'custom';
            _setSspConnected(true);
            Log.i('Core', '[initSSP] custom: $activeSspUrl');
            return true;
          }
        }
      } catch (e) {
        Log.w('Core', '[initSSP] custom lookup failed: $e');
      }
    }

    // 5. Default (public fallback — never cached).
    activeSspUrl = DEFAULT_SSP_URL;
    activeSspSource = 'default';
    final reachable = await _testSspUrl(DEFAULT_SSP_URL);
    _setSspConnected(reachable);
    Log.i('Core', '[initSSP] default: $activeSspUrl connected=$reachable');
    return reachable;
  }

  /// Liveness probe for the *currently active* SSP.
  ///
  /// Unlike [initSSP], this re-resolves nothing — no on-chain subscription
  /// lookup, no DB read. It pings [activeSspUrl] and emits [sspStatus].
  /// This is the call a status poller wants; [initSSP] is far too heavy to
  /// run on a timer.
  static Future<bool> pingSsp() async {
    final reachable = await _testSspUrl(activeSspUrl);
    _setSspConnected(reachable);
    return reachable;
  }

  /// Test whether an SSP/feed server URL is reachable.
  /// Uses a lightweight HEAD request with 5s timeout.
  static Future<bool> _testSspUrl(String url) async {
    try {
      final response = await httpClient
          .head(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  /// **Stage 4 — XMTP.**
  /// Create the XMTP plugin, register codecs, load the last used key, and
  /// start the message stream. If no key is found, returns without error
  /// (the app continues without messaging).
  ///
  /// Precondition: [isAuthenticated] or at least [sessionBlockchainAddress]
  /// set (XMTP keys are stored per-account).
  ///
  /// Returns true if the XMTP client is active at the end.
  static Future<bool> initXMTP() async {
    final accountAddr = myPublicosAddress;
    if (accountAddr == null) {
      Log.w('Core', '[initXMTP] skipping — no active account');
      return false;
    }

    Log.i('Core', '[initXMTP] starting');

    // 1. Create plugin + register codecs (idempotent — safe to re-run)
    xmtpClient ??= XmtpPlugin();
    _registerDefaultXmtpCodecs(xmtpClient!);

    // 2. Look up last used key label for this account.
    // Keychain stores everything under the account address (myPublicosAddress),
    // NOT the session/device address (sessionBlockchainAddress).
    final selectedKey = await secureStorage.read(
      key: '$xmtpSelectedKeyPrefix$accountAddr',
    );
    final lastKey = selectedKey ??
        await secureStorage.read(
          key: '$xmtpLastKeyPrefix$accountAddr',
        );

    if (lastKey == null) {
      Log.i('Core', '[initXMTP] no stored XMTP key — messaging inactive');
      _setXmtpConnected(false);
      return false;
    }

    // 3. Load private key + DB key from secureStorage
    final privateKeyB64 = await secureStorage.read(
      key: '$keychainKeyPrefix${accountAddr}_$lastKey',
    );
    if (privateKeyB64 == null) {
      Log.w('Core', '[initXMTP] key label "$lastKey" has no private key stored');
      _setXmtpConnected(false);
      return false;
    }

    try {
      final privateKey = EthPrivateKey.fromHex(utf8.decode(base64Decode(privateKeyB64)));
      final walletAddress = privateKey.address.eip55With0x;
      final dbKeyB64 = await secureStorage.read(
        key: '$xmtpDbKeyPrefix${accountAddr}_${walletAddress.toLowerCase()}',
      );
      if (dbKeyB64 == null) {
        Log.w('Core', '[initXMTP] no XMTP DB key for wallet $walletAddress');
        _setXmtpConnected(false);
        return false;
      }
      final dbKey = base64Decode(dbKeyB64);

      // 3b. Boot must never register a new installation. If the stored key's
      // local database is gone (e.g. app data cleared), skip silently and
      // leave messaging inactive — the user manages create/restore from the
      // Messages view, we never assume. (initializeClient on a missing DB
      // would otherwise create a fresh DB and register a new installation.)
      final status = await PublicOSKeychain.xmtpSetupStatusFor(accountAddr, lastKey);
      if (status != XmtpSetupStatus.ready) {
        Log.i('Core', '[initXMTP] key "$lastKey" not ready (${status.name}) — messaging inactive, user manages setup');
        _setXmtpConnected(false);
        return false;
      }

      // 4. Initialize the client
      final address = await xmtpClient!.initializeClient(
        privateKey.privateKey,
        dbKey,
        dbDirectory: xmtpDbDirectory,
      );
      currentXMTPPrivateKey = privateKey;
      clientXmtpAddress = address;
      currentXmtpDbKey = dbKey;
      currentXmtpKeyLabel = lastKey;
      clientXmtpInboxId = await xmtpClient!.getClientInboxId();

      // Persist selection
      await secureStorage.write(
        key: '$xmtpSelectedKeyPrefix$accountAddr',
        value: lastKey,
      );
      await secureStorage.write(
        key: '$xmtpLastKeyPrefix$accountAddr',
        value: lastKey,
      );

      // 5. Start message stream (handled by publicos_messages extension)
      await PublicOSConversations.initializeMessages();

      _setXmtpConnected(true);
      onXmtpClientReady?.call();
      Log.i('Core', '[initXMTP] ready — label=$lastKey inboxId=$clientXmtpInboxId');
      return true;
    } catch (e) {
      Log.e('Core', '[initXMTP] failed: $e');
      _setXmtpConnected(false);
      return false;
    }
  }

  /// Register the full set of XMTP codecs on the given client instance.
  /// Used by [init], [initXMTP], [reinitializeXmtpClientWithKeys], and
  /// [clearXmtpClientState] — one source of truth.
  static void _registerDefaultXmtpCodecs(XmtpPlugin client) {
    client.registerCodec(TextCodec());
    client.registerCodec(AttachmentCodec());
    client.registerCodec(RemoteAttachmentCodec());
    // NB: do NOT register ReplyCodec here. ReplyCodec needs the *client's* own
    // codec registry to decode nested (replied-with) content, and that registry
    // is private to XmtpPlugin. The plugin self-registers ReplyCodec(realRegistry)
    // inside initializeClient. Registering `ReplyCodec(XMTPCodecRegistry())` here
    // would clobber it with an empty registry, making every reply fail to decode
    // (decodedContent stays null and the raw EncodedContent leaks into previews).
    client.registerCodec(ReactionV2Codec());
    client.registerCodec(GroupUpdatedCodec());
    client.registerCodec(ReadReceiptCodec());
    client.registerCodec(ActionsCodec());
    client.registerCodec(IntentCodec());
    // On-chain transaction content types (XIP-21 receipt / XIP-59 request).
    // Registered so the client can SEND them (encode goes through the registry);
    // receive already worked via the by-typeId re-parse fallback.
    client.registerCodec(TransactionReferenceCodec());
    client.registerCodec(WalletSendCallsCodec());
  }

  /// Initialize Web3 client using the public RPC node (pre-auth bootstrap).
  /// Non-blocking: client is created regardless of RPC availability.
  /// Post-auth, [initBSP] resolves the user's BSP endpoint.
  static Future<void> _initializeWeb3() async {
    Log.d('Core', 'Initializing Web3 client with public node');

    web3Client = Web3Client(PUBLIC_RPC_URL, httpClient);
    try {
      await web3Client.getBlockNumber().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException(
            'Public RPC connection timed out',
            const Duration(seconds: 5),
          );
        },
      );
      Log.i('Core', 'Connected to public RPC: $PUBLIC_RPC_URL');
      _setWeb3Connected(true);
    } catch (e) {
      Log.w('Core', 'Public RPC unreachable, chain features unavailable until reconnect: $e');
      _setWeb3Connected(false);
    }
  }

  /// How long one request to a social server may take before it fails.
  /// Uploads and downloads of files set their own.
  static const Duration serverRequestTimeout = Duration(seconds: 15);

  /// Test whether an RPC URL is reachable (5-second timeout).
  static Future<bool> testRpcUrl(String url) async {
    try {
      final probeHttpClient = Client();
      final testClient = Web3Client(url, probeHttpClient);
      try {
        await testClient.getBlockNumber().timeout(
          const Duration(seconds: 5),
        );
        return true;
      } finally {
        testClient.dispose();
        // Web3Client.dispose() does not own the http client we passed in.
        // Close it explicitly or every probe leaks a connection pool.
        probeHttpClient.close();
      }
    } catch (_) {
      return false;
    }
  }

  /// Liveness probe for the *currently active* RPC.
  ///
  /// Unlike [PublicOSBsp.getBlockNumber], this NEVER fails over or switches
  /// the active endpoint — it only reports reachability and emits [web3Status].
  /// Status pollers must use this; a probe that mutates endpoint selection
  /// will silently demote the app to the public RPC on any transient blip.
  static Future<bool> pingRpc() async {
    final reachable = await testRpcUrl(activeRpcUrl);
    _setWeb3Connected(reachable);
    return reachable;
  }

  /// Switch the active web3 client to a new RPC endpoint.
  static void switchWeb3Client(String url, String source) {
    final oldClient = web3Client;
    web3Client = Web3Client(url, httpClient);
    activeRpcUrl = url;
    activeRpcSource = source;
    oldClient.dispose();
    Log.i('Core', 'Switched RPC to: $url ($source)');
  }

  /// Upgrade RPC to the best available endpoint after authentication.
  /// Resolution order: override → BSP (cached then fresh) → custom RPCs → stay on public.
  /// Only switches if connection succeeds.
  static Future<void> upgradeRpcPostAuth() async {
    // Override set — skip all resolution, force this endpoint
    if (rpcOverrideUrl != null) {
      if (activeRpcUrl != rpcOverrideUrl) {
        switchWeb3Client(rpcOverrideUrl!, _rpcOverrideSource ?? 'override');
      }
      return;
    }

    if (sessionBlockchainAddress == null) return;

    Log.d('Core', 'Post-auth RPC upgrade starting');

    // 1. Try cached active RPC selection from secure storage (unified JSON
    //    blob {endpoint, source}, written by switchToRpcEndpoint / the fresh-
    //    resolve success path). Fast path, at most one chain call.
    //
    //    Source-aware verification:
    //      source == 'bsp'    → verify the subscription still exists via
    //                           rentMemoryContract.assignedBSP(account). If
    //                           the slug is empty the cache is stale (chain
    //                           reset, provider deregistered, subscription
    //                           lapsed) — clear it and fall through.
    //      source == 'custom' → trust the entry. Custom selections have no
    //                           chain state to verify against; the local
    //                           secure-storage blob is authoritative.
    //
    //    We intentionally do NOT short-circuit when `cached.endpoint ==
    //    activeRpcUrl`: a BSP's RPC can legitimately be the same URL as the
    //    public fallback (e.g. the "publicos" BSP is fronted by
    //    rpc.publicos.dev). We still need the switchWeb3Client call so the
    //    source tag flips from 'public' to 'bsp'/'custom'.
    final cached = await PublicOSBsp.getCachedActiveRpc();
    if (cached != null) {
      bool trustCache = true;
      if (cached.source == 'bsp') {
        try {
          final addr = EthereumAddress.fromHex(myPublicosAddress!);
          final slug = await PublicOSBsp.subsMemoryContract.slugOf((axis: BigInt.zero, a: addr));
          if (slug.isEmpty) {
            Log.i('Core', 'Cached BSP cleared — no on-chain subscription');
            await PublicOSBsp.clearCachedActiveRpc();
            trustCache = false;
          }
        } catch (e) {
          Log.w('Core', 'BSP verification failed, keeping cache: $e');
        }
      }
      if (trustCache && await testRpcUrl(cached.endpoint)) {
        switchWeb3Client(cached.endpoint, cached.source);
        Log.i('Core',
            'Upgraded to cached ${cached.source} RPC: ${cached.endpoint}');
        return;
      }
    }

    // 2. Resolve BSP fresh from chain
    if (await _resolveAndCacheBsp()) return;

    // 3. Try custom RPCs from DB
    try {
      final customRpcs =
          await database.getRpcServersForSession(sessionBlockchainAddress!);
      for (final rpc in customRpcs) {
        if (rpc.rpcUrl != activeRpcUrl && await testRpcUrl(rpc.rpcUrl)) {
          switchWeb3Client(rpc.rpcUrl, 'custom');
          Log.i('Core', 'Upgraded to custom RPC: ${rpc.rpcUrl}');
          return;
        }
      }
    } catch (e) {
      Log.w('Core', 'Failed reading custom RPCs: $e');
    }

    // 4. Stay on current (public) — no switch needed
    Log.d('Core', 'No BSP or custom RPC available, staying on $activeRpcUrl');
  }

  /// Resolve BSP subscription from chain, test connectivity, cache if success.
  /// Returns true if BSP was resolved and switched to successfully.
  ///
  /// Side effect: on detected no-subscription (assignedBSP empty) the active-
  /// RPC cache is proactively cleared, so the next startup doesn't have to
  /// pay the verification cost to discover the same thing.
  static Future<bool> _resolveAndCacheBsp() async {
    try {
      if (myPublicosAddress == null) return false;
      final address = EthereumAddress.fromHex(myPublicosAddress!);

      final slug = await PublicOSBsp.subsMemoryContract.slugOf((axis: BigInt.zero, a: address));
      if (slug.isEmpty) {
        await PublicOSBsp.clearCachedActiveRpc();
        return false;
      }

      // Get BSP details — url is at index 3
      final bspData = await PublicOSBsp.bspRegistryMemoryContract.getBSPBySlug(
        (slug: slug),
      );
      final exists = bspData[0] as bool;
      if (!exists) return false;

      final mainUrl = bspData[3] as String;
      String? rpcUrl = mainUrl.isNotEmpty ? mainUrl : null;

      // Fall back to 'rpc-url' pointer if main url is empty
      if (rpcUrl == null) {
        try {
          final pointers =
              await PublicOSBsp.bspRegistryMemoryContract.getAllBSPPointers(
            (slug: slug),
          );
          for (int i = 0; i < pointers.pointerTypes.length; i++) {
            if (pointers.pointerTypes[i] == 'rpc-url') {
              rpcUrl = pointers.values[i];
              break;
            }
          }
        } catch (_) {}
      }
      if (rpcUrl == null || rpcUrl.isEmpty) return false;

      if (await testRpcUrl(rpcUrl)) {
        // Cache the selection for next startup as a unified {endpoint, source}
        // blob. Going through setCachedActiveRpc enforces the source enum.
        await PublicOSBsp.setCachedActiveRpc(rpcUrl, 'bsp');
        // Always switch, even when `rpcUrl == activeRpcUrl`. See the long
        // comment in `upgradeRpcPostAuth` step 1 — a BSP whose RPC matches
        // the public fallback URL still needs the source tag flipped to
        // 'bsp' so the UI stops showing "public fallback".
        switchWeb3Client(rpcUrl, 'bsp');
        Log.i('Core', 'Upgraded to BSP RPC: $rpcUrl (slug: $slug)');
        return true;
      } else {
        Log.w('Core', 'BSP RPC unreachable: $rpcUrl (slug: $slug)');
        return false;
      }
    } catch (e) {
      Log.w('Core', 'BSP RPC resolution failed: $e');
      return false;
    }
  }

  ///*********************************************
  /// NOTIFICATIONS
  ///*********************************************

  /// Initialize local notifications for the app
  /// Called once during app startup - shared by messages, feeds, etc.
  static Future<bool> initializeNotifications() async {
    if (notificationsInitialized) return true;

    try {
      Log.d('Core', 'Initializing notifications');
      notificationsPlugin = FlutterLocalNotificationsPlugin();

      // Android settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS/macOS settings
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      final initialized = await notificationsPlugin!.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        // Create notification channel for Android (messages)
        if (Platform.isAndroid) {
          await _createAndroidNotificationChannels();
        }

        notificationsInitialized = true;
        Log.i('Core', 'Notifications initialized successfully');

        // The tap that LAUNCHED the process (Android: the plugin only fires
        // onDidReceiveNotificationResponse while the process is alive; a
        // launching tap is exposed here only). The client registers
        // onNotificationTapped before this runs, so the route parks until
        // the account is selected. iOS popups carry no plugin payload (the
        // extension renders them) and come back through FCM instead.
        try {
          final launch =
              await notificationsPlugin!.getNotificationAppLaunchDetails();
          final resp = launch?.notificationResponse;
          if (launch?.didNotificationLaunchApp == true && resp != null) {
            Log.i('Core', 'Launched by a notification tap');
            _onNotificationTapped(resp);
          }
        } catch (e) {
          Log.w('Core', 'Launch notification lookup failed: $e');
        }
        return true;
      }

      Log.w('Core', 'Notifications initialization returned false');
      return false;
    } catch (e) {
      Log.e('Core', 'Error initializing notifications: $e');
      lastError = e.toString();
      return false;
    }
  }

  /// Create Android notification channels
  static Future<void> _createAndroidNotificationChannels() async {
    final androidPlugin = notificationsPlugin!
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Messages channel
    const messagesChannel = AndroidNotificationChannel(
      'publicos_messages',
      'Messages',
      description: 'Notifications for new messages',
      importance: Importance.high,
    );

    // Feeds channel (for later)
    const feedsChannel = AndroidNotificationChannel(
      'publicos_feeds',
      'Feeds',
      description: 'Notifications for feed updates',
      importance: Importance.defaultImportance,
    );

    await androidPlugin.createNotificationChannel(messagesChannel);
    await androidPlugin.createNotificationChannel(feedsChannel);
    Log.d('Core', 'Android notification channels created');
  }

  /// The local-notification payload for a tap: `type:identifier`, or
  /// `type:0x<account>:identifier` when an account is signed in (the popup
  /// is for that account's inbox; a different account must not open it).
  /// The account is fixed width, so an identifier's own colons (a URL)
  /// never confuse [_onNotificationTapped].
  static String notificationPayload(String type, String identifier) {
    final me = myPublicosAddress;
    return me == null ? '$type:$identifier' : '$type:$me:$identifier';
  }

  static final RegExp _payloadAccount = RegExp(r'^0x[0-9a-fA-F]{40}:');

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    // Payload format: "type:identifier" or "type:0x<account>:identifier"
    // (see [notificationPayload]).
    final colonIndex = payload.indexOf(':');
    if (colonIndex < 0) return;

    final type = payload.substring(0, colonIndex);
    var identifier = payload.substring(colonIndex + 1);
    String? account;
    final m = _payloadAccount.firstMatch(identifier);
    if (m != null) {
      account = identifier.substring(0, m.end - 1);
      identifier = identifier.substring(m.end);
    }
    Log.d('Core', 'Notification tapped — type: $type, identifier: ${identifier.length > 20 ? '${identifier.substring(0, 20)}...' : identifier}');

    if (onNotificationTapped != null) {
      onNotificationTapped!(type, identifier, account: account);
    } else {
      Log.w('Core', 'Notification tapped but no handler registered');
    }
  }

  ///*********************************************
  /// BACKGROUND SYNC
  ///*********************************************

  static const String bgTaskName = 'com.publicos.dev.message_sync';
  static const String bgTaskTag = 'message_sync';
  static const String bgLastSyncKey = 'bg_last_sync';

  /// Register periodic background task
  static Future<void> registerBackgroundSync() async {
    try {
      await Workmanager().registerPeriodicTask(
        bgTaskTag,
        bgTaskName,
        frequency: const Duration(minutes: 15),
        initialDelay: const Duration(seconds: 30),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
      Log.i('Core', 'Background sync registered (every 15 min, starts in 30s)');
    } catch (e) {
      Log.e('Core', 'Error registering background sync: $e');
    }
  }
   
  /// Cancel periodic background task
  static Future<void> cancelBackgroundSync() async {
    try {
      await Workmanager().cancelByTag(bgTaskTag);
      Log.i('Core', 'Background sync cancelled');
    } catch (e) {
      Log.e('Core', 'Error cancelling background sync: $e');
    }
  }

  /// Debug key for background sync logs
  static const String bgDebugLogKey = 'bg_debug_log';

  /// Bring a fresh background isolate to the point where the foreground-style
  /// push path (`PublicOSPush.handleIncomingPush` → `resolveNotificationIdentity`
  /// → `showMessageNotification`) works: credentials loaded, XMTP client + DB +
  /// notifications plugin initialized, and the PublicOS statics set (a bg
  /// isolate starts with its own blank copy of static state).
  ///
  /// Returns the handles the 15-min sweep needs for its scan, or `null` if the
  /// isolate can't be made ready (no selected account / missing keys) — the
  /// caller should bail.
  ///
  /// Shared by both consumers: [executeBackgroundSync] (the Workmanager sweep)
  /// and `firebasePushBackgroundHandler` (the FCM data-push direct-decrypt
  /// path). Does NOT do the `app_in_foreground` skip — that's sweep-only policy
  /// and lives in [executeBackgroundSync].
  ///
  /// **One client per isolate.** The FCM background isolate lives
  /// as long as the app process; building a fresh `XmtpPlugin`
  /// client + `AppDatabase` on every push without closing the previous pair
  /// would put N+1 libxmtp clients on one SQLCipher
  /// file next to the main isolate's live client (`database is locked`
  /// errors and very slow renders). So the
  /// handles built here are kept in [_bgReady] and returned again while the
  /// isolate lives; an account or key-label change closes them and rebuilds.
  /// The sweep clears the cache after closing its database (its isolate is
  /// one-shot), so only the push isolate ever reuses.
  static Future<BgIsolateHandles?> ensureBackgroundIsolateReady() async {
    WidgetsFlutterBinding.ensureInitialized();
    const secureStorage = FlutterSecureStorage();

    final lastUserAddress =
        await secureStorage.read(key: 'selected_publicos_AccountAddress');
    if (lastUserAddress == null || lastUserAddress.isEmpty) return null;

    final lastSessionAddress = await secureStorage.read(
      key: 'selected_publicos_SessionAddress_$lastUserAddress',
    );
    if (lastSessionAddress == null || lastSessionAddress.isEmpty) return null;

    // XMTP key label: try selected first, then last (matches regular flow).
    String? xmtpKeyLabel = await secureStorage.read(
      key: '$xmtpSelectedKeyPrefix$lastUserAddress',
    );
    if (xmtpKeyLabel == null || xmtpKeyLabel.isEmpty) {
      xmtpKeyLabel = await secureStorage.read(
        key: '$xmtpLastKeyPrefix$lastUserAddress',
      );
    }
    if (xmtpKeyLabel == null || xmtpKeyLabel.isEmpty) return null;

    // Reuse what this isolate already built, unless the account changed.
    final bgReadyKey = '$lastUserAddress/$xmtpKeyLabel';
    final cached = _bgReady;
    if (cached != null) {
      if (_bgReadyKey == bgReadyKey) {
        Log.d('Core', 'BG isolate already ready — reusing XMTP client + DB');
        return cached;
      }
      Log.d('Core', 'BG isolate account changed — closing old client + DB');
      await _releaseBackgroundIsolateHandles();
    }

    final privateKeyB64 = await secureStorage.read(
      key: '$keychainKeyPrefix${lastUserAddress}_$xmtpKeyLabel',
    );
    if (privateKeyB64 == null) return null;

    final privateKeyHex = utf8.decode(base64Decode(privateKeyB64));
    final privateKey = EthPrivateKey.fromHex(privateKeyHex);
    final walletAddress = privateKey.address.eip55With0x.toLowerCase();

    final dbKeyB64 = await secureStorage.read(
      key: '$xmtpDbKeyPrefix${lastUserAddress}_$walletAddress',
    );
    if (dbKeyB64 == null) return null;
    final dbKey = base64Decode(dbKeyB64);

    // XMTP client
    final xmtpClient = XmtpPlugin();
    xmtpClient.registerCodec(TextCodec());
    xmtpClient.registerCodec(AttachmentCodec());
    xmtpClient.registerCodec(RemoteAttachmentCodec());
    xmtpClient.registerCodec(ReactionV2Codec());
    xmtpClient.registerCodec(GroupUpdatedCodec());
    xmtpClient.registerCodec(ReadReceiptCodec());
    xmtpClient.registerCodec(ActionsCodec());
    xmtpClient.registerCodec(IntentCodec());
    // On-chain transaction content types (XIP-21 receipt / XIP-59 request) —
    // registered so this client can send/encode them. See _registerDefaultXmtpCodecs.
    xmtpClient.registerCodec(TransactionReferenceCodec());
    xmtpClient.registerCodec(WalletSendCallsCodec());
    await xmtpClient.initializeClient(
      privateKey.privateKey,
      dbKey,
      dbDirectory: PublicOS.xmtpDbDirectory,
    );
    final myInboxId = await xmtpClient.getClientInboxId();

    // DB — MUST resolve via resolveDbFile() so this isolate hits the same
    // SQLite file as the main app's PublicOS.database.
    final dbFile = await AppDatabase.resolveDbFile();
    final bgDatabase = AppDatabase(NativeDatabase(dbFile));

    // Notifications plugin
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

    // Wire the statics so the foreground-style render path finds them in this
    // isolate (bg isolate has its own copy of static state).
    PublicOS.xmtpClient = xmtpClient;
    PublicOS.database = bgDatabase;
    PublicOS.sessionBlockchainAddress = lastSessionAddress;
    notificationsPlugin = notifications;
    notificationsInitialized = true;

    final handles = (
      xmtpClient: xmtpClient,
      database: bgDatabase,
      sessionAddress: lastSessionAddress,
      myInboxId: myInboxId,
    );
    _bgReady = handles;
    _bgReadyKey = bgReadyKey;
    return handles;
  }

  /// The handles [ensureBackgroundIsolateReady] built in THIS isolate (every
  /// isolate has its own copy of static state), and the account/key-label
  /// they were built for.
  static BgIsolateHandles? _bgReady;
  static String? _bgReadyKey;

  /// Close the cached background handles and forget them. Used when the
  /// selected account changed under a long-lived push isolate.
  static Future<void> _releaseBackgroundIsolateHandles() async {
    final r = _bgReady;
    _bgReady = null;
    _bgReadyKey = null;
    if (r == null) return;
    try {
      await r.xmtpClient.closeClient();
    } catch (e) {
      Log.w('Core', 'BG closeClient failed (ignored): $e');
    }
    try {
      await r.database.close();
    } catch (e) {
      Log.w('Core', 'BG database.close failed (ignored): $e');
    }
  }

  // NOTE: publicos_client's 15-min Workmanager task no longer calls this —
  // that worker is now chain-only (publicos_client/main.dart::
  // runChainNotificationSync → PublicOSActivity sweep + showActivityNotification).
  // executeBackgroundSync stays because the FCM data-push handler
  // (publicos_client::firebasePushBackgroundHandler) and publicos_desktop still
  // run it for message catch-up.

  /// Execute background sync - called by the FCM push handler (and desktop)
  static Future<bool> executeBackgroundSync() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> debugLog = [];

    void logDebug(String message) {
      final timestamp = DateTime.now().toIso8601String().substring(11, 19);
      debugLog.add('[$timestamp] $message');
      Log.d('Core', 'BG: $message');
    }

    try {
      logDebug('Starting background sync');
      WidgetsFlutterBinding.ensureInitialized();

      // Skip if app is in the foreground — the live stream handles messages
      if (prefs.getBool('app_in_foreground') == true) {
        logDebug('App is in foreground, skipping background sync');
        await prefs.setString(bgDebugLogKey, debugLog.join('\n'));
        return true;
      }

      // Bring this fresh isolate to a ready state (creds → XMTP client → DB →
      // notifications plugin, statics wired). Shared with the FCM push handler.
      final ready = await ensureBackgroundIsolateReady();
      if (ready == null) {
        logDebug('Isolate not ready (no account/keys), skipping');
        await prefs.setString(bgDebugLogKey, debugLog.join('\n'));
        return true;
      }
      final xmtpClient = ready.xmtpClient;
      final bgDatabase = ready.database;
      final lastSessionAddress = ready.sessionAddress;
      final myInboxId = ready.myInboxId;
      logDebug('Isolate ready, inbox: ${myInboxId.substring(0, 10)}...');

      // Last sync time (sweep-only — the scan asks "what's new since this?").
      final lastSync = prefs.getInt(bgLastSyncKey) ??
          DateTime.now().subtract(const Duration(minutes: 15)).millisecondsSinceEpoch;
      final lastSyncDate = DateTime.fromMillisecondsSinceEpoch(lastSync);
      logDebug('Last sync: $lastSyncDate');

      // 8. Fetch conversations and check for new messages
      // Note: listConversations doesn't exist in native plugin, use listDms + listGroups
      final dms = await xmtpClient.listDms();
      final groups = await xmtpClient.listGroups();
      final conversations = <Map<String, dynamic>>[
        for (final c in dms) {...c, '_kind': 'dm'},
        for (final c in groups) {...c, '_kind': 'group'},
      ];
      logDebug('Found ${dms.length} DMs + ${groups.length} groups = ${conversations.length} conversations');

      int notificationCount = 0;
      for (final conv in conversations) {
        final topic = conv['topic'] as String?;
        if (topic == null) continue;
        final isGroup = conv['_kind'] == 'group';

        final messages = await xmtpClient.getMessagesAfterDateByTopic(topic, lastSyncDate);

        for (final msg in messages) {
          final senderInboxId = msg['senderInboxId'] as String?;
          final msgTime = msg['sent'] as int? ?? 0;
          final decodedContent = msg['decodedContent'];

          // Skip: own messages, old messages, system messages.
          // Reactions ARE notified — but only `added`, not `removed` (a user
          // un-reacting shouldn't pop a fresh notification).
          if (senderInboxId == null || senderInboxId == myInboxId) continue;
          if (msgTime <= lastSync) continue;
          if (decodedContent is ReadReceipt || decodedContent is GroupUpdated) continue;
          if (decodedContent is Reaction && decodedContent.action == ReactionAction.removed) {
            continue;
          }

          // Resolve sender name + avatar + group name via the shared
          // notification-identity resolver — one place, used by both this
          // sweep and the FCM direct-decrypt path.
          final id = await PublicOSConversations.resolveNotificationIdentity(
            senderInboxId: senderInboxId,
            topic: topic,
            isGroup: isGroup,
            database: bgDatabase,
            sessionAddress: lastSessionAddress,
          );

          // For reactions, look up the parent message preview so the body
          // reads "reacted ❤️ to '<snippet>'" instead of just "reacted ❤️".
          String? reactionParentPreview;
          if (decodedContent is Reaction) {
            try {
              reactionParentPreview = await PublicOSConversations.previewForReactedMessage(
                decodedContent.reference,
                database: bgDatabase,
                sessionAddress: lastSessionAddress,
                ownerInboxId: myInboxId,
              );
            } catch (e) {
              logDebug('Reaction parent lookup failed: $e');
            }
          }

          // Format message preview
          final messagePreview = PublicOSConversations.formatMessagePreview(
            msg['body'] as String?,
            decodedContent,
            reactionParentPreview: reactionParentPreview,
          );

          // Show notification via the shared MessagingStyle renderer.
          // bypassSettingsGate: true — bg sweep is already behind its own
          // toggle in publicos_client settings (publicos_messages channel).
          await PublicOSConversations.showMessageNotification(
            senderName: id.name,
            messagePreview: messagePreview,
            conversationTopic: topic,
            avatarUrl: id.avatarUrl,
            groupName: id.groupName,
            senderInboxId: senderInboxId,
            bypassSettingsGate: true,
          );
          notificationCount++;
        }
      }

      // 9. Update last sync time
      await prefs.setInt(bgLastSyncKey, DateTime.now().millisecondsSinceEpoch);

      // 10. Cleanup. The sweep's isolate is one-shot, so it closes its
      // database as before and drops the per-isolate cache with it — the
      // cache is for the long-lived FCM push isolate only.
      await bgDatabase.close();
      _bgReady = null;
      _bgReadyKey = null;

      logDebug('Sync complete! $notificationCount notifications shown');
      await prefs.setString(bgDebugLogKey, debugLog.join('\n'));
      return true;
    } catch (e) {
      debugLog.add('[ERROR] $e');
      await prefs.setString(bgDebugLogKey, debugLog.join('\n'));
      Log.e('Core', 'BG: Error during background sync: $e');
      return false;
    }
  }

  /// Get the last background sync debug log (call from UI to check)
  static Future<String?> getBackgroundSyncLog() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(bgDebugLogKey);
  }

  /// Reset core state and services
  static Future<void> reset() async {
    Log.i('Core', 'Resetting core state');
    try {
      isAuthenticated = false;
      isInitialized = false;
      myPublicosAddress = null;
      currentBlockchainPrivateKey = null;
      sessionBlockchainAddress = null;
      currentBlockchainDbKey = null;

      // Reset new XMTP state variables
      currentXMTPPrivateKey = null;
      currentXMTPPrivateKey = null;
      clientXmtpAddress = null;
      clientXmtpInboxId = null;
      currentXmtpKeyLabel = null;
      currentXmtpDbKey = null; // This was the existing one, correctly reset.

      lastError = null;

      // Reset RPC to public node
      activeRpcUrl = PUBLIC_RPC_URL;
      activeRpcSource = 'public';

      await database.close();
      await web3Client.dispose();
      httpClient.close();

      Log.i('Core', 'Reset completed successfully');
    } catch (e) {
      lastError = e.toString();
      Log.e('Core', 'Error during reset: $e');
      rethrow;
    }
  }

  /// Clear all data from the system
  static Future<void> clearAllDatabaseAndSecretsData() async {
    if (!isAuthenticated) {
      throw Exception('Authentication required');
    }

    Log.i('Core', 'Clearing all data');
    try {
      //Keeping rss feeds for now, bug came out as useful
      await database.transaction(() async {
        await database.delete(database.messages).go();
        await database.delete(database.contacts).go();
      });
      await secureStorage.deleteAll();
      await reset();
      Log.i('Core', 'All data cleared successfully');
    } catch (e) {
      lastError = e.toString();
      Log.e('Core', 'Error clearing data: $e');
      rethrow;
    }
  }

  /// Clear all locally stored messages and conversations. XMTP network state
  /// is untouched — conversations reappear on the next sync, messages do not
  /// (XMTP MLS doesn't rehydrate historical payloads from the network).
  static Future<void> clearAllMessagesAndConversations() async {
    if (!isAuthenticated) {
      throw Exception('Authentication required');
    }

    Log.i('Core', 'Clearing all messages and conversations');
    try {
      await database.transaction(() async {
        await database.delete(database.messages).go();
        await database.delete(database.conversations).go();
      });
      Log.i('Core', 'Messages and conversations cleared successfully');
    } catch (e) {
      lastError = e.toString();
      Log.e('Core', 'Error clearing messages and conversations: $e');
      rethrow;
    }
  }

  /// Loads the last used XMTP key for the current user from secure storage
  /// and reinitializes the XMTP client with it.
  static Future<void> loadLastUsedXmtpKey() async {
    Log.d('Core', 'Attempting to load last used XMTP key.');
    if (PublicOS.myPublicosAddress == null) {
      Log.w('Core', 'Cannot load last used XMTP key: User not loaded yet or address is null.');
      return;
    }
    final String currentUserAddressHex = PublicOS.myPublicosAddress!;

    // 1. Get the label of the last used key - try selected key first, then last key
    final String selectedKeyStorageKey = '$xmtpSelectedKeyPrefix$currentUserAddressHex';
    final String lastKeyStorageKey = '$xmtpLastKeyPrefix$currentUserAddressHex';

    String? lastSelectedLabel = await PublicOS.secureStorage.read(key: selectedKeyStorageKey);
    if (lastSelectedLabel == null || lastSelectedLabel.isEmpty) {
      lastSelectedLabel = await PublicOS.secureStorage.read(key: lastKeyStorageKey);
    }

    if (lastSelectedLabel == null || lastSelectedLabel.isEmpty) {
      Log.w('Core', 'No last used keychain key label found for user $currentUserAddressHex.');
      return;
    }
    Log.d('Core', 'Found last used keychain key label: "$lastSelectedLabel" for user $currentUserAddressHex.');

    // 2. Fetch the keychain private key using the label
    final String itemKey = '$keychainKeyPrefix${currentUserAddressHex}_$lastSelectedLabel';
    final String? base64Pk = await PublicOS.secureStorage.read(key: itemKey);

    if (base64Pk == null) {
      Log.e('Core', 'Could not retrieve stored private key for label: "$lastSelectedLabel".');
      // Optionally, remove the potentially orphaned lastKeyStorageKey
      // await PublicOS.secureStorage.delete(key: lastKeyStorageKey);
      return;
    }

    EthPrivateKey privateKey;
    try {
      final String pkHex = utf8.decode(base64Decode(base64Pk));
      privateKey = EthPrivateKey.fromHex(pkHex);
    } catch (e) {
      Log.e('Core', 'Failed to decode or create EthPrivateKey for label "$lastSelectedLabel": $e');
      return;
    }

    // 3. Fetch the associated XMTP DB Key (indexed by wallet address)
    final walletAddress = privateKey.address.eip55With0x.toLowerCase();
    final String dbKeyStorageKey = '$xmtpDbKeyPrefix${currentUserAddressHex}_$walletAddress';
    final String? base64DbKey = await PublicOS.secureStorage.read(key: dbKeyStorageKey);
    Uint8List? xmtpDbKey; // Nullable, as reinitializeXmtpClientWithKeys will generate one if null

    if (base64DbKey != null) {
      try {
        xmtpDbKey = base64Decode(base64DbKey);
        Log.d('Core', 'Successfully retrieved stored XMTP DB key for wallet: $walletAddress.');
      } catch (e) {
        Log.w('Core', 'Failed to decode stored XMTP DB key for wallet $walletAddress: $e. A new DB key will be generated.');
        // xmtpDbKey remains null, a new one will be generated by reinitializeXmtpClientWithKeys
      }
    } else {
      Log.w('Core', 'No stored XMTP DB key found for wallet: $walletAddress. A new DB key will be generated.');
      // xmtpDbKey remains null
    }

    // 4. Reinitialize XMTP Client with the fetched private key and DB key (if found)
    try {
      await PublicOS.reinitializeXmtpClientWithKeys(privateKey, lastSelectedLabel, existingDbKey: xmtpDbKey);
      PublicOS.currentXmtpKeyLabel = lastSelectedLabel; // Set the label in memory

      // Store this label as both the "current" active one and "last selected for next startup"
      await PublicOS.secureStorage.write(key: selectedKeyStorageKey, value: lastSelectedLabel);
      await PublicOS.secureStorage.write(key: lastKeyStorageKey, value: lastSelectedLabel);
      Log.d('Core', 'Stored current keychain key label "$lastSelectedLabel" to secure storage for user $currentUserAddressHex.');
      PublicOS.clientXmtpInboxId = await xmtpClient!.getClientInboxId();

      Log.i('Core', 'Reinitialized XMTP client with last used key: "$lastSelectedLabel".');
    } catch (e) {
      Log.e('Core', 'Failed to reinitialize XMTP client with key "$lastSelectedLabel": $e');
      // Reset related XMTP state if reinitialization fails
       PublicOS.currentXMTPPrivateKey = null;
       PublicOS.currentXMTPPrivateKey = null;
       PublicOS.clientXmtpAddress = null;
       PublicOS.clientXmtpInboxId = null; // Not directly set here, so not reset here.
      PublicOS.currentXmtpDbKey = null;
      PublicOS.currentXmtpKeyLabel = null;
    }
  }

  static void dispose() {
    // _selectedProfileStreamController.close();
    // _xmtpClientReloadedStreamController.close();
    // _selectedAppController.close(); // Removed as _selectedAppController is removed
  }
}
