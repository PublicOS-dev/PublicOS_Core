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
  '[{"inputs":[{"internalType":"address","name":"_minterAccountAddress","type":"address"},{"internalType":"address","name":"_moduleRegistryAddress","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[{"internalType":"address","name":"token","type":"address"}],"name":"SafeERC20FailedOperation","type":"error"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"token","type":"address"},{"indexed":false,"internalType":"uint256","name":"amountOrId","type":"uint256"},{"indexed":true,"internalType":"address","name":"mainSafe","type":"address"}],"name":"Swept","type":"event"},{"inputs":[{"internalType":"bytes32[]","name":"keep","type":"bytes32[]"},{"internalType":"uint256","name":"limit","type":"uint256"}],"name":"clearRecords","outputs":[{"internalType":"uint256","name":"deleted","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"key","type":"string"}],"name":"deleteRecord","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string[]","name":"keys","type":"string[]"}],"name":"deleteRecords","outputs":[{"internalType":"uint256","name":"deleted","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"offset","type":"uint256"},{"internalType":"uint256","name":"limit","type":"uint256"}],"name":"getAllRecords","outputs":[{"internalType":"string[]","name":"keys","type":"string[]"},{"internalType":"string[]","name":"values","type":"string[]"},{"internalType":"uint256[]","name":"expirations","type":"uint256[]"},{"internalType":"uint8[]","name":"types","type":"uint8[]"},{"internalType":"string[]","name":"customTypes","type":"string[]"},{"internalType":"bool[]","name":"expired","type":"bool[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getAllRecords","outputs":[{"internalType":"string[]","name":"keys","type":"string[]"},{"internalType":"string[]","name":"values","type":"string[]"},{"internalType":"uint256[]","name":"expirations","type":"uint256[]"},{"internalType":"uint8[]","name":"types","type":"uint8[]"},{"internalType":"string[]","name":"customTypes","type":"string[]"},{"internalType":"bool[]","name":"expired","type":"bool[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getMinter","outputs":[{"internalType":"address","name":"minterAccountAddress","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"key","type":"string"}],"name":"getRecord","outputs":[{"internalType":"string","name":"value","type":"string"},{"internalType":"uint256","name":"expiration","type":"uint256"},{"internalType":"uint8","name":"recordType","type":"uint8"},{"internalType":"string","name":"customType","type":"string"},{"internalType":"bool","name":"exists","type":"bool"},{"internalType":"bool","name":"expired","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getRecordCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"customTypeValue","type":"string"}],"name":"getRecordsByCustomType","outputs":[{"internalType":"string[]","name":"keys","type":"string[]"},{"internalType":"string[]","name":"values","type":"string[]"},{"internalType":"uint256[]","name":"expirations","type":"uint256[]"},{"internalType":"bool[]","name":"expired","type":"bool[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"customTypeValue","type":"string"},{"internalType":"uint256","name":"offset","type":"uint256"},{"internalType":"uint256","name":"limit","type":"uint256"}],"name":"getRecordsByCustomType","outputs":[{"internalType":"string[]","name":"keys","type":"string[]"},{"internalType":"string[]","name":"values","type":"string[]"},{"internalType":"uint256[]","name":"expirations","type":"uint256[]"},{"internalType":"bool[]","name":"expired","type":"bool[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint8","name":"recordTypeValue","type":"uint8"},{"internalType":"uint256","name":"offset","type":"uint256"},{"internalType":"uint256","name":"limit","type":"uint256"}],"name":"getRecordsByType","outputs":[{"internalType":"string[]","name":"keys","type":"string[]"},{"internalType":"string[]","name":"values","type":"string[]"},{"internalType":"uint256[]","name":"expirations","type":"uint256[]"},{"internalType":"string[]","name":"customTypes","type":"string[]"},{"internalType":"bool[]","name":"expired","type":"bool[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint8","name":"recordTypeValue","type":"uint8"}],"name":"getRecordsByType","outputs":[{"internalType":"string[]","name":"keys","type":"string[]"},{"internalType":"string[]","name":"values","type":"string[]"},{"internalType":"uint256[]","name":"expirations","type":"uint256[]"},{"internalType":"string[]","name":"customTypes","type":"string[]"},{"internalType":"bool[]","name":"expired","type":"bool[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"key","type":"string"}],"name":"hasRecord","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_minterAccountAddress","type":"address"},{"internalType":"address","name":"_moduleRegistryAddress","type":"address"}],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"minter","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleRegistry","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"key","type":"string"},{"internalType":"string","name":"value","type":"string"},{"internalType":"uint256","name":"expiration","type":"uint256"},{"internalType":"uint8","name":"recordTypeValue","type":"uint8"},{"internalType":"string","name":"customType","type":"string"}],"name":"setRecord","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string[]","name":"keys","type":"string[]"},{"internalType":"string[]","name":"values","type":"string[]"},{"internalType":"uint256[]","name":"expirations","type":"uint256[]"},{"internalType":"uint8[]","name":"recordTypes","type":"uint8[]"},{"internalType":"string[]","name":"customTypes","type":"string[]"}],"name":"setRecords","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"}],"name":"sweepERC20","outputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"sweepERC721","outputs":[],"stateMutability":"nonpayable","type":"function"}]',
  'AccountBlueprint',
);

