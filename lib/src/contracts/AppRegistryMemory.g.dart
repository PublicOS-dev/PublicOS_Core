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
  '[{"inputs":[{"internalType":"address","name":"_moduleRegistryAddress","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"string","name":"slug","type":"string"},{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"string","name":"pointerType","type":"string"}],"name":"AppPointerRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"string","name":"slug","type":"string"},{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"string","name":"pointerType","type":"string"},{"indexed":false,"internalType":"string","name":"value","type":"string"}],"name":"AppPointerSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"string","name":"slug","type":"string"},{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"string","name":"title","type":"string"}],"name":"AppRegistered","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"string","name":"slug","type":"string"},{"indexed":true,"internalType":"address","name":"owner","type":"address"}],"name":"AppRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"string","name":"slug","type":"string"},{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"string","name":"oldTitle","type":"string"},{"indexed":false,"internalType":"string","name":"newTitle","type":"string"}],"name":"AppTitleUpdated","type":"event"},{"inputs":[{"internalType":"string","name":"slug","type":"string"}],"name":"appExists","outputs":[{"internalType":"bool","name":"exists","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"slug","type":"string"}],"name":"getAllAppPointers","outputs":[{"internalType":"string[]","name":"pointerTypes","type":"string[]"},{"internalType":"string[]","name":"values","type":"string[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"slug","type":"string"}],"name":"getAppBySlug","outputs":[{"components":[{"internalType":"bool","name":"exists","type":"bool"},{"internalType":"string","name":"slug","type":"string"},{"internalType":"string","name":"title","type":"string"},{"internalType":"address","name":"owner","type":"address"}],"internalType":"struct IAppRegistryMemory.App","name":"app","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"slug","type":"string"}],"name":"getAppOwner","outputs":[{"internalType":"address","name":"owner","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"slug","type":"string"},{"internalType":"string","name":"pointerType","type":"string"}],"name":"getAppPointer","outputs":[{"internalType":"string","name":"value","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"getAppsByOwner","outputs":[{"internalType":"string[]","name":"slugs","type":"string[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"uint256","name":"offset","type":"uint256"},{"internalType":"uint256","name":"limit","type":"uint256"}],"name":"getAppsByOwner","outputs":[{"internalType":"string[]","name":"slugs","type":"string[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"getAppsByOwnerCount","outputs":[{"internalType":"uint256","name":"count","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getTotalAppCount","outputs":[{"internalType":"uint256","name":"count","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleRegistry","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleType","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"string","name":"slug","type":"string"},{"internalType":"string","name":"pointerType","type":"string"}],"name":"pointerExists","outputs":[{"internalType":"bool","name":"exists","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"string","name":"slug","type":"string"},{"internalType":"string","name":"title","type":"string"}],"name":"registerApp","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"string","name":"slug","type":"string"}],"name":"removeApp","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"string","name":"slug","type":"string"},{"internalType":"string","name":"pointerType","type":"string"}],"name":"removeAppPointer","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"title","type":"string"}],"name":"searchByTitle","outputs":[{"internalType":"string[]","name":"slugs","type":"string[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"string","name":"slug","type":"string"},{"internalType":"string","name":"pointerType","type":"string"},{"internalType":"string","name":"value","type":"string"}],"name":"setAppPointer","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"string","name":"slug","type":"string"},{"internalType":"string","name":"newTitle","type":"string"}],"name":"updateAppTitle","outputs":[],"stateMutability":"nonpayable","type":"function"}]',
  'AppRegistryMemory',
);

