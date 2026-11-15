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
  '[{"inputs":[{"internalType":"address","name":"_moduleRegistry","type":"address"},{"internalType":"address","name":"_flagRegistryMemory","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[],"name":"AdminCapReached","type":"error"},{"inputs":[],"name":"AlreadyAdmin","type":"error"},{"inputs":[],"name":"InvalidAdmin","type":"error"},{"inputs":[],"name":"InvalidShortString","type":"error"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"ModuleNotRegistered","type":"error"},{"inputs":[],"name":"NotAdmin","type":"error"},{"inputs":[],"name":"NotAuthorized","type":"error"},{"inputs":[],"name":"RootNotResolvable","type":"error"},{"inputs":[{"internalType":"string","name":"str","type":"string"}],"name":"StringTooLong","type":"error"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"admin","type":"address"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"AdminAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"admin","type":"address"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"AdminRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint8","name":"id","type":"uint8"},{"indexed":false,"internalType":"bool","name":"enabled","type":"bool"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"CategorySet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"string","name":"evidence","type":"string"},{"indexed":false,"internalType":"bool","name":"closed","type":"bool"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"CourtNote","type":"event"},{"anonymous":false,"inputs":[],"name":"EIP712DomainChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"bool","name":"overturned","type":"bool"},{"indexed":false,"internalType":"string","name":"evidence","type":"string"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"FlagRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"window","type":"uint256"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"FlagWindowSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":true,"internalType":"address","name":"flagger","type":"address"}],"name":"FlagWithdrawn","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":true,"internalType":"address","name":"flagger","type":"address"},{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"bytes32","name":"target","type":"bytes32"},{"indexed":false,"internalType":"string","name":"url","type":"string"},{"indexed":false,"internalType":"bytes32","name":"contentHash","type":"bytes32"},{"indexed":false,"internalType":"string","name":"host","type":"string"},{"indexed":false,"internalType":"uint8","name":"category","type":"uint8"},{"indexed":false,"internalType":"string","name":"note","type":"string"},{"indexed":false,"internalType":"uint64","name":"expiresAt","type":"uint64"}],"name":"Flagged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"string","name":"evidence","type":"string"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"FlaggerRestored","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"uint64","name":"until","type":"uint64"},{"indexed":false,"internalType":"string","name":"evidence","type":"string"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"FlaggerSuspended","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bool","name":"on","type":"bool"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"InheritanceSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"NoticeClosed","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":true,"internalType":"address","name":"requester","type":"address"},{"indexed":false,"internalType":"string","name":"host","type":"string"},{"indexed":false,"internalType":"bytes32","name":"commitment","type":"bytes32"}],"name":"NoticeFiled","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":true,"internalType":"address","name":"by","type":"address"},{"indexed":false,"internalType":"enum IFlagRegistryMemory.NoticeStatus","name":"status","type":"uint8"},{"indexed":false,"internalType":"uint64","name":"at","type":"uint64"},{"indexed":false,"internalType":"address","name":"signer","type":"address"}],"name":"NoticeUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"cooldown","type":"uint256"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"ReflagCooldownSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"bytes32","name":"target","type":"bytes32"},{"indexed":false,"internalType":"uint256","name":"count","type":"uint256"},{"indexed":false,"internalType":"bool","name":"overturned","type":"bool"},{"indexed":false,"internalType":"string","name":"evidence","type":"string"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"TargetCleared","type":"event"},{"inputs":[],"name":"MAX_FLAG_WINDOW","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"MAX_NOTE","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"MAX_REFLAG_COOLDOWN","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"MAX_SUSPENSION","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"MAX_URL","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"MIN_FLAG_WINDOW","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"MIN_REFLAG_COOLDOWN","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"MIN_SUSPENSION","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"NOTICE_UPDATE_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"bytes32","name":"target","type":"bytes32"},{"internalType":"uint8","name":"category","type":"uint8"},{"internalType":"uint256","name":"from","type":"uint256"},{"internalType":"uint256","name":"limit","type":"uint256"}],"name":"activeCount","outputs":[{"internalType":"uint256","name":"k","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"bytes32","name":"target","type":"bytes32"},{"internalType":"uint256","name":"from","type":"uint256"},{"internalType":"uint256","name":"limit","type":"uint256"}],"name":"activeFlags","outputs":[{"internalType":"uint256[]","name":"out","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"addAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"admins","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"bytes32","name":"target","type":"bytes32"},{"internalType":"bool","name":"overturned","type":"bool"},{"internalType":"string","name":"evidence","type":"string"}],"name":"clearTarget","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"close","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"evidence","type":"string"},{"internalType":"bool","name":"closeIt","type":"bool"}],"name":"courtNote","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"eip712Domain","outputs":[{"internalType":"bytes1","name":"fields","type":"bytes1"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"version","type":"string"},{"internalType":"uint256","name":"chainId","type":"uint256"},{"internalType":"address","name":"verifyingContract","type":"address"},{"internalType":"bytes32","name":"salt","type":"bytes32"},{"internalType":"uint256[]","name":"extensions","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"host","type":"string"},{"internalType":"bytes32","name":"commitment","type":"bytes32"}],"name":"fileNotice","outputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"bytes32","name":"target","type":"bytes32"},{"internalType":"string","name":"url","type":"string"},{"internalType":"bytes32","name":"contentHash","type":"bytes32"},{"internalType":"string","name":"host","type":"string"},{"internalType":"uint8","name":"category","type":"uint8"},{"internalType":"string","name":"note","type":"string"}],"name":"flag","outputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"flagRegistryMemory","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"flagWindow","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"inheritanceOn","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"isAdmin","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint8","name":"id","type":"uint8"}],"name":"isCategoryEnabled","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleRegistry","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleType","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"enum IFlagRegistryMemory.NoticeStatus","name":"status","type":"uint8"},{"internalType":"uint64","name":"at","type":"uint64"}],"name":"noticeDigest","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"enum IFlagRegistryMemory.NoticeStatus","name":"status","type":"uint8"},{"internalType":"uint64","name":"at","type":"uint64"},{"internalType":"bytes","name":"sig","type":"bytes"}],"name":"pushUpdate","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"reflagCooldown","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"removeAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"bool","name":"overturned","type":"bool"},{"internalType":"string","name":"evidence","type":"string"}],"name":"removeFlag","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"string","name":"evidence","type":"string"}],"name":"restoreFlagger","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint8","name":"id","type":"uint8"},{"internalType":"bool","name":"enabled","type":"bool"}],"name":"setCategory","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"window","type":"uint256"}],"name":"setFlagWindow","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"on","type":"bool"}],"name":"setInheritance","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"cooldown","type":"uint256"}],"name":"setReflagCooldown","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"duration","type":"uint256"},{"internalType":"string","name":"evidence","type":"string"}],"name":"suspendFlagger","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"bytes32","name":"target","type":"bytes32"}],"name":"targetFlagCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"bytes32","name":"target","type":"bytes32"}],"name":"unflag","outputs":[],"stateMutability":"nonpayable","type":"function"}]',
  'FlagRegistryManager',
);