class AccountBlueprint extends _i1.GeneratedContract {
  AccountBlueprint({
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

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> clearRecords(
    ({dynamic keep, BigInt limit}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, 'de1f2612'));
    final params = [
      args.keep,
      args.limit,
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
  Future<String> deleteRecord(
    ({String key}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, 'fbc47d53'));
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
  Future<String> deleteRecords(
    ({List<String> keys}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, '1007b010'));
    final params = [args.keys];
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
  Future<GetAllRecords$2> getAllRecords$2(
    ({BigInt offset, BigInt limit}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, '553e9c6e'));
    final params = [
      args.offset,
      args.limit,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return GetAllRecords$2(response);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<GetAllRecords> getAllRecords(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, 'a7f9fe72'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return GetAllRecords(response);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i2.EthereumAddress> getMinter(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, 'f3667517'));
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
  Future<GetRecord> getRecord(
    ({String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, '11dd8845'));
    final params = [args.key];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return GetRecord(response);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> getRecordCount(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, 'ca267f28'));
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
  Future<GetRecordsByCustomType> getRecordsByCustomType(
    ({String customTypeValue}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[9];
    assert(checkSignature(function, '715ad074'));
    final params = [args.customTypeValue];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return GetRecordsByCustomType(response);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<GetRecordsByCustomType$3> getRecordsByCustomType$3(
    ({String customTypeValue, BigInt offset, BigInt limit}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[10];
    assert(checkSignature(function, 'b958cf13'));
    final params = [
      args.customTypeValue,
      args.offset,
      args.limit,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return GetRecordsByCustomType$3(response);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<GetRecordsByType$3> getRecordsByType$3(
    ({BigInt recordTypeValue, BigInt offset, BigInt limit}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[11];
    assert(checkSignature(function, 'f828b140'));
    final params = [
      args.recordTypeValue,
      args.offset,
      args.limit,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return GetRecordsByType$3(response);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<GetRecordsByType> getRecordsByType(
    ({BigInt recordTypeValue}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[12];
    assert(checkSignature(function, 'f8ed51a8'));
    final params = [args.recordTypeValue];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return GetRecordsByType(response);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> hasRecord(
    ({String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[13];
    assert(checkSignature(function, '2bac2ad7'));
    final params = [args.key];
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
  Future<String> initialize(
    ({_i2.EthereumAddress minterAccountAddress, _i2.EthereumAddress moduleRegistryAddress}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[14];
    assert(checkSignature(function, '485cc955'));
    final params = [
      args.minterAccountAddress,
      args.moduleRegistryAddress,
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
  Future<_i2.EthereumAddress> minter(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[15];
    assert(checkSignature(function, '07546172'));
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
  Future<_i2.EthereumAddress> moduleRegistry(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[16];
    assert(checkSignature(function, 'b95459e4'));
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
  Future<String> setRecord(
    ({String key, String value, BigInt expiration, BigInt recordTypeValue, String customType}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[17];
    assert(checkSignature(function, 'b2219b43'));
    final params = [
      args.key,
      args.value,
      args.expiration,
      args.recordTypeValue,
      args.customType,
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
  Future<String> setRecords(
    ({List<String> keys, List<String> values, List<BigInt> expirations, List<BigInt> recordTypes, List<String> customTypes}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[18];
    assert(checkSignature(function, 'fab7298c'));
    final params = [
      args.keys,
      args.values,
      args.expirations,
      args.recordTypes,
      args.customTypes,
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
  Future<String> sweepERC20(
    ({_i2.EthereumAddress token}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[19];
    assert(checkSignature(function, 'e00af4a7'));
    final params = [args.token];
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
  Future<String> sweepERC721(
    ({_i2.EthereumAddress token, BigInt tokenId}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[20];
    assert(checkSignature(function, '7e39e1ff'));
    final params = [
      args.token,
      args.tokenId,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// Returns a live stream of all Swept events emitted by this contract.
  Stream<Swept> sweptEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Swept');
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
      return Swept(
        decoded,
        result,
      );
    });
  }
}

class GetAllRecords$2 {
  GetAllRecords$2(List<dynamic> response)
      : keys = (response[0] as List<dynamic>).cast<String>(),
        values = (response[1] as List<dynamic>).cast<String>(),
        expirations = (response[2] as List<dynamic>).cast<BigInt>(),
        types = (response[3] as List<dynamic>).cast<BigInt>(),
        customTypes = (response[4] as List<dynamic>).cast<String>(),
        expired = (response[5] as dynamic);

  final List<String> keys;

  final List<String> values;

  final List<BigInt> expirations;

  final List<BigInt> types;

  final List<String> customTypes;

  final dynamic expired;

}

class GetAllRecords {
  GetAllRecords(List<dynamic> response)
      : keys = (response[0] as List<dynamic>).cast<String>(),
        values = (response[1] as List<dynamic>).cast<String>(),
        expirations = (response[2] as List<dynamic>).cast<BigInt>(),
        types = (response[3] as List<dynamic>).cast<BigInt>(),
        customTypes = (response[4] as List<dynamic>).cast<String>(),
        expired = (response[5] as dynamic);

  final List<String> keys;

  final List<String> values;

  final List<BigInt> expirations;

  final List<BigInt> types;

  final List<String> customTypes;

  final dynamic expired;

}

class GetRecord {
  GetRecord(List<dynamic> response)
      : value = (response[0] as String),
        expiration = (response[1] as BigInt),
        recordType = (response[2] as BigInt),
        customType = (response[3] as String),
        exists = (response[4] as bool),
        expired = (response[5] as bool);

  final String value;

  final BigInt expiration;

  final BigInt recordType;

  final String customType;

  final bool exists;

  final bool expired;

}

class GetRecordsByCustomType {
  GetRecordsByCustomType(List<dynamic> response)
      : keys = (response[0] as List<dynamic>).cast<String>(),
        values = (response[1] as List<dynamic>).cast<String>(),
        expirations = (response[2] as List<dynamic>).cast<BigInt>(),
        expired = (response[3] as dynamic);

  final List<String> keys;

  final List<String> values;

  final List<BigInt> expirations;

  final dynamic expired;

}

class GetRecordsByCustomType$3 {
  GetRecordsByCustomType$3(List<dynamic> response)
      : keys = (response[0] as List<dynamic>).cast<String>(),
        values = (response[1] as List<dynamic>).cast<String>(),
        expirations = (response[2] as List<dynamic>).cast<BigInt>(),
        expired = (response[3] as dynamic);

  final List<String> keys;

  final List<String> values;

  final List<BigInt> expirations;

  final dynamic expired;

}

class GetRecordsByType$3 {
  GetRecordsByType$3(List<dynamic> response)
      : keys = (response[0] as List<dynamic>).cast<String>(),
        values = (response[1] as List<dynamic>).cast<String>(),
        expirations = (response[2] as List<dynamic>).cast<BigInt>(),
        customTypes = (response[3] as List<dynamic>).cast<String>(),
        expired = (response[4] as dynamic);

  final List<String> keys;

  final List<String> values;

  final List<BigInt> expirations;

  final List<String> customTypes;

  final dynamic expired;

}

class GetRecordsByType {
  GetRecordsByType(List<dynamic> response)
      : keys = (response[0] as List<dynamic>).cast<String>(),
        values = (response[1] as List<dynamic>).cast<String>(),
        expirations = (response[2] as List<dynamic>).cast<BigInt>(),
        customTypes = (response[3] as List<dynamic>).cast<String>(),
        expired = (response[4] as dynamic);

  final List<String> keys;

  final List<String> values;

  final List<BigInt> expirations;

  final List<String> customTypes;

  final dynamic expired;

}

class Swept {
  Swept(
    List<dynamic> response,
    this.event,
  )   : token = (response[0] as _i2.EthereumAddress),
        amountOrId = (response[1] as BigInt),
        mainSafe = (response[2] as _i2.EthereumAddress);

  final _i2.EthereumAddress token;

  final BigInt amountOrId;

  final _i2.EthereumAddress mainSafe;

  final _i1.FilterEvent event;
}
