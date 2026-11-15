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
  '[{"inputs":[{"internalType":"address","name":"_moduleRegistryAddress","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[],"name":"AdminCapReached","type":"error"},{"inputs":[],"name":"AlreadyAdmin","type":"error"},{"inputs":[],"name":"FailedDeployment","type":"error"},{"inputs":[{"internalType":"uint256","name":"balance","type":"uint256"},{"internalType":"uint256","name":"needed","type":"uint256"}],"name":"InsufficientBalance","type":"error"},{"inputs":[],"name":"InvalidAdmin","type":"error"},{"inputs":[],"name":"InvalidShortString","type":"error"},{"inputs":[],"name":"NotAdmin","type":"error"},{"inputs":[],"name":"NotAuthorized","type":"error"},{"inputs":[],"name":"RootNotResolvable","type":"error"},{"inputs":[{"internalType":"string","name":"str","type":"string"}],"name":"StringTooLong","type":"error"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":false,"internalType":"string","name":"displayName","type":"string"},{"indexed":true,"internalType":"address","name":"firstSessionAddress","type":"address"},{"indexed":true,"internalType":"address","name":"minterAccountAddress","type":"address"}],"name":"AccountCreated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":true,"internalType":"address","name":"minter","type":"address"}],"name":"AccountCreatedViaInvitation","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"targetAccountAddress","type":"address"},{"indexed":true,"internalType":"address","name":"newSoleSession","type":"address"},{"indexed":false,"internalType":"uint256","name":"previousSessionCount","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"previousContactCount","type":"uint256"}],"name":"AccountFullResetByDAO","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":false,"internalType":"bool","name":"suspended","type":"bool"}],"name":"AccountSuspensionSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"admin","type":"address"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"AdminAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"admin","type":"address"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"AdminRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":false,"internalType":"string","name":"oldDisplayName","type":"string"},{"indexed":false,"internalType":"string","name":"newDisplayName","type":"string"}],"name":"DisplayNameSet","type":"event"},{"anonymous":false,"inputs":[],"name":"EIP712DomainChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":true,"internalType":"address","name":"sessionAddress","type":"address"},{"indexed":false,"internalType":"uint48","name":"expiredAt","type":"uint48"}],"name":"ExpiredSessionPruned","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":true,"internalType":"address","name":"newSoleSession","type":"address"},{"indexed":false,"internalType":"uint256","name":"landsAt","type":"uint256"}],"name":"FullResetAnnounced","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":true,"internalType":"address","name":"by","type":"address"},{"indexed":false,"internalType":"uint256","name":"landsAt","type":"uint256"}],"name":"FullResetObjected","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bool","name":"on","type":"bool"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"InheritanceSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newMax","type":"uint256"}],"name":"MaxSessionTtlSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newMinimum","type":"uint256"}],"name":"MinRecoveryThresholdSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"orgAccountAddress","type":"address"},{"indexed":false,"internalType":"string","name":"displayName","type":"string"},{"indexed":false,"internalType":"address[]","name":"initialMembers","type":"address[]"},{"indexed":false,"internalType":"uint256","name":"initialThreshold","type":"uint256"}],"name":"OrgCreated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":true,"internalType":"address","name":"recoveryContactAccountAddress","type":"address"}],"name":"RecoveryContactAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":true,"internalType":"address","name":"recoveryContactAccountAddress","type":"address"}],"name":"RecoveryContactRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":false,"internalType":"uint256","name":"newThreshold","type":"uint256"}],"name":"RecoveryThresholdSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"victim","type":"address"},{"indexed":false,"internalType":"string","name":"newName","type":"string"},{"indexed":false,"internalType":"string","name":"oldDisplayName","type":"string"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"RootForceRenamed","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"target","type":"address"},{"indexed":false,"internalType":"string","name":"newName","type":"string"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"RootNameGranted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":true,"internalType":"address","name":"sessionAddress","type":"address"}],"name":"SessionAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":true,"internalType":"address","name":"sessionAddress","type":"address"},{"indexed":false,"internalType":"uint48","name":"oldUntil","type":"uint48"},{"indexed":false,"internalType":"uint48","name":"newUntil","type":"uint48"}],"name":"SessionExpirySet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":true,"internalType":"address","name":"sessionAddress","type":"address"}],"name":"SessionRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":true,"internalType":"address","name":"newSoleSession","type":"address"},{"indexed":false,"internalType":"uint256","name":"previousSessionCount","type":"uint256"}],"name":"SessionReseeded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"topLevel","type":"address"},{"indexed":true,"internalType":"address","name":"parent","type":"address"},{"indexed":true,"internalType":"address","name":"subAccount","type":"address"},{"indexed":false,"internalType":"string","name":"slug","type":"string"}],"name":"SubdomainCreated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"topLevel","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"SubdomainCreationBurned","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"topLevel","type":"address"},{"indexed":true,"internalType":"address","name":"parent","type":"address"},{"indexed":true,"internalType":"address","name":"subAccount","type":"address"},{"indexed":false,"internalType":"string","name":"slug","type":"string"}],"name":"SubdomainDeleted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"topLevel","type":"address"},{"indexed":true,"internalType":"address","name":"parent","type":"address"},{"indexed":true,"internalType":"address","name":"subAccount","type":"address"},{"indexed":false,"internalType":"string","name":"oldSlug","type":"string"},{"indexed":false,"internalType":"string","name":"newSlug","type":"string"}],"name":"SubdomainRenamed","type":"event"},{"inputs":[],"name":"MAX_PRUNE","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"RESET_DELAY","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"RESET_DELAY_OBJECTED","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"}],"name":"accountExists","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"addAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"recoveryContactAccountAddress","type":"address"}],"name":"addRecoveryContact","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"sessionToAdd","type":"address"},{"internalType":"uint256","name":"ttl","type":"uint256"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"bytes","name":"sig","type":"bytes"}],"name":"addSession","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"admins","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"accounts","type":"address[]"},{"internalType":"string[]","name":"newNames","type":"string[]"}],"name":"applyNames","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"displayName","type":"string"},{"internalType":"address","name":"firstSessionAddress","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"bytes","name":"sig","type":"bytes"}],"name":"createAccount","outputs":[{"internalType":"address","name":"accountAddress","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"minter","type":"address"},{"internalType":"string","name":"displayName","type":"string"},{"internalType":"address","name":"firstSessionAddress","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"bytes","name":"sig","type":"bytes"}],"name":"createAccountFromInvitation","outputs":[{"internalType":"address","name":"accountAddress","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"displayName","type":"string"},{"internalType":"address[]","name":"initialMembers","type":"address[]"},{"internalType":"uint256","name":"initialThreshold","type":"uint256"},{"internalType":"bool","name":"isPublic","type":"bool"}],"name":"createOrg","outputs":[{"internalType":"address","name":"orgAccountAddress","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"parentAcc","type":"address"},{"internalType":"string","name":"slug","type":"string"}],"name":"createSubdomain","outputs":[{"internalType":"address","name":"subAccount","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"parentAcc","type":"address"},{"internalType":"string","name":"slug","type":"string"}],"name":"createSubdomainForOrg","outputs":[{"internalType":"address","name":"subAccount","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"subAccount","type":"address"}],"name":"deleteSubdomain","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"subAccount","type":"address"}],"name":"deleteSubdomainForOrg","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"eip712Domain","outputs":[{"internalType":"bytes1","name":"fields","type":"bytes1"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"version","type":"string"},{"internalType":"uint256","name":"chainId","type":"uint256"},{"internalType":"address","name":"verifyingContract","type":"address"},{"internalType":"bytes32","name":"salt","type":"bytes32"},{"internalType":"uint256[]","name":"extensions","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"executeFullReset","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"targetAccountAddress","type":"address"},{"internalType":"address","name":"newSoleSession","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"bytes","name":"sig","type":"bytes"}],"name":"fullResetByDAO","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"sessionAddress","type":"address"}],"name":"getAccountAddressForSession","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"}],"name":"getAccountRecoveryContacts","outputs":[{"internalType":"address[]","name":"contacts","type":"address[]"},{"internalType":"uint256","name":"threshold","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"}],"name":"getMainSafeAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"inheritanceOn","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"}],"name":"isAccountSuspended","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"isAdmin","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"}],"name":"isOrgAccount","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"},{"internalType":"address","name":"sessionAddress","type":"address"}],"name":"isValidSessionForAccount","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"maxRecoveryContacts","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"maxSessionTtl","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"minRecoveryThreshold","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleRegistry","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleType","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"objectToReset","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"},{"internalType":"address[]","name":"sessions","type":"address[]"}],"name":"pruneExpiredSessions","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"removeAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"recoveryContactAccountAddress","type":"address"}],"name":"removeRecoveryContact","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"sessionToRemove","type":"address"}],"name":"removeSession","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"subAccount","type":"address"},{"internalType":"string","name":"newSlug","type":"string"}],"name":"renameSubdomain","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"subAccount","type":"address"},{"internalType":"string","name":"newSlug","type":"string"}],"name":"renameSubdomainForOrg","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"targetAccountAddress","type":"address"},{"internalType":"address","name":"newSoleSession","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"bytes","name":"sig","type":"bytes"}],"name":"reseedSessionViaRecovery","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"victim","type":"address"},{"internalType":"string","name":"newNameForVictim","type":"string"}],"name":"rootForceRename","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"target","type":"address"},{"internalType":"string","name":"newName","type":"string"}],"name":"rootGrantName","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"},{"internalType":"bool","name":"suspended","type":"bool"}],"name":"setAccountSuspended","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"on","type":"bool"}],"name":"setInheritance","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"newMax","type":"uint256"}],"name":"setMaxRecoveryContacts","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"newMax","type":"uint256"}],"name":"setMaxSessionTtl","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"newMinimum","type":"uint256"}],"name":"setMinRecoveryThreshold","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"threshold","type":"uint256"}],"name":"setRecoveryThreshold","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"session","type":"address"},{"internalType":"uint256","name":"ttl","type":"uint256"}],"name":"setSessionExpiry","outputs":[],"stateMutability":"nonpayable","type":"function"}]',
  'AccountManagerWithInvite',
);

