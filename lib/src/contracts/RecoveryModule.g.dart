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
  '[{"inputs":[{"internalType":"address","name":"_moduleRegistryAddress","type":"address"},{"internalType":"uint256","name":"_initialVoteDuration","type":"uint256"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[],"name":"AdminCapReached","type":"error"},{"inputs":[],"name":"AlreadyAdmin","type":"error"},{"inputs":[],"name":"InvalidAdmin","type":"error"},{"inputs":[],"name":"NotAdmin","type":"error"},{"inputs":[],"name":"NotAuthorized","type":"error"},{"inputs":[],"name":"RootNotResolvable","type":"error"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"admin","type":"address"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"AdminAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"admin","type":"address"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"AdminRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bool","name":"on","type":"bool"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"InheritanceSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newMax","type":"uint256"}],"name":"MaxVoteDurationSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"targetAccountAddress","type":"address"},{"indexed":true,"internalType":"address","name":"proposedSessionAddress","type":"address"},{"indexed":false,"internalType":"string","name":"reason","type":"string"}],"name":"VoteCancelled","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"targetAccountAddress","type":"address"},{"indexed":true,"internalType":"address","name":"voterAccountAddress","type":"address"},{"indexed":false,"internalType":"address","name":"voterSessionAddress","type":"address"},{"indexed":false,"internalType":"bool","name":"votedToAdd","type":"bool"}],"name":"VoteCast","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newDuration","type":"uint256"}],"name":"VoteDurationSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"targetAccountAddress","type":"address"},{"indexed":true,"internalType":"address","name":"proposedSessionAddress","type":"address"}],"name":"VotePassedAndExecuted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"targetAccountAddress","type":"address"},{"indexed":true,"internalType":"address","name":"proposedSessionAddress","type":"address"},{"indexed":false,"internalType":"string","name":"reason","type":"string"}],"name":"VotePassedButExecutionFailed","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"targetAccountAddress","type":"address"},{"indexed":true,"internalType":"address","name":"proposedSessionAddress","type":"address"},{"indexed":false,"internalType":"address","name":"initiatorSessionAddress","type":"address"},{"indexed":true,"internalType":"address","name":"initiatorAccountAddress","type":"address"},{"indexed":false,"internalType":"uint256","name":"requiredThreshold","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"expirationTimestamp","type":"uint256"}],"name":"VoteStarted","type":"event"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"activeVotes","outputs":[{"internalType":"address","name":"proposedSessionAddress","type":"address"},{"internalType":"address","name":"initiatorSessionAddress","type":"address"},{"internalType":"address","name":"initiatorAccountAddress","type":"address"},{"internalType":"uint256","name":"requiredThreshold","type":"uint256"},{"internalType":"uint256","name":"expirationTimestamp","type":"uint256"},{"internalType":"uint256","name":"addVotesCount","type":"uint256"},{"internalType":"uint256","name":"cancelVotesCount","type":"uint256"},{"internalType":"uint256","name":"voteNonce","type":"uint256"},{"internalType":"bool","name":"isActive","type":"bool"},{"internalType":"uint256","name":"consentDeadline","type":"uint256"},{"internalType":"bytes","name":"consentSig","type":"bytes"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"addAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"admins","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"targetAccountAddress","type":"address"},{"internalType":"bool","name":"voteToAdd","type":"bool"}],"name":"castVote","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"targetAccountAddress","type":"address"}],"name":"getRecoveryVote","outputs":[{"components":[{"internalType":"address","name":"targetAccountAddress","type":"address"},{"internalType":"address","name":"proposedSessionAddress","type":"address"},{"internalType":"address","name":"initiatorSessionAddress","type":"address"},{"internalType":"address","name":"initiatorAccountAddress","type":"address"},{"internalType":"uint256","name":"requiredThreshold","type":"uint256"},{"internalType":"uint256","name":"expirationTimestamp","type":"uint256"},{"internalType":"uint256","name":"addVotesCount","type":"uint256"},{"internalType":"uint256","name":"cancelVotesCount","type":"uint256"},{"internalType":"bool","name":"isActive","type":"bool"}],"internalType":"struct IRecoveryModule.RecoveryVoteView","name":"voteDetails","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"inheritanceOn","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"isAdmin","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"maxVoteDuration","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleRegistry","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleType","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"removeAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"on","type":"bool"}],"name":"setInheritance","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"newMax","type":"uint256"}],"name":"setMaxVoteDuration","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"newDuration","type":"uint256"}],"name":"setVoteDuration","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"targetAccountAddress","type":"address"},{"internalType":"address","name":"proposedSoleSession","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"bytes","name":"sig","type":"bytes"}],"name":"startReseedVote","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"voteDuration","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}]',
  'RecoveryModule',
);

