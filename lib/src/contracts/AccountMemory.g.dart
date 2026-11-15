// @dart=3.0
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:web3dart/web3dart.dart' as _i1;
import 'package:wallet/wallet.dart' as _i2;
import 'dart:typed_data' as _i3;

final _contractAbi = _i1.ContractAbi.fromJson(
  '[{"inputs":[{"internalType":"address","name":"_moduleRegistryAddress","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[],"name":"AdminCapReached","type":"error"},{"inputs":[],"name":"AlreadyAdmin","type":"error"},{"inputs":[],"name":"InvalidAdmin","type":"error"},{"inputs":[],"name":"NotAdmin","type":"error"},{"inputs":[],"name":"NotAuthorized","type":"error"},{"inputs":[],"name":"RootNotResolvable","type":"error"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"admin","type":"address"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"AdminAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"admin","type":"address"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"AdminRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bool","name":"on","type":"bool"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"InheritanceSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bool","name":"paused","type":"bool"}],"name":"Memory_AccountCreationPaused","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":false,"internalType":"string","name":"displayName","type":"string"},{"indexed":false,"internalType":"bool","name":"isOrg","type":"bool"}],"name":"Memory_AccountInitialized","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":false,"internalType":"bool","name":"suspended","type":"bool"}],"name":"Memory_AccountSuspensionSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newValue","type":"uint256"}],"name":"Memory_CitizenOrgCreationCooldownSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":false,"internalType":"string","name":"newDisplayName","type":"string"}],"name":"Memory_DisplayNameSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint8","name":"newValue","type":"uint8"}],"name":"Memory_FreeSubdomainTierSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newValue","type":"uint256"}],"name":"Memory_MaxRecordsPerAccountSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newValue","type":"uint256"}],"name":"Memory_MaxSessionsPerAccountSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint8","name":"newValue","type":"uint8"}],"name":"Memory_MaxSubdomainDepthSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint16","name":"newValue","type":"uint16"}],"name":"Memory_MaxSubdomainsPerCitizenSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint16","name":"newValue","type":"uint16"}],"name":"Memory_MaxSubdomainsPerPrivateSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"uint256","name":"until","type":"uint256"}],"name":"Memory_MintBlockedUntilSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newValue","type":"uint256"}],"name":"Memory_NonCitizenOrgCreationCooldownSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"creator","type":"address"},{"indexed":false,"internalType":"uint256","name":"timestamp","type":"uint256"}],"name":"Memory_OrgCreationRecorded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":true,"internalType":"address","name":"contactAddress","type":"address"}],"name":"Memory_RecoveryContactAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":true,"internalType":"address","name":"contactAddress","type":"address"}],"name":"Memory_RecoveryContactRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":false,"internalType":"uint256","name":"previousContactCount","type":"uint256"}],"name":"Memory_RecoveryContactsCleared","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":false,"internalType":"uint256","name":"newThreshold","type":"uint256"}],"name":"Memory_RecoveryThresholdSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"keyHash","type":"bytes32"},{"indexed":false,"internalType":"string","name":"key","type":"string"}],"name":"Memory_ReservedRecordKeyAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"keyHash","type":"bytes32"},{"indexed":false,"internalType":"string","name":"key","type":"string"}],"name":"Memory_ReservedRecordKeyRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":true,"internalType":"address","name":"sessionAddress","type":"address"}],"name":"Memory_SessionAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":true,"internalType":"address","name":"sessionAddress","type":"address"},{"indexed":false,"internalType":"uint48","name":"oldUntil","type":"uint48"},{"indexed":false,"internalType":"uint48","name":"newUntil","type":"uint48"}],"name":"Memory_SessionExpirySet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":true,"internalType":"address","name":"sessionAddress","type":"address"}],"name":"Memory_SessionRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":true,"internalType":"address","name":"newSoleSession","type":"address"},{"indexed":false,"internalType":"uint256","name":"previousSessionCount","type":"uint256"}],"name":"Memory_SessionReseeded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"parent","type":"address"},{"indexed":true,"internalType":"address","name":"subAccount","type":"address"},{"indexed":false,"internalType":"string","name":"slug","type":"string"}],"name":"Memory_SubdomainCreated","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newValue","type":"uint256"}],"name":"Memory_SubdomainCreationBurnSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"parent","type":"address"},{"indexed":true,"internalType":"address","name":"subAccount","type":"address"},{"indexed":false,"internalType":"string","name":"slug","type":"string"}],"name":"Memory_SubdomainDeleted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"parent","type":"address"},{"indexed":true,"internalType":"address","name":"subAccount","type":"address"},{"indexed":false,"internalType":"string","name":"oldSlug","type":"string"},{"indexed":false,"internalType":"string","name":"newSlug","type":"string"}],"name":"Memory_SubdomainRenamed","type":"event"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"accountAddressToDisplayName","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"accountCreationPaused","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"accountExists","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"accountRecoveryThresholds","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"accountSuspended","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"addAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"},{"internalType":"address","name":"contactToAdd","type":"address"}],"name":"addRecoveryContactData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"key","type":"string"}],"name":"addReservedRecordKey","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"},{"internalType":"address","name":"sessionToAdd","type":"address"},{"internalType":"uint48","name":"until","type":"uint48"}],"name":"addSessionData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"admins","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"},{"internalType":"string","name":"newDisplayName","type":"string"}],"name":"applyNameData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"citizenOrgCreationCooldown","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"clearPendingReset","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"}],"name":"clearRecoveryContactsData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"subAccount","type":"address"}],"name":"clearSubdomainData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newSession","type":"address"}],"name":"consentConsumed","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"freeSubdomainTier","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"displayName","type":"string"}],"name":"getAccountAddressByDisplayName","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"displayNameHash","type":"bytes32"}],"name":"getAccountAddressByDisplayNameHash","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"}],"name":"getAccountExists","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"}],"name":"getAccountOrSubdomainExists","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"}],"name":"getAccountSessions","outputs":[{"internalType":"address[]","name":"active","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"}],"name":"getAccountSuspended","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"parent","type":"address"}],"name":"getDirectSubdomainCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"}],"name":"getDisplayName","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"acc","type":"address"}],"name":"getEffectiveAccount","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"}],"name":"getIsOrgAccount","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"getPendingReset","outputs":[{"components":[{"internalType":"address","name":"newSoleSession","type":"address"},{"internalType":"uint64","name":"announcedAt","type":"uint64"},{"internalType":"uint64","name":"landsAt","type":"uint64"},{"internalType":"bool","name":"extended","type":"bool"}],"internalType":"struct IAccountMemory.PendingReset","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"}],"name":"getRecoveryDetails","outputs":[{"internalType":"address[]","name":"contacts","type":"address[]"},{"internalType":"uint256","name":"threshold","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"offset","type":"uint256"},{"internalType":"uint256","name":"limit","type":"uint256"}],"name":"getReservedRecordKeys","outputs":[{"internalType":"string[]","name":"keys","type":"string[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"sessionAddress","type":"address"}],"name":"getSessionAccount","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"}],"name":"getSessionCounts","outputs":[{"internalType":"uint256","name":"active","type":"uint256"},{"internalType":"uint256","name":"permanent","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"session","type":"address"}],"name":"getSessionTenure","outputs":[{"components":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint48","name":"since","type":"uint48"},{"internalType":"uint48","name":"until","type":"uint48"}],"internalType":"struct IAccountMemory.SessionTenure","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"parent","type":"address"},{"internalType":"uint256","name":"offset","type":"uint256"},{"internalType":"uint256","name":"limit","type":"uint256"}],"name":"getSubdomainsByParent","outputs":[{"internalType":"address[]","name":"page","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"individualCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"inheritanceOn","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"},{"internalType":"string","name":"displayName","type":"string"},{"internalType":"address","name":"firstSessionOrZero","type":"address"},{"internalType":"bool","name":"isOrg","type":"bool"},{"internalType":"address","name":"minterAccountOrZero","type":"address"}],"name":"initializeAccountData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"subAccount","type":"address"},{"internalType":"address","name":"parentAcc","type":"address"},{"internalType":"address","name":"topLevelAcc","type":"address"},{"internalType":"string","name":"slug","type":"string"}],"name":"initializeSubdomainData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"isAdmin","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"isOrgAccount","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"key","type":"string"}],"name":"isReservedRecordKey","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"lastOrgCreationAt","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"maxRecordsPerAccount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"maxSessionsPerAccount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"maxSubdomainDepth","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"maxSubdomainsPerCitizen","outputs":[{"internalType":"uint16","name":"","type":"uint16"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"maxSubdomainsPerPrivate","outputs":[{"internalType":"uint16","name":"","type":"uint16"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"mintBlockedUntil","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleRegistry","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleType","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"nonCitizenOrgCreationCooldown","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"orgCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"parentAccount","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"creator","type":"address"}],"name":"recordOrgCreation","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"removeAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"},{"internalType":"address","name":"contactToRemove","type":"address"}],"name":"removeRecoveryContactData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"key","type":"string"}],"name":"removeReservedRecordKey","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"},{"internalType":"address","name":"sessionToRemove","type":"address"}],"name":"removeSessionData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"subAccount","type":"address"},{"internalType":"string","name":"newSlug","type":"string"}],"name":"renameSubdomainData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"},{"internalType":"address","name":"newSoleSession","type":"address"}],"name":"reseedSessionData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"name":"reservedRecordKey","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"sessionToAccountAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bool","name":"paused","type":"bool"}],"name":"setAccountCreationPaused","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"},{"internalType":"bool","name":"suspended","type":"bool"}],"name":"setAccountSuspendedData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"newValue","type":"uint256"}],"name":"setCitizenOrgCreationCooldown","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"},{"internalType":"string","name":"oldDisplayName","type":"string"},{"internalType":"string","name":"newDisplayName","type":"string"}],"name":"setDisplayNameData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint8","name":"newValue","type":"uint8"}],"name":"setFreeSubdomainTier","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"on","type":"bool"}],"name":"setInheritance","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"newValue","type":"uint256"}],"name":"setMaxRecordsPerAccount","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"newValue","type":"uint256"}],"name":"setMaxSessionsPerAccount","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint8","name":"newValue","type":"uint8"}],"name":"setMaxSubdomainDepth","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint16","name":"newValue","type":"uint16"}],"name":"setMaxSubdomainsPerCitizen","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint16","name":"newValue","type":"uint16"}],"name":"setMaxSubdomainsPerPrivate","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"until","type":"uint256"}],"name":"setMintBlockedUntil","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"newValue","type":"uint256"}],"name":"setNonCitizenOrgCreationCooldown","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"components":[{"internalType":"address","name":"newSoleSession","type":"address"},{"internalType":"uint64","name":"announcedAt","type":"uint64"},{"internalType":"uint64","name":"landsAt","type":"uint64"},{"internalType":"bool","name":"extended","type":"bool"}],"internalType":"struct IAccountMemory.PendingReset","name":"p","type":"tuple"}],"name":"setPendingResetData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"},{"internalType":"uint256","name":"newThreshold","type":"uint256"}],"name":"setRecoveryThresholdData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"},{"internalType":"address","name":"session","type":"address"},{"internalType":"uint48","name":"until","type":"uint48"}],"name":"setSessionExpiryData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"newValue","type":"uint256"}],"name":"setSubdomainCreationBurn","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"subdomainCount","outputs":[{"internalType":"uint16","name":"","type":"uint16"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"subdomainCreationBurn","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"bytes32","name":"","type":"bytes32"}],"name":"subdomainOf","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"subdomainSlug","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"topLevelAccountOf","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"session","type":"address"},{"internalType":"address","name":"accountAddress","type":"address"},{"internalType":"uint256","name":"timestamp","type":"uint256"}],"name":"wasSessionAt","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"}]',
  'AccountMemory',
);

