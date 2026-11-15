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
  '[{"inputs":[{"internalType":"address","name":"_moduleRegistryAddress","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":true,"internalType":"bytes","name":"inboxId","type":"bytes"},{"indexed":false,"internalType":"string","name":"label","type":"string"}],"name":"XmtpInboxIdAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":true,"internalType":"bytes","name":"inboxId","type":"bytes"},{"indexed":false,"internalType":"string","name":"label","type":"string"}],"name":"XmtpInboxIdRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"accountAddress","type":"address"},{"indexed":true,"internalType":"bytes","name":"inboxId","type":"bytes"},{"indexed":false,"internalType":"string","name":"oldLabel","type":"string"},{"indexed":false,"internalType":"string","name":"newLabel","type":"string"}],"name":"XmtpInboxIdUpdated","type":"event"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"},{"internalType":"bytes","name":"inboxId","type":"bytes"},{"internalType":"string","name":"label","type":"string"}],"name":"addInboxId","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes","name":"inboxId","type":"bytes"}],"name":"getAccountAddressByInboxId","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"}],"name":"getAllInboxIds","outputs":[{"internalType":"bytes[]","name":"inboxIds","type":"bytes[]"},{"internalType":"string[]","name":"labels","type":"string[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"},{"internalType":"string","name":"label","type":"string"}],"name":"getInboxIdByLabel","outputs":[{"internalType":"bytes","name":"","type":"bytes"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"},{"internalType":"bytes","name":"inboxId","type":"bytes"}],"name":"getInboxIdLabel","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes","name":"inboxId","type":"bytes"}],"name":"inboxIdExists","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes","name":"","type":"bytes"}],"name":"inboxIdToAccountAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"},{"internalType":"string","name":"label","type":"string"}],"name":"labelExists","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleRegistry","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleType","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"},{"internalType":"bytes","name":"inboxId","type":"bytes"}],"name":"removeInboxId","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"accountAddress","type":"address"},{"internalType":"bytes","name":"inboxId","type":"bytes"},{"internalType":"string","name":"newLabel","type":"string"}],"name":"updateInboxIdLabel","outputs":[],"stateMutability":"nonpayable","type":"function"}]',
  'XmtpMemory',
);

class XmtpMemory extends _i1.GeneratedContract {
  XmtpMemory({
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
  Future<String> addInboxId(
    ({_i2.EthereumAddress accountAddress, _i3.Uint8List inboxId, String label}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '5f325985'));
    final params = [
      args.accountAddress,
      args.inboxId,
      args.label,
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
  Future<_i2.EthereumAddress> getAccountAddressByInboxId(
    ({_i3.Uint8List inboxId}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, '2c3bd85c'));
    final params = [args.inboxId];
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
  Future<GetAllInboxIds> getAllInboxIds(
    ({_i2.EthereumAddress accountAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, '19f9d1c8'));
    final params = [args.accountAddress];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return GetAllInboxIds(response);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i3.Uint8List> getInboxIdByLabel(
    ({_i2.EthereumAddress accountAddress, String label}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, '976b8180'));
    final params = [
      args.accountAddress,
      args.label,
    ];
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
  Future<String> getInboxIdLabel(
    ({_i2.EthereumAddress accountAddress, _i3.Uint8List inboxId}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, 'e3049edd'));
    final params = [
      args.accountAddress,
      args.inboxId,
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
  Future<bool> inboxIdExists(
    ({_i3.Uint8List inboxId}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, 'fa123ff9'));
    final params = [args.inboxId];
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
  Future<_i2.EthereumAddress> inboxIdToAccountAddress(
    ({_i3.Uint8List arg0}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, '53967956'));
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
  Future<bool> labelExists(
    ({_i2.EthereumAddress accountAddress, String label}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, 'dcb246b9'));
    final params = [
      args.accountAddress,
      args.label,
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
  Future<_i2.EthereumAddress> moduleRegistry(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[9];
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
    final function = self.abi.functions[10];
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
  Future<String> removeInboxId(
    ({_i2.EthereumAddress accountAddress, _i3.Uint8List inboxId}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[11];
    assert(checkSignature(function, '71fddf9f'));
    final params = [
      args.accountAddress,
      args.inboxId,
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
  Future<String> updateInboxIdLabel(
    ({_i2.EthereumAddress accountAddress, _i3.Uint8List inboxId, String newLabel}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[12];
    assert(checkSignature(function, '6b8209ea'));
    final params = [
      args.accountAddress,
      args.inboxId,
      args.newLabel,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// Returns a live stream of all XmtpInboxIdAdded events emitted by this contract.
  Stream<XmtpInboxIdAdded> xmtpInboxIdAddedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('XmtpInboxIdAdded');
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
      return XmtpInboxIdAdded(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all XmtpInboxIdRemoved events emitted by this contract.
  Stream<XmtpInboxIdRemoved> xmtpInboxIdRemovedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('XmtpInboxIdRemoved');
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
      return XmtpInboxIdRemoved(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all XmtpInboxIdUpdated events emitted by this contract.
  Stream<XmtpInboxIdUpdated> xmtpInboxIdUpdatedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('XmtpInboxIdUpdated');
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
      return XmtpInboxIdUpdated(
        decoded,
        result,
      );
    });
  }
}

class GetAllInboxIds {
  GetAllInboxIds(List<dynamic> response)
      : inboxIds = (response[0] as dynamic),
        labels = (response[1] as List<dynamic>).cast<String>();

  final dynamic inboxIds;

  final List<String> labels;

}

class XmtpInboxIdAdded {
  XmtpInboxIdAdded(
    List<dynamic> response,
    this.event,
  )   : accountAddress = (response[0] as _i2.EthereumAddress),
        inboxId = (response[1] as _i3.Uint8List),
        label = (response[2] as String);

  final _i2.EthereumAddress accountAddress;

  final _i3.Uint8List inboxId;

  final String label;

  final _i1.FilterEvent event;
}

class XmtpInboxIdRemoved {
  XmtpInboxIdRemoved(
    List<dynamic> response,
    this.event,
  )   : accountAddress = (response[0] as _i2.EthereumAddress),
        inboxId = (response[1] as _i3.Uint8List),
        label = (response[2] as String);

  final _i2.EthereumAddress accountAddress;

  final _i3.Uint8List inboxId;

  final String label;

  final _i1.FilterEvent event;
}

class XmtpInboxIdUpdated {
  XmtpInboxIdUpdated(
    List<dynamic> response,
    this.event,
  )   : accountAddress = (response[0] as _i2.EthereumAddress),
        inboxId = (response[1] as _i3.Uint8List),
        oldLabel = (response[2] as String),
        newLabel = (response[3] as String);

  final _i2.EthereumAddress accountAddress;

  final _i3.Uint8List inboxId;

  final String oldLabel;

  final String newLabel;

  final _i1.FilterEvent event;
}