class AccountManagerWithInvite extends _i1.GeneratedContract {
  AccountManagerWithInvite({
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
  Future<BigInt> MAX_PRUNE(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, 'c3eb0bf2'));
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
  Future<BigInt> RESET_DELAY(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, '3bd6ca24'));
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
  Future<BigInt> RESET_DELAY_OBJECTED(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, '1a586d62'));
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
  Future<bool> accountExists(
    ({_i2.EthereumAddress accountAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, '75cd51ed'));
    final params = [args.accountAddress];
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
    final function = self.abi.functions[5];
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
  Future<String> addRecoveryContact(
    ({_i2.EthereumAddress recoveryContactAccountAddress}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, '2c8d20e6'));
    final params = [args.recoveryContactAccountAddress];
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
  Future<String> addSession(
    ({_i2.EthereumAddress sessionToAdd, BigInt ttl, BigInt deadline, _i3.Uint8List sig}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, '1c75a542'));
    final params = [
      args.sessionToAdd,
      args.ttl,
      args.deadline,
      args.sig,
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
    final function = self.abi.functions[8];
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
  Future<String> applyNames(
    ({List<_i2.EthereumAddress> accounts, List<String> newNames}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[9];
    assert(checkSignature(function, '9a225050'));
    final params = [
      args.accounts,
      args.newNames,
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
  Future<String> createAccount(
    ({String displayName, _i2.EthereumAddress firstSessionAddress, BigInt deadline, _i3.Uint8List sig}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[10];
    assert(checkSignature(function, '33322ee1'));
    final params = [
      args.displayName,
      args.firstSessionAddress,
      args.deadline,
      args.sig,
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
  Future<String> createAccountFromInvitation(
    ({_i2.EthereumAddress minter, String displayName, _i2.EthereumAddress firstSessionAddress, BigInt deadline, _i3.Uint8List sig}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[11];
    assert(checkSignature(function, '37040eeb'));
    final params = [
      args.minter,
      args.displayName,
      args.firstSessionAddress,
      args.deadline,
      args.sig,
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
  Future<String> createOrg(
    ({String displayName, List<_i2.EthereumAddress> initialMembers, BigInt initialThreshold, bool isPublic}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[12];
    assert(checkSignature(function, '5d785685'));
    final params = [
      args.displayName,
      args.initialMembers,
      args.initialThreshold,
      args.isPublic,
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
  Future<String> createSubdomain(
    ({_i2.EthereumAddress parentAcc, String slug}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[13];
    assert(checkSignature(function, '7778ba75'));
    final params = [
      args.parentAcc,
      args.slug,
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
  Future<String> createSubdomainForOrg(
    ({_i2.EthereumAddress parentAcc, String slug}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[14];
    assert(checkSignature(function, '4fd67d59'));
    final params = [
      args.parentAcc,
      args.slug,
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
  Future<String> deleteSubdomain(
    ({_i2.EthereumAddress subAccount}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[15];
    assert(checkSignature(function, '3121c362'));
    final params = [args.subAccount];
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
  Future<String> deleteSubdomainForOrg(
    ({_i2.EthereumAddress subAccount}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[16];
    assert(checkSignature(function, 'c704d56b'));
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
  Future<Eip712Domain> eip712Domain(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[17];
    assert(checkSignature(function, '84b0196e'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return Eip712Domain(response);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> executeFullReset(
    ({_i2.EthereumAddress account}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[18];
    assert(checkSignature(function, 'ed2128dc'));
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
  Future<String> fullResetByDAO(
    ({_i2.EthereumAddress targetAccountAddress, _i2.EthereumAddress newSoleSession, BigInt deadline, _i3.Uint8List sig}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[19];
    assert(checkSignature(function, '3667798a'));
    final params = [
      args.targetAccountAddress,
      args.newSoleSession,
      args.deadline,
      args.sig,
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
  Future<_i2.EthereumAddress> getAccountAddressForSession(
    ({_i2.EthereumAddress sessionAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[20];
    assert(checkSignature(function, '84929f4d'));
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
  Future<GetAccountRecoveryContacts> getAccountRecoveryContacts(
    ({_i2.EthereumAddress accountAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[21];
    assert(checkSignature(function, '84d933fd'));
    final params = [args.accountAddress];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return GetAccountRecoveryContacts(response);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i2.EthereumAddress> getMainSafeAddress(
    ({_i2.EthereumAddress accountAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[22];
    assert(checkSignature(function, '60bd86cb'));
    final params = [args.accountAddress];
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
  Future<bool> inheritanceOn(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[23];
    assert(checkSignature(function, '84a5bada'));
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
  Future<bool> isAccountSuspended(
    ({_i2.EthereumAddress accountAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[24];
    assert(checkSignature(function, 'eeb0e851'));
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
  Future<bool> isAdmin(
    ({_i2.EthereumAddress account}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[25];
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
    ({_i2.EthereumAddress accountAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[26];
    assert(checkSignature(function, '1ed05916'));
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
  Future<bool> isValidSessionForAccount(
    ({_i2.EthereumAddress accountAddress, _i2.EthereumAddress sessionAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[27];
    assert(checkSignature(function, '70c7e83b'));
    final params = [
      args.accountAddress,
      args.sessionAddress,
    ];
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
  Future<BigInt> maxRecoveryContacts(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[28];
    assert(checkSignature(function, '939095b8'));
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
  Future<BigInt> maxSessionTtl(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[29];
    assert(checkSignature(function, '64d0e1bb'));
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
  Future<BigInt> minRecoveryThreshold(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[30];
    assert(checkSignature(function, '71466afd'));
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
  Future<_i2.EthereumAddress> moduleRegistry(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[31];
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
    final function = self.abi.functions[32];
    assert(checkSignature(function, '6465e69f'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i3.Uint8List);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> objectToReset(
    ({_i2.EthereumAddress account}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[33];
    assert(checkSignature(function, '31823718'));
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
  Future<String> pruneExpiredSessions(
    ({_i2.EthereumAddress accountAddress, List<_i2.EthereumAddress> sessions}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[34];
    assert(checkSignature(function, 'ebd28cf0'));
    final params = [
      args.accountAddress,
      args.sessions,
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
  Future<String> removeAdmin(
    ({_i2.EthereumAddress account}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[35];
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
  Future<String> removeRecoveryContact(
    ({_i2.EthereumAddress recoveryContactAccountAddress}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[36];
    assert(checkSignature(function, '3aad070e'));
    final params = [args.recoveryContactAccountAddress];
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
  Future<String> removeSession(
    ({_i2.EthereumAddress sessionToRemove}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[37];
    assert(checkSignature(function, '5c9fec4c'));
    final params = [args.sessionToRemove];
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
  Future<String> renameSubdomain(
    ({_i2.EthereumAddress subAccount, String newSlug}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[38];
    assert(checkSignature(function, '294f04c0'));
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
  Future<String> renameSubdomainForOrg(
    ({_i2.EthereumAddress subAccount, String newSlug}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[39];
    assert(checkSignature(function, '6f45a379'));
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
  Future<String> reseedSessionViaRecovery(
    ({_i2.EthereumAddress targetAccountAddress, _i2.EthereumAddress newSoleSession, BigInt deadline, _i3.Uint8List sig}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[40];
    assert(checkSignature(function, '6d9098ba'));
    final params = [
      args.targetAccountAddress,
      args.newSoleSession,
      args.deadline,
      args.sig,
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
  Future<String> rootForceRename(
    ({_i2.EthereumAddress victim, String newNameForVictim}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[41];
    assert(checkSignature(function, 'c508ccd3'));
    final params = [
      args.victim,
      args.newNameForVictim,
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
  Future<String> rootGrantName(
    ({_i2.EthereumAddress target, String newName}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[42];
    assert(checkSignature(function, '3333a7b0'));
    final params = [
      args.target,
      args.newName,
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
  Future<String> setAccountSuspended(
    ({_i2.EthereumAddress accountAddress, bool suspended}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[43];
    assert(checkSignature(function, 'cf9860b8'));
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
  Future<String> setInheritance(
    ({bool on}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[44];
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
  Future<String> setMaxRecoveryContacts(
    ({BigInt newMax}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[45];
    assert(checkSignature(function, '31adf525'));
    final params = [args.newMax];
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
  Future<String> setMaxSessionTtl(
    ({BigInt newMax}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[46];
    assert(checkSignature(function, '18aa6c29'));
    final params = [args.newMax];
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
  Future<String> setMinRecoveryThreshold(
    ({BigInt newMinimum}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[47];
    assert(checkSignature(function, 'a2afdcb8'));
    final params = [args.newMinimum];
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
  Future<String> setRecoveryThreshold(
    ({BigInt threshold}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[48];
    assert(checkSignature(function, '780d111c'));
    final params = [args.threshold];
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
  Future<String> setSessionExpiry(
    ({_i2.EthereumAddress session, BigInt ttl}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[49];
    assert(checkSignature(function, '9fbc63b2'));
    final params = [
      args.session,
      args.ttl,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// Returns a live stream of all AccountCreated events emitted by this contract.
  Stream<AccountCreated> accountCreatedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('AccountCreated');
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
      return AccountCreated(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all AccountCreatedViaInvitation events emitted by this contract.
  Stream<AccountCreatedViaInvitation> accountCreatedViaInvitationEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('AccountCreatedViaInvitation');
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
      return AccountCreatedViaInvitation(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all AccountFullResetByDAO events emitted by this contract.
  Stream<AccountFullResetByDAO> accountFullResetByDAOEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('AccountFullResetByDAO');
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
      return AccountFullResetByDAO(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all AccountSuspensionSet events emitted by this contract.
  Stream<AccountSuspensionSet> accountSuspensionSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('AccountSuspensionSet');
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
      return AccountSuspensionSet(
        decoded,
        result,
      );
    });
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

  /// Returns a live stream of all DisplayNameSet events emitted by this contract.
  Stream<DisplayNameSet> displayNameSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('DisplayNameSet');
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
      return DisplayNameSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all EIP712DomainChanged events emitted by this contract.
  Stream<EIP712DomainChanged> eIP712DomainChangedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('EIP712DomainChanged');
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
      return EIP712DomainChanged(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all ExpiredSessionPruned events emitted by this contract.
  Stream<ExpiredSessionPruned> expiredSessionPrunedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('ExpiredSessionPruned');
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
      return ExpiredSessionPruned(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all FullResetAnnounced events emitted by this contract.
  Stream<FullResetAnnounced> fullResetAnnouncedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('FullResetAnnounced');
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
      return FullResetAnnounced(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all FullResetObjected events emitted by this contract.
  Stream<FullResetObjected> fullResetObjectedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('FullResetObjected');
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
      return FullResetObjected(
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

  /// Returns a live stream of all MaxSessionTtlSet events emitted by this contract.
  Stream<MaxSessionTtlSet> maxSessionTtlSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('MaxSessionTtlSet');
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
      return MaxSessionTtlSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all MinRecoveryThresholdSet events emitted by this contract.
  Stream<MinRecoveryThresholdSet> minRecoveryThresholdSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('MinRecoveryThresholdSet');
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
      return MinRecoveryThresholdSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all OrgCreated events emitted by this contract.
  Stream<OrgCreated> orgCreatedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('OrgCreated');
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
      return OrgCreated(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all RecoveryContactAdded events emitted by this contract.
  Stream<RecoveryContactAdded> recoveryContactAddedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('RecoveryContactAdded');
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
      return RecoveryContactAdded(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all RecoveryContactRemoved events emitted by this contract.
  Stream<RecoveryContactRemoved> recoveryContactRemovedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('RecoveryContactRemoved');
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
      return RecoveryContactRemoved(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all RecoveryThresholdSet events emitted by this contract.
  Stream<RecoveryThresholdSet> recoveryThresholdSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('RecoveryThresholdSet');
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
      return RecoveryThresholdSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all RootForceRenamed events emitted by this contract.
  Stream<RootForceRenamed> rootForceRenamedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('RootForceRenamed');
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
      return RootForceRenamed(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all RootNameGranted events emitted by this contract.
  Stream<RootNameGranted> rootNameGrantedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('RootNameGranted');
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
      return RootNameGranted(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all SessionAdded events emitted by this contract.
  Stream<SessionAdded> sessionAddedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('SessionAdded');
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
      return SessionAdded(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all SessionExpirySet events emitted by this contract.
  Stream<SessionExpirySet> sessionExpirySetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('SessionExpirySet');
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
      return SessionExpirySet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all SessionRemoved events emitted by this contract.
  Stream<SessionRemoved> sessionRemovedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('SessionRemoved');
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
      return SessionRemoved(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all SessionReseeded events emitted by this contract.
  Stream<SessionReseeded> sessionReseededEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('SessionReseeded');
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
      return SessionReseeded(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all SubdomainCreated events emitted by this contract.
  Stream<SubdomainCreated> subdomainCreatedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('SubdomainCreated');
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
      return SubdomainCreated(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all SubdomainCreationBurned events emitted by this contract.
  Stream<SubdomainCreationBurned> subdomainCreationBurnedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('SubdomainCreationBurned');
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
      return SubdomainCreationBurned(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all SubdomainDeleted events emitted by this contract.
  Stream<SubdomainDeleted> subdomainDeletedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('SubdomainDeleted');
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
      return SubdomainDeleted(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all SubdomainRenamed events emitted by this contract.
  Stream<SubdomainRenamed> subdomainRenamedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('SubdomainRenamed');
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
      return SubdomainRenamed(
        decoded,
        result,
      );
    });
  }
}

class Eip712Domain {
  Eip712Domain(List<dynamic> response)
      : fields = (response[0] as dynamic),
        name = (response[1] as String),
        version = (response[2] as String),
        chainId = (response[3] as BigInt),
        verifyingContract = (response[4] as _i2.EthereumAddress),
        salt = (response[5] as _i3.Uint8List),
        extensions = (response[6] as List<dynamic>).cast<BigInt>();

  final dynamic fields;

  final String name;

  final String version;

  final BigInt chainId;

  final _i2.EthereumAddress verifyingContract;

  final _i3.Uint8List salt;

  final List<BigInt> extensions;

}

class GetAccountRecoveryContacts {
  GetAccountRecoveryContacts(List<dynamic> response)
      : contacts = (response[0] as List<dynamic>).cast<_i2.EthereumAddress>(),
        threshold = (response[1] as BigInt);

  final List<_i2.EthereumAddress> contacts;

  final BigInt threshold;

}

class AccountCreated {
  AccountCreated(
    List<dynamic> response,
    this.event,
  )   : accountAddress = (response[0] as _i2.EthereumAddress),
        displayName = (response[1] as String),
        firstSessionAddress = (response[2] as _i2.EthereumAddress),
        minterAccountAddress = (response[3] as _i2.EthereumAddress);

  final _i2.EthereumAddress accountAddress;

  final String displayName;

  final _i2.EthereumAddress firstSessionAddress;

  final _i2.EthereumAddress minterAccountAddress;

  final _i1.FilterEvent event;
}

class AccountCreatedViaInvitation {
  AccountCreatedViaInvitation(
    List<dynamic> response,
    this.event,
  )   : account = (response[0] as _i2.EthereumAddress),
        minter = (response[1] as _i2.EthereumAddress);

  final _i2.EthereumAddress account;

  final _i2.EthereumAddress minter;

  final _i1.FilterEvent event;
}

class AccountFullResetByDAO {
  AccountFullResetByDAO(
    List<dynamic> response,
    this.event,
  )   : targetAccountAddress = (response[0] as _i2.EthereumAddress),
        newSoleSession = (response[1] as _i2.EthereumAddress),
        previousSessionCount = (response[2] as BigInt),
        previousContactCount = (response[3] as BigInt);

  final _i2.EthereumAddress targetAccountAddress;

  final _i2.EthereumAddress newSoleSession;

  final BigInt previousSessionCount;

  final BigInt previousContactCount;

  final _i1.FilterEvent event;
}

class AccountSuspensionSet {
  AccountSuspensionSet(
    List<dynamic> response,
    this.event,
  )   : accountAddress = (response[0] as _i2.EthereumAddress),
        suspended = (response[1] as bool);

  final _i2.EthereumAddress accountAddress;

  final bool suspended;

  final _i1.FilterEvent event;
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

class DisplayNameSet {
  DisplayNameSet(
    List<dynamic> response,
    this.event,
  )   : accountAddress = (response[0] as _i2.EthereumAddress),
        oldDisplayName = (response[1] as String),
        newDisplayName = (response[2] as String);

  final _i2.EthereumAddress accountAddress;

  final String oldDisplayName;

  final String newDisplayName;

  final _i1.FilterEvent event;
}

class EIP712DomainChanged {
  EIP712DomainChanged(
    List<dynamic> response,
    this.event,
  );

  final _i1.FilterEvent event;
}

class ExpiredSessionPruned {
  ExpiredSessionPruned(
    List<dynamic> response,
    this.event,
  )   : accountAddress = (response[0] as _i2.EthereumAddress),
        sessionAddress = (response[1] as _i2.EthereumAddress),
        expiredAt = (response[2] as BigInt);

  final _i2.EthereumAddress accountAddress;

  final _i2.EthereumAddress sessionAddress;

  final BigInt expiredAt;

  final _i1.FilterEvent event;
}

class FullResetAnnounced {
  FullResetAnnounced(
    List<dynamic> response,
    this.event,
  )   : account = (response[0] as _i2.EthereumAddress),
        newSoleSession = (response[1] as _i2.EthereumAddress),
        landsAt = (response[2] as BigInt);

  final _i2.EthereumAddress account;

  final _i2.EthereumAddress newSoleSession;

  final BigInt landsAt;

  final _i1.FilterEvent event;
}

class FullResetObjected {
  FullResetObjected(
    List<dynamic> response,
    this.event,
  )   : account = (response[0] as _i2.EthereumAddress),
        by = (response[1] as _i2.EthereumAddress),
        landsAt = (response[2] as BigInt);

  final _i2.EthereumAddress account;

  final _i2.EthereumAddress by;

  final BigInt landsAt;

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

class MaxSessionTtlSet {
  MaxSessionTtlSet(
    List<dynamic> response,
    this.event,
  )   : newMax = (response[0] as BigInt);

  final BigInt newMax;

  final _i1.FilterEvent event;
}

class MinRecoveryThresholdSet {
  MinRecoveryThresholdSet(
    List<dynamic> response,
    this.event,
  )   : newMinimum = (response[0] as BigInt);

  final BigInt newMinimum;

  final _i1.FilterEvent event;
}

class OrgCreated {
  OrgCreated(
    List<dynamic> response,
    this.event,
  )   : orgAccountAddress = (response[0] as _i2.EthereumAddress),
        displayName = (response[1] as String),
        initialMembers = (response[2] as List<dynamic>).cast<_i2.EthereumAddress>(),
        initialThreshold = (response[3] as BigInt);

  final _i2.EthereumAddress orgAccountAddress;

  final String displayName;

  final List<_i2.EthereumAddress> initialMembers;

  final BigInt initialThreshold;

  final _i1.FilterEvent event;
}

class RecoveryContactAdded {
  RecoveryContactAdded(
    List<dynamic> response,
    this.event,
  )   : accountAddress = (response[0] as _i2.EthereumAddress),
        recoveryContactAccountAddress = (response[1] as _i2.EthereumAddress);

  final _i2.EthereumAddress accountAddress;

  final _i2.EthereumAddress recoveryContactAccountAddress;

  final _i1.FilterEvent event;
}

class RecoveryContactRemoved {
  RecoveryContactRemoved(
    List<dynamic> response,
    this.event,
  )   : accountAddress = (response[0] as _i2.EthereumAddress),
        recoveryContactAccountAddress = (response[1] as _i2.EthereumAddress);

  final _i2.EthereumAddress accountAddress;

  final _i2.EthereumAddress recoveryContactAccountAddress;

  final _i1.FilterEvent event;
}

class RecoveryThresholdSet {
  RecoveryThresholdSet(
    List<dynamic> response,
    this.event,
  )   : accountAddress = (response[0] as _i2.EthereumAddress),
        newThreshold = (response[1] as BigInt);

  final _i2.EthereumAddress accountAddress;

  final BigInt newThreshold;

  final _i1.FilterEvent event;
}

class RootForceRenamed {
  RootForceRenamed(
    List<dynamic> response,
    this.event,
  )   : victim = (response[0] as _i2.EthereumAddress),
        newName = (response[1] as String),
        oldDisplayName = (response[2] as String),
        by = (response[3] as _i2.EthereumAddress);

  final _i2.EthereumAddress victim;

  final String newName;

  final String oldDisplayName;

  final _i2.EthereumAddress by;

  final _i1.FilterEvent event;
}

class RootNameGranted {
  RootNameGranted(
    List<dynamic> response,
    this.event,
  )   : target = (response[0] as _i2.EthereumAddress),
        newName = (response[1] as String),
        by = (response[2] as _i2.EthereumAddress);

  final _i2.EthereumAddress target;

  final String newName;

  final _i2.EthereumAddress by;

  final _i1.FilterEvent event;
}

class SessionAdded {
  SessionAdded(
    List<dynamic> response,
    this.event,
  )   : accountAddress = (response[0] as _i2.EthereumAddress),
        sessionAddress = (response[1] as _i2.EthereumAddress);

  final _i2.EthereumAddress accountAddress;

  final _i2.EthereumAddress sessionAddress;

  final _i1.FilterEvent event;
}

class SessionExpirySet {
  SessionExpirySet(
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

class SessionRemoved {
  SessionRemoved(
    List<dynamic> response,
    this.event,
  )   : accountAddress = (response[0] as _i2.EthereumAddress),
        sessionAddress = (response[1] as _i2.EthereumAddress);

  final _i2.EthereumAddress accountAddress;

  final _i2.EthereumAddress sessionAddress;

  final _i1.FilterEvent event;
}

class SessionReseeded {
  SessionReseeded(
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

class SubdomainCreated {
  SubdomainCreated(
    List<dynamic> response,
    this.event,
  )   : topLevel = (response[0] as _i2.EthereumAddress),
        parent = (response[1] as _i2.EthereumAddress),
        subAccount = (response[2] as _i2.EthereumAddress),
        slug = (response[3] as String);

  final _i2.EthereumAddress topLevel;

  final _i2.EthereumAddress parent;

  final _i2.EthereumAddress subAccount;

  final String slug;

  final _i1.FilterEvent event;
}

class SubdomainCreationBurned {
  SubdomainCreationBurned(
    List<dynamic> response,
    this.event,
  )   : topLevel = (response[0] as _i2.EthereumAddress),
        amount = (response[1] as BigInt);

  final _i2.EthereumAddress topLevel;

  final BigInt amount;

  final _i1.FilterEvent event;
}

class SubdomainDeleted {
  SubdomainDeleted(
    List<dynamic> response,
    this.event,
  )   : topLevel = (response[0] as _i2.EthereumAddress),
        parent = (response[1] as _i2.EthereumAddress),
        subAccount = (response[2] as _i2.EthereumAddress),
        slug = (response[3] as String);

  final _i2.EthereumAddress topLevel;

  final _i2.EthereumAddress parent;

  final _i2.EthereumAddress subAccount;

  final String slug;

  final _i1.FilterEvent event;
}

class SubdomainRenamed {
  SubdomainRenamed(
    List<dynamic> response,
    this.event,
  )   : topLevel = (response[0] as _i2.EthereumAddress),
        parent = (response[1] as _i2.EthereumAddress),
        subAccount = (response[2] as _i2.EthereumAddress),
        oldSlug = (response[3] as String),
        newSlug = (response[4] as String);

  final _i2.EthereumAddress topLevel;

  final _i2.EthereumAddress parent;

  final _i2.EthereumAddress subAccount;

  final String oldSlug;

  final String newSlug;

  final _i1.FilterEvent event;
}
