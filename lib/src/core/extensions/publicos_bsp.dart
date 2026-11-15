import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import 'package:wallet/wallet.dart';
import 'package:drift/drift.dart' show Value;
import 'package:publicos_core/src/database/database.dart';
import 'package:publicos_core/src/core/publicos_core.dart';
import 'package:publicos_core/src/utils/log.dart';
import 'package:publicos_core/src/contracts/AccountManager.g.dart';
import 'package:publicos_core/src/contracts/AccountMemory.g.dart';
import 'package:publicos_core/src/contracts/InvitationManager.g.dart';
import 'package:publicos_core/src/contracts/AccountBlueprint.g.dart';
import 'package:publicos_core/src/contracts/OrgManager.g.dart';
import 'package:publicos_core/src/contracts/OrgStorage.g.dart';
import 'package:publicos_core/src/contracts/SafeManager.g.dart';
import 'package:publicos_core/src/contracts/SafeMemory.g.dart';
import 'package:publicos_core/src/contracts/WalletDirectoryManager.g.dart';
import 'package:publicos_core/src/contracts/WalletDirectoryMemory.g.dart';
import 'package:publicos_core/src/contracts/AgreementMemory.g.dart';
import 'package:publicos_core/src/contracts/SubsManager.g.dart';
import 'package:publicos_core/src/contracts/SubsMemory.g.dart'; // agreementMemoryContract (the citizen claim sheet reads the texts)
import 'package:publicos_core/src/contracts/SafeAuth.g.dart';
import 'package:publicos_core/src/contracts/XmtpManager.g.dart';
import 'package:publicos_core/src/contracts/Governor.g.dart';
import 'package:publicos_core/src/contracts/VoteWeight.g.dart';
import 'package:publicos_core/src/contracts/RecoveryModule.g.dart';
import 'package:publicos_core/src/contracts/AppRegistryManager.g.dart';
import 'package:publicos_core/src/contracts/TreasuryManager.g.dart';
import 'package:publicos_core/src/contracts/NodeRegistryManager.g.dart';
import 'package:publicos_core/src/contracts/NodeRegistryMemory.g.dart';
import 'package:publicos_core/src/contracts/TreasuryMemory.g.dart';
import 'package:publicos_core/src/contracts/Accumulator.g.dart';
import 'package:publicos_core/src/contracts/DomainManager.g.dart';
import 'package:publicos_core/src/contracts/DomainMemory.g.dart';
import 'package:publicos_core/src/contracts/GrantsManager.g.dart';
import 'package:publicos_core/src/contracts/GrantsMemory.g.dart';
import 'package:publicos_core/src/contracts/RecordManager.g.dart';
import 'package:publicos_core/src/contracts/AgreementManager.g.dart';
import 'package:publicos_core/src/contracts/FlagRegistryManager.g.dart';
import 'package:publicos_core/src/contracts/FlagRegistryMemory.g.dart';
import 'package:publicos_core/src/contracts/PenaltiesManager.g.dart';
import 'package:publicos_core/src/contracts/PenaltiesMemory.g.dart';
import 'package:publicos_core/src/contracts/SuspensionNotice.g.dart';
import 'package:publicos_core/src/contracts/UpgradeTimelock.g.dart';
import 'package:publicos_core/src/contracts/TimeLock.g.dart';
import 'package:publicos_core/src/contracts/OrgAddPermitsManager.g.dart';
import 'package:publicos_core/src/contracts/OrgCancelVoteMemory.g.dart';
import 'package:publicos_core/src/contracts/ModuleRegistry.g.dart';
import 'package:publicos_core/src/contracts/PublicOSToken.g.dart';
import 'package:publicos_core/src/contracts/VouchManager.g.dart';
import 'package:publicos_core/src/contracts/VouchMemory.g.dart';
import 'package:publicos_core/src/contracts/CitizenshipManager.g.dart';
import 'package:publicos_core/src/contracts/CitizenshipMemory.g.dart';
import 'package:publicos_core/src/contracts/OrgHierarchyStorage.g.dart';
import 'package:publicos_core/src/contracts/BSPRegistryManager.g.dart';
import 'package:publicos_core/src/contracts/BSPRegistryMemory.g.dart';
import 'package:publicos_core/src/contracts/SocialServerRegistryManager.g.dart';
import 'package:publicos_core/src/contracts/SocialServerRegistryMemory.g.dart';


/// Web3 and smart contract management extension for PublicOS.
///
/// Handles Ethereum client management, RPC connections, and contract interactions.
/// Represents an RPC endpoint entry for UI display.
class RpcEndpointEntry {
  final String label;
  final String url;

  /// 'public', 'bsp', or 'custom'
  final String source;
  final String? bspSlug;
  final int? rpcServerId;
  final bool isActive;

  RpcEndpointEntry({
    required this.label,
    required this.url,
    required this.source,
    this.bspSlug,
    this.rpcServerId,
    required this.isActive,
  });
}

extension PublicOSBsp on PublicOS {

  static const _tag = 'BSP';

  /// Hardhat funder accoutn

  // ModuleRegistry address — immutable anchor, never changes
  static final EthereumAddress moduleRegistryAddress = EthereumAddress.fromHex(
    '0xF69a649A5541d2d0108E00f697647fF1dD4Bd4bD',
  );

  // PublicOS Core Contracts (mutable — resolved from ModuleRegistry)
  //
  // The fallbacks below must match the live registry. A chain redeploy can
  // move any of them, and one made with a different deployer key moves the
  // anchor too, so every literal here — including moduleRegistryAddress —
  // changes. A freed address can be recycled by another contract, so a stale
  // value may point at a live-but-wrong contract.
  // Symptom when stale: the app resolves nothing and reports a perfectly valid
  // session as "not linked to an account".
  // These should become nullable and be backed by a persisted cache instead.
  static EthereumAddress accountMemoryAddress = EthereumAddress.fromHex(
    '0x6BC03d196fe5aa37ac674b62b48d1E13F10CE27a',
  );

  static EthereumAddress accountManagerAddress = EthereumAddress.fromHex(
    '0x158033BC70614c809318604Ef29eCf886A96c2A1',
  );

  // Safe pair. Resolved from registry,
  // no hardcoded fallback — these land via resolveModuleAddresses() on init.
  static EthereumAddress? safeMemoryAddress;
  static EthereumAddress? safeManagerAddress;

  // Wallet directory pair (multi-protocol additional wallets). Resolved from
  // registry, no hardcoded fallback.
  static EthereumAddress? walletDirectoryMemoryAddress;
  static EthereumAddress? walletDirectoryManagerAddress;

  static EthereumAddress safeAuthAddress = EthereumAddress.fromHex(
    '0x003659496f489c344e6Dbee32e59130d2F7F8eAa',
  );