class AccountMemory extends _i1.GeneratedContract {
  AccountMemory({
    required _i2.EthereumAddress address,
    required _i1.Web3Client client,
    int? chainId,
  }) : super(
          _i1.DeployedContract(
            _contractAbi,
            address,
          ),
          client,
          chainId,
        );

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<String> accountAddressToDisplayName(
    ({_i2.EthereumAddress arg0}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '5c3069e7'));
    final params = [args.arg0];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as String);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> accountCreationPaused(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, 'f99c41bd'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> accountExists(
    ({_i2.EthereumAddress arg0}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, '75cd51ed'));
    final params = [args.arg0];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> accountRecoveryThresholds(
    ({_i2.EthereumAddress arg0}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, '86fc3c56'));
    final params = [args.arg0];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> accountSuspended(
    ({_i2.EthereumAddress arg0}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, 'e4838f0f'));
    final params = [args.arg0];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> addAdmin(
    ({_i2.EthereumAddress account}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, '70480275'));
    final params = [args.account];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> addRecoveryContactData(
    ({_i2.EthereumAddress accountAddress, _i2.EthereumAddress contactToAdd}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, '18125934'));
    final params = [
      args.accountAddress,
      args.contactToAdd,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> addReservedRecordKey(
    ({String key}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, '8c9ddd56'));
    final params = [args.key];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> addSessionData(
    ({_i2.EthereumAddress accountAddress, _i2.EthereumAddress sessionToAdd, BigInt until}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[9];
    assert(checkSignature(function, '6e5986df'));
    final params = [
      args.accountAddress,
      args.sessionToAdd,
      args.until,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<_i2.EthereumAddress>> admins(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[10];
    assert(checkSignature(function, 'a5de3619'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<_i2.EthereumAddress>();
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> applyNameData(
    ({_i2.EthereumAddress accountAddress, String newDisplayName}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[11];
    assert(checkSignature(function, 'f10f8737'));
    final params = [
      args.accountAddress,
      args.newDisplayName,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> citizenOrgCreationCooldown(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[12];
    assert(checkSignature(function, '59245a77'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> clearPendingReset(
    ({_i2.EthereumAddress account}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[13];
    assert(checkSignature(function, 'dc2e1011'));
    final params = [args.account];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> clearRecoveryContactsData(
    ({_i2.EthereumAddress accountAddress}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[14];
    assert(checkSignature(function, '44bc1aad'));
    final params = [args.accountAddress];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> clearSubdomainData(
    ({_i2.EthereumAddress subAccount}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[15];
    assert(checkSignature(function, 'c54f8f2e'));
    final params = [args.subAccount];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> consentConsumed(
    ({_i2.EthereumAddress newSession}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[16];
    assert(checkSignature(function, 'ddcb00b6'));
    final params = [args.newSession];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> freeSubdomainTier(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[17];
    assert(checkSignature(function, '3e728a0f'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i2.EthereumAddress> getAccountAddressByDisplayName(
    ({String displayName}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[18];
    assert(checkSignature(function, 'cd8e9f6d'));
    final params = [args.displayName];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i2.EthereumAddress);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i2.EthereumAddress> getAccountAddressByDisplayNameHash(
    ({_i3.Uint8List displayNameHash}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[19];
    assert(checkSignature(function, 'c2d21d95'));
    final params = [args.displayNameHash];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i2.EthereumAddress);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> getAccountExists(
    ({_i2.EthereumAddress accountAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[20];
    assert(checkSignature(function, '6a83fe64'));
    final params = [args.accountAddress];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> getAccountOrSubdomainExists(
    ({_i2.EthereumAddress accountAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[21];
    assert(checkSignature(function, '4498463b'));
    final params = [args.accountAddress];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<_i2.EthereumAddress>> getAccountSessions(
    ({_i2.EthereumAddress accountAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[22];
    assert(checkSignature(function, 'c5afe04a'));
    final params = [args.accountAddress];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<_i2.EthereumAddress>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> getAccountSuspended(
    ({_i2.EthereumAddress accountAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[23];
    assert(checkSignature(function, '0e2fb3ac'));
    final params = [args.accountAddress];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> getDirectSubdomainCount(
    ({_i2.EthereumAddress parent}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[24];
    assert(checkSignature(function, '255fb08c'));
    final params = [args.parent];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<String> getDisplayName(
    ({_i2.EthereumAddress accountAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[25];
    assert(checkSignature(function, '1042876d'));
    final params = [args.accountAddress];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as String);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i2.EthereumAddress> getEffectiveAccount(
    ({_i2.EthereumAddress acc}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[26];
    assert(checkSignature(function, '55a7d7a5'));
    final params = [args.acc];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i2.EthereumAddress);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> getIsOrgAccount(
    ({_i2.EthereumAddress accountAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[27];
    assert(checkSignature(function, '1fce6bcc'));
    final params = [args.accountAddress];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<dynamic> getPendingReset(
    ({_i2.EthereumAddress account}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[28];
    assert(checkSignature(function, '6121fd7e'));
    final params = [args.account];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as dynamic);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<GetRecoveryDetails> getRecoveryDetails(
    ({_i2.EthereumAddress accountAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[29];
    assert(checkSignature(function, '409920d5'));
    final params = [args.accountAddress];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return GetRecoveryDetails(response);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<String>> getReservedRecordKeys(
    ({BigInt offset, BigInt limit}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[30];
    assert(checkSignature(function, '473a5cd1'));
    final params = [
      args.offset,
      args.limit,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<String>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i2.EthereumAddress> getSessionAccount(
    ({_i2.EthereumAddress sessionAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[31];
    assert(checkSignature(function, '3e99c4a2'));
    final params = [args.sessionAddress];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i2.EthereumAddress);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<GetSessionCounts> getSessionCounts(
    ({_i2.EthereumAddress accountAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[32];
    assert(checkSignature(function, '2dae6355'));
    final params = [args.accountAddress];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return GetSessionCounts(response);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<dynamic> getSessionTenure(
    ({_i2.EthereumAddress session}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[33];
    assert(checkSignature(function, 'fd99dd30'));
    final params = [args.session];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as dynamic);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<_i2.EthereumAddress>> getSubdomainsByParent(
    ({_i2.EthereumAddress parent, BigInt offset, BigInt limit}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[34];
    assert(checkSignature(function, 'ea723011'));
    final params = [
      args.parent,
      args.offset,
      args.limit,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<_i2.EthereumAddress>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> individualCount(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[35];
    assert(checkSignature(function, '7b360965'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> inheritanceOn(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[36];
    assert(checkSignature(function, '84a5bada'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> initializeAccountData(
    ({_i2.EthereumAddress accountAddress, String displayName, _i2.EthereumAddress firstSessionOrZero, bool isOrg, _i2.EthereumAddress minterAccountOrZero}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[37];
    assert(checkSignature(function, 'd59b39a5'));
    final params = [
      args.accountAddress,
      args.displayName,
      args.firstSessionOrZero,
      args.isOrg,
      args.minterAccountOrZero,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> initializeSubdomainData(
    ({_i2.EthereumAddress subAccount, _i2.EthereumAddress parentAcc, _i2.EthereumAddress topLevelAcc, String slug}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[38];
    assert(checkSignature(function, '9a84bb26'));
    final params = [
      args.subAccount,
      args.parentAcc,
      args.topLevelAcc,
      args.slug,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> isAdmin(
    ({_i2.EthereumAddress account}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[39];
    assert(checkSignature(function, '24d7806c'));
    final params = [args.account];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> isOrgAccount(
    ({_i2.EthereumAddress arg0}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[40];
    assert(checkSignature(function, '1ed05916'));
    final params = [args.arg0];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> isReservedRecordKey(
    ({String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[41];
    assert(checkSignature(function, '496e5d4b'));
    final params = [args.key];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> lastOrgCreationAt(
    ({_i2.EthereumAddress arg0}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[42];
    assert(checkSignature(function, 'ab1bd6a7'));
    final params = [args.arg0];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> maxRecordsPerAccount(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[43];
    assert(checkSignature(function, 'c1e15d0f'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> maxSessionsPerAccount(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[44];
    assert(checkSignature(function, 'e7a4505f'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> maxSubdomainDepth(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[45];
    assert(checkSignature(function, '12f5a748'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> maxSubdomainsPerCitizen(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[46];
    assert(checkSignature(function, '922f9e8d'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> maxSubdomainsPerPrivate(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[47];
    assert(checkSignature(function, '91b14026'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> mintBlockedUntil(
    ({_i2.EthereumAddress account}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[48];
    assert(checkSignature(function, 'aa10ac4f'));
    final params = [args.account];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i2.EthereumAddress> moduleRegistry(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[49];
    assert(checkSignature(function, 'b95459e4'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i2.EthereumAddress);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i3.Uint8List> moduleType(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[50];
    assert(checkSignature(function, '6465e69f'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i3.Uint8List);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> nonCitizenOrgCreationCooldown(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[51];
    assert(checkSignature(function, '58ed2caf'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> orgCount(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[52];
    assert(checkSignature(function, 'd8106690'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i2.EthereumAddress> parentAccount(
    ({_i2.EthereumAddress arg0}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[53];
    assert(checkSignature(function, '40590a05'));
    final params = [args.arg0];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i2.EthereumAddress);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> recordOrgCreation(
    ({_i2.EthereumAddress creator}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[54];
    assert(checkSignature(function, '86328933'));
    final params = [args.creator];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> removeAdmin(
    ({_i2.EthereumAddress account}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[55];
    assert(checkSignature(function, '1785f53c'));
    final params = [args.account];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> removeRecoveryContactData(
    ({_i2.EthereumAddress accountAddress, _i2.EthereumAddress contactToRemove}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[56];
    assert(checkSignature(function, '9c576be9'));
    final params = [
      args.accountAddress,
      args.contactToRemove,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> removeReservedRecordKey(
    ({String key}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[57];
    assert(checkSignature(function, '852cbc46'));
    final params = [args.key];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> removeSessionData(
    ({_i2.EthereumAddress accountAddress, _i2.EthereumAddress sessionToRemove}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[58];
    assert(checkSignature(function, '9978efa2'));
    final params = [
      args.accountAddress,
      args.sessionToRemove,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> renameSubdomainData(
    ({_i2.EthereumAddress subAccount, String newSlug}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[59];
    assert(checkSignature(function, 'bfeeb423'));
    final params = [
      args.subAccount,
      args.newSlug,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> reseedSessionData(
    ({_i2.EthereumAddress accountAddress, _i2.EthereumAddress newSoleSession}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[60];
    assert(checkSignature(function, '254d1830'));
    final params = [
      args.accountAddress,
      args.newSoleSession,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> reservedRecordKey(
    ({_i3.Uint8List arg0}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[61];
    assert(checkSignature(function, 'fe68194a'));
    final params = [args.arg0];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i2.EthereumAddress> sessionToAccountAddress(
    ({_i2.EthereumAddress arg0}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[62];
    assert(checkSignature(function, 'c095e6a2'));
    final params = [args.arg0];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i2.EthereumAddress);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> setAccountCreationPaused(
    ({bool paused}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[63];
    assert(checkSignature(function, '50632e91'));
    final params = [args.paused];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> setAccountSuspendedData(
    ({_i2.EthereumAddress accountAddress, bool suspended}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[64];
    assert(checkSignature(function, 'a8991971'));
    final params = [
      args.accountAddress,
      args.suspended,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> setCitizenOrgCreationCooldown(
    ({BigInt newValue}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[65];
    assert(checkSignature(function, '9a6c2fbc'));
    final params = [args.newValue];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> setDisplayNameData(
    ({_i2.EthereumAddress accountAddress, String oldDisplayName, String newDisplayName}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[66];
    assert(checkSignature(function, '0708d4ba'));
    final params = [
      args.accountAddress,
      args.oldDisplayName,
      args.newDisplayName,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> setFreeSubdomainTier(
    ({BigInt newValue}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[67];
    assert(checkSignature(function, '3c9d2017'));
    final params = [args.newValue];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> setInheritance(
    ({bool on}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[68];
    assert(checkSignature(function, 'c5a66d2c'));
    final params = [args.on];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> setMaxRecordsPerAccount(
    ({BigInt newValue}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[69];
    assert(checkSignature(function, 'e75df9a0'));
    final params = [args.newValue];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> setMaxSessionsPerAccount(
    ({BigInt newValue}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[70];
    assert(checkSignature(function, '2d5514c7'));
    final params = [args.newValue];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> setMaxSubdomainDepth(
    ({BigInt newValue}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[71];
    assert(checkSignature(function, '67c42dce'));
    final params = [args.newValue];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> setMaxSubdomainsPerCitizen(
    ({BigInt newValue}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[72];
    assert(checkSignature(function, '8d8359ac'));
    final params = [args.newValue];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> setMaxSubdomainsPerPrivate(
    ({BigInt newValue}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[73];
    assert(checkSignature(function, 'df6471de'));
    final params = [args.newValue];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> setMintBlockedUntil(
    ({_i2.EthereumAddress account, BigInt until}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[74];
    assert(checkSignature(function, '35959b04'));
    final params = [
      args.account,
      args.until,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> setNonCitizenOrgCreationCooldown(
    ({BigInt newValue}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[75];
    assert(checkSignature(function, '418c7234'));
    final params = [args.newValue];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> setPendingResetData(
    ({_i2.EthereumAddress account, dynamic p}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[76];
    assert(checkSignature(function, '764dee76'));
    final params = [
      args.account,
      args.p,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> setRecoveryThresholdData(
    ({_i2.EthereumAddress accountAddress, BigInt newThreshold}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[77];
    assert(checkSignature(function, '76545280'));
    final params = [
      args.accountAddress,
      args.newThreshold,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> setSessionExpiryData(
    ({_i2.EthereumAddress accountAddress, _i2.EthereumAddress session, BigInt until}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[78];
    assert(checkSignature(function, '1e3bab37'));
    final params = [
      args.accountAddress,
      args.session,
      args.until,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> setSubdomainCreationBurn(
    ({BigInt newValue}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[79];
    assert(checkSignature(function, '57e2b794'));
    final params = [args.newValue];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> subdomainCount(
    ({_i2.EthereumAddress arg0}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[80];
    assert(checkSignature(function, '6b81e5d7'));
    final params = [args.arg0];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> subdomainCreationBurn(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[81];
    assert(checkSignature(function, 'b0d420ce'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i2.EthereumAddress> subdomainOf(
    ({_i2.EthereumAddress arg0, _i3.Uint8List arg1}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[82];
    assert(checkSignature(function, '9130ab12'));
    final params = [
      args.arg0,
      args.arg1,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i2.EthereumAddress);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<String> subdomainSlug(
    ({_i2.EthereumAddress arg0}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[83];
    assert(checkSignature(function, 'ede1d3a0'));
    final params = [args.arg0];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as String);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i2.EthereumAddress> topLevelAccountOf(
    ({_i2.EthereumAddress arg0}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[84];
    assert(checkSignature(function, '1664cd54'));
    final params = [args.arg0];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i2.EthereumAddress);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> wasSessionAt(
    ({_i2.EthereumAddress session, _i2.EthereumAddress accountAddress, BigInt timestamp}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[85];
    assert(checkSignature(function, '24317b71'));
    final params = [
      args.session,
      args.accountAddress,
      args.timestamp,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// Returns a live stream of all AdminAdded events emitted by this contract.
  Stream<AdminAdded> adminAddedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('AdminAdded');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return AdminAdded(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all AdminRemoved events emitted by this contract.
  Stream<AdminRemoved> adminRemovedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('AdminRemoved');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return AdminRemoved(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all InheritanceSet events emitted by this contract.
  Stream<InheritanceSet> inheritanceSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('InheritanceSet');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return InheritanceSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_AccountCreationPaused events emitted by this contract.
  Stream<Memory_AccountCreationPaused> memory_AccountCreationPausedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_AccountCreationPaused');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_AccountCreationPaused(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_AccountInitialized events emitted by this contract.
  Stream<Memory_AccountInitialized> memory_AccountInitializedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_AccountInitialized');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_AccountInitialized(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_AccountSuspensionSet events emitted by this contract.
  Stream<Memory_AccountSuspensionSet> memory_AccountSuspensionSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_AccountSuspensionSet');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_AccountSuspensionSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_CitizenOrgCreationCooldownSet events emitted by this contract.
  Stream<Memory_CitizenOrgCreationCooldownSet> memory_CitizenOrgCreationCooldownSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_CitizenOrgCreationCooldownSet');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_CitizenOrgCreationCooldownSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_DisplayNameSet events emitted by this contract.
  Stream<Memory_DisplayNameSet> memory_DisplayNameSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_DisplayNameSet');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_DisplayNameSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_FreeSubdomainTierSet events emitted by this contract.
  Stream<Memory_FreeSubdomainTierSet> memory_FreeSubdomainTierSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_FreeSubdomainTierSet');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_FreeSubdomainTierSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_MaxRecordsPerAccountSet events emitted by this contract.
  Stream<Memory_MaxRecordsPerAccountSet> memory_MaxRecordsPerAccountSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_MaxRecordsPerAccountSet');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_MaxRecordsPerAccountSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_MaxSessionsPerAccountSet events emitted by this contract.
  Stream<Memory_MaxSessionsPerAccountSet> memory_MaxSessionsPerAccountSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_MaxSessionsPerAccountSet');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_MaxSessionsPerAccountSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_MaxSubdomainDepthSet events emitted by this contract.
  Stream<Memory_MaxSubdomainDepthSet> memory_MaxSubdomainDepthSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_MaxSubdomainDepthSet');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_MaxSubdomainDepthSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_MaxSubdomainsPerCitizenSet events emitted by this contract.
  Stream<Memory_MaxSubdomainsPerCitizenSet> memory_MaxSubdomainsPerCitizenSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_MaxSubdomainsPerCitizenSet');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_MaxSubdomainsPerCitizenSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_MaxSubdomainsPerPrivateSet events emitted by this contract.
  Stream<Memory_MaxSubdomainsPerPrivateSet> memory_MaxSubdomainsPerPrivateSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_MaxSubdomainsPerPrivateSet');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_MaxSubdomainsPerPrivateSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_MintBlockedUntilSet events emitted by this contract.
  Stream<Memory_MintBlockedUntilSet> memory_MintBlockedUntilSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_MintBlockedUntilSet');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_MintBlockedUntilSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_NonCitizenOrgCreationCooldownSet events emitted by this contract.
  Stream<Memory_NonCitizenOrgCreationCooldownSet> memory_NonCitizenOrgCreationCooldownSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_NonCitizenOrgCreationCooldownSet');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_NonCitizenOrgCreationCooldownSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_OrgCreationRecorded events emitted by this contract.
  Stream<Memory_OrgCreationRecorded> memory_OrgCreationRecordedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_OrgCreationRecorded');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_OrgCreationRecorded(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_RecoveryContactAdded events emitted by this contract.
  Stream<Memory_RecoveryContactAdded> memory_RecoveryContactAddedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_RecoveryContactAdded');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_RecoveryContactAdded(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_RecoveryContactRemoved events emitted by this contract.
  Stream<Memory_RecoveryContactRemoved> memory_RecoveryContactRemovedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_RecoveryContactRemoved');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_RecoveryContactRemoved(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_RecoveryContactsCleared events emitted by this contract.
  Stream<Memory_RecoveryContactsCleared> memory_RecoveryContactsClearedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_RecoveryContactsCleared');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_RecoveryContactsCleared(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_RecoveryThresholdSet events emitted by this contract.
  Stream<Memory_RecoveryThresholdSet> memory_RecoveryThresholdSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_RecoveryThresholdSet');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_RecoveryThresholdSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_ReservedRecordKeyAdded events emitted by this contract.
  Stream<Memory_ReservedRecordKeyAdded> memory_ReservedRecordKeyAddedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_ReservedRecordKeyAdded');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_ReservedRecordKeyAdded(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_ReservedRecordKeyRemoved events emitted by this contract.
  Stream<Memory_ReservedRecordKeyRemoved> memory_ReservedRecordKeyRemovedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_ReservedRecordKeyRemoved');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_ReservedRecordKeyRemoved(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_SessionAdded events emitted by this contract.
  Stream<Memory_SessionAdded> memory_SessionAddedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_SessionAdded');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_SessionAdded(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_SessionExpirySet events emitted by this contract.
  Stream<Memory_SessionExpirySet> memory_SessionExpirySetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_SessionExpirySet');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_SessionExpirySet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_SessionRemoved events emitted by this contract.
  Stream<Memory_SessionRemoved> memory_SessionRemovedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_SessionRemoved');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_SessionRemoved(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_SessionReseeded events emitted by this contract.
  Stream<Memory_SessionReseeded> memory_SessionReseededEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_SessionReseeded');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_SessionReseeded(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_SubdomainCreated events emitted by this contract.
  Stream<Memory_SubdomainCreated> memory_SubdomainCreatedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_SubdomainCreated');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_SubdomainCreated(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_SubdomainCreationBurnSet events emitted by this contract.
  Stream<Memory_SubdomainCreationBurnSet> memory_SubdomainCreationBurnSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_SubdomainCreationBurnSet');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_SubdomainCreationBurnSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_SubdomainDeleted events emitted by this contract.
  Stream<Memory_SubdomainDeleted> memory_SubdomainDeletedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_SubdomainDeleted');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_SubdomainDeleted(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_SubdomainRenamed events emitted by this contract.
  Stream<Memory_SubdomainRenamed> memory_SubdomainRenamedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_SubdomainRenamed');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_SubdomainRenamed(
        decoded,
        result,
      );
    });
  }
}

class GetRecoveryDetails {
  GetRecoveryDetails(List<dynamic> response)
      : contacts = (response[0] as List<dynamic>).cast<_i2.EthereumAddress>(),
        threshold = (response[1] as BigInt);

  final List<_i2.EthereumAddress> contacts;

  final BigInt threshold;

}

class GetSessionCounts {
  GetSessionCounts(List<dynamic> response)
      : active = (response[0] as BigInt),
        permanent = (response[1] as BigInt);

  final BigInt active;

  final BigInt permanent;

}

class AdminAdded {
  AdminAdded(
    List<dynamic> response,
    this.event,
  )   : admin = (response[0] as _i2.EthereumAddress),
        by = (response[1] as _i2.EthereumAddress);

  final _i2.EthereumAddress admin;

  final _i2.EthereumAddress by;

  final _i1.FilterEvent event;
}

class AdminRemoved {
  AdminRemoved(
    List<dynamic> response,
    this.event,
  )   : admin = (response[0] as _i2.EthereumAddress),
        by = (response[1] as _i2.EthereumAddress);

  final _i2.EthereumAddress admin;

  final _i2.EthereumAddress by;

  final _i1.FilterEvent event;
}

class InheritanceSet {
  InheritanceSet(
    List<dynamic> response,
    this.event,
  )   : on = (response[0] as bool),
        by = (response[1] as _i2.EthereumAddress);

  final bool on;

  final _i2.EthereumAddress by;

  final _i1.FilterEvent event;
}

class Memory_AccountCreationPaused {
  Memory_AccountCreationPaused(
    List<dynamic> response,
    this.event,
  )   : paused = (response[0] as bool);

  final bool paused;

  final _i1.FilterEvent event;
}

class Memory_AccountInitialized {
  Memory_AccountInitialized(
    List<dynamic> response,
    this.event,
  )   : accountAddress = (response[0] as _i2.EthereumAddress),
        displayName = (response[1] as String),
        isOrg = (response[2] as bool);

  final _i2.EthereumAddress accountAddress;

  final String displayName;

  final bool isOrg;

  final _i1.FilterEvent event;
}

class Memory_AccountSuspensionSet {
  Memory_AccountSuspensionSet(
    List<dynamic> response,
    this.event,
  )   : accountAddress = (response[0] as _i2.EthereumAddress),
        suspended = (response[1] as bool);

  final _i2.EthereumAddress accountAddress;

  final bool suspended;

  final _i1.FilterEvent event;
}

class Memory_CitizenOrgCreationCooldownSet {
  Memory_CitizenOrgCreationCooldownSet(
    List<dynamic> response,
    this.event,
  )   : newValue = (response[0] as BigInt);

  final BigInt newValue;

  final _i1.FilterEvent event;
}

class Memory_DisplayNameSet {
  Memory_DisplayNameSet(
    List<dynamic> response,
    this.event,
  )   : accountAddress = (response[0] as _i2.EthereumAddress),
        newDisplayName = (response[1] as String);

  final _i2.EthereumAddress accountAddress;

  final String newDisplayName;

  final _i1.FilterEvent event;
}

class Memory_FreeSubdomainTierSet {
  Memory_FreeSubdomainTierSet(
    List<dynamic> response,
    this.event,
  )   : newValue = (response[0] as BigInt);

  final BigInt newValue;

  final _i1.FilterEvent event;
}

class Memory_MaxRecordsPerAccountSet {
  Memory_MaxRecordsPerAccountSet(
    List<dynamic> response,
    this.event,
  )   : newValue = (response[0] as BigInt);

  final BigInt newValue;

  final _i1.FilterEvent event;
}

class Memory_MaxSessionsPerAccountSet {
  Memory_MaxSessionsPerAccountSet(
    List<dynamic> response,
    this.event,
  )   : newValue = (response[0] as BigInt);

  final BigInt newValue;

  final _i1.FilterEvent event;
}

class Memory_MaxSubdomainDepthSet {
  Memory_MaxSubdomainDepthSet(
    List<dynamic> response,
    this.event,
  )   : newValue = (response[0] as BigInt);

  final BigInt newValue;

  final _i1.FilterEvent event;
}

class Memory_MaxSubdomainsPerCitizenSet {
  Memory_MaxSubdomainsPerCitizenSet(
    List<dynamic> response,
    this.event,
  )   : newValue = (response[0] as BigInt);

  final BigInt newValue;

  final _i1.FilterEvent event;
}

class Memory_MaxSubdomainsPerPrivateSet {
  Memory_MaxSubdomainsPerPrivateSet(
    List<dynamic> response,
    this.event,
  )   : newValue = (response[0] as BigInt);

  final BigInt newValue;

  final _i1.FilterEvent event;
}

class Memory_MintBlockedUntilSet {
  Memory_MintBlockedUntilSet(
    List<dynamic> response,
    this.event,
  )   : account = (response[0] as _i2.EthereumAddress),
        until = (response[1] as BigInt);

  final _i2.EthereumAddress account;

  final BigInt until;

  final _i1.FilterEvent event;
}

class Memory_NonCitizenOrgCreationCooldownSet {
  Memory_NonCitizenOrgCreationCooldownSet(
    List<dynamic> response,
    this.event,
  )   : newValue = (response[0] as BigInt);

  final BigInt newValue;

  final _i1.FilterEvent event;
}

class Memory_OrgCreationRecorded {
  Memory_OrgCreationRecorded(
    List<dynamic> response,
    this.event,
  )   : creator = (response[0] as _i2.EthereumAddress),
        timestamp = (response[1] as BigInt);

  final _i2.EthereumAddress creator;

  final BigInt timestamp;

  final _i1.FilterEvent event;
}

class Memory_RecoveryContactAdded {
  Memory_RecoveryContactAdded(
    List<dynamic> response,
    this.event,
  )   : accountAddress = (response[0] as _i2.EthereumAddress),
        contactAddress = (response[1] as _i2.EthereumAddress);

  final _i2.EthereumAddress accountAddress;

  final _i2.EthereumAddress contactAddress;

  final _i1.FilterEvent event;
}

class Memory_RecoveryContactRemoved {
  Memory_RecoveryContactRemoved(
    List<dynamic> response,
    this.event,
  )   : accountAddress = (response[0] as _i2.EthereumAddress),
        contactAddress = (response[1] as _i2.EthereumAddress);

  final _i2.EthereumAddress accountAddress;

  final _i2.EthereumAddress contactAddress;

  final _i1.FilterEvent event;
}

class Memory_RecoveryContactsCleared {
  Memory_RecoveryContactsCleared(
    List<dynamic> response,
    this.event,
  )   : accountAddress = (response[0] as _i2.EthereumAddress),
        previousContactCount = (response[1] as BigInt);

  final _i2.EthereumAddress accountAddress;

  final BigInt previousContactCount;

  final _i1.FilterEvent event;
}

class Memory_RecoveryThresholdSet {
  Memory_RecoveryThresholdSet(
    List<dynamic> response,
    this.event,
  )   : accountAddress = (response[0] as _i2.EthereumAddress),
        newThreshold = (response[1] as BigInt);

  final _i2.EthereumAddress accountAddress;

  final BigInt newThreshold;

  final _i1.FilterEvent event;
}

class Memory_ReservedRecordKeyAdded {
  Memory_ReservedRecordKeyAdded(
    List<dynamic> response,
    this.event,
  )   : keyHash = (response[0] as _i3.Uint8List),
        key = (response[1] as String);

  final _i3.Uint8List keyHash;

  final String key;

  final _i1.FilterEvent event;
}

class Memory_ReservedRecordKeyRemoved {
  Memory_ReservedRecordKeyRemoved(
    List<dynamic> response,
    this.event,
  )   : keyHash = (response[0] as _i3.Uint8List),
        key = (response[1] as String);

  final _i3.Uint8List keyHash;

  final String key;

  final _i1.FilterEvent event;
}

class Memory_SessionAdded {
  Memory_SessionAdded(
    List<dynamic> response,
    this.event,
  )   : accountAddress = (response[0] as _i2.EthereumAddress),
        sessionAddress = (response[1] as _i2.EthereumAddress);

  final _i2.EthereumAddress accountAddress;

  final _i2.EthereumAddress sessionAddress;

  final _i1.FilterEvent event;
}

class Memory_SessionExpirySet {
  Memory_SessionExpirySet(
    List<dynamic> response,
    this.event,
  )   : accountAddress = (response[0] as _i2.EthereumAddress),
        sessionAddress = (response[1] as _i2.EthereumAddress),
        oldUntil = (response[2] as BigInt),
        newUntil = (response[3] as BigInt);

  final _i2.EthereumAddress accountAddress;

  final _i2.EthereumAddress sessionAddress;

  final BigInt oldUntil;

  final BigInt newUntil;

  final _i1.FilterEvent event;
}

class Memory_SessionRemoved {
  Memory_SessionRemoved(
    List<dynamic> response,
    this.event,
  )   : accountAddress = (response[0] as _i2.EthereumAddress),
        sessionAddress = (response[1] as _i2.EthereumAddress);

  final _i2.EthereumAddress accountAddress;

  final _i2.EthereumAddress sessionAddress;

  final _i1.FilterEvent event;
}

class Memory_SessionReseeded {
  Memory_SessionReseeded(
    List<dynamic> response,
    this.event,
  )   : accountAddress = (response[0] as _i2.EthereumAddress),
        newSoleSession = (response[1] as _i2.EthereumAddress),
        previousSessionCount = (response[2] as BigInt);

  final _i2.EthereumAddress accountAddress;

  final _i2.EthereumAddress newSoleSession;

  final BigInt previousSessionCount;

  final _i1.FilterEvent event;
}

class Memory_SubdomainCreated {
  Memory_SubdomainCreated(
    List<dynamic> response,
    this.event,
  )   : parent = (response[0] as _i2.EthereumAddress),
        subAccount = (response[1] as _i2.EthereumAddress),
        slug = (response[2] as String);

  final _i2.EthereumAddress parent;

  final _i2.EthereumAddress subAccount;

  final String slug;

  final _i1.FilterEvent event;
}

class Memory_SubdomainCreationBurnSet {
  Memory_SubdomainCreationBurnSet(
    List<dynamic> response,
    this.event,
  )   : newValue = (response[0] as BigInt);

  final BigInt newValue;

  final _i1.FilterEvent event;
}

class Memory_SubdomainDeleted {
  Memory_SubdomainDeleted(
    List<dynamic> response,
    this.event,
  )   : parent = (response[0] as _i2.EthereumAddress),
        subAccount = (response[1] as _i2.EthereumAddress),
        slug = (response[2] as String);

  final _i2.EthereumAddress parent;

  final _i2.EthereumAddress subAccount;

  final String slug;

  final _i1.FilterEvent event;
}

class Memory_SubdomainRenamed {
  Memory_SubdomainRenamed(
    List<dynamic> response,
    this.event,
  )   : parent = (response[0] as _i2.EthereumAddress),
        subAccount = (response[1] as _i2.EthereumAddress),
        oldSlug = (response[2] as String),
        newSlug = (response[3] as String);

  final _i2.EthereumAddress parent;

  final _i2.EthereumAddress subAccount;

  final String oldSlug;

  final String newSlug;

  final _i1.FilterEvent event;
}
