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
  '[{"inputs":[{"internalType":"address","name":"_moduleRegistry","type":"address"},{"internalType":"uint256","name":"_voteDuration","type":"uint256"},{"internalType":"uint256","name":"_quorumBps","type":"uint256"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[],"name":"AdminCapReached","type":"error"},{"inputs":[],"name":"AlreadyAdmin","type":"error"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"address","name":"voter","type":"address"}],"name":"Gov_AlreadyVoted","type":"error"},{"inputs":[],"name":"Gov_BadCooldown","type":"error"},{"inputs":[],"name":"Gov_BadDuration","type":"error"},{"inputs":[],"name":"Gov_BadMaxOpen","type":"error"},{"inputs":[],"name":"Gov_BadQuorum","type":"error"},{"inputs":[],"name":"Gov_BadReason","type":"error"},{"inputs":[],"name":"Gov_MemoryNotRegistered","type":"error"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"Gov_NotClosable","type":"error"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"Gov_NotOpen","type":"error"},{"inputs":[{"internalType":"address","name":"caller","type":"address"}],"name":"Gov_OnlyOrgManager","type":"error"},{"inputs":[],"name":"Gov_OrgManagerNotRegistered","type":"error"},{"inputs":[{"internalType":"address","name":"proposer","type":"address"},{"internalType":"address","name":"org","type":"address"}],"name":"Gov_ProposerHasOpenVote","type":"error"},{"inputs":[{"internalType":"address","name":"proposer","type":"address"},{"internalType":"address","name":"org","type":"address"},{"internalType":"uint256","name":"until","type":"uint256"}],"name":"Gov_ProposerInCooldown","type":"error"},{"inputs":[{"internalType":"address","name":"org","type":"address"},{"internalType":"uint256","name":"maxOpen","type":"uint256"}],"name":"Gov_TooManyOpenVotes","type":"error"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"Gov_UnknownProposal","type":"error"},{"inputs":[],"name":"Gov_VoteWeightNotRegistered","type":"error"},{"inputs":[],"name":"Gov_ZeroAddress","type":"error"},{"inputs":[{"internalType":"address","name":"voter","type":"address"},{"internalType":"address","name":"org","type":"address"}],"name":"Gov_ZeroWeight","type":"error"},{"inputs":[],"name":"InvalidAdmin","type":"error"},{"inputs":[],"name":"NotAdmin","type":"error"},{"inputs":[],"name":"NotAuthorized","type":"error"},{"inputs":[],"name":"RootNotResolvable","type":"error"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"admin","type":"address"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"AdminAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"admin","type":"address"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"AdminRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bool","name":"on","type":"bool"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"InheritanceSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"orgAddress","type":"address"},{"indexed":false,"internalType":"uint256","name":"cooldownSeconds","type":"uint256"}],"name":"OrgCancelCooldownSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"orgAddress","type":"address"},{"indexed":false,"internalType":"uint256","name":"maxOpen","type":"uint256"}],"name":"OrgMaxOpenSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"orgAddress","type":"address"},{"indexed":false,"internalType":"bool","name":"on","type":"bool"}],"name":"OrgProposerCapSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"orgAddress","type":"address"},{"indexed":false,"internalType":"uint256","name":"bps","type":"uint256"}],"name":"OrgQuorumBpsSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"orgAddress","type":"address"},{"indexed":false,"internalType":"uint256","name":"durationSeconds","type":"uint256"}],"name":"OrgVoteDurationSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"orgAddress","type":"address"},{"indexed":false,"internalType":"bool","name":"on","type":"bool"}],"name":"OrgWaitFullPeriodSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newQuorumBps","type":"uint256"}],"name":"QuorumBpsSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"proposalId","type":"uint256"},{"indexed":true,"internalType":"address","name":"orgAddress","type":"address"},{"indexed":false,"internalType":"enum IVotingEngine.CancelKind","name":"kind","type":"uint8"},{"indexed":false,"internalType":"address","name":"by","type":"address"},{"indexed":false,"internalType":"string","name":"reason","type":"string"},{"indexed":false,"internalType":"uint256","name":"forVotes","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"againstVotes","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"abstainVotes","type":"uint256"}],"name":"VoteCancelled","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"proposalId","type":"uint256"},{"indexed":true,"internalType":"address","name":"orgAddress","type":"address"},{"indexed":true,"internalType":"address","name":"voterAccountAddress","type":"address"},{"indexed":false,"internalType":"enum IVotingEngine.VoteType","name":"support","type":"uint8"},{"indexed":false,"internalType":"uint256","name":"weight","type":"uint256"}],"name":"VoteCast","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newDuration","type":"uint256"}],"name":"VoteDurationSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"proposalId","type":"uint256"},{"indexed":true,"internalType":"address","name":"orgAddress","type":"address"},{"indexed":false,"internalType":"enum IOrgManager.VoteActionType","name":"actionType","type":"uint8"},{"indexed":false,"internalType":"address","name":"targetAddress","type":"address"}],"name":"VoteExecuted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"proposalId","type":"uint256"},{"indexed":true,"internalType":"address","name":"orgAddress","type":"address"},{"indexed":false,"internalType":"bytes","name":"reason","type":"bytes"}],"name":"VoteFailed","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"proposalId","type":"uint256"},{"indexed":true,"internalType":"address","name":"orgAddress","type":"address"},{"indexed":false,"internalType":"bytes","name":"reason","type":"bytes"}],"name":"VoteRunFailed","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"proposalId","type":"uint256"},{"indexed":true,"internalType":"address","name":"orgAddress","type":"address"},{"indexed":true,"internalType":"address","name":"initiatorAccountAddress","type":"address"},{"indexed":false,"internalType":"enum IOrgManager.VoteActionType","name":"actionType","type":"uint8"},{"indexed":false,"internalType":"bytes32","name":"tag","type":"bytes32"},{"indexed":false,"internalType":"uint256","name":"expirationTimestamp","type":"uint256"},{"indexed":false,"internalType":"bool","name":"waitFullPeriod","type":"bool"},{"indexed":false,"internalType":"uint256","name":"requiredQuorum","type":"uint256"}],"name":"VoteStarted","type":"event"},{"inputs":[],"name":"AUTO_RETRY_WINDOW","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"DEFAULT_MAX_OPEN","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"EXECUTE_WINDOW","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"MAX_CANCEL_REASON","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"MAX_OPEN_CAP","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"MAX_VOTE_DURATION","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"MIN_VOTE_DURATION","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"addAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"admins","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"enum IVotingEngine.CancelKind","name":"kind","type":"uint8"},{"internalType":"address","name":"by","type":"address"},{"internalType":"string","name":"reason","type":"string"}],"name":"cancel","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"address","name":"voter","type":"address"},{"internalType":"enum IVotingEngine.VoteType","name":"support","type":"uint8"}],"name":"castVote","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"close","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"orgAddress","type":"address"},{"internalType":"address","name":"proposer","type":"address"}],"name":"cooldownUntil","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"bool","name":"ok","type":"bool"},{"internalType":"bytes","name":"reason","type":"bytes"}],"name":"endVote","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"getExecutionInfo","outputs":[{"internalType":"bool","name":"shouldExecute","type":"bool"},{"internalType":"address","name":"orgAddress","type":"address"},{"internalType":"enum IOrgManager.VoteActionType","name":"actionType","type":"uint8"},{"components":[{"internalType":"address","name":"targetAddress","type":"address"},{"internalType":"uint256","name":"valueParam","type":"uint256"},{"internalType":"string","name":"keyParam","type":"string"},{"internalType":"string","name":"valueStringParam","type":"string"},{"internalType":"uint8","name":"recordTypeValueParam","type":"uint8"},{"internalType":"string","name":"customTypeParam","type":"string"},{"internalType":"bytes","name":"dataParam","type":"bytes"},{"internalType":"enum Enum.Operation","name":"operationParam","type":"uint8"}],"internalType":"struct IOrgManager.VoteActionParams","name":"params","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"getProposal","outputs":[{"components":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"address","name":"org","type":"address"},{"internalType":"enum IVotingEngine.Status","name":"status","type":"uint8"},{"internalType":"bool","name":"waitFullPeriod","type":"bool"},{"internalType":"uint256","name":"snapshotBlock","type":"uint256"},{"internalType":"uint256","name":"expirationTimestamp","type":"uint256"},{"internalType":"address","name":"initiator","type":"address"},{"internalType":"enum IOrgManager.VoteActionType","name":"actionType","type":"uint8"},{"internalType":"bytes32","name":"tag","type":"bytes32"},{"internalType":"uint256","name":"snapshotTotal","type":"uint256"},{"internalType":"uint256","name":"quorumBps","type":"uint256"},{"internalType":"uint256","name":"requiredQuorum","type":"uint256"},{"internalType":"uint256","name":"forVotes","type":"uint256"},{"internalType":"uint256","name":"againstVotes","type":"uint256"},{"internalType":"uint256","name":"abstainVotes","type":"uint256"},{"internalType":"bool","name":"passed","type":"bool"},{"internalType":"bool","name":"executable","type":"bool"},{"internalType":"bool","name":"closable","type":"bool"},{"components":[{"internalType":"address","name":"targetAddress","type":"address"},{"internalType":"uint256","name":"valueParam","type":"uint256"},{"internalType":"string","name":"keyParam","type":"string"},{"internalType":"string","name":"valueStringParam","type":"string"},{"internalType":"uint8","name":"recordTypeValueParam","type":"uint8"},{"internalType":"string","name":"customTypeParam","type":"string"},{"internalType":"bytes","name":"dataParam","type":"bytes"},{"internalType":"enum Enum.Operation","name":"operationParam","type":"uint8"}],"internalType":"struct IOrgManager.VoteActionParams","name":"params","type":"tuple"},{"internalType":"address","name":"cancelledBy","type":"address"},{"internalType":"enum IVotingEngine.CancelKind","name":"cancelKind","type":"uint8"},{"internalType":"string","name":"cancelReason","type":"string"}],"internalType":"struct IVotingEngine.ProposalView","name":"v","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"address","name":"voter","type":"address"}],"name":"hasVoted","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"inheritanceOn","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"isAdmin","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleRegistry","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleType","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"nextProposalId","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"orgAddress","type":"address"}],"name":"openProposals","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"orgAddress","type":"address"}],"name":"orgCancelCooldown","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"orgAddress","type":"address"}],"name":"orgMaxOpen","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"orgAddress","type":"address"}],"name":"orgProposerCap","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"orgAddress","type":"address"}],"name":"orgQuorumBps","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"orgAddress","type":"address"}],"name":"orgVoteDuration","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"orgAddress","type":"address"}],"name":"orgWaitFullPeriod","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"proposalOrg","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"quorumBps","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"removeAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"on","type":"bool"}],"name":"setInheritance","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"orgAddress","type":"address"},{"internalType":"uint256","name":"cooldownSeconds","type":"uint256"}],"name":"setOrgCancelCooldown","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"orgAddress","type":"address"},{"internalType":"uint256","name":"maxOpen","type":"uint256"}],"name":"setOrgMaxOpen","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"orgAddress","type":"address"},{"internalType":"bool","name":"on","type":"bool"}],"name":"setOrgProposerCap","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"orgAddress","type":"address"},{"internalType":"uint256","name":"bps","type":"uint256"}],"name":"setOrgQuorumBps","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"orgAddress","type":"address"},{"internalType":"uint256","name":"durationSeconds","type":"uint256"}],"name":"setOrgVoteDuration","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"orgAddress","type":"address"},{"internalType":"bool","name":"on","type":"bool"}],"name":"setOrgWaitFullPeriod","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"newQuorumBps","type":"uint256"}],"name":"setQuorumBps","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"newDuration","type":"uint256"}],"name":"setVoteDuration","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"orgAddress","type":"address"},{"internalType":"address","name":"initiatorAccountAddress","type":"address"},{"internalType":"enum IOrgManager.VoteActionType","name":"actionType","type":"uint8"},{"components":[{"internalType":"address","name":"targetAddress","type":"address"},{"internalType":"uint256","name":"valueParam","type":"uint256"},{"internalType":"string","name":"keyParam","type":"string"},{"internalType":"string","name":"valueStringParam","type":"string"},{"internalType":"uint8","name":"recordTypeValueParam","type":"uint8"},{"internalType":"string","name":"customTypeParam","type":"string"},{"internalType":"bytes","name":"dataParam","type":"bytes"},{"internalType":"enum Enum.Operation","name":"operationParam","type":"uint8"}],"internalType":"struct IOrgManager.VoteActionParams","name":"params","type":"tuple"},{"internalType":"bytes32","name":"tag","type":"bytes32"}],"name":"startVote","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"bool","name":"runNow","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"voteDuration","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}]',
  'Governor',
);

