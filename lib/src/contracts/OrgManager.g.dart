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
  '[{"inputs":[{"internalType":"address","name":"_moduleRegistryAddress","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[],"name":"ReentrancyGuardReentrantCall","type":"error"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"accountManagerAddress","type":"address"}],"name":"AccountManagerSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"orgAddress","type":"address"},{"indexed":true,"internalType":"address","name":"memberAccountAddress","type":"address"}],"name":"MemberAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"orgAddress","type":"address"},{"indexed":true,"internalType":"address","name":"memberAccountAddress","type":"address"}],"name":"MemberLeft","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"orgAddress","type":"address"},{"indexed":true,"internalType":"address","name":"memberAccountAddress","type":"address"}],"name":"MemberRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"orgStorageAddress","type":"address"}],"name":"OrgStorageSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"safeAuthAddress","type":"address"}],"name":"SafeAuthSet","type":"event"},{"inputs":[{"internalType":"uint256","name":"proposalId","type":"uint256"},{"internalType":"string","name":"reason","type":"string"}],"name":"cancelVote","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"proposalId","type":"uint256"},{"internalType":"string","name":"reason","type":"string"}],"name":"cancelVoteAsOrg","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"proposalId","type":"uint256"},{"internalType":"uint8","name":"support","type":"uint8"}],"name":"castVote","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"orgAddress","type":"address"},{"internalType":"bytes32","name":"tag","type":"bytes32"},{"internalType":"address","name":"delegatee","type":"address"}],"name":"delegate","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"proposalId","type":"uint256"},{"internalType":"address","name":"orgAddress","type":"address"},{"internalType":"enum IOrgManager.VoteActionType","name":"actionType","type":"uint8"},{"components":[{"internalType":"address","name":"targetAddress","type":"address"},{"internalType":"uint256","name":"valueParam","type":"uint256"},{"internalType":"string","name":"keyParam","type":"string"},{"internalType":"string","name":"valueStringParam","type":"string"},{"internalType":"uint8","name":"recordTypeValueParam","type":"uint8"},{"internalType":"string","name":"customTypeParam","type":"string"},{"internalType":"bytes","name":"dataParam","type":"bytes"},{"internalType":"enum Enum.Operation","name":"operationParam","type":"uint8"}],"internalType":"struct IOrgManager.VoteActionParams","name":"p","type":"tuple"}],"name":"dispatchVote","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"proposalId","type":"uint256"}],"name":"execute","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"orgAccountAddress","type":"address"},{"internalType":"address[]","name":"initialMembers","type":"address[]"},{"internalType":"uint256","name":"initialThreshold","type":"uint256"},{"internalType":"address","name":"creator","type":"address"},{"internalType":"bool","name":"isPublic","type":"bool"}],"name":"initializeOrg","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"orgAddress","type":"address"}],"name":"leaveOrg","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"moduleRegistry","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleType","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"onCitizenshipGranted","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"onCitizenshipRevoked","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"orgAddress","type":"address"}],"name":"openProposals","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"proposalId","type":"uint256"}],"name":"proposalOrg","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"orgAddress","type":"address"},{"internalType":"enum IOrgManager.VoteActionType","name":"actionType","type":"uint8"},{"components":[{"internalType":"address","name":"targetAddress","type":"address"},{"internalType":"uint256","name":"valueParam","type":"uint256"},{"internalType":"string","name":"keyParam","type":"string"},{"internalType":"string","name":"valueStringParam","type":"string"},{"internalType":"uint8","name":"recordTypeValueParam","type":"uint8"},{"internalType":"string","name":"customTypeParam","type":"string"},{"internalType":"bytes","name":"dataParam","type":"bytes"},{"internalType":"enum Enum.Operation","name":"operationParam","type":"uint8"}],"internalType":"struct IOrgManager.VoteActionParams","name":"params","type":"tuple"},{"internalType":"bytes32","name":"tag","type":"bytes32"}],"name":"startVote","outputs":[{"internalType":"uint256","name":"proposalId","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"proposalId","type":"uint256"},{"internalType":"string","name":"reason","type":"string"}],"name":"veto","outputs":[],"stateMutability":"nonpayable","type":"function"}]',
  'OrgManager',
);