  static EthereumAddress recoveryModuleAddress = EthereumAddress.fromHex(
    '0x13CBb80f8Dc377790b175Bf2b9c7BdAF080F0040',
  );

  static EthereumAddress orgStorageAddress = EthereumAddress.fromHex(
    '0x1f9d2461ADB8Fa6789D7bbD65214124069cB2e90',
  );

  static EthereumAddress votingMechanismAddress = EthereumAddress.fromHex(
    '0x671cb088352FaAfE0c5520ECf0F1342cC31331a4',
  );

  /// The checkpointed per-org / per-tag voting-weight store (VOTE_WEIGHT).
  /// Registry-resolved only — no hardcoded fallback.
  static EthereumAddress? voteWeightAddress;

  static EthereumAddress orgManagerAddress = EthereumAddress.fromHex(
    '0x42275628C3e6aD785a76dAE2009727023663b688',
  );

  static EthereumAddress xmtpMemoryAddress = EthereumAddress.fromHex(
    '0x7343FFED3D4fafc06AB8463AbACDfc95CC03bed7',
  );

  static EthereumAddress xmtpManagerAddress = EthereumAddress.fromHex(
    '0x9B1D1805688B03f8c6593294e4a58Ed944B19138',
  );

  // App Registry Contracts
  static EthereumAddress appRegistryMemoryAddress = EthereumAddress.fromHex(
    '0x79b5c40377bE3Fe331D2E7B23229d541934Ee106',
  );

  static EthereumAddress appRegistryManagerAddress = EthereumAddress.fromHex(
    '0xDD88954367e766d92fbCb5669090FbE0B527259a',
  );

  // Treasury Contracts
  static EthereumAddress treasuryMemoryAddress = EthereumAddress.fromHex(
    '0x3F68b7C887652473913A4d26943ae76C2CeD2f65',
  );

  static EthereumAddress treasuryManagerAddress = EthereumAddress.fromHex(
    '0x80e24982ba9Cb0687b85c74CbC4850c2E6E59EF0',
  );

  // Domain-rights economy contracts (resolved from registry)
  static EthereumAddress? accumulatorAddress;
  static EthereumAddress? domainMemoryAddress;
  static EthereumAddress? domainManagerAddress;
  // Subscriptions ("pay as served"): ONE manager +
  // ONE memory for both axes (0 = BSP, 1 = SSP).
  static EthereumAddress? subsManagerAddress;
  static EthereumAddress? subsMemoryAddress;
  static EthereumAddress? grantsMemoryAddress;
  static EthereumAddress? grantsManagerAddress;

  // Additional Contracts (resolved from registry, no hardcoded fallback)
  static EthereumAddress? nodeRegistryMemoryAddress;
  static EthereumAddress? nodeRegistryManagerAddress;
  static EthereumAddress? contactOsGuardAddress;
  static EthereumAddress? safeProxyFactoryAddress;
  static EthereumAddress? publicOSTokenAddress;
  static EthereumAddress? bspRegistryMemoryAddress;
  static EthereumAddress? bspRegistryManagerAddress;
  static EthereumAddress? socialServerRegistryMemoryAddress;
  static EthereumAddress? socialServerRegistryManagerAddress;
  static EthereumAddress? orgHierarchyStorageAddress;
  static EthereumAddress? vouchMemoryAddress;
  static EthereumAddress? vouchManagerAddress;
  static EthereumAddress? citizenshipMemoryAddress;
  static EthereumAddress? citizenshipManagerAddress;

  /// Bootstrap-only. Resolved from the registry only while the invitation
  /// window is active (INVITATION_MANAGER registered). Null pre-/post-bootstrap.
  static EthereumAddress? invitationManagerAddress;

  /// The record writer. Every AccountBlueprint
  /// record write (`setRecord` / `setMultipleRecords` / `deleteRecord` /
  /// `deleteMultipleRecords` / `clearAllRecords`) lives here, not on
  /// AccountManager.
  static EthereumAddress? recordManagerAddress;

  /// Agreements: `currentVersion(kind)` is read before signing a
  /// `CreateAccountConsent` (the consent binds the PROTOCOL agreement version).
  static EthereumAddress? agreementManagerAddress;

  /// Agreements: the published texts live in the memory
  /// (`getVersion(kind, version)`), read by the citizen claim sheet.
  static EthereumAddress? agreementMemoryAddress;

  /// Enforcement surface. Flags +
  /// notices (FlagRegistry), the court's penalties, and the 10-day
  /// SuspensionNotice.
  static EthereumAddress? flagRegistryManagerAddress;
  static EthereumAddress? flagRegistryMemoryAddress;
  static EthereumAddress? penaltiesManagerAddress;
  static EthereumAddress? penaltiesMemoryAddress;
  static EthereumAddress? suspensionNoticeAddress;

  /// Org add permits: "who can add me to groups" (switch, list, quota).
  static EthereumAddress? orgAddPermitsManagerAddress;

  /// Each org's vetoer (vote 57 SET_VETOER).
  static EthereumAddress? orgCancelVoteMemoryAddress;

  // --- Module Resolution ---