class Governor extends _i1.GeneratedContract {
  Governor({
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
  Future<BigInt> AUTO_RETRY_WINDOW(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '9411d4b7'));
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
  Future<BigInt> DEFAULT_MAX_OPEN(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, '20fc823b'));
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
  Future<BigInt> EXECUTE_WINDOW(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, 'f354efcb'));
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
  Future<BigInt> MAX_CANCEL_REASON(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, '7da706fe'));
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
  Future<BigInt> MAX_OPEN_CAP(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, '587194a7'));
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
  Future<BigInt> MAX_VOTE_DURATION(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, '1ecbb9de'));
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
  Future<BigInt> MIN_VOTE_DURATION(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, '3eedfc10'));
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
    final function = self.abi.functions[8];
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
    final function = self.abi.functions[9];
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
  Future<String> cancel(
    ({BigInt id, BigInt kind, _i2.EthereumAddress by, String reason}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[10];
    assert(checkSignature(function, '8707550f'));
    final params = [
      args.id,
      args.kind,
      args.by,
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
    ({BigInt id, _i2.EthereumAddress voter, BigInt support}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[11];
    assert(checkSignature(function, 'cf8795cc'));
    final params = [
      args.id,
      args.voter,
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
  Future<String> close(
    ({BigInt id}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[12];
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
  Future<BigInt> cooldownUntil(
    ({_i2.EthereumAddress orgAddress, _i2.EthereumAddress proposer}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[13];
    assert(checkSignature(function, 'eb10306a'));
    final params = [
      args.orgAddress,
      args.proposer,
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
  Future<String> endVote(
    ({BigInt id, bool ok, _i3.Uint8List reason}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[14];
    assert(checkSignature(function, '89dad74c'));
    final params = [
      args.id,
      args.ok,
      args.reason,
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
  Future<GetExecutionInfo> getExecutionInfo(
    ({BigInt id}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[15];
    assert(checkSignature(function, '73ba3745'));
    final params = [args.id];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return GetExecutionInfo(response);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<dynamic> getProposal(
    ({BigInt id}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[16];
    assert(checkSignature(function, 'c7f758a8'));
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
  Future<bool> hasVoted(
    ({BigInt id, _i2.EthereumAddress voter}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[17];
    assert(checkSignature(function, '43859632'));
    final params = [
      args.id,
      args.voter,
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
  Future<bool> inheritanceOn(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[18];
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
    final function = self.abi.functions[19];
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
  Future<_i2.EthereumAddress> moduleRegistry(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[20];
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
    final function = self.abi.functions[21];
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
  Future<BigInt> nextProposalId(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[22];
    assert(checkSignature(function, '2ab09d14'));
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
  Future<List<BigInt>> openProposals(
    ({_i2.EthereumAddress orgAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[23];
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
  Future<BigInt> orgCancelCooldown(
    ({_i2.EthereumAddress orgAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[24];
    assert(checkSignature(function, '194e104e'));
    final params = [args.orgAddress];
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
  Future<BigInt> orgMaxOpen(
    ({_i2.EthereumAddress orgAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[25];
    assert(checkSignature(function, '3f6143f0'));
    final params = [args.orgAddress];
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
  Future<bool> orgProposerCap(
    ({_i2.EthereumAddress orgAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[26];
    assert(checkSignature(function, 'f537cfd2'));
    final params = [args.orgAddress];
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
  Future<BigInt> orgQuorumBps(
    ({_i2.EthereumAddress orgAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[27];
    assert(checkSignature(function, '845e4ba9'));
    final params = [args.orgAddress];
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
  Future<BigInt> orgVoteDuration(
    ({_i2.EthereumAddress orgAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[28];
    assert(checkSignature(function, 'd24287dc'));
    final params = [args.orgAddress];
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
  Future<bool> orgWaitFullPeriod(
    ({_i2.EthereumAddress orgAddress}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[29];
    assert(checkSignature(function, '90f0825b'));
    final params = [args.orgAddress];
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
  Future<_i2.EthereumAddress> proposalOrg(
    ({BigInt id}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[30];
    assert(checkSignature(function, '4f323e47'));
    final params = [args.id];
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
  Future<BigInt> quorumBps(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[31];
    assert(checkSignature(function, 'cd2ddd0c'));
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
    final function = self.abi.functions[32];
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
    final function = self.abi.functions[33];
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
  Future<String> setOrgCancelCooldown(
    ({_i2.EthereumAddress orgAddress, BigInt cooldownSeconds}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[34];
    assert(checkSignature(function, 'd539f80c'));
    final params = [
      args.orgAddress,
      args.cooldownSeconds,
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
  Future<String> setOrgMaxOpen(
    ({_i2.EthereumAddress orgAddress, BigInt maxOpen}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[35];
    assert(checkSignature(function, 'f45bf3ed'));
    final params = [
      args.orgAddress,
      args.maxOpen,
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
  Future<String> setOrgProposerCap(
    ({_i2.EthereumAddress orgAddress, bool on}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[36];
    assert(checkSignature(function, '1a6d9a65'));
    final params = [
      args.orgAddress,
      args.on,
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
  Future<String> setOrgQuorumBps(
    ({_i2.EthereumAddress orgAddress, BigInt bps}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[37];
    assert(checkSignature(function, 'ea378342'));
    final params = [
      args.orgAddress,
      args.bps,
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
  Future<String> setOrgVoteDuration(
    ({_i2.EthereumAddress orgAddress, BigInt durationSeconds}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[38];
    assert(checkSignature(function, '812657b6'));
    final params = [
      args.orgAddress,
      args.durationSeconds,
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
  Future<String> setOrgWaitFullPeriod(
    ({_i2.EthereumAddress orgAddress, bool on}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[39];
    assert(checkSignature(function, 'fba93ff2'));
    final params = [
      args.orgAddress,
      args.on,
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
  Future<String> setQuorumBps(
    ({BigInt newQuorumBps}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[40];
    assert(checkSignature(function, 'a815ca52'));
    final params = [args.newQuorumBps];
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
    final function = self.abi.functions[41];
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
  Future<String> startVote(
    ({_i2.EthereumAddress orgAddress, _i2.EthereumAddress initiatorAccountAddress, BigInt actionType, dynamic params, _i3.Uint8List tag}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[42];
    assert(checkSignature(function, '56481e06'));
    final params = [
      args.orgAddress,
      args.initiatorAccountAddress,
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

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> voteDuration(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[43];
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

  /// Returns a live stream of all OrgCancelCooldownSet events emitted by this contract.
  Stream<OrgCancelCooldownSet> orgCancelCooldownSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('OrgCancelCooldownSet');
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
      return OrgCancelCooldownSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all OrgMaxOpenSet events emitted by this contract.
  Stream<OrgMaxOpenSet> orgMaxOpenSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('OrgMaxOpenSet');
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
      return OrgMaxOpenSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all OrgProposerCapSet events emitted by this contract.
  Stream<OrgProposerCapSet> orgProposerCapSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('OrgProposerCapSet');
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
      return OrgProposerCapSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all OrgQuorumBpsSet events emitted by this contract.
  Stream<OrgQuorumBpsSet> orgQuorumBpsSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('OrgQuorumBpsSet');
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
      return OrgQuorumBpsSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all OrgVoteDurationSet events emitted by this contract.
  Stream<OrgVoteDurationSet> orgVoteDurationSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('OrgVoteDurationSet');
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
      return OrgVoteDurationSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all OrgWaitFullPeriodSet events emitted by this contract.
  Stream<OrgWaitFullPeriodSet> orgWaitFullPeriodSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('OrgWaitFullPeriodSet');
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
      return OrgWaitFullPeriodSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all QuorumBpsSet events emitted by this contract.
  Stream<QuorumBpsSet> quorumBpsSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('QuorumBpsSet');
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
      return QuorumBpsSet(
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

  /// Returns a live stream of all VoteExecuted events emitted by this contract.
  Stream<VoteExecuted> voteExecutedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('VoteExecuted');
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
      return VoteExecuted(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all VoteFailed events emitted by this contract.
  Stream<VoteFailed> voteFailedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('VoteFailed');
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
      return VoteFailed(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all VoteRunFailed events emitted by this contract.
  Stream<VoteRunFailed> voteRunFailedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('VoteRunFailed');
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
      return VoteRunFailed(
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

class GetExecutionInfo {
  GetExecutionInfo(List<dynamic> response)
      : shouldExecute = (response[0] as bool),
        orgAddress = (response[1] as _i2.EthereumAddress),
        actionType = (response[2] as BigInt),
        params = (response[3] as dynamic);

  final bool shouldExecute;

  final _i2.EthereumAddress orgAddress;

  final BigInt actionType;

  final dynamic params;

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

class OrgCancelCooldownSet {
  OrgCancelCooldownSet(
    List<dynamic> response,
    this.event,
  )   : orgAddress = (response[0] as _i2.EthereumAddress),
        cooldownSeconds = (response[1] as BigInt);

  final _i2.EthereumAddress orgAddress;

  final BigInt cooldownSeconds;

  final _i1.FilterEvent event;
}

class OrgMaxOpenSet {
  OrgMaxOpenSet(
    List<dynamic> response,
    this.event,
  )   : orgAddress = (response[0] as _i2.EthereumAddress),
        maxOpen = (response[1] as BigInt);

  final _i2.EthereumAddress orgAddress;

  final BigInt maxOpen;

  final _i1.FilterEvent event;
}

class OrgProposerCapSet {
  OrgProposerCapSet(
    List<dynamic> response,
    this.event,
  )   : orgAddress = (response[0] as _i2.EthereumAddress),
        on = (response[1] as bool);

  final _i2.EthereumAddress orgAddress;

  final bool on;

  final _i1.FilterEvent event;
}

class OrgQuorumBpsSet {
  OrgQuorumBpsSet(
    List<dynamic> response,
    this.event,
  )   : orgAddress = (response[0] as _i2.EthereumAddress),
        bps = (response[1] as BigInt);

  final _i2.EthereumAddress orgAddress;

  final BigInt bps;

  final _i1.FilterEvent event;
}

class OrgVoteDurationSet {
  OrgVoteDurationSet(
    List<dynamic> response,
    this.event,
  )   : orgAddress = (response[0] as _i2.EthereumAddress),
        durationSeconds = (response[1] as BigInt);

  final _i2.EthereumAddress orgAddress;

  final BigInt durationSeconds;

  final _i1.FilterEvent event;
}

class OrgWaitFullPeriodSet {
  OrgWaitFullPeriodSet(
    List<dynamic> response,
    this.event,
  )   : orgAddress = (response[0] as _i2.EthereumAddress),
        on = (response[1] as bool);

  final _i2.EthereumAddress orgAddress;

  final bool on;

  final _i1.FilterEvent event;
}

class QuorumBpsSet {
  QuorumBpsSet(
    List<dynamic> response,
    this.event,
  )   : newQuorumBps = (response[0] as BigInt);

  final BigInt newQuorumBps;

  final _i1.FilterEvent event;
}

class VoteCancelled {
  VoteCancelled(
    List<dynamic> response,
    this.event,
  )   : proposalId = (response[0] as BigInt),
        orgAddress = (response[1] as _i2.EthereumAddress),
        kind = (response[2] as BigInt),
        by = (response[3] as _i2.EthereumAddress),
        reason = (response[4] as String),
        forVotes = (response[5] as BigInt),
        againstVotes = (response[6] as BigInt),
        abstainVotes = (response[7] as BigInt);

  final BigInt proposalId;

  final _i2.EthereumAddress orgAddress;

  final BigInt kind;

  final _i2.EthereumAddress by;

  final String reason;

  final BigInt forVotes;

  final BigInt againstVotes;

  final BigInt abstainVotes;

  final _i1.FilterEvent event;
}

class VoteCast {
  VoteCast(
    List<dynamic> response,
    this.event,
  )   : proposalId = (response[0] as BigInt),
        orgAddress = (response[1] as _i2.EthereumAddress),
        voterAccountAddress = (response[2] as _i2.EthereumAddress),
        support = (response[3] as BigInt),
        weight = (response[4] as BigInt);

  final BigInt proposalId;

  final _i2.EthereumAddress orgAddress;

  final _i2.EthereumAddress voterAccountAddress;

  final BigInt support;

  final BigInt weight;

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

class VoteExecuted {
  VoteExecuted(
    List<dynamic> response,
    this.event,
  )   : proposalId = (response[0] as BigInt),
        orgAddress = (response[1] as _i2.EthereumAddress),
        actionType = (response[2] as BigInt),
        targetAddress = (response[3] as _i2.EthereumAddress);

  final BigInt proposalId;

  final _i2.EthereumAddress orgAddress;

  final BigInt actionType;

  final _i2.EthereumAddress targetAddress;

  final _i1.FilterEvent event;
}

class VoteFailed {
  VoteFailed(
    List<dynamic> response,
    this.event,
  )   : proposalId = (response[0] as BigInt),
        orgAddress = (response[1] as _i2.EthereumAddress),
        reason = (response[2] as _i3.Uint8List);

  final BigInt proposalId;

  final _i2.EthereumAddress orgAddress;

  final _i3.Uint8List reason;

  final _i1.FilterEvent event;
}

class VoteRunFailed {
  VoteRunFailed(
    List<dynamic> response,
    this.event,
  )   : proposalId = (response[0] as BigInt),
        orgAddress = (response[1] as _i2.EthereumAddress),
        reason = (response[2] as _i3.Uint8List);

  final BigInt proposalId;

  final _i2.EthereumAddress orgAddress;

  final _i3.Uint8List reason;

  final _i1.FilterEvent event;
}

class VoteStarted {
  VoteStarted(
    List<dynamic> response,
    this.event,
  )   : proposalId = (response[0] as BigInt),
        orgAddress = (response[1] as _i2.EthereumAddress),
        initiatorAccountAddress = (response[2] as _i2.EthereumAddress),
        actionType = (response[3] as BigInt),
        tag = (response[4] as _i3.Uint8List),
        expirationTimestamp = (response[5] as BigInt),
        waitFullPeriod = (response[6] as bool),
        requiredQuorum = (response[7] as BigInt);

  final BigInt proposalId;

  final _i2.EthereumAddress orgAddress;

  final _i2.EthereumAddress initiatorAccountAddress;

  final BigInt actionType;

  final _i3.Uint8List tag;

  final BigInt expirationTimestamp;

  final bool waitFullPeriod;

  final BigInt requiredQuorum;

  final _i1.FilterEvent event;
}
