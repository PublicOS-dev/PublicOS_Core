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
  '[{"inputs":[{"internalType":"address","name":"_moduleRegistry","type":"address"},{"internalType":"address","name":"_treasuryMemory","type":"address"},{"internalType":"address","name":"_token","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[],"name":"AdminCapReached","type":"error"},{"inputs":[],"name":"AlreadyAdmin","type":"error"},{"inputs":[],"name":"InvalidAdmin","type":"error"},{"inputs":[],"name":"NotAdmin","type":"error"},{"inputs":[],"name":"NotAuthorized","type":"error"},{"inputs":[],"name":"RootNotResolvable","type":"error"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"admin","type":"address"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"AdminAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"admin","type":"address"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"AdminRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"enforcer","type":"address"},{"indexed":true,"internalType":"bytes32","name":"orderRef","type":"bytes32"},{"indexed":false,"internalType":"uint8","name":"kind","type":"uint8"},{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"until","type":"uint256"}],"name":"Enforcement","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"enforcer","type":"address"}],"name":"EnforcerRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"enforcer","type":"address"},{"indexed":false,"internalType":"uint256","name":"activeAt","type":"uint256"}],"name":"EnforcerScheduled","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"}],"name":"FreezeExpired","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bool","name":"on","type":"bool"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"InheritanceSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"target","type":"address"}],"name":"NoGoAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"target","type":"address"},{"indexed":false,"internalType":"uint256","name":"at","type":"uint256"}],"name":"NoGoRemovalScheduled","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"target","type":"address"}],"name":"NoGoRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"key","type":"bytes32"},{"indexed":false,"internalType":"uint256","name":"cap","type":"uint256"}],"name":"PolicyKeyMintCapSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"key","type":"bytes32"},{"indexed":false,"internalType":"bool","name":"on","type":"bool"}],"name":"PolicyKeySet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"policy","type":"address"},{"indexed":false,"internalType":"uint256","name":"newCap","type":"uint256"}],"name":"PolicyMintCapSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"policy","type":"address"}],"name":"PolicyRegistered","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"policy","type":"address"}],"name":"PolicyRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"policy","type":"address"},{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"TokensBurned","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"policy","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"TokensMinted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"policy","type":"address"},{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"TokensTransferred","type":"event"},{"inputs":[],"name":"ENFORCER_DELAY","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"MAX_FREEZE","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"NOGO_REMOVAL_DELAY","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"RENEW_WINDOW","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"TRANSFER_NOTICE","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"addAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"target","type":"address"}],"name":"addNoGo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"admins","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"burnTokens","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"until","type":"uint256"},{"internalType":"bytes32","name":"orderRef","type":"bytes32"}],"name":"enforceFreeze","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"bytes32","name":"orderRef","type":"bytes32"}],"name":"enforceTransfer","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"bytes32","name":"orderRef","type":"bytes32"}],"name":"enforceUnfreeze","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"target","type":"address"}],"name":"executeNoGoRemoval","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"expireFreeze","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"policy","type":"address"}],"name":"getPolicyMintCap","outputs":[{"internalType":"uint256","name":"cap","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"policy","type":"address"}],"name":"getPolicyMinted","outputs":[{"internalType":"uint256","name":"minted","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"inheritanceOn","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"isAdmin","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"a","type":"address"}],"name":"isFrozen","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"isPolicyKey","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"policy","type":"address"}],"name":"isRegisteredPolicy","outputs":[{"internalType":"bool","name":"ok","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"policy","type":"address"}],"name":"mintCap","outputs":[{"internalType":"uint256","name":"cap","type":"uint256"},{"internalType":"uint256","name":"minted","type":"uint256"},{"internalType":"uint256","name":"monthStart","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"mintTokens","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"moduleRegistry","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleType","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"address","name":"enforcer","type":"address"}],"name":"registerEnforcer","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"policy","type":"address"}],"name":"registerPolicy","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"registerPolicyKey","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"removeAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"enforcer","type":"address"}],"name":"removeEnforcer","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"policy","type":"address"}],"name":"removePolicy","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"removePolicyKey","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"newUntil","type":"uint256"}],"name":"renewFreeze","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"target","type":"address"}],"name":"requestNoGoRemoval","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"on","type":"bool"}],"name":"setInheritance","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"internalType":"uint256","name":"newCap","type":"uint256"}],"name":"setPolicyKeyMintCap","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"policy","type":"address"},{"internalType":"uint256","name":"newCap","type":"uint256"}],"name":"setPolicyMintCap","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"token","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferTokens","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"treasuryMemory","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"}]',
  'TreasuryManager',
);