  /// Module type keccak256 hashes (matching Solidity's keccak256("TYPE_STRING"))
  static final List<Uint8List> _moduleTypeHashes = [
    _hexToBytes('affaeb35714f8aff83414a4e78c1b9b54edea79a5b0930d1552d0c8adb61ca88'), // ACCOUNT_MANAGER
    _hexToBytes('f4f67ed407d00bb6031ed05eefd20c18fe270cdc76c9705ddceba0d3e28430c1'), // ACCOUNT_MEMORY
    _hexToBytes('cb6b568a9b41c1e3eea3c3e55253fa6a578927ab4fe8324da13f570cae14cf33'), // SAFE_MANAGER
    _hexToBytes('88467653cecfa194dc79ccceee35c4a64cb351b8e8949e1635191219c27dad08'), // SAFE_MEMORY
    _hexToBytes('cce2dc2f58ffc61e9c65b0cf789314a15f81926072f302648144d7658b32533b'), // WALLET_DIRECTORY_MANAGER
    _hexToBytes('f2054aa0ca22c2b6e08454447228fef0668ff1ab8799387b49653eba372574ec'), // WALLET_DIRECTORY_MEMORY
    _hexToBytes('99277c044b11f8582bdfd94406b96ab90d447b1d01267732e66de13ef6636b9f'), // SAFE_AUTH
    _hexToBytes('6883fc014dca626055bee7ce2b275b9da2d3aa54f3aa2dd59e8ee1dde9eff17a'), // RECOVERY_MODULE
    _hexToBytes('0fde6c4cd4439e31974e969150ca18b9e0245ba72ab96351b95c3e7520aa254d'), // ORG_STORAGE
    _hexToBytes('b9890cb6ec78243e6c55611553ab93ad42bfb58c1169375a4af528f1355292ad'), // VOTING_MECHANISM
    _hexToBytes('cdd7ba10b36b7349d5c9710e5e447ec8acaa8e3cbba8d20f4393eccf61f185b1'), // VOTE_WEIGHT
    _hexToBytes('b833d6cd785526e1f93f8b6cf3f574cea6874e98d18c71c404d4e21f214547ea'), // ORG_MANAGER
    _hexToBytes('d0adb7017a06d5c710b3e32b4a6b910ccba67976415c88943d23879434236b10'), // XMTP_MEMORY
    _hexToBytes('1387fd6781b5040b8dbfdb9df62255a60821689fdb56a963779b67988159c18b'), // XMTP_MANAGER
    _hexToBytes('c03e4d85f83885a50de12c98623ea292ef36a0d2eecc6d607dff5f43eef7010d'), // APP_REGISTRY_MEMORY
    _hexToBytes('4d046837193e6dc2b46b378ad1cb9f434835c12f86db3fea6328239ff1ac6a3d'), // APP_REGISTRY_MANAGER
    _hexToBytes('23c3196b65e1dc7838d8a0dc32436d895ee421d2bdf9d4a0708f1c2b61cbcc96'), // TREASURY_MEMORY
    _hexToBytes('fb33b7fa49278e0b9e45aa996caa7eae999f04705ef455a86b73159c5d256fa0'), // TREASURY_MANAGER
    _hexToBytes('14a3d492acc9debbad0f78dcc5dad2f7a2b728a75c8e4818f5aa49ed1298255c'), // NODE_REGISTRY_MEMORY
    _hexToBytes('40f5a13b1b26e098079b13f4216a47a955bae7efef11ff1ab5f289d88c8a09dc'), // NODE_REGISTRY_MANAGER
    _hexToBytes('1287c43e4d313be3e8a1033c03827ada1a57a1ddb20f1c70c2a477735b6c04b1'), // CONTACTOS_GUARD
    _hexToBytes('a277a23c492b12d972206c92a4ee24f9648d332895f7f720704b273eaae41c30'), // SAFE_PROXY_FACTORY
    _hexToBytes('60bc5959ed6705573e29a891621522f76426ac39469fbde8738b4494e19571bd'), // PUBLICOS_TOKEN
    _hexToBytes('1c11a925f5a38724469cb2077fba5c0bffcfa07b100ca5e49a032c339268b74f'), // BSP_REGISTRY_MEMORY
    _hexToBytes('cc61965e04b261de1e27f3e198f788189d42a942be2cfef26862f7c8c21746cc'), // BSP_REGISTRY_MANAGER
    _hexToBytes('8fc7ca69a5545893486cdf8b8ceabae9939b01593152b70c84c55ddec79b8478'), // SOCIAL_SERVER_REGISTRY_MEMORY
    _hexToBytes('11fdf6b960313a4b6dbd8b92bbf7c1b35852482d48fbb676eee5f3024e35f79d'), // SOCIAL_SERVER_REGISTRY_MANAGER
    _hexToBytes('d72f4dd27063e3b39be35312955df67894aa8fa7e53c9cd8dad2db582f00de4d'), // ORG_HIERARCHY_STORAGE
    _hexToBytes('394c065da05f875b5eb20508ae62edaba51cdc4f429bd8382bf506737738fd6e'), // VOUCH_MEMORY
    _hexToBytes('a54cc23ca2b4f754491dd90a0d43651cbb4d9327502637ef3d392972ae60365f'), // VOUCH_MANAGER
    _hexToBytes('2f63364fda01610459457e7a834b2f896990f28122de6a0897f8ca894738c125'), // CITIZENSHIP_MEMORY
    _hexToBytes('c3ff0c04e24c244e7eb8a1ddb9cb5519e5f09fec75d7b46c072764b06aa6122e'), // CITIZENSHIP_MANAGER
    // Domain-rights economy (replaces Rent/Dividend/Grant/ProviderPayment).
    // Order MUST stay aligned with _moduleSetters below.
    _hexToBytes('c7005fca56b12607498bdd82dec29ede8d806b4b8262ae06f0a5bd473842d2a9'), // ACCUMULATOR
    _hexToBytes('345490ade6830581af1d1df5f930b0b992b6ba7b8bba645c8b6c2d3d5e55dd38'), // DOMAIN_MEMORY
    _hexToBytes('41c96a149eeeadbb3b3c521ba28e45a2beab5fcfe001e42c5d39887d79d884e6'), // DOMAIN_MANAGER
    _hexToBytes('bcf2e6d6c12109a7d9454a6c0d98010efda7f28fcb0a1cf423b28736eb87baef'), // SUBS_MANAGER (subs_v2, both axes)
    _hexToBytes('009440d050fa8ad19a404c43e2d48ca92ba77a93325633535cbf9f31efae023c'), // SUBS_MEMORY  (subs_v2, both axes)
    _hexToBytes('12c9871b6e43e77791566de06ee4b89f8eee22a92f15dcbbc0a179ed0afc7c7b'), // GRANTS_MEMORY
    _hexToBytes('970b61d3f59557f384fa6ff0034eed5b85330859243d719517a23e4838666aac'), // GRANTS_MANAGER
    _hexToBytes('6c4b2443bc27849c45968e4321fbe7724372730ea1675ad8cea188d49f46ed02'), // INVITATION_MANAGER (bootstrap-only)
    // The record writer: every AccountBlueprint record write lives here, not on AccountManager.
    _hexToBytes('619c22e0b753cc842b48b0d4e2babc23b4eb0174b02a532e9e237dfcff24a5d3'), // RECORD_MANAGER
    // Agreements: CreateAccountConsent binds the current PROTOCOL version.
    _hexToBytes('c4fe11aa873d584790e0200c58083150e0e7aebc68a1490e75a9f71a573f4dc0'), // AGREEMENT_MANAGER
    _hexToBytes('22654d907e661c4647087c7e608d1c52cb88b82c8ceb5b43ca36922410bea4ec'), // AGREEMENT_MEMORY
    // Org add permits: who can add me to groups.
    _hexToBytes('cbb73767d28da902473628616c2703d91f486efca32b8cb444fb4dea596d4e63'), // ORG_ADD_PERMITS_MANAGER
    // Enforcement surface.
    _hexToBytes('18b595d079371778fd060c7e99e786fa2af973c5606ee328618369131586e7dd'), // FLAG_REGISTRY_MANAGER
    _hexToBytes('61bc3a480c248047cee21799f3a754c5822ef56f8b0dbf5af0d505319d2348d6'), // FLAG_REGISTRY_MEMORY
    _hexToBytes('ddc398fc1dbb5ea39249c32b664ef42f68c1dcfad60686cbda4ba078b2b56c92'), // PENALTIES_MANAGER
    _hexToBytes('743ed8353367325af79c10e9b2efb14d4f84cd9d53f09dcd8643080c11f31700'), // PENALTIES_MEMORY
    _hexToBytes('ed22123d9f42334f7321a45c7769812aafc996f756c30a8b36e35a7e585d07e1'), // SUSPENSION_NOTICE
    // The org's vetoer.
    _hexToBytes('12168f0fa1787f6beb746d6c1092f20e45be73bdc4f9a362ee9846f04f633c98'), // ORG_CANCEL_VOTE_MEMORY
  ];