class OrgManager extends _i1.GeneratedContract {
  OrgManager({
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
  Future<String> cancelVote(
    ({BigInt proposalId, String reason}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '4d1070c0'));
    final params = [
      args.proposalId,
      args.reason,
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
  Future<String> cancelVoteAsOrg(
    ({BigInt proposalId, String reason}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, '43ab980f'));
    final params = [
      args.proposalId,
      args.reason,
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
  Future<String> castVote(
    ({BigInt proposalId, BigInt support}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, '56781388'));
    final params = [
      args.proposalId,
      args.support,
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
  Future<String> delegate(
    ({_i2.EthereumAddress orgAddress, _i3.Uint8List tag, _i2.EthereumAddress delegatee}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, 'd4697308'));
    final params = [
      args.orgAddress,
      args.tag,
      args.delegatee,
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
  Future<String> dispatchVote(
    ({BigInt proposalId, _i2.EthereumAddress orgAddress, BigInt actionType, dynamic p}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, '733fa64e'));
    final params = [
      args.proposalId,
      args.orgAddress,
      args.actionType,
      args.p,
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
  Future<String> execute(
    ({BigInt proposalId}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, 'fe0d94c1'));
    final params = [args.proposalId];
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
  Future<String> initializeOrg(
    ({_i2.EthereumAddress orgAccountAddress, List<_i2.EthereumAddress> initialMembers, BigInt initialThreshold, _i2.EthereumAddress creator, bool isPublic}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, '8bbd91d3'));
    final params = [
      args.orgAccountAddress,
      args.initialMembers,
      args.initialThreshold,
      args.creator,
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
  Future<String> leaveOrg(
    ({_i2.EthereumAddress orgAddress}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, 'dbc35ebf'));
    final params = [args.orgAddress];
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
  Future<String> onCitizenshipGranted(
    ({_i2.EthereumAddress account}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[11];
    assert(checkSignature(function, '2a6251ce'));
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
  Future<String> onCitizenshipRevoked(
    ({_i2.EthereumAddress account}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[12];
    assert(checkSignature(function, 'b2aeb3cc'));
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
  Future<List<BigInt>> openProposals(
    ({_i2.EthereumAddress orgAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[13];
    assert(checkSignature(function, 'a12605ca'));
    final params = [args.orgAddress];
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
  Future<_i2.EthereumAddress> proposalOrg(
    ({BigInt proposalId}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[14];
    assert(checkSignature(function, '4f323e47'));
    final params = [args.proposalId];
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
  Future<String> startVote(
    ({_i2.EthereumAddress orgAddress, BigInt actionType, dynamic params, _i3.Uint8List tag}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[15];
    assert(checkSignature(function, 'a70a2c30'));
    final params = [
      args.orgAddress,
      args.actionType,
      args.params,
      args.tag,
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
  Future<String> veto(
    ({BigInt proposalId, String reason}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[16];
    assert(checkSignature(function, 'b9180682'));
    final params = [
      args.proposalId,
      args.reason,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// Returns a live stream of all AccountManagerSet events emitted by this contract.
  Stream<AccountManagerSet> accountManagerSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('AccountManagerSet');
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
      return AccountManagerSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all MemberAdded events emitted by this contract.
  Stream<MemberAdded> memberAddedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('MemberAdded');
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
      return MemberAdded(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all MemberLeft events emitted by this contract.
  Stream<MemberLeft> memberLeftEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('MemberLeft');
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
      return MemberLeft(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all MemberRemoved events emitted by this contract.
  Stream<MemberRemoved> memberRemovedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('MemberRemoved');
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
      return MemberRemoved(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all OrgStorageSet events emitted by this contract.
  Stream<OrgStorageSet> orgStorageSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('OrgStorageSet');
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
      return OrgStorageSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all SafeAuthSet events emitted by this contract.
  Stream<SafeAuthSet> safeAuthSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('SafeAuthSet');
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
      return SafeAuthSet(
        decoded,
        result,
      );
    });
  }
}

class AccountManagerSet {
  AccountManagerSet(
    List<dynamic> response,
    this.event,
  )   : accountManagerAddress = (response[0] as _i2.EthereumAddress);

  final _i2.EthereumAddress accountManagerAddress;

  final _i1.FilterEvent event;
}

class MemberAdded {
  MemberAdded(
    List<dynamic> response,
    this.event,
  )   : orgAddress = (response[0] as _i2.EthereumAddress),
        memberAccountAddress = (response[1] as _i2.EthereumAddress);

  final _i2.EthereumAddress orgAddress;

  final _i2.EthereumAddress memberAccountAddress;

  final _i1.FilterEvent event;
}

class MemberLeft {
  MemberLeft(
    List<dynamic> response,
    this.event,
  )   : orgAddress = (response[0] as _i2.EthereumAddress),
        memberAccountAddress = (response[1] as _i2.EthereumAddress);

  final _i2.EthereumAddress orgAddress;

  final _i2.EthereumAddress memberAccountAddress;

  final _i1.FilterEvent event;
}

class MemberRemoved {
  MemberRemoved(
    List<dynamic> response,
    this.event,
  )   : orgAddress = (response[0] as _i2.EthereumAddress),
        memberAccountAddress = (response[1] as _i2.EthereumAddress);

  final _i2.EthereumAddress orgAddress;

  final _i2.EthereumAddress memberAccountAddress;

  final _i1.FilterEvent event;
}

class OrgStorageSet {
  OrgStorageSet(
    List<dynamic> response,
    this.event,
  )   : orgStorageAddress = (response[0] as _i2.EthereumAddress);

  final _i2.EthereumAddress orgStorageAddress;

  final _i1.FilterEvent event;
}

class SafeAuthSet {
  SafeAuthSet(
    List<dynamic> response,
    this.event,
  )   : safeAuthAddress = (response[0] as _i2.EthereumAddress);

  final _i2.EthereumAddress safeAuthAddress;

  final _i1.FilterEvent event;
}