class FlagRegistryManager extends _i1.GeneratedContract {
  FlagRegistryManager({
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
  Future<BigInt> MAX_FLAG_WINDOW(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '8989d8fd'));
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
  Future<BigInt> MAX_NOTE(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, '92727498'));
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
  Future<BigInt> MAX_REFLAG_COOLDOWN(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, '2d763a75'));
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
  Future<BigInt> MAX_SUSPENSION(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, '5b9d46a0'));
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
  Future<BigInt> MAX_URL(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, '90dd258f'));
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
  Future<BigInt> MIN_FLAG_WINDOW(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, 'dcf8ccb0'));
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
  Future<BigInt> MIN_REFLAG_COOLDOWN(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, 'a39e13fa'));
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
  Future<BigInt> MIN_SUSPENSION(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, '6226f695'));
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
  Future<_i3.Uint8List> NOTICE_UPDATE_TYPEHASH(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[9];
    assert(checkSignature(function, '8983b19f'));
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
  Future<BigInt> activeCount(
    ({_i2.EthereumAddress owner, _i3.Uint8List target, BigInt category, BigInt from, BigInt limit}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[10];
    assert(checkSignature(function, '8e6076e1'));
    final params = [
      args.owner,
      args.target,
      args.category,
      args.from,
      args.limit,
    ];
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
  Future<List<BigInt>> activeFlags(
    ({_i2.EthereumAddress owner, _i3.Uint8List target, BigInt from, BigInt limit}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[11];
    assert(checkSignature(function, '4722f43e'));
    final params = [
      args.owner,
      args.target,
      args.from,
      args.limit,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<BigInt>();
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> addAdmin(
    ({_i2.EthereumAddress account}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[12];
    assert(checkSignature(function, '70480275'));
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
  Future<List<_i2.EthereumAddress>> admins(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[13];
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
  Future<String> clearTarget(
    ({_i2.EthereumAddress owner, _i3.Uint8List target, bool overturned, String evidence}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[14];
    assert(checkSignature(function, 'b1c4263a'));
    final params = [
      args.owner,
      args.target,
      args.overturned,
      args.evidence,
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
  Future<String> close(
    ({BigInt id}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[15];
    assert(checkSignature(function, '0aebeb4e'));
    final params = [args.id];
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
  Future<String> courtNote(
    ({BigInt id, String evidence, bool closeIt}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[16];
    assert(checkSignature(function, '56605c1c'));
    final params = [
      args.id,
      args.evidence,
      args.closeIt,
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
  Future<String> fileNotice(
    ({String host, _i3.Uint8List commitment}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[18];
    assert(checkSignature(function, 'f5f37cf6'));
    final params = [
      args.host,
      args.commitment,
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
  Future<String> flag(
    ({_i2.EthereumAddress owner, _i3.Uint8List target, String url, _i3.Uint8List contentHash, String host, BigInt category, String note}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[19];
    assert(checkSignature(function, '361c9a4d'));
    final params = [
      args.owner,
      args.target,
      args.url,
      args.contentHash,
      args.host,
      args.category,
      args.note,
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
  Future<_i2.EthereumAddress> flagRegistryMemory(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[20];
    assert(checkSignature(function, 'e1d57d18'));
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
  Future<BigInt> flagWindow(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[21];
    assert(checkSignature(function, '82f6420c'));
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
    final function = self.abi.functions[22];
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
    final function = self.abi.functions[23];
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
  Future<bool> isCategoryEnabled(
    ({BigInt id}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[24];
    assert(checkSignature(function, 'b51d3202'));
    final params = [args.id];
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
  Future<_i2.EthereumAddress> moduleRegistry(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[25];
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
    final function = self.abi.functions[26];
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
  Future<_i3.Uint8List> noticeDigest(
    ({BigInt id, BigInt status, BigInt at}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[27];
    assert(checkSignature(function, '1b2e74a3'));
    final params = [
      args.id,
      args.status,
      args.at,
    ];
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
  Future<String> pushUpdate(
    ({BigInt id, BigInt status, BigInt at, _i3.Uint8List sig}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[28];
    assert(checkSignature(function, '60411e4e'));
    final params = [
      args.id,
      args.status,
      args.at,
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
  Future<BigInt> reflagCooldown(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[29];
    assert(checkSignature(function, '8a2a5fc3'));
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
  Future<String> removeAdmin(
    ({_i2.EthereumAddress account}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[30];
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
  Future<String> removeFlag(
    ({BigInt id, bool overturned, String evidence}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[31];
    assert(checkSignature(function, '2728491b'));
    final params = [
      args.id,
      args.overturned,
      args.evidence,
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
  Future<String> restoreFlagger(
    ({_i2.EthereumAddress account, String evidence}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[32];
    assert(checkSignature(function, '5d0932bf'));
    final params = [
      args.account,
      args.evidence,
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
  Future<String> setCategory(
    ({BigInt id, bool enabled}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[33];
    assert(checkSignature(function, '7c479251'));
    final params = [
      args.id,
      args.enabled,
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
  Future<String> setFlagWindow(
    ({BigInt window}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[34];
    assert(checkSignature(function, '80a100c0'));
    final params = [args.window];
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
  Future<String> setReflagCooldown(
    ({BigInt cooldown}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[36];
    assert(checkSignature(function, '62a79b36'));
    final params = [args.cooldown];
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
  Future<String> suspendFlagger(
    ({_i2.EthereumAddress account, BigInt duration, String evidence}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[37];
    assert(checkSignature(function, '5a6b483a'));
    final params = [
      args.account,
      args.duration,
      args.evidence,
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
  Future<BigInt> targetFlagCount(
    ({_i2.EthereumAddress owner, _i3.Uint8List target}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[38];
    assert(checkSignature(function, '61ab28f0'));
    final params = [
      args.owner,
      args.target,
    ];
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
  Future<String> unflag(
    ({_i2.EthereumAddress owner, _i3.Uint8List target}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[39];
    assert(checkSignature(function, '1824c4d0'));
    final params = [
      args.owner,
      args.target,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
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

  /// Returns a live stream of all CategorySet events emitted by this contract.
  Stream<CategorySet> categorySetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('CategorySet');
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
      return CategorySet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all CourtNote events emitted by this contract.
  Stream<CourtNote> courtNoteEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('CourtNote');
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
      return CourtNote(
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

  /// Returns a live stream of all FlagRemoved events emitted by this contract.
  Stream<FlagRemoved> flagRemovedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('FlagRemoved');
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
      return FlagRemoved(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all FlagWindowSet events emitted by this contract.
  Stream<FlagWindowSet> flagWindowSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('FlagWindowSet');
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
      return FlagWindowSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all FlagWithdrawn events emitted by this contract.
  Stream<FlagWithdrawn> flagWithdrawnEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('FlagWithdrawn');
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
      return FlagWithdrawn(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Flagged events emitted by this contract.
  Stream<Flagged> flaggedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Flagged');
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
      return Flagged(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all FlaggerRestored events emitted by this contract.
  Stream<FlaggerRestored> flaggerRestoredEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('FlaggerRestored');
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
      return FlaggerRestored(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all FlaggerSuspended events emitted by this contract.
  Stream<FlaggerSuspended> flaggerSuspendedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('FlaggerSuspended');
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
      return FlaggerSuspended(
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

  /// Returns a live stream of all NoticeClosed events emitted by this contract.
  Stream<NoticeClosed> noticeClosedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('NoticeClosed');
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
      return NoticeClosed(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all NoticeFiled events emitted by this contract.
  Stream<NoticeFiled> noticeFiledEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('NoticeFiled');
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
      return NoticeFiled(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all NoticeUpdated events emitted by this contract.
  Stream<NoticeUpdated> noticeUpdatedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('NoticeUpdated');
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
      return NoticeUpdated(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all ReflagCooldownSet events emitted by this contract.
  Stream<ReflagCooldownSet> reflagCooldownSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('ReflagCooldownSet');
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
      return ReflagCooldownSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all TargetCleared events emitted by this contract.
  Stream<TargetCleared> targetClearedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('TargetCleared');
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
      return TargetCleared(
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

class CategorySet {
  CategorySet(
    List<dynamic> response,
    this.event,
  )   : id = (response[0] as BigInt),
        enabled = (response[1] as bool),
        by = (response[2] as _i2.EthereumAddress);

  final BigInt id;

  final bool enabled;

  final _i2.EthereumAddress by;

  final _i1.FilterEvent event;
}

class CourtNote {
  CourtNote(
    List<dynamic> response,
    this.event,
  )   : id = (response[0] as BigInt),
        evidence = (response[1] as String),
        closed = (response[2] as bool),
        by = (response[3] as _i2.EthereumAddress);

  final BigInt id;

  final String evidence;

  final bool closed;

  final _i2.EthereumAddress by;

  final _i1.FilterEvent event;
}

class EIP712DomainChanged {
  EIP712DomainChanged(
    List<dynamic> response,
    this.event,
  );

  final _i1.FilterEvent event;
}

class FlagRemoved {
  FlagRemoved(
    List<dynamic> response,
    this.event,
  )   : id = (response[0] as BigInt),
        overturned = (response[1] as bool),
        evidence = (response[2] as String),
        by = (response[3] as _i2.EthereumAddress);

  final BigInt id;

  final bool overturned;

  final String evidence;

  final _i2.EthereumAddress by;

  final _i1.FilterEvent event;
}

class FlagWindowSet {
  FlagWindowSet(
    List<dynamic> response,
    this.event,
  )   : window = (response[0] as BigInt),
        by = (response[1] as _i2.EthereumAddress);

  final BigInt window;

  final _i2.EthereumAddress by;

  final _i1.FilterEvent event;
}

class FlagWithdrawn {
  FlagWithdrawn(
    List<dynamic> response,
    this.event,
  )   : id = (response[0] as BigInt),
        flagger = (response[1] as _i2.EthereumAddress);

  final BigInt id;

  final _i2.EthereumAddress flagger;

  final _i1.FilterEvent event;
}

class Flagged {
  Flagged(
    List<dynamic> response,
    this.event,
  )   : id = (response[0] as BigInt),
        flagger = (response[1] as _i2.EthereumAddress),
        owner = (response[2] as _i2.EthereumAddress),
        target = (response[3] as _i3.Uint8List),
        url = (response[4] as String),
        contentHash = (response[5] as _i3.Uint8List),
        host = (response[6] as String),
        category = (response[7] as BigInt),
        note = (response[8] as String),
        expiresAt = (response[9] as BigInt);

  final BigInt id;

  final _i2.EthereumAddress flagger;

  final _i2.EthereumAddress owner;

  final _i3.Uint8List target;

  final String url;

  final _i3.Uint8List contentHash;

  final String host;

  final BigInt category;

  final String note;

  final BigInt expiresAt;

  final _i1.FilterEvent event;
}

class FlaggerRestored {
  FlaggerRestored(
    List<dynamic> response,
    this.event,
  )   : account = (response[0] as _i2.EthereumAddress),
        evidence = (response[1] as String),
        by = (response[2] as _i2.EthereumAddress);

  final _i2.EthereumAddress account;

  final String evidence;

  final _i2.EthereumAddress by;

  final _i1.FilterEvent event;
}

class FlaggerSuspended {
  FlaggerSuspended(
    List<dynamic> response,
    this.event,
  )   : account = (response[0] as _i2.EthereumAddress),
        until = (response[1] as BigInt),
        evidence = (response[2] as String),
        by = (response[3] as _i2.EthereumAddress);

  final _i2.EthereumAddress account;

  final BigInt until;

  final String evidence;

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

class NoticeClosed {
  NoticeClosed(
    List<dynamic> response,
    this.event,
  )   : id = (response[0] as BigInt),
        by = (response[1] as _i2.EthereumAddress);

  final BigInt id;

  final _i2.EthereumAddress by;

  final _i1.FilterEvent event;
}

class NoticeFiled {
  NoticeFiled(
    List<dynamic> response,
    this.event,
  )   : id = (response[0] as BigInt),
        requester = (response[1] as _i2.EthereumAddress),
        host = (response[2] as String),
        commitment = (response[3] as _i3.Uint8List);

  final BigInt id;

  final _i2.EthereumAddress requester;

  final String host;

  final _i3.Uint8List commitment;

  final _i1.FilterEvent event;
}

class NoticeUpdated {
  NoticeUpdated(
    List<dynamic> response,
    this.event,
  )   : id = (response[0] as BigInt),
        by = (response[1] as _i2.EthereumAddress),
        status = (response[2] as BigInt),
        at = (response[3] as BigInt),
        signer = (response[4] as _i2.EthereumAddress);

  final BigInt id;

  final _i2.EthereumAddress by;

  final BigInt status;

  final BigInt at;

  final _i2.EthereumAddress signer;

  final _i1.FilterEvent event;
}

class ReflagCooldownSet {
  ReflagCooldownSet(
    List<dynamic> response,
    this.event,
  )   : cooldown = (response[0] as BigInt),
        by = (response[1] as _i2.EthereumAddress);

  final BigInt cooldown;

  final _i2.EthereumAddress by;

  final _i1.FilterEvent event;
}

class TargetCleared {
  TargetCleared(
    List<dynamic> response,
    this.event,
  )   : owner = (response[0] as _i2.EthereumAddress),
        target = (response[1] as _i3.Uint8List),
        count = (response[2] as BigInt),
        overturned = (response[3] as bool),
        evidence = (response[4] as String),
        by = (response[5] as _i2.EthereumAddress);

  final _i2.EthereumAddress owner;

  final _i3.Uint8List target;

  final BigInt count;

  final bool overturned;

  final String evidence;

  final _i2.EthereumAddress by;

  final _i1.FilterEvent event;
}