  /// Setters indexed by position in _moduleTypeHashes
  static final List<void Function(EthereumAddress)> _moduleSetters = [
    (a) => accountManagerAddress = a,
    (a) => accountMemoryAddress = a,
    (a) => safeManagerAddress = a,
    (a) => safeMemoryAddress = a,
    (a) => walletDirectoryManagerAddress = a,
    (a) => walletDirectoryMemoryAddress = a,
    (a) => safeAuthAddress = a,
    (a) => recoveryModuleAddress = a,
    (a) => orgStorageAddress = a,
    (a) => votingMechanismAddress = a,
    (a) => voteWeightAddress = a,
    (a) => orgManagerAddress = a,
    (a) => xmtpMemoryAddress = a,
    (a) => xmtpManagerAddress = a,
    (a) => appRegistryMemoryAddress = a,
    (a) => appRegistryManagerAddress = a,
    (a) => treasuryMemoryAddress = a,
    (a) => treasuryManagerAddress = a,
    (a) => nodeRegistryMemoryAddress = a,
    (a) => nodeRegistryManagerAddress = a,
    (a) => contactOsGuardAddress = a,
    (a) => safeProxyFactoryAddress = a,
    (a) => publicOSTokenAddress = a,
    (a) => bspRegistryMemoryAddress = a,
    (a) => bspRegistryManagerAddress = a,
    (a) => socialServerRegistryMemoryAddress = a,
    (a) => socialServerRegistryManagerAddress = a,
    (a) => orgHierarchyStorageAddress = a,
    (a) => vouchMemoryAddress = a,
    (a) => vouchManagerAddress = a,
    (a) => citizenshipMemoryAddress = a,
    (a) => citizenshipManagerAddress = a,
    // Domain-rights economy — order MUST match _moduleTypeHashes above.
    (a) => accumulatorAddress = a,
    (a) => domainMemoryAddress = a,
    (a) => domainManagerAddress = a,
    (a) => subsManagerAddress = a,
    (a) => subsMemoryAddress = a,
    (a) => grantsMemoryAddress = a,
    (a) => grantsManagerAddress = a,
    (a) => invitationManagerAddress = a,
    (a) => recordManagerAddress = a,
    (a) => agreementManagerAddress = a,
    (a) => agreementMemoryAddress = a,
    (a) => orgAddPermitsManagerAddress = a,
    (a) => flagRegistryManagerAddress = a,
    (a) => flagRegistryMemoryAddress = a,
    (a) => penaltiesManagerAddress = a,
    (a) => penaltiesMemoryAddress = a,
    (a) => suspensionNoticeAddress = a,
    (a) => orgCancelVoteMemoryAddress = a,
  ];

  static final EthereumAddress _zeroAddress = EthereumAddress.fromHex(
    '0x0000000000000000000000000000000000000000',
  );

  static DateTime? _lastResolutionTime;
  static Timer? _resolutionTimer;
  static Completer<void>? _resolutionInFlight;

  /// Batch-resolve all module addresses from the on-chain ModuleRegistry.
  /// Only updates addresses that come back non-zero.
  ///
  /// Concurrent callers share the in-flight future — if resolution is
  /// already running, additional calls await the same completion rather
  /// than returning early (which would race the caller against the
  /// still-null module addresses).
  static Future<void> resolveModuleAddresses() async {
    if (_resolutionInFlight != null) {
      return _resolutionInFlight!.future;
    }
    final completer = Completer<void>();
    _resolutionInFlight = completer;

    try {
      final registry = ModuleRegistry(
        address: moduleRegistryAddress,
        client: PublicOS.web3Client,
        chainId: PublicOS.CHAIN_ID,
      );

      final addresses = await Future.any([
        registry.getModuleAddresses((moduleTypes: _moduleTypeHashes)),
        Future.delayed(const Duration(seconds: 10))
            .then((_) => throw TimeoutException('Module resolution timed out')),
      ]);

      int updated = 0;
      for (int i = 0; i < addresses.length && i < _moduleSetters.length; i++) {
        if (addresses[i] != _zeroAddress) {
          _moduleSetters[i](addresses[i]);
          updated++;
        }
      }

      _lastResolutionTime = DateTime.now();
      Log.i(_tag, 'Resolved $updated/${ _moduleSetters.length} module addresses from registry');
    } catch (e) {
      Log.e(_tag, 'Module resolution failed (using fallback addresses): $e');
    } finally {
      _resolutionInFlight = null;
      completer.complete();
    }
  }

  /// Start periodic polling for module address updates.
  static void startPolling([Duration interval = const Duration(minutes: 60)]) {
    stopPolling();
    _resolutionTimer = Timer.periodic(interval, (_) => resolveModuleAddresses());
    Log.i(_tag, 'Module polling started (every ${interval.inMinutes} min)');
  }

  /// Stop periodic polling.
  static void stopPolling() {
    _resolutionTimer?.cancel();
    _resolutionTimer = null;
  }

  /// Restart polling with a new interval.
  static void reconfigurePolling(Duration interval) {
    stopPolling();
    startPolling(interval);
  }