class RecoveryModule extends _i1.GeneratedContract {
  RecoveryModule({
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
  Future<ActiveVotes> activeVotes(
    ({_i2.EthereumAddress arg0}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '0ee918b0'));
    final params = [args.arg0];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return ActiveVotes(response);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> addAdmin(
    ({_i2.EthereumAddress account}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[2];
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
    final function = self.abi.functions[3];
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
  Future<String> castVote(
    ({_i2.EthereumAddress targetAccountAddress, bool voteToAdd}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, '1a419c0c'));
    final params = [
      args.targetAccountAddress,
      args.voteToAdd,
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
  Future<dynamic> getRecoveryVote(
    ({_i2.EthereumAddress targetAccountAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, '6eebb176'));
    final params = [args.targetAccountAddress];
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
  Future<bool> inheritanceOn(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[6];
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
    final function = self.abi.functions[7];
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
  Future<BigInt> maxVoteDuration(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, 'd942d30a'));
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
  Future<String> removeAdmin(
    ({_i2.EthereumAddress account}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[11];
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
  Future<String> setInheritance(
    ({bool on}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[12];
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
  Future<String> setMaxVoteDuration(
    ({BigInt newMax}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[13];
    assert(checkSignature(function, 'bd840d43'));
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
  Future<String> setVoteDuration(
    ({BigInt newDuration}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[14];
    assert(checkSignature(function, '9449a655'));
    final params = [args.newDuration];
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
  Future<String> startReseedVote(
    ({_i2.EthereumAddress targetAccountAddress, _i2.EthereumAddress proposedSoleSession, BigInt deadline, _i3.Uint8List sig}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[15];
    assert(checkSignature(function, '4477dd23'));
    final params = [
      args.targetAccountAddress,
      args.proposedSoleSession,
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
  Future<BigInt> voteDuration(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[16];
    assert(checkSignature(function, '56364499'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
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

  /// Returns a live stream of all MaxVoteDurationSet events emitted by this contract.
  Stream<MaxVoteDurationSet> maxVoteDurationSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('MaxVoteDurationSet');
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
      return MaxVoteDurationSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all VoteCancelled events emitted by this contract.
  Stream<VoteCancelled> voteCancelledEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('VoteCancelled');
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
      return VoteCancelled(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all VoteCast events emitted by this contract.
  Stream<VoteCast> voteCastEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('VoteCast');
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
      return VoteCast(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all VoteDurationSet events emitted by this contract.
  Stream<VoteDurationSet> voteDurationSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('VoteDurationSet');
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
      return VoteDurationSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all VotePassedAndExecuted events emitted by this contract.
  Stream<VotePassedAndExecuted> votePassedAndExecutedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('VotePassedAndExecuted');
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
      return VotePassedAndExecuted(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all VotePassedButExecutionFailed events emitted by this contract.
  Stream<VotePassedButExecutionFailed> votePassedButExecutionFailedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('VotePassedButExecutionFailed');
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
      return VotePassedButExecutionFailed(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all VoteStarted events emitted by this contract.
  Stream<VoteStarted> voteStartedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('VoteStarted');
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
      return VoteStarted(
        decoded,
        result,
      );
    });
  }
}

class ActiveVotes {
  ActiveVotes(List<dynamic> response)
      : proposedSessionAddress = (response[0] as _i2.EthereumAddress),
        initiatorSessionAddress = (response[1] as _i2.EthereumAddress),
        initiatorAccountAddress = (response[2] as _i2.EthereumAddress),
        requiredThreshold = (response[3] as BigInt),
        expirationTimestamp = (response[4] as BigInt),
        addVotesCount = (response[5] as BigInt),
        cancelVotesCount = (response[6] as BigInt),
        voteNonce = (response[7] as BigInt),
        isActive = (response[8] as bool),
        consentDeadline = (response[9] as BigInt),
        consentSig = (response[10] as _i3.Uint8List);

  final _i2.EthereumAddress proposedSessionAddress;

  final _i2.EthereumAddress initiatorSessionAddress;

  final _i2.EthereumAddress initiatorAccountAddress;

  final BigInt requiredThreshold;

  final BigInt expirationTimestamp;

  final BigInt addVotesCount;

  final BigInt cancelVotesCount;

  final BigInt voteNonce;

  final bool isActive;

  final BigInt consentDeadline;

  final _i3.Uint8List consentSig;

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

class MaxVoteDurationSet {
  MaxVoteDurationSet(
    List<dynamic> response,
    this.event,
  )   : newMax = (response[0] as BigInt);

  final BigInt newMax;

  final _i1.FilterEvent event;
}

class VoteCancelled {
  VoteCancelled(
    List<dynamic> response,
    this.event,
  )   : targetAccountAddress = (response[0] as _i2.EthereumAddress),
        proposedSessionAddress = (response[1] as _i2.EthereumAddress),
        reason = (response[2] as String);

  final _i2.EthereumAddress targetAccountAddress;

  final _i2.EthereumAddress proposedSessionAddress;

  final String reason;

  final _i1.FilterEvent event;
}

class VoteCast {
  VoteCast(
    List<dynamic> response,
    this.event,
  )   : targetAccountAddress = (response[0] as _i2.EthereumAddress),
        voterAccountAddress = (response[1] as _i2.EthereumAddress),
        voterSessionAddress = (response[2] as _i2.EthereumAddress),
        votedToAdd = (response[3] as bool);

  final _i2.EthereumAddress targetAccountAddress;

  final _i2.EthereumAddress voterAccountAddress;

  final _i2.EthereumAddress voterSessionAddress;

  final bool votedToAdd;

  final _i1.FilterEvent event;
}

class VoteDurationSet {
  VoteDurationSet(
    List<dynamic> response,
    this.event,
  )   : newDuration = (response[0] as BigInt);

  final BigInt newDuration;

  final _i1.FilterEvent event;
}

class VotePassedAndExecuted {
  VotePassedAndExecuted(
    List<dynamic> response,
    this.event,
  )   : targetAccountAddress = (response[0] as _i2.EthereumAddress),
        proposedSessionAddress = (response[1] as _i2.EthereumAddress);

  final _i2.EthereumAddress targetAccountAddress;

  final _i2.EthereumAddress proposedSessionAddress;

  final _i1.FilterEvent event;
}

class VotePassedButExecutionFailed {
  VotePassedButExecutionFailed(
    List<dynamic> response,
    this.event,
  )   : targetAccountAddress = (response[0] as _i2.EthereumAddress),
        proposedSessionAddress = (response[1] as _i2.EthereumAddress),
        reason = (response[2] as String);

  final _i2.EthereumAddress targetAccountAddress;

  final _i2.EthereumAddress proposedSessionAddress;

  final String reason;

  final _i1.FilterEvent event;
}

class VoteStarted {
  VoteStarted(
    List<dynamic> response,
    this.event,
  )   : targetAccountAddress = (response[0] as _i2.EthereumAddress),
        proposedSessionAddress = (response[1] as _i2.EthereumAddress),
        initiatorSessionAddress = (response[2] as _i2.EthereumAddress),
        initiatorAccountAddress = (response[3] as _i2.EthereumAddress),
        requiredThreshold = (response[4] as BigInt),
        expirationTimestamp = (response[5] as BigInt);

  final _i2.EthereumAddress targetAccountAddress;

  final _i2.EthereumAddress proposedSessionAddress;

  final _i2.EthereumAddress initiatorSessionAddress;

  final _i2.EthereumAddress initiatorAccountAddress;

  final BigInt requiredThreshold;

  final BigInt expirationTimestamp;

  final _i1.FilterEvent event;
}
