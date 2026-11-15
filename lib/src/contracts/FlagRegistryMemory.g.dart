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
  '[{"inputs":[{"internalType":"address","name":"_moduleRegistry","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"attachmentsOf","outputs":[{"components":[{"internalType":"address","name":"by","type":"address"},{"internalType":"enum IFlagRegistryMemory.NoticeStatus","name":"status","type":"uint8"},{"internalType":"uint64","name":"at","type":"uint64"},{"internalType":"address","name":"signer","type":"address"},{"internalType":"bytes","name":"sig","type":"bytes"}],"internalType":"struct IFlagRegistryMemory.Attachment[]","name":"","type":"tuple[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"bytes32","name":"target","type":"bytes32"},{"internalType":"bool","name":"overturned","type":"bool"}],"name":"clear","outputs":[{"internalType":"uint256","name":"count","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"close","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"flagCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"flagger","type":"address"},{"internalType":"uint256","name":"from","type":"uint256"},{"internalType":"uint256","name":"limit","type":"uint256"}],"name":"flaggerFlagIds","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"getFlag","outputs":[{"components":[{"internalType":"address","name":"flagger","type":"address"},{"internalType":"address","name":"owner","type":"address"},{"internalType":"bytes32","name":"target","type":"bytes32"},{"internalType":"bytes32","name":"contentHash","type":"bytes32"},{"internalType":"uint8","name":"category","type":"uint8"},{"internalType":"enum IFlagRegistryMemory.FlagStatus","name":"status","type":"uint8"},{"internalType":"uint64","name":"createdAt","type":"uint64"},{"internalType":"uint64","name":"expiresAt","type":"uint64"},{"internalType":"string","name":"url","type":"string"},{"internalType":"string","name":"host","type":"string"},{"internalType":"string","name":"note","type":"string"}],"internalType":"struct IFlagRegistryMemory.Flag","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"getNotice","outputs":[{"components":[{"internalType":"address","name":"requester","type":"address"},{"internalType":"bytes32","name":"commitment","type":"bytes32"},{"internalType":"uint64","name":"filedAt","type":"uint64"},{"internalType":"bool","name":"closed","type":"bool"},{"internalType":"string","name":"host","type":"string"}],"internalType":"struct IFlagRegistryMemory.Notice","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"host","type":"string"},{"internalType":"uint256","name":"from","type":"uint256"},{"internalType":"uint256","name":"limit","type":"uint256"}],"name":"hostFlagIds","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"host","type":"string"},{"internalType":"uint256","name":"from","type":"uint256"},{"internalType":"uint256","name":"limit","type":"uint256"}],"name":"hostNoticeIds","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"isOpen","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"flagger","type":"address"},{"internalType":"address","name":"owner","type":"address"},{"internalType":"bytes32","name":"target","type":"bytes32"}],"name":"lastFlagId","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleRegistry","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleType","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"noticeCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"flagger","type":"address"},{"internalType":"address","name":"owner","type":"address"},{"internalType":"bytes32","name":"target","type":"bytes32"}],"name":"openFlagId","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"components":[{"internalType":"address","name":"by","type":"address"},{"internalType":"enum IFlagRegistryMemory.NoticeStatus","name":"status","type":"uint8"},{"internalType":"uint64","name":"at","type":"uint64"},{"internalType":"address","name":"signer","type":"address"},{"internalType":"bytes","name":"sig","type":"bytes"}],"internalType":"struct IFlagRegistryMemory.Attachment","name":"a","type":"tuple"}],"name":"pushAttachment","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"components":[{"internalType":"address","name":"flagger","type":"address"},{"internalType":"address","name":"owner","type":"address"},{"internalType":"bytes32","name":"target","type":"bytes32"},{"internalType":"bytes32","name":"contentHash","type":"bytes32"},{"internalType":"uint8","name":"category","type":"uint8"},{"internalType":"enum IFlagRegistryMemory.FlagStatus","name":"status","type":"uint8"},{"internalType":"uint64","name":"createdAt","type":"uint64"},{"internalType":"uint64","name":"expiresAt","type":"uint64"},{"internalType":"string","name":"url","type":"string"},{"internalType":"string","name":"host","type":"string"},{"internalType":"string","name":"note","type":"string"}],"internalType":"struct IFlagRegistryMemory.Flag","name":"f","type":"tuple"},{"internalType":"uint256","name":"reflagCooldown","type":"uint256"}],"name":"pushFlag","outputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"requester","type":"address"},{"internalType":"string","name":"host","type":"string"},{"internalType":"bytes32","name":"commitment","type":"bytes32"}],"name":"pushNotice","outputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"bool","name":"overturned","type":"bool"}],"name":"remove","outputs":[{"internalType":"address","name":"flagger","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint64","name":"until","type":"uint64"}],"name":"setSuspendedUntil","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"standingOf","outputs":[{"components":[{"internalType":"uint256","name":"filed","type":"uint256"},{"internalType":"uint256","name":"overturned","type":"uint256"},{"internalType":"uint64","name":"suspendedUntil","type":"uint64"}],"internalType":"struct IFlagRegistryMemory.Standing","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"bytes32","name":"target","type":"bytes32"}],"name":"targetFlagCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"bytes32","name":"target","type":"bytes32"},{"internalType":"uint256","name":"from","type":"uint256"},{"internalType":"uint256","name":"limit","type":"uint256"}],"name":"targetFlagIds","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"flagger","type":"address"},{"internalType":"address","name":"owner","type":"address"},{"internalType":"bytes32","name":"target","type":"bytes32"}],"name":"withdraw","outputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"stateMutability":"nonpayable","type":"function"}]',
  'FlagRegistryMemory',
);