class TreasuryManager extends _i1.GeneratedContract {
  TreasuryManager({
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
  Future<BigInt> ENFORCER_DELAY(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '7d607824'));
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
  Future<BigInt> MAX_FREEZE(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, '963abbd5'));
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
  Future<BigInt> NOGO_REMOVAL_DELAY(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, 'c7f7edb3'));
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
  Future<BigInt> RENEW_WINDOW(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, '1981cfd7'));
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
  Future<BigInt> TRANSFER_NOTICE(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, 'd09e8bcd'));
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
  Future<String> addNoGo(
    ({_i2.EthereumAddress target}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, 'cd8d79a9'));
    final params = [args.target];
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
  Future<String> burnTokens(
    ({_i2.EthereumAddress from, BigInt amount}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[9];
    assert(checkSignature(function, '0d1118ce'));
    final params = [
      args.from,
      args.amount,
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
  Future<String> enforceFreeze(
    ({_i2.EthereumAddress account, BigInt until, _i3.Uint8List orderRef}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[10];
    assert(checkSignature(function, '6fe941c3'));
    final params = [
      args.account,
      args.until,
      args.orderRef,
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
  Future<String> enforceTransfer(
    ({_i2.EthereumAddress from, _i2.EthereumAddress to, BigInt amount, _i3.Uint8List orderRef}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[11];
    assert(checkSignature(function, '42898876'));
    final params = [
      args.from,
      args.to,
      args.amount,
      args.orderRef,
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
  Future<String> enforceUnfreeze(
    ({_i2.EthereumAddress account, _i3.Uint8List orderRef}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[12];
    assert(checkSignature(function, '0b905b93'));
    final params = [
      args.account,
      args.orderRef,
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
  Future<String> executeNoGoRemoval(
    ({_i2.EthereumAddress target}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[13];
    assert(checkSignature(function, '2e597112'));
    final params = [args.target];
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
  Future<String> expireFreeze(
    ({_i2.EthereumAddress account}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[14];
    assert(checkSignature(function, '1950610f'));
    final params = [args.account];
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
  Future<BigInt> getPolicyMintCap(
    ({_i2.EthereumAddress policy}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[15];
    assert(checkSignature(function, '28140bad'));
    final params = [args.policy];
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
  Future<BigInt> getPolicyMinted(
    ({_i2.EthereumAddress policy}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[16];
    assert(checkSignature(function, 'd392ecd1'));
    final params = [args.policy];
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
    final function = self.abi.functions[17];
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
  Future<bool> isAdmin(
    ({_i2.EthereumAddress account}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[18];
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
  Future<bool> isFrozen(
    ({_i2.EthereumAddress a}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[19];
    assert(checkSignature(function, 'e5839836'));
    final params = [args.a];
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
  Future<bool> isPolicyKey(
    ({_i3.Uint8List key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[20];
    assert(checkSignature(function, '2fb5b9bf'));
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
  Future<bool> isRegisteredPolicy(
    ({_i2.EthereumAddress policy}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[21];
    assert(checkSignature(function, '6738f910'));
    final params = [args.policy];
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
  Future<MintCap> mintCap(
    ({_i2.EthereumAddress policy}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[22];
    assert(checkSignature(function, '61db4271'));
    final params = [args.policy];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return MintCap(response);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> mintTokens(
    ({_i2.EthereumAddress to, BigInt amount}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[23];
    assert(checkSignature(function, 'f0dda65c'));
    final params = [
      args.to,
      args.amount,
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
  Future<_i2.EthereumAddress> moduleRegistry(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[24];
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
    final function = self.abi.functions[25];
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
  Future<String> registerEnforcer(
    ({_i2.EthereumAddress enforcer}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[26];
    assert(checkSignature(function, '9f8d8fde'));
    final params = [args.enforcer];
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
  Future<String> registerPolicy(
    ({_i2.EthereumAddress policy}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[27];
    assert(checkSignature(function, '0a4050a5'));
    final params = [args.policy];
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
  Future<String> registerPolicyKey(
    ({_i3.Uint8List key}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[28];
    assert(checkSignature(function, '1da44970'));
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
  Future<String> removeAdmin(
    ({_i2.EthereumAddress account}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[29];
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
  Future<String> removeEnforcer(
    ({_i2.EthereumAddress enforcer}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[30];
    assert(checkSignature(function, '6611fc99'));
    final params = [args.enforcer];
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
  Future<String> removePolicy(
    ({_i2.EthereumAddress policy}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[31];
    assert(checkSignature(function, '78d38d82'));
    final params = [args.policy];
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
  Future<String> removePolicyKey(
    ({_i3.Uint8List key}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[32];
    assert(checkSignature(function, '71ec9c4c'));
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
  Future<String> renewFreeze(
    ({_i2.EthereumAddress account, BigInt newUntil}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[33];
    assert(checkSignature(function, '32b4773e'));
    final params = [
      args.account,
      args.newUntil,
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
  Future<String> requestNoGoRemoval(
    ({_i2.EthereumAddress target}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[34];
    assert(checkSignature(function, '2cb74a49'));
    final params = [args.target];
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
    final function = self.abi.functions[35];
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
  Future<String> setPolicyKeyMintCap(
    ({_i3.Uint8List key, BigInt newCap}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[36];
    assert(checkSignature(function, 'a51a9855'));
    final params = [
      args.key,
      args.newCap,
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
  Future<String> setPolicyMintCap(
    ({_i2.EthereumAddress policy, BigInt newCap}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[37];
    assert(checkSignature(function, 'c438bdc1'));
    final params = [
      args.policy,
      args.newCap,
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
  Future<_i2.EthereumAddress> token(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[38];
    assert(checkSignature(function, 'fc0c546a'));
    final params = [];
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
  Future<String> transferTokens(
    ({_i2.EthereumAddress from, _i2.EthereumAddress to, BigInt amount}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[39];
    assert(checkSignature(function, 'a64b6e5f'));
    final params = [
      args.from,
      args.to,
      args.amount,
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
  Future<_i2.EthereumAddress> treasuryMemory(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[40];
    assert(checkSignature(function, 'f0c09132'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i2.EthereumAddress);
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

  /// Returns a live stream of all Enforcement events emitted by this contract.
  Stream<Enforcement> enforcementEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Enforcement');
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
      return Enforcement(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all EnforcerRemoved events emitted by this contract.
  Stream<EnforcerRemoved> enforcerRemovedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('EnforcerRemoved');
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
      return EnforcerRemoved(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all EnforcerScheduled events emitted by this contract.
  Stream<EnforcerScheduled> enforcerScheduledEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('EnforcerScheduled');
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
      return EnforcerScheduled(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all FreezeExpired events emitted by this contract.
  Stream<FreezeExpired> freezeExpiredEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('FreezeExpired');
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
      return FreezeExpired(
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

  /// Returns a live stream of all NoGoAdded events emitted by this contract.
  Stream<NoGoAdded> noGoAddedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('NoGoAdded');
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
      return NoGoAdded(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all NoGoRemovalScheduled events emitted by this contract.
  Stream<NoGoRemovalScheduled> noGoRemovalScheduledEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('NoGoRemovalScheduled');
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
      return NoGoRemovalScheduled(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all NoGoRemoved events emitted by this contract.
  Stream<NoGoRemoved> noGoRemovedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('NoGoRemoved');
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
      return NoGoRemoved(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all PolicyKeyMintCapSet events emitted by this contract.
  Stream<PolicyKeyMintCapSet> policyKeyMintCapSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('PolicyKeyMintCapSet');
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
      return PolicyKeyMintCapSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all PolicyKeySet events emitted by this contract.
  Stream<PolicyKeySet> policyKeySetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('PolicyKeySet');
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
      return PolicyKeySet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all PolicyMintCapSet events emitted by this contract.
  Stream<PolicyMintCapSet> policyMintCapSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('PolicyMintCapSet');
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
      return PolicyMintCapSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all PolicyRegistered events emitted by this contract.
  Stream<PolicyRegistered> policyRegisteredEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('PolicyRegistered');
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
      return PolicyRegistered(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all PolicyRemoved events emitted by this contract.
  Stream<PolicyRemoved> policyRemovedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('PolicyRemoved');
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
      return PolicyRemoved(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all TokensBurned events emitted by this contract.
  Stream<TokensBurned> tokensBurnedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('TokensBurned');
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
      return TokensBurned(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all TokensMinted events emitted by this contract.
  Stream<TokensMinted> tokensMintedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('TokensMinted');
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
      return TokensMinted(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all TokensTransferred events emitted by this contract.
  Stream<TokensTransferred> tokensTransferredEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('TokensTransferred');
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
      return TokensTransferred(
        decoded,
        result,
      );
    });
  }
}

class MintCap {
  MintCap(List<dynamic> response)
      : cap = (response[0] as BigInt),
        minted = (response[1] as BigInt),
        monthStart = (response[2] as BigInt);

  final BigInt cap;

  final BigInt minted;

  final BigInt monthStart;

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

class Enforcement {
  Enforcement(
    List<dynamic> response,
    this.event,
  )   : enforcer = (response[0] as _i2.EthereumAddress),
        orderRef = (response[1] as _i3.Uint8List),
        kind = (response[2] as BigInt),
        account = (response[3] as _i2.EthereumAddress),
        to = (response[4] as _i2.EthereumAddress),
        amount = (response[5] as BigInt),
        until = (response[6] as BigInt);

  final _i2.EthereumAddress enforcer;

  final _i3.Uint8List orderRef;

  final BigInt kind;

  final _i2.EthereumAddress account;

  final _i2.EthereumAddress to;

  final BigInt amount;

  final BigInt until;

  final _i1.FilterEvent event;
}

class EnforcerRemoved {
  EnforcerRemoved(
    List<dynamic> response,
    this.event,
  )   : enforcer = (response[0] as _i2.EthereumAddress);

  final _i2.EthereumAddress enforcer;

  final _i1.FilterEvent event;
}

class EnforcerScheduled {
  EnforcerScheduled(
    List<dynamic> response,
    this.event,
  )   : enforcer = (response[0] as _i2.EthereumAddress),
        activeAt = (response[1] as BigInt);

  final _i2.EthereumAddress enforcer;

  final BigInt activeAt;

  final _i1.FilterEvent event;
}

class FreezeExpired {
  FreezeExpired(
    List<dynamic> response,
    this.event,
  )   : account = (response[0] as _i2.EthereumAddress);

  final _i2.EthereumAddress account;

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

class NoGoAdded {
  NoGoAdded(
    List<dynamic> response,
    this.event,
  )   : target = (response[0] as _i2.EthereumAddress);

  final _i2.EthereumAddress target;

  final _i1.FilterEvent event;
}

class NoGoRemovalScheduled {
  NoGoRemovalScheduled(
    List<dynamic> response,
    this.event,
  )   : target = (response[0] as _i2.EthereumAddress),
        at = (response[1] as BigInt);

  final _i2.EthereumAddress target;

  final BigInt at;

  final _i1.FilterEvent event;
}

class NoGoRemoved {
  NoGoRemoved(
    List<dynamic> response,
    this.event,
  )   : target = (response[0] as _i2.EthereumAddress);

  final _i2.EthereumAddress target;

  final _i1.FilterEvent event;
}

class PolicyKeyMintCapSet {
  PolicyKeyMintCapSet(
    List<dynamic> response,
    this.event,
  )   : key = (response[0] as _i3.Uint8List),
        cap = (response[1] as BigInt);

  final _i3.Uint8List key;

  final BigInt cap;

  final _i1.FilterEvent event;
}

class PolicyKeySet {
  PolicyKeySet(
    List<dynamic> response,
    this.event,
  )   : key = (response[0] as _i3.Uint8List),
        on = (response[1] as bool);

  final _i3.Uint8List key;

  final bool on;

  final _i1.FilterEvent event;
}

class PolicyMintCapSet {
  PolicyMintCapSet(
    List<dynamic> response,
    this.event,
  )   : policy = (response[0] as _i2.EthereumAddress),
        newCap = (response[1] as BigInt);

  final _i2.EthereumAddress policy;

  final BigInt newCap;

  final _i1.FilterEvent event;
}

class PolicyRegistered {
  PolicyRegistered(
    List<dynamic> response,
    this.event,
  )   : policy = (response[0] as _i2.EthereumAddress);

  final _i2.EthereumAddress policy;

  final _i1.FilterEvent event;
}

class PolicyRemoved {
  PolicyRemoved(
    List<dynamic> response,
    this.event,
  )   : policy = (response[0] as _i2.EthereumAddress);

  final _i2.EthereumAddress policy;

  final _i1.FilterEvent event;
}

class TokensBurned {
  TokensBurned(
    List<dynamic> response,
    this.event,
  )   : policy = (response[0] as _i2.EthereumAddress),
        from = (response[1] as _i2.EthereumAddress),
        amount = (response[2] as BigInt);

  final _i2.EthereumAddress policy;

  final _i2.EthereumAddress from;

  final BigInt amount;

  final _i1.FilterEvent event;
}

class TokensMinted {
  TokensMinted(
    List<dynamic> response,
    this.event,
  )   : policy = (response[0] as _i2.EthereumAddress),
        to = (response[1] as _i2.EthereumAddress),
        amount = (response[2] as BigInt);

  final _i2.EthereumAddress policy;

  final _i2.EthereumAddress to;

  final BigInt amount;

  final _i1.FilterEvent event;
}

class TokensTransferred {
  TokensTransferred(
    List<dynamic> response,
    this.event,
  )   : policy = (response[0] as _i2.EthereumAddress),
        from = (response[1] as _i2.EthereumAddress),
        to = (response[2] as _i2.EthereumAddress),
        amount = (response[3] as BigInt);

  final _i2.EthereumAddress policy;

  final _i2.EthereumAddress from;

  final _i2.EthereumAddress to;

  final BigInt amount;

  final _i1.FilterEvent event;
}
