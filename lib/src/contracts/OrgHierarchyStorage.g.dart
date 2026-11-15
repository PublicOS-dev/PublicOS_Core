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
  '[{"inputs":[{"internalType":"address","name":"_moduleRegistryAddress","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"parent","type":"address"},{"indexed":true,"internalType":"address","name":"child","type":"address"}],"name":"ChildAccepted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"parent","type":"address"},{"indexed":true,"internalType":"address","name":"child","type":"address"},{"indexed":false,"internalType":"bool","name":"locked","type":"bool"}],"name":"ChildLockSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"parent","type":"address"},{"indexed":true,"internalType":"address","name":"child","type":"address"}],"name":"ChildReleased","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"child","type":"address"},{"indexed":true,"internalType":"address","name":"previouslyRequestedParent","type":"address"}],"name":"ParentRequestCancelled","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"child","type":"address"},{"indexed":true,"internalType":"address","name":"requestedParent","type":"address"}],"name":"ParentRequested","type":"event"},{"inputs":[{"internalType":"address","name":"parent","type":"address"},{"internalType":"address","name":"child","type":"address"}],"name":"acceptChild","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"child","type":"address"}],"name":"cancelRequest","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"org","type":"address"}],"name":"getChildCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"org","type":"address"},{"internalType":"uint256","name":"offset","type":"uint256"},{"internalType":"uint256","name":"limit","type":"uint256"}],"name":"getChildren","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"org","type":"address"}],"name":"getChildren","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"org","type":"address"}],"name":"getParent","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"child","type":"address"}],"name":"getPendingRequest","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"ancestor","type":"address"},{"internalType":"address","name":"descendant","type":"address"}],"name":"isAncestor","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"org","type":"address"}],"name":"isChildLocked","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleRegistry","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleType","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"address","name":"parent","type":"address"},{"internalType":"address","name":"child","type":"address"}],"name":"releaseChild","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"child","type":"address"},{"internalType":"address","name":"parent","type":"address"}],"name":"requestParent","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"parent","type":"address"},{"internalType":"address","name":"child","type":"address"},{"internalType":"bool","name":"locked","type":"bool"}],"name":"setChildLock","outputs":[],"stateMutability":"nonpayable","type":"function"}]',
  'OrgHierarchyStorage',
);

class OrgHierarchyStorage extends _i1.GeneratedContract {
  OrgHierarchyStorage({
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
  Future<String> acceptChild(
    ({_i2.EthereumAddress parent, _i2.EthereumAddress child}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '6391a947'));
    final params = [
      args.parent,
      args.child,
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
  Future<String> cancelRequest(
    ({_i2.EthereumAddress child}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, 'af98f757'));
    final params = [args.child];
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
  Future<BigInt> getChildCount(
    ({_i2.EthereumAddress org}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, '9d4c8eed'));
    final params = [args.org];
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
  Future<List<_i2.EthereumAddress>> getChildren$3(
    ({_i2.EthereumAddress org, BigInt offset, BigInt limit}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, '4280d359'));
    final params = [
      args.org,
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
  Future<List<_i2.EthereumAddress>> getChildren(
    ({_i2.EthereumAddress org}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, '6999fa45'));
    final params = [args.org];
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
  Future<_i2.EthereumAddress> getParent(
    ({_i2.EthereumAddress org}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, 'a9405923'));
    final params = [args.org];
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
  Future<_i2.EthereumAddress> getPendingRequest(
    ({_i2.EthereumAddress child}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, '817697b1'));
    final params = [args.child];
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
  Future<bool> isAncestor(
    ({_i2.EthereumAddress ancestor, _i2.EthereumAddress descendant}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, '05a7304b'));
    final params = [
      args.ancestor,
      args.descendant,
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
  Future<bool> isChildLocked(
    ({_i2.EthereumAddress org}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[9];
    assert(checkSignature(function, '58aecfc2'));
    final params = [args.org];
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

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> releaseChild(
    ({_i2.EthereumAddress parent, _i2.EthereumAddress child}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[12];
    assert(checkSignature(function, '01a06143'));
    final params = [
      args.parent,
      args.child,
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
  Future<String> requestParent(
    ({_i2.EthereumAddress child, _i2.EthereumAddress parent}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[13];
    assert(checkSignature(function, '06797081'));
    final params = [
      args.child,
      args.parent,
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
  Future<String> setChildLock(
    ({_i2.EthereumAddress parent, _i2.EthereumAddress child, bool locked}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[14];
    assert(checkSignature(function, '0286c962'));
    final params = [
      args.parent,
      args.child,
      args.locked,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// Returns a live stream of all ChildAccepted events emitted by this contract.
  Stream<ChildAccepted> childAcceptedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('ChildAccepted');
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
      return ChildAccepted(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all ChildLockSet events emitted by this contract.
  Stream<ChildLockSet> childLockSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('ChildLockSet');
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
      return ChildLockSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all ChildReleased events emitted by this contract.
  Stream<ChildReleased> childReleasedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('ChildReleased');
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
      return ChildReleased(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all ParentRequestCancelled events emitted by this contract.
  Stream<ParentRequestCancelled> parentRequestCancelledEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('ParentRequestCancelled');
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
      return ParentRequestCancelled(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all ParentRequested events emitted by this contract.
  Stream<ParentRequested> parentRequestedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('ParentRequested');
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
      return ParentRequested(
        decoded,
        result,
      );
    });
  }
}

class ChildAccepted {
  ChildAccepted(
    List<dynamic> response,
    this.event,
  )   : parent = (response[0] as _i2.EthereumAddress),
        child = (response[1] as _i2.EthereumAddress);

  final _i2.EthereumAddress parent;

  final _i2.EthereumAddress child;

  final _i1.FilterEvent event;
}

class ChildLockSet {
  ChildLockSet(
    List<dynamic> response,
    this.event,
  )   : parent = (response[0] as _i2.EthereumAddress),
        child = (response[1] as _i2.EthereumAddress),
        locked = (response[2] as bool);

  final _i2.EthereumAddress parent;

  final _i2.EthereumAddress child;

  final bool locked;

  final _i1.FilterEvent event;
}

class ChildReleased {
  ChildReleased(
    List<dynamic> response,
    this.event,
  )   : parent = (response[0] as _i2.EthereumAddress),
        child = (response[1] as _i2.EthereumAddress);

  final _i2.EthereumAddress parent;

  final _i2.EthereumAddress child;

  final _i1.FilterEvent event;
}

class ParentRequestCancelled {
  ParentRequestCancelled(
    List<dynamic> response,
    this.event,
  )   : child = (response[0] as _i2.EthereumAddress),
        previouslyRequestedParent = (response[1] as _i2.EthereumAddress);

  final _i2.EthereumAddress child;

  final _i2.EthereumAddress previouslyRequestedParent;

  final _i1.FilterEvent event;
}

class ParentRequested {
  ParentRequested(
    List<dynamic> response,
    this.event,
  )   : child = (response[0] as _i2.EthereumAddress),
        requestedParent = (response[1] as _i2.EthereumAddress);

  final _i2.EthereumAddress child;

  final _i2.EthereumAddress requestedParent;

  final _i1.FilterEvent event;
}