class FlagRegistryMemory extends _i1.GeneratedContract {
  FlagRegistryMemory({
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
  Future<dynamic> attachmentsOf(
    ({BigInt id}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '226dd55c'));
    final params = [args.id];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as dynamic);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> clear(
    ({_i2.EthereumAddress owner, _i3.Uint8List target, bool overturned}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, '05bdaee7'));
    final params = [
      args.owner,
      args.target,
      args.overturned,
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
    final function = self.abi.functions[3];
    assert(checkSignature(function, '0aebeb4e'));
    final params = [args.id];
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
  Future<BigInt> flagCount(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, 'f5dc7c4c'));
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
  Future<List<BigInt>> flaggerFlagIds(
    ({_i2.EthereumAddress flagger, BigInt from, BigInt limit}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, 'e01d78c2'));
    final params = [
      args.flagger,
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

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<dynamic> getFlag(
    ({BigInt id}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, '95fdc999'));
    final params = [args.id];
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
  Future<dynamic> getNotice(
    ({BigInt id}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, '5becfac7'));
    final params = [args.id];
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
  Future<List<BigInt>> hostFlagIds(
    ({String host, BigInt from, BigInt limit}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, 'e9d67559'));
    final params = [
      args.host,
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

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<BigInt>> hostNoticeIds(
    ({String host, BigInt from, BigInt limit}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[9];
    assert(checkSignature(function, 'a4eafd57'));
    final params = [
      args.host,
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

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> isOpen(
    ({BigInt id}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[10];
    assert(checkSignature(function, '4d6861a6'));
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
  Future<BigInt> lastFlagId(
    ({_i2.EthereumAddress flagger, _i2.EthereumAddress owner, _i3.Uint8List target}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[11];
    assert(checkSignature(function, 'b8122df5'));
    final params = [
      args.flagger,
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

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i2.EthereumAddress> moduleRegistry(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[12];
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
    final function = self.abi.functions[13];
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
  Future<BigInt> noticeCount(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[14];
    assert(checkSignature(function, '67251e82'));
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
  Future<BigInt> openFlagId(
    ({_i2.EthereumAddress flagger, _i2.EthereumAddress owner, _i3.Uint8List target}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[15];
    assert(checkSignature(function, '7cf9b2d8'));
    final params = [
      args.flagger,
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
  Future<String> pushAttachment(
    ({BigInt id, dynamic a}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[16];
    assert(checkSignature(function, 'fb24bf5a'));
    final params = [
      args.id,
      args.a,
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
  Future<String> pushFlag(
    ({dynamic f, BigInt reflagCooldown}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[17];
    assert(checkSignature(function, 'c7b62694'));
    final params = [
      args.f,
      args.reflagCooldown,
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
  Future<String> pushNotice(
    ({_i2.EthereumAddress requester, String host, _i3.Uint8List commitment}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[18];
    assert(checkSignature(function, 'da18ad04'));
    final params = [
      args.requester,
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
  Future<String> remove(
    ({BigInt id, bool overturned}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[19];
    assert(checkSignature(function, 'd5f615c6'));
    final params = [
      args.id,
      args.overturned,
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
  Future<String> setSuspendedUntil(
    ({_i2.EthereumAddress account, BigInt until}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[20];
    assert(checkSignature(function, '150e5e0d'));
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

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<dynamic> standingOf(
    ({_i2.EthereumAddress account}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[21];
    assert(checkSignature(function, '2254f925'));
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
  Future<BigInt> targetFlagCount(
    ({_i2.EthereumAddress owner, _i3.Uint8List target}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[22];
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

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<BigInt>> targetFlagIds(
    ({_i2.EthereumAddress owner, _i3.Uint8List target, BigInt from, BigInt limit}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[23];
    assert(checkSignature(function, 'cb91e373'));
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
  Future<String> withdraw(
    ({_i2.EthereumAddress flagger, _i2.EthereumAddress owner, _i3.Uint8List target}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[24];
    assert(checkSignature(function, 'd2701f99'));
    final params = [
      args.flagger,
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
}