class AppRegistryMemory extends _i1.GeneratedContract {
  AppRegistryMemory({
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
  Future<bool> appExists(
    ({String slug}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, 'ba4fd0df'));
    final params = [args.slug];
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
  Future<GetAllAppPointers> getAllAppPointers(
    ({String slug}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, '5df703db'));
    final params = [args.slug];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return GetAllAppPointers(response);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<dynamic> getAppBySlug(
    ({String slug}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, '119f6b81'));
    final params = [args.slug];
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
  Future<_i2.EthereumAddress> getAppOwner(
    ({String slug}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, 'eda742b2'));
    final params = [args.slug];
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
  Future<String> getAppPointer(
    ({String slug, String pointerType}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, '63cc4da1'));
    final params = [
      args.slug,
      args.pointerType,
    ];
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
  Future<List<String>> getAppsByOwner(
    ({_i2.EthereumAddress owner}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, '849a7ebf'));
    final params = [args.owner];
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
  Future<List<String>> getAppsByOwner$3(
    ({_i2.EthereumAddress owner, BigInt offset, BigInt limit}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, 'd2e1b99d'));
    final params = [
      args.owner,
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
  Future<BigInt> getAppsByOwnerCount(
    ({_i2.EthereumAddress owner}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, '147a0fa7'));
    final params = [args.owner];
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
  Future<BigInt> getTotalAppCount(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[9];
    assert(checkSignature(function, '43429ec2'));
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
    final function = self.abi.functions[10];
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
    final function = self.abi.functions[11];
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
  Future<bool> pointerExists(
    ({String slug, String pointerType}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[12];
    assert(checkSignature(function, 'f5c55c1c'));
    final params = [
      args.slug,
      args.pointerType,
    ];
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
  Future<String> registerApp(
    ({_i2.EthereumAddress owner, String slug, String title}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[13];
    assert(checkSignature(function, '80fd73d0'));
    final params = [
      args.owner,
      args.slug,
      args.title,
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
  Future<String> removeApp(
    ({_i2.EthereumAddress owner, String slug}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[14];
    assert(checkSignature(function, '10eb076f'));
    final params = [
      args.owner,
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
  Future<String> removeAppPointer(
    ({_i2.EthereumAddress owner, String slug, String pointerType}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[15];
    assert(checkSignature(function, '5b31f80f'));
    final params = [
      args.owner,
      args.slug,
      args.pointerType,
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
  Future<List<String>> searchByTitle(
    ({String title}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[16];
    assert(checkSignature(function, '5bab3ba1'));
    final params = [args.title];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<String>();
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> setAppPointer(
    ({_i2.EthereumAddress owner, String slug, String pointerType, String value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[17];
    assert(checkSignature(function, '6b7ee212'));
    final params = [
      args.owner,
      args.slug,
      args.pointerType,
      args.value,
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
  Future<String> updateAppTitle(
    ({_i2.EthereumAddress owner, String slug, String newTitle}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[18];
    assert(checkSignature(function, '4cf1f7c0'));
    final params = [
      args.owner,
      args.slug,
      args.newTitle,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// Returns a live stream of all AppPointerRemoved events emitted by this contract.
  Stream<AppPointerRemoved> appPointerRemovedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('AppPointerRemoved');
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
      return AppPointerRemoved(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all AppPointerSet events emitted by this contract.
  Stream<AppPointerSet> appPointerSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('AppPointerSet');
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
      return AppPointerSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all AppRegistered events emitted by this contract.
  Stream<AppRegistered> appRegisteredEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('AppRegistered');
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
      return AppRegistered(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all AppRemoved events emitted by this contract.
  Stream<AppRemoved> appRemovedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('AppRemoved');
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
      return AppRemoved(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all AppTitleUpdated events emitted by this contract.
  Stream<AppTitleUpdated> appTitleUpdatedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('AppTitleUpdated');
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
      return AppTitleUpdated(
        decoded,
        result,
      );
    });
  }
}

class GetAllAppPointers {
  GetAllAppPointers(List<dynamic> response)
      : pointerTypes = (response[0] as List<dynamic>).cast<String>(),
        values = (response[1] as List<dynamic>).cast<String>();

  final List<String> pointerTypes;

  final List<String> values;

}

class AppPointerRemoved {
  AppPointerRemoved(
    List<dynamic> response,
    this.event,
  )   : slug = (response[0] as String),
        owner = (response[1] as _i2.EthereumAddress),
        pointerType = (response[2] as String);

  final String slug;

  final _i2.EthereumAddress owner;

  final String pointerType;

  final _i1.FilterEvent event;
}

class AppPointerSet {
  AppPointerSet(
    List<dynamic> response,
    this.event,
  )   : slug = (response[0] as String),
        owner = (response[1] as _i2.EthereumAddress),
        pointerType = (response[2] as String),
        value = (response[3] as String);

  final String slug;

  final _i2.EthereumAddress owner;

  final String pointerType;

  final String value;

  final _i1.FilterEvent event;
}

class AppRegistered {
  AppRegistered(
    List<dynamic> response,
    this.event,
  )   : slug = (response[0] as String),
        owner = (response[1] as _i2.EthereumAddress),
        title = (response[2] as String);

  final String slug;

  final _i2.EthereumAddress owner;

  final String title;

  final _i1.FilterEvent event;
}

class AppRemoved {
  AppRemoved(
    List<dynamic> response,
    this.event,
  )   : slug = (response[0] as String),
        owner = (response[1] as _i2.EthereumAddress);

  final String slug;

  final _i2.EthereumAddress owner;

  final _i1.FilterEvent event;
}

class AppTitleUpdated {
  AppTitleUpdated(
    List<dynamic> response,
    this.event,
  )   : slug = (response[0] as String),
        owner = (response[1] as _i2.EthereumAddress),
        oldTitle = (response[2] as String),
        newTitle = (response[3] as String);

  final String slug;

  final _i2.EthereumAddress owner;

  final String oldTitle;

  final String newTitle;

  final _i1.FilterEvent event;
}