  /// Get active UserManager contract instance
  static AccountManager get accountManagerContract => AccountManager(address: accountManagerAddress, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static AccountMemory get accountMemoryContract => AccountMemory(address: accountMemoryAddress, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  /// Bootstrap-only. Throws if [invitationManagerAddress] is null (module not
  /// registered) — callers guard on the address before using this.
  static InvitationManager get invitationManagerContract => InvitationManager(address: invitationManagerAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static SafeManager get safeManagerContract => SafeManager(address: safeManagerAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static SafeMemory get safeMemoryContract => SafeMemory(address: safeMemoryAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static WalletDirectoryManager get walletDirectoryManagerContract => WalletDirectoryManager(address: walletDirectoryManagerAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static WalletDirectoryMemory get walletDirectoryMemoryContract => WalletDirectoryMemory(address: walletDirectoryMemoryAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static SafeAuth get safeAuthContract => SafeAuth(address: safeAuthAddress, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static XmtpManager get xmtpManagerContract => XmtpManager(address: xmtpManagerAddress, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static OrgManager get orgManagerContract => OrgManager(address: orgManagerAddress, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static OrgStorage get orgStorageContract => OrgStorage(address: orgStorageAddress, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  // The VOTING_MECHANISM slot holds the plug-n-play Governor engine.
  static Governor get votingMechanismContract => Governor(address: votingMechanismAddress, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static VoteWeight get voteWeightContract => VoteWeight(address: voteWeightAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static RecoveryModule get recoveryModuleContract => RecoveryModule(address: recoveryModuleAddress, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static AppRegistryManager get appRegistryManagerContract => AppRegistryManager(address: appRegistryManagerAddress, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static TreasuryManager get treasuryManagerContract => TreasuryManager(address: treasuryManagerAddress, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static TreasuryMemory get treasuryMemoryContract => TreasuryMemory(address: treasuryMemoryAddress, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static PublicOSToken get publicOSTokenContract => PublicOSToken(address: publicOSTokenAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static VouchManager get vouchManagerContract => VouchManager(address: vouchManagerAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static VouchMemory get vouchMemoryContract => VouchMemory(address: vouchMemoryAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static CitizenshipManager get citizenshipManagerContract => CitizenshipManager(address: citizenshipManagerAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static CitizenshipMemory get citizenshipMemoryContract => CitizenshipMemory(address: citizenshipMemoryAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static OrgHierarchyStorage get orgHierarchyStorageContract => OrgHierarchyStorage(address: orgHierarchyStorageAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static NodeRegistryManager get nodeRegistryManagerContract => NodeRegistryManager(address: nodeRegistryManagerAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static NodeRegistryMemory get nodeRegistryMemoryContract => NodeRegistryMemory(address: nodeRegistryMemoryAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static BSPRegistryManager get bspRegistryManagerContract => BSPRegistryManager(address: bspRegistryManagerAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static BSPRegistryMemory get bspRegistryMemoryContract => BSPRegistryMemory(address: bspRegistryMemoryAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static SocialServerRegistryManager get socialServerRegistryManagerContract => SocialServerRegistryManager(address: socialServerRegistryManagerAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static SocialServerRegistryMemory get socialServerRegistryMemoryContract => SocialServerRegistryMemory(address: socialServerRegistryMemoryAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  // Domain-rights economy.
  static Accumulator get accumulatorContract => Accumulator(address: accumulatorAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static DomainMemory get domainMemoryContract => DomainMemory(address: domainMemoryAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static DomainManager get domainManagerContract => DomainManager(address: domainManagerAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  // subs_v2: one manager + one memory for both axes (0 = BSP, 1 = SSP). Reads: SubsMemory.slugOf /
  // subscriberCount / fee / period / minSubscribers / gateOpenSince / getAccount; the ONE predicate every
  // consumer uses is SubsManager.isActive(axis, account). Writes: subscribe(axis, slug, topUp) /
  // leave(axis) / withdraw(amount). The high-level API is PublicOSTreasury.
  static SubsManager get subsManagerContract => SubsManager(address: subsManagerAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static SubsMemory get subsMemoryContract => SubsMemory(address: subsMemoryAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static GrantsManager get grantsManagerContract => GrantsManager(address: grantsManagerAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static GrantsMemory get grantsMemoryContract => GrantsMemory(address: grantsMemoryAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  /// The record writer (see [recordManagerAddress]).
  static RecordManager get recordManagerContract => RecordManager(address: recordManagerAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  /// agreements: `currentVersion(kind)` + the published texts (see [agreementManagerAddress]).
  static AgreementManager get agreementManagerContract => AgreementManager(address: agreementManagerAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);

  // Enforcement surface.
  static FlagRegistryManager get flagRegistryManagerContract => FlagRegistryManager(address: flagRegistryManagerAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static FlagRegistryMemory get flagRegistryMemoryContract => FlagRegistryMemory(address: flagRegistryMemoryAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static PenaltiesManager get penaltiesManagerContract => PenaltiesManager(address: penaltiesManagerAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static PenaltiesMemory get penaltiesMemoryContract => PenaltiesMemory(address: penaltiesMemoryAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  /// The org's vetoer — see [orgCancelVoteMemoryAddress].
  static OrgCancelVoteMemory get orgCancelVoteMemoryContract => OrgCancelVoteMemory(address: orgCancelVoteMemoryAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  static SuspensionNotice get suspensionNoticeContract => SuspensionNotice(address: suspensionNoticeAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);

  /// The token's own TimeLock (the founder's locked tranches). Not in the
  /// ModuleRegistry: the token creates it, so its address is `token.timeLock()`.
  static Future<TimeLock> timeLockContract() async => TimeLock(
      address: await publicOSTokenContract.timeLock(),
      client: PublicOS.web3Client,
      chainId: PublicOS.CHAIN_ID);

  /// The UpgradeTimelock that owns the ModuleRegistry (5-day window on module
  /// swaps). Not a registered module: it IS the registry's owner.
  static Future<UpgradeTimelock> upgradeTimelockContract() async {
    final registry = ModuleRegistry(
        address: moduleRegistryAddress,
        client: PublicOS.web3Client,
        chainId: PublicOS.CHAIN_ID);
    return UpgradeTimelock(
        address: await registry.owner(),
        client: PublicOS.web3Client,
        chainId: PublicOS.CHAIN_ID);
  }
  /// agreements: the texts (`getVersion`) — see [agreementMemoryAddress].
  static AgreementMemory get agreementMemoryContract => AgreementMemory(address: agreementMemoryAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  /// Org add permits: "who can add me to groups" — see [orgAddPermitsManagerAddress].
  static OrgAddPermitsManager get orgAddPermitsManagerContract => OrgAddPermitsManager(address: orgAddPermitsManagerAddress!, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);

  /// Helper to create an AccountBlueprint from a hex string address
  static AccountBlueprint accountFromHex(String addressHex) {
    final ethAddress = EthereumAddress.fromHex(addressHex);
    return AccountBlueprint(address: ethAddress, client: PublicOS.web3Client, chainId: PublicOS.CHAIN_ID);
  }

  ///*********************************************
  /// WEB3 SESSION MANAGEMENT
  ///*********************************************


  /// Try connecting to an available RPC endpoint.
  /// Builds a dynamic endpoint list: custom RPCs → BSP → public node.
  /// Skips the currently active (failed) endpoint.
  static Future<bool> connectToAvailableRPC() async {
    final failedUrl = PublicOS.activeRpcUrl;
    final candidates = <String>[];

    // 1. If authenticated, gather custom RPCs from DB
    if (PublicOS.isAuthenticated && PublicOS.sessionBlockchainAddress != null) {
      try {
        final customRpcs = await PublicOS.database
            .getRpcServersForSession(PublicOS.sessionBlockchainAddress!);
        for (final rpc in customRpcs) {
          if (rpc.rpcUrl != failedUrl && !candidates.contains(rpc.rpcUrl)) {
            candidates.add(rpc.rpcUrl);
          }
        }
      } catch (_) {}

      // Try cached active-RPC entry (may be 'bsp' or 'custom'). We only use
      // the endpoint for reachability probing here — the real source tag gets
      // re-derived below based on the URL's identity, because we can't trust
      // a stale cache's source claim without chain verification and we don't
      // want to gate failover on a chain read.
      try {
        final cached = await getCachedActiveRpc();
        if (cached != null &&
            cached.endpoint != failedUrl &&
            !candidates.contains(cached.endpoint)) {
          candidates.add(cached.endpoint);
        }
      } catch (_) {}
    }

    // 2. Always include public node as last resort
    if (PublicOS.PUBLIC_RPC_URL != failedUrl &&
        !candidates.contains(PublicOS.PUBLIC_RPC_URL)) {
      candidates.add(PublicOS.PUBLIC_RPC_URL);
    }

    // 3. Try each candidate
    for (final url in candidates) {
      Log.d(_tag, 'Failover: trying $url');
      if (await PublicOS.testRpcUrl(url)) {
        final source = url == PublicOS.PUBLIC_RPC_URL ? 'public' : 'custom';
        PublicOS.switchWeb3Client(url, source);
        Log.i(_tag, 'Failover succeeded: $url');
        // Re-resolve module addresses on the new connection
        await resolveModuleAddresses();
        return true;
      }
    }

    PublicOS.lastError = 'All RPC endpoints unreachable';
    Log.e(_tag, 'Failover failed: no RPC endpoints available');
    return false;
  }

  /// Get the current block number
  static Future<int> getBlockNumber() async {
    try {
      return await Future.any([
        PublicOS.web3Client.getBlockNumber(),
        Future.delayed(const Duration(seconds: 5)).then((_) => throw TimeoutException('Request timed out for getBlockNumber')),
      ]);
    } on TimeoutException catch (e, s) {
      Log.w(_tag, 'TimeoutException in getBlockNumber. Attempting to switch RPC and retry. Error: $e');
      bool switched = await PublicOSBsp.connectToAvailableRPC();
      if (switched) {
        Log.i(_tag, 'Switched RPC successfully for getBlockNumber. Retrying operation...');
        try {
          return await Future.any([
            PublicOS.web3Client.getBlockNumber(),
            Future.delayed(const Duration(seconds: 5)).then((_) => throw TimeoutException('Retry timed out for getBlockNumber')),
          ]);
        } catch (retryException) {
          Log.e(_tag, 'Exception during retry of getBlockNumber after RPC switch: $retryException');
          PublicOS.lastError = retryException.toString();
          rethrow;
        }
      } else {
        Log.e(_tag, 'Failed to switch RPC for getBlockNumber. Rethrowing original TimeoutException.');
        PublicOS.lastError = e.toString();
        rethrow;
      }
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error in getBlockNumber: $e');
      rethrow;
    }
  }


  ///*********************************************
  /// TRANSACTION MANAGEMENT
  ///*********************************************


  /// Send ETH from a keychain wallet (EOA) to any address
  /// This is a direct transaction, not through Safe contracts
  static Future<String?> sendTransactionFromKeychain({
    required String privateKeyHex,
    required String to,
    required BigInt valueWei,
  }) async {
    try {
      Log.d(_tag, 'Sending keychain transaction to $to');
      final credentials = EthPrivateKey.fromHex(privateKeyHex);
      final txHash = await PublicOS.web3Client.sendTransaction(
        credentials,
        Transaction(
          to: EthereumAddress.fromHex(to),
          value: EtherAmount.inWei(valueWei),
        ),
        chainId: PublicOS.CHAIN_ID,
      );
      Log.i(_tag, 'Keychain transaction sent: $txHash');
      return txHash;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error sending keychain transaction: $e');
      return null;
    }
  }

  /// Send ERC20 tokens from a keychain wallet (EOA).
  /// Encodes transfer(address,uint256) calldata as a direct contract call.
  ///
  /// Multi-chain: by default this sends the OX token on chain 4489 via the
  /// global [PublicOS.web3Client] (back-compat). To send a different token on
  /// another chain, pass a [client] built against that chain's RPC, the
  /// [chainId], and the [tokenAddress]. [amount] is always in the token's raw
  /// smallest units — the caller scales by the token's decimals before calling.
  /// (Safe/group wallets cannot go multi-chain — see [PublicOSSafe.sendTokenFromSafe].)
  ///
  /// Set [native] to send the chain's NATIVE gas token (ETH / POL / xDAI) — a
  /// plain value transfer to [to], no ERC-20 calldata, [tokenAddress] ignored.
  static Future<String?> sendTokenFromKeychain({
    required String privateKeyHex,
    required EthereumAddress to,
    required BigInt amount,
    Web3Client? client,
    int? chainId,
    EthereumAddress? tokenAddress,
    bool native = false,
  }) async {
    try {
      final web3 = client ?? PublicOS.web3Client;
      final targetChainId = chainId ?? PublicOS.CHAIN_ID;
      final credentials = EthPrivateKey.fromHex(privateKeyHex);

      final Transaction tx;
      if (native) {
        // Native value transfer (ETH/POL/xDAI): to = recipient, value = amount.
        Log.d(_tag,
            'Sending NATIVE transfer from keychain to ${to.eip55With0x} (chain $targetChainId)');
        tx = Transaction(to: to, value: EtherAmount.inWei(amount));
      } else {
        final token = tokenAddress ?? publicOSTokenAddress!;
        Log.d(_tag,
            'Sending token transfer from keychain to ${to.eip55With0x} (chain $targetChainId, token ${token.eip55With0x})');
        // Encode ERC20 transfer(address,uint256) — selector 0xa9059cbb
        final toHex = to.without0x.padLeft(64, '0');
        final amountHex = amount.toRadixString(16).padLeft(64, '0');
        final data = _hexToBytes('a9059cbb$toHex$amountHex');
        tx = Transaction(to: token, value: EtherAmount.zero(), data: data);
      }

      final txHash =
          await web3.sendTransaction(credentials, tx, chainId: targetChainId);
      Log.i(_tag, 'Token transfer sent: $txHash');
      return txHash;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error sending token transfer from keychain: $e');
      return null;
    }
  }

  //insert function to get an address eth balance
  static Future<EtherAmount> getEthBalance(String address) async {
    try {
      return await Future.any([
        PublicOS.web3Client.getBalance(
          EthereumAddress.fromHex(address),
        ),
        Future.delayed(const Duration(seconds: 5)).then((_) => throw TimeoutException('Request timed out for getEthBalance for $address')),
      ]);
    } on TimeoutException catch (e, s) {
      Log.w(_tag, 'TimeoutException in getEthBalance for $address. Attempting to switch RPC and retry. Error: $e');
      bool switched = await PublicOSBsp.connectToAvailableRPC();
      if (switched) {
        Log.i(_tag, 'Switched RPC successfully for getEthBalance. Retrying operation for $address...');
        try {
          return await Future.any([
            PublicOS.web3Client.getBalance(
              EthereumAddress.fromHex(address),
            ),
            Future.delayed(const Duration(seconds: 5)).then((_) => throw TimeoutException('Retry timed out for getEthBalance for $address')),
          ]);
        } catch (retryException) {
          Log.e(_tag, 'Exception during retry of getEthBalance for $address after RPC switch: $retryException');
          PublicOS.lastError = retryException.toString();
          rethrow;
        }
      } else {
        Log.e(_tag, 'Failed to switch RPC for getEthBalance for $address. Rethrowing original TimeoutException.');
        PublicOS.lastError = e.toString();
        rethrow;
      }
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error in getEthBalance for $address: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // RPC MANAGEMENT (merged from publicos_rpc.dart)
  // ==========================================================================

  // =========================================================================
  // CUSTOM RPC SERVER CRUD
  // =========================================================================

  /// Add a custom RPC server for the current user.
  /// Tests connectivity before saving. Returns null if URL is unreachable.
  static Future<RpcServer?> addRpcServer(
    String url, {
    String? name,
  }) async {
    try {
      if (PublicOS.sessionBlockchainAddress == null) {
        Log.w(_tag, 'Cannot add RPC server: no authenticated user');
        return null;
      }

      // Test connectivity first
      if (!await PublicOS.testRpcUrl(url)) {
        Log.w(_tag, 'RPC server unreachable: $url');
        return null;
      }

      final sessionAddr = PublicOS.sessionBlockchainAddress!;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check if already exists
      final existing =
          await PublicOS.database.getRpcServersForSession(sessionAddr);
      final alreadyExists = existing.any((r) => r.rpcUrl == url);
      if (alreadyExists) {
        Log.d(_tag, 'RPC server already exists: $url');
        return existing.firstWhere((r) => r.rpcUrl == url);
      }

      final id = await PublicOS.database.upsertRpcServer(
        RpcServersCompanion(
          rpcUrl: Value(url),
          name: Value(name),
          isDefault: Value(existing.isEmpty), // first one becomes default
          sessionAddress: Value(sessionAddr),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      Log.i(_tag, 'Added custom RPC server: $url (ID: $id)');

      return RpcServer(
        id: id,
        rpcUrl: url,
        name: name,
        isDefault: existing.isEmpty,
        sessionAddress: sessionAddr,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      Log.e(_tag, 'Error adding RPC server: $e');
      return null;
    }
  }

  /// Get all custom RPC servers for the current user.
  static Future<List<RpcServer>> getRpcServers() async {
    try {
      if (PublicOS.sessionBlockchainAddress == null) return [];
      return await PublicOS.database
          .getRpcServersForSession(PublicOS.sessionBlockchainAddress!);
    } catch (e) {
      Log.e(_tag, 'Error getting RPC servers: $e');
      return [];
    }
  }

  /// Remove a custom RPC server. If it was the active endpoint, falls back.
  static Future<bool> removeRpcServer(int id) async {
    try {
      if (PublicOS.sessionBlockchainAddress == null) return false;

      // Check if this is the currently active endpoint
      final servers = await getRpcServers();
      final server = servers.where((s) => s.id == id).firstOrNull;

      final deleted = await PublicOS.database
          .deleteRpcServerById(id, PublicOS.sessionBlockchainAddress!);

      if (deleted > 0 &&
          server != null &&
          PublicOS.activeRpcUrl == server.rpcUrl) {
        // Was active — fall back to BSP or public
        await _fallbackRpc();
      }

      Log.i(_tag, 'Removed custom RPC server ID: $id');
      return deleted > 0;
    } catch (e) {
      Log.e(_tag, 'Error removing RPC server: $e');
      return false;
    }
  }

  // =========================================================================
  // BSP RPC RESOLUTION
  // =========================================================================

  /// Resolve the BSP RPC URL for the current user's active BSP subscription.
  /// Checks the BSP's main url field first, then the 'rpc-url' pointer.
  static Future<({String slug, String title, String rpcUrl})?> getBSPRpcInfo() async {
    try {
      final address = PublicOS.myPublicosAddress != null ? EthereumAddress.fromHex(PublicOS.myPublicosAddress!) : null;
      if (address == null) return null;

      // 1. Get active BSP slug for this account. Under the domain-rights economy
      // BSP assignment lives on the subs_v2 SubsMemory (slugOf, axis 0).
      final slug = await PublicOSBsp.subsMemoryContract.slugOf((axis: BigInt.zero, a: address));
      if (slug.isEmpty) return null;

      // 2. Get BSP details from registry — url is at index 3
      final bspData = await PublicOSBsp.bspRegistryMemoryContract.getBSPBySlug(
        (slug: slug),
      );
      final exists = bspData[0] as bool;
      if (!exists) return null;

      final title = bspData[2] as String;
      final mainUrl = bspData[3] as String;

      // 3. Use main url field first; fall back to 'rpc-url' pointer
      String? rpcUrl = mainUrl.isNotEmpty ? mainUrl : null;

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
        } catch (e) {
          Log.d(_tag, 'BSP pointer lookup failed: $e');
        }
      }

      if (rpcUrl == null || rpcUrl.isEmpty) {
        Log.d(_tag, 'BSP "$slug" has no RPC URL (no url field, no rpc-url pointer)');
        return null;
      }

      return (slug: slug, title: title, rpcUrl: rpcUrl);
    } catch (e) {
      Log.d(_tag, 'BSP RPC resolution failed: $e');
      return null;
    }
  }

  // =========================================================================
  // PROVIDER REGISTRATION ALLOWLIST
  //
  // Each registry (BSP, SSP) can be invite-only: only listed owner accounts
  // pass its registration doors. Root (the root org's Safe) or an admin sets it.
  // Returns null when the read fails, which includes a chain whose registries
  // predate the allowlist; callers treat null as "unknown" and keep today's
  // REGISTER button (the transaction is the final word either way).
  // =========================================================================

  /// Whether [account] may register a BSP under the registry's allowlist.
  /// The ban, citizenship and the operator agreement are separate gates.
  static Future<bool?> canRegisterBsp(EthereumAddress account) async {
    try {
      return await bspRegistryManagerContract.isRegistrationAllowed((account: account));
    } catch (e) {
      Log.d(_tag, 'BSP allowlist read failed: $e');
      return null;
    }
  }

  /// Whether [account] may register an SSP under the registry's allowlist.
  static Future<bool?> canRegisterSsp(EthereumAddress account) async {
    try {
      return await socialServerRegistryManagerContract.isRegistrationAllowed((account: account));
    } catch (e) {
      Log.d(_tag, 'SSP allowlist read failed: $e');
      return null;
    }
  }

  // =========================================================================
  // ACTIVE RPC CACHE (via SecureStorage, per account)
  //
  // One JSON blob per session: {"endpoint": "...", "source": "bsp" | "custom"}
  // — replaces the prior {cached_bsp_rpc, selected_rpc_url, selected_rpc_source}
  // trio. Public fallback is NEVER cached: when the active source is 'public'
  // (or on fallthrough), the cache is cleared instead of written. A source-less
  // URL can't exist in this shape, so step 1 of upgradeRpcPostAuth can branch
  // on source to decide whether it needs chain verification (for 'bsp') or can
  // trust the entry at face value (for 'custom').
  // =========================================================================

  static String _activeRpcKey(String sessionAddr) => 'active_rpc_$sessionAddr';

  /// Read the cached active RPC selection for the current account.
  /// Returns null when nothing is cached (fresh install / post-logout / after
  /// a fallthrough to public fallback).
  static Future<({String endpoint, String source})?> getCachedActiveRpc() async {
    if (PublicOS.sessionBlockchainAddress == null) return null;
    final raw = await PublicOS.secureStorage
        .read(key: _activeRpcKey(PublicOS.sessionBlockchainAddress!));
    if (raw == null || raw.isEmpty) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final endpoint = j['endpoint'] as String?;
      final source = j['source'] as String?;
      if (endpoint == null || endpoint.isEmpty) return null;
      if (source != 'bsp' && source != 'custom') return null;
      return (endpoint: endpoint, source: source!);
    } catch (_) {
      return null;
    }
  }

  /// Write the cached active RPC selection for the current account.
  /// [source] must be 'bsp' or 'custom' — public fallback must use
  /// [clearCachedActiveRpc] instead (the cache never represents fallback).
  static Future<void> setCachedActiveRpc(String endpoint, String source) async {
    if (PublicOS.sessionBlockchainAddress == null) return;
    if (source != 'bsp' && source != 'custom') {
      Log.w(_tag, 'setCachedActiveRpc called with unexpected source="$source" — '
          'ignoring. Use clearCachedActiveRpc() to express "no selection".');
      return;
    }
    final blob = jsonEncode({'endpoint': endpoint, 'source': source});
    await PublicOS.secureStorage.write(
      key: _activeRpcKey(PublicOS.sessionBlockchainAddress!),
      value: blob,
    );
  }

  /// Clear the cached active RPC selection. Used when the user falls back to
  /// the public node, when a cached 'bsp' entry's subscription is detected
  /// as gone, or during sign-out flows.
  static Future<void> clearCachedActiveRpc() async {
    if (PublicOS.sessionBlockchainAddress == null) return;
    await PublicOS.secureStorage
        .delete(key: _activeRpcKey(PublicOS.sessionBlockchainAddress!));
  }

  // =========================================================================
  // ENDPOINT LIST BUILDER (for UI)
  // =========================================================================

  /// Build the complete RPC endpoint list for display in the BSP screen.
  /// Returns: [BSP entry (if subscribed), custom entries, public node].
  static Future<List<RpcEndpointEntry>> buildRpcEndpointList() async {
    final entries = <RpcEndpointEntry>[];

    // 1. BSP subscription entry (if subscribed)
    try {
      final bspInfo = await getBSPRpcInfo();
      if (bspInfo != null) {
        entries.add(RpcEndpointEntry(
          label: bspInfo.title.isNotEmpty ? bspInfo.title : bspInfo.slug,
          url: bspInfo.rpcUrl,
          source: 'bsp',
          bspSlug: bspInfo.slug,
          isActive: PublicOS.activeRpcUrl == bspInfo.rpcUrl,
        ));
      }
    } catch (e) {
      Log.d(_tag, 'BSP info unavailable for endpoint list: $e');
    }

    // 2. Custom entries
    final customRpcs = await getRpcServers();
    for (final rpc in customRpcs) {
      // Skip if same URL as BSP (avoid duplicates)
      if (entries.any((e) => e.url == rpc.rpcUrl)) continue;
      entries.add(RpcEndpointEntry(
        label: rpc.name ?? rpc.rpcUrl,
        url: rpc.rpcUrl,
        source: 'custom',
        rpcServerId: rpc.id,
        isActive: PublicOS.activeRpcUrl == rpc.rpcUrl,
      ));
    }

    // 3. Public node (always present, non-removable)
    if (!entries.any((e) => e.url == PublicOS.PUBLIC_RPC_URL)) {
      entries.add(RpcEndpointEntry(
        label: 'Public Node',
        url: PublicOS.PUBLIC_RPC_URL,
        source: 'public',
        isActive: PublicOS.activeRpcUrl == PublicOS.PUBLIC_RPC_URL,
      ));
    }

    return entries;
  }

  /// Manually switch to a specific RPC endpoint. Tests connection first.
  /// Persists the selection so it's restored on next launch.
  /// Returns true if switch was successful.
  ///
  /// [source] must be one of 'bsp' / 'custom' / 'public'. 'public' clears
  /// the cache (fallback is never cached); the other two write a unified
  /// {endpoint, source} JSON blob via [setCachedActiveRpc].
  static Future<bool> switchToRpcEndpoint(String url, String source) async {
    if (await PublicOS.testRpcUrl(url)) {
      PublicOS.switchWeb3Client(url, source);

      if (source == 'public') {
        await clearCachedActiveRpc();
      } else {
        await setCachedActiveRpc(url, source);
      }

      Log.i(_tag, 'Switched to RPC: $url ($source)');
      return true;
    }
    Log.w(_tag, 'Cannot switch — RPC unreachable: $url');
    return false;
  }

  // =========================================================================
  // INTERNAL HELPERS
  // =========================================================================

  /// Fall back to best available RPC after removing the active one.
  static Future<void> _fallbackRpc() async {
    // Try BSP first
    final bspInfo = await getBSPRpcInfo();
    if (bspInfo != null && await PublicOS.testRpcUrl(bspInfo.rpcUrl)) {
      PublicOS.switchWeb3Client(bspInfo.rpcUrl, 'bsp');
      return;
    }

    // Try custom RPCs
    final servers = await getRpcServers();
    for (final s in servers) {
      if (await PublicOS.testRpcUrl(s.rpcUrl)) {
        PublicOS.switchWeb3Client(s.rpcUrl, 'custom');
        return;
      }
    }

    // Fall back to public
    PublicOS.switchWeb3Client(PublicOS.PUBLIC_RPC_URL, 'public');
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  /// Convert a hex string (with or without 0x prefix) to bytes.
  /// Used by module type hash initialization.
  static Uint8List _hexToBytes(String hex) {
    final h = hex.startsWith('0x') ? hex.substring(2) : hex;
    final result = Uint8List(h.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(h.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }
}
