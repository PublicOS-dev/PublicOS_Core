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
  '[{"inputs":[{"internalType":"address","name":"_moduleRegistry","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"grantId","type":"uint256"}],"name":"GrantCancelled","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"grantId","type":"uint256"},{"indexed":true,"internalType":"address","name":"recipient","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"intervalSeconds","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"endTime","type":"uint256"}],"name":"GrantCreated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"grantId","type":"uint256"}],"name":"GrantDeactivated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"grantId","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"timestamp","type":"uint256"}],"name":"GrantProcessedAt","type":"event"},{"inputs":[{"internalType":"uint256","name":"grantId","type":"uint256"}],"name":"cancelGrant","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"uint256","name":"intervalSeconds","type":"uint256"},{"internalType":"uint256","name":"endTime","type":"uint256"}],"name":"createGrant","outputs":[{"internalType":"uint256","name":"grantId","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"grantId","type":"uint256"}],"name":"deactivateGrant","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"grantId","type":"uint256"}],"name":"getGrant","outputs":[{"components":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"uint256","name":"intervalSeconds","type":"uint256"},{"internalType":"uint256","name":"lastProcessed","type":"uint256"},{"internalType":"bool","name":"active","type":"bool"},{"internalType":"uint256","name":"endTime","type":"uint256"}],"internalType":"struct IGrantsMemory.Grant","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"grantCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleRegistry","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleType","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"grantId","type":"uint256"},{"internalType":"uint256","name":"timestamp","type":"uint256"}],"name":"setGrantProcessed","outputs":[],"stateMutability":"nonpayable","type":"function"}]',
  'GrantsMemory',
);

class GrantsMemory extends _i1.GeneratedContract {
  GrantsMemory({
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
  Future<String> cancelGrant(
    ({BigInt grantId}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, 'abff9d80'));
    final params = [args.grantId];
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
  Future<String> createGrant(
    ({_i2.EthereumAddress recipient, BigInt amount, BigInt intervalSeconds, BigInt endTime}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, '16140b7a'));
    final params = [
      args.recipient,
      args.amount,
      args.intervalSeconds,
      args.endTime,
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
  Future<String> deactivateGrant(
    ({BigInt grantId}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, '26812286'));
    final params = [args.grantId];
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
  Future<dynamic> getGrant(
    ({BigInt grantId}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, 'b8cc6c93'));
    final params = [args.grantId];
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
  Future<BigInt> grantCount(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, 'cab42672'));
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
    final function = self.abi.functions[6];
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
    final function = self.abi.functions[7];
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
  Future<String> setGrantProcessed(
    ({BigInt grantId, BigInt timestamp}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, 'c3b27ea3'));
    final params = [
      args.grantId,
      args.timestamp,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// Returns a live stream of all GrantCancelled events emitted by this contract.
  Stream<GrantCancelled> grantCancelledEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('GrantCancelled');
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
      return GrantCancelled(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all GrantCreated events emitted by this contract.
  Stream<GrantCreated> grantCreatedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('GrantCreated');
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
      return GrantCreated(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all GrantDeactivated events emitted by this contract.
  Stream<GrantDeactivated> grantDeactivatedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('GrantDeactivated');
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
      return GrantDeactivated(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all GrantProcessedAt events emitted by this contract.
  Stream<GrantProcessedAt> grantProcessedAtEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('GrantProcessedAt');
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
      return GrantProcessedAt(
        decoded,
        result,
      );
    });
  }
}

class GrantCancelled {
  GrantCancelled(
    List<dynamic> response,
    this.event,
  )   : grantId = (response[0] as BigInt);

  final BigInt grantId;

  final _i1.FilterEvent event;
}

class GrantCreated {
  GrantCreated(
    List<dynamic> response,
    this.event,
  )   : grantId = (response[0] as BigInt),
        recipient = (response[1] as _i2.EthereumAddress),
        amount = (response[2] as BigInt),
        intervalSeconds = (response[3] as BigInt),
        endTime = (response[4] as BigInt);

  final BigInt grantId;

  final _i2.EthereumAddress recipient;

  final BigInt amount;

  final BigInt intervalSeconds;

  final BigInt endTime;

  final _i1.FilterEvent event;
}

class GrantDeactivated {
  GrantDeactivated(
    List<dynamic> response,
    this.event,
  )   : grantId = (response[0] as BigInt);

  final BigInt grantId;

  final _i1.FilterEvent event;
}

class GrantProcessedAt {
  GrantProcessedAt(
    List<dynamic> response,
    this.event,
  )   : grantId = (response[0] as BigInt),
        timestamp = (response[1] as BigInt);

  final BigInt grantId;

  final BigInt timestamp;

  final _i1.FilterEvent event;
}
