import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web3dart/web3dart.dart';
import 'package:wallet/wallet.dart';
import 'package:publicos_core/src/core/publicos_core.dart';
import 'package:publicos_core/src/core/extensions/publicos_bsp.dart';
import 'package:publicos_core/src/core/extensions/publicos_accounts.dart';
import 'package:publicos_core/src/models/record_model.dart';
import 'package:publicos_core/src/utils/log.dart';
import 'package:publicos_core/src/utils/string_utils.dart' show bytes32ToString;
import 'package:publicos_core/src/utils/tx_utils.dart';

/// Extension for org management functionality including voting
extension PublicOSGovernance on PublicOS {
  static const _tag = 'Orgs';

  /// Get voting history for a specific org (last week of data)
  /// An org's proposals STARTED in a time window, with everything that happened
  /// to them since (ballots, run, failure, cancel). The window defaults to the
  /// last 7 days; the apps page backwards a week at a time ("load more")
  /// and stop at the org's creation ([getOrgCreatedAt]).
  /// The window is found by block TIMESTAMP ([blockAtOrAfter]), so a week is a
  /// week of time even across chain downtime. The nodes keep a log index
  /// (`LogIndex.Enabled`), so an address+topic query answers over
  /// any range; without it a node refuses more than 10,000 blocks per call.
  static Future<List<VoteHistoryItem>> getVotingHistory(
    String orgAddress, {
    DateTime? since,
    DateTime? until,
  }) async {

    try {
      final orgAddr = EthereumAddress.fromHex(orgAddress);

      final head = await PublicOS.web3Client.getBlockNumber();
      final from = await blockAtOrAfter(since ?? DateTime.now().subtract(const Duration(days: 7)));
      final to = until == null ? head : (await blockAtOrAfter(until)) - 1;
      if (from > head || to < from) return [];

      // Parallel-votes engine (Governor): every event
      // is keyed by proposal id, so the fold below matches ballots to their
      // proposal exactly. Starts come from the window; what happened to them
      // can come later, so the other five read from the window's start to head.
      final results = await Future.wait([
        _getEngineEvents('VoteStarted', orgAddr, from, to),
        _getEngineEvents('VoteCast', orgAddr, from, head),
        _getEngineEvents('VoteExecuted', orgAddr, from, head),
        _getEngineEvents('VoteFailed', orgAddr, from, head),
        _getEngineEvents('VoteRunFailed', orgAddr, from, head),
        _getEngineEvents('VoteCancelled', orgAddr, from, head), // vote_cancel
      ]);

      if (results[0].isEmpty) return [];

      return _processVotingEvents(
        orgAddress,
        results[0],
        results[1],
        results[2],
        results[3],
        results[4],
        results[5],
      );
    } catch (e) {
      Log.e(_tag, 'Error fetching voting history: $e');
      return [];
    }
  }

  static final Map<int, int> _blockSeconds = {};

  static Future<int> _blockTs(int n) async {
    final cached = _blockSeconds[n];
    if (cached != null) return cached;
    final b = await PublicOS.web3Client.getBlockInformation(blockNumber: '0x${n.toRadixString(16)}');
    final s = b.timestamp.millisecondsSinceEpoch ~/ 1000;
    _blockSeconds[n] = s;
    return s;
  }

  /// The first block whose timestamp is at or after [t] (head + 1 when none is).
  /// AuRa seals at most one block per 2-second step, so `head - (headTs - t) / 2`
  /// is a lower bound; downtime only pushes the answer up from there. Gallop up
  /// from that bound, then binary-search: a few calls on a healthy chain.
  static Future<int> blockAtOrAfter(DateTime t) async {
    final head = await PublicOS.web3Client.getBlockNumber();
    final target = t.millisecondsSinceEpoch ~/ 1000;
    final headTs = await _blockTs(head);
    if (headTs < target) return head + 1;
    var lo = (head - (headTs - target) ~/ 2).clamp(0, head);
    if (await _blockTs(lo) >= target) return lo;
    var step = 1;
    var hi = lo + step;
    while (hi < head && await _blockTs(hi) < target) {
      lo = hi;
      step *= 2;
      hi = (lo + step).clamp(0, head);
    }
    // ts(lo) < target <= ts(hi)
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (await _blockTs(mid) < target) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return hi;
  }

  /// When [orgAddress] was created (its `OrgCreated` event), or null when it
  /// cannot be read. The vote history pages back to here and no further.
  static Future<DateTime?> getOrgCreatedAt(String orgAddress) =>
      PublicOSAccounts.getAccountCreatedAt(EthereumAddress.fromHex(orgAddress), isOrg: true);

  // ── Parallel votes (Governor). The engine is keyed by PROPOSAL ID: an org may
  //    have up to `orgMaxOpen` proposals open at once, `startVote` returns an id,
  //    `castVote(id, support)` is the only ballot entry (there is no For-only
  //    castVote(org)). All writes route through OrgManager
  //    (engine + VoteWeight are onlyOrgManager); reads hit the engine. ──

  /// Every open proposal of an org, newest first. Reads
  /// `Governor.openProposals(org)` then `getProposal(id)` for each.
  static Future<List<ActiveVoteInfo>> getOpenVotes(String orgAddress) async {
    try {
      final orgAddr = EthereumAddress.fromHex(orgAddress);
      final engine = PublicOSBsp.votingMechanismContract;
      final ids = await engine.openProposals((orgAddress: orgAddr));
      if (ids.isEmpty) return const [];
      final views = await Future.wait(ids.map((id) => engine.getProposal((id: id))));
      final out = <ActiveVoteInfo>[];
      for (var i = 0; i < ids.length; i++) {
        final info = ActiveVoteInfo.fromProposalView(
          views[i],
          parameters: await _paramsForProposal(ids[i]),
        );
        if (info != null) out.add(info);
      }
      out.sort((a, b) => b.proposalId.compareTo(a.proposalId));
      return out;
    } catch (e) {
      Log.e(_tag, 'Error reading open votes for $orgAddress: $e');
      return const [];
    }
  }

  /// One open proposal of an org — the NEWEST when several are open — or null.
  /// Kept for the screens that still think "one vote per org"; new code lists
  /// [getOpenVotes] and acts by [ActiveVoteInfo.proposalId].
  static Future<ActiveVoteInfo?> getActiveVote(String orgAddress) async {
    final open = await getOpenVotes(orgAddress);
    return open.isEmpty ? null : open.first;
  }

  /// One proposal by id, any status; null when the engine has none under it.
  static Future<ActiveVoteInfo?> getVote(BigInt proposalId) async {
    try {
      final view = await PublicOSBsp.votingMechanismContract.getProposal((id: proposalId));
      return ActiveVoteInfo.fromProposalView(
        view,
        parameters: await _paramsForProposal(proposalId),
      );
    } catch (e) {
      Log.e(_tag, 'Error reading proposal $proposalId: $e');
      return null;
    }
  }

  /// Floor for every OrgManager vote send (startVote / castVote / execute).
  /// A vote runs its action inside a try/catch, so `eth_estimateGas` finds the
  /// smallest limit at which the OUTER tx succeeds, even when the action inside
  /// then runs out of gas and the proposal ends Failed. So we still estimate
  /// (a vote the contract refuses surfaces its reason here, before anything is
  /// sent) but send with max(estimate × 2, 8 M). Gas is free on 4489 (price 0,
  /// 200 M blocks). Same reason as `publicos_recovery.dart`'s `_reseedGasLimit`.
  static const int voteGasFloor = 8000000;

  static Future<Transaction> _voteTransaction(String functionName, List<dynamic> params, Credentials credentials) async {
    final contract = PublicOSBsp.orgManagerContract.self;
    final estimate = await PublicOS.web3Client.estimateGas(
      sender: credentials.address,
      to: contract.address,
      data: contract.function(functionName).encodeCall(params),
    );
    final doubled = estimate * BigInt.two;
    final floor = BigInt.from(voteGasFloor);
    return Transaction(maxGas: (doubled > floor ? doubled : floor).toInt());
  }

  /// `OrgManager.startVote` with the vote gas rule ([voteGasFloor]).
  static Future<String> sendStartVote(
    ({EthereumAddress orgAddress, BigInt actionType, dynamic params, Uint8List tag}) args, {
    required Credentials credentials,
  }) async {
    final tx = await _voteTransaction('startVote', [args.orgAddress, args.actionType, args.params, args.tag], credentials);
    return PublicOSBsp.orgManagerContract.startVote(args, credentials: credentials, transaction: tx);
  }

  /// `OrgManager.castVote` with the vote gas rule ([voteGasFloor]).
  static Future<String> sendCastVote(({BigInt proposalId, BigInt support}) args, {required Credentials credentials}) async {
    final tx = await _voteTransaction('castVote', [args.proposalId, args.support], credentials);
    return PublicOSBsp.orgManagerContract.castVote(args, credentials: credentials, transaction: tx);
  }

  /// `OrgManager.execute` with the vote gas rule ([voteGasFloor]).
  static Future<String> sendExecute(({BigInt proposalId}) args, {required Credentials credentials}) async {
    final tx = await _voteTransaction('execute', [args.proposalId], credentials);
    return PublicOSBsp.orgManagerContract.execute(args, credentials: credentials, transaction: tx);
  }

  /// Cast a ballot on ONE proposal: Against / For / Abstain. Routes through
  /// `OrgManager.castVote(proposalId, support)`. Weight is the caller's
  /// checkpointed weight at the proposal's snapshot block, resolved on the
  /// proposal's tag. A ballot simulated in the proposal's start block reverts
  /// (`VW_FutureLookup`), so wait one block after `VoteStarted` before sending.
  static Future<bool> castVote(BigInt proposalId, VoteSupport support) async {
    try {
      Log.d(_tag, 'castVote id=$proposalId support=${support.name} account=${PublicOS.myPublicosAddress} session=${PublicOS.sessionBlockchainAddress}');
      final txHash = await sendCastVote(
        (proposalId: proposalId, support: BigInt.from(support.index)),
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );
      Log.i(_tag, 'castVote($proposalId, ${support.name}) tx sent: $txHash — polling for receipt...');
      return await TxUtils.waitForReceipt(txHash, label: 'castVote($proposalId, ${support.name})');
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error casting ${support.name} vote on $proposalId: $e');
      return false;
    }
  }

  /// Org-keyed convenience over [castVote]: ballots the org's single open
  /// proposal. Refuses (false + `lastError`) when none or several are open —
  /// then the caller picks an id from [getOpenVotes].
  static Future<bool> castVoteWithSupport(
    String orgAddress,
    VoteSupport support, {
    BigInt? proposalId,
  }) async {
    var id = proposalId;
    if (id == null) {
      final open = await getOpenVotes(orgAddress);
      if (open.isEmpty) {
        PublicOS.lastError = 'castVote: no open vote in $orgAddress';
        Log.w(_tag, PublicOS.lastError!);
        return false;
      }
      if (open.length > 1) {
        PublicOS.lastError = 'castVote: ${open.length} open votes in $orgAddress — pass proposalId';
        Log.w(_tag, PublicOS.lastError!);
        return false;
      }
      id = open.first.proposalId;
    }
    return castVote(id, support);
  }

  /// Run a passed proposal: wait-full-period mode after its period (within the
  /// engine's EXECUTE_WINDOW), or a retry of a passed auto-run one whose run
  /// failed (`VoteRunFailed`). Any member may call. `OrgManager.execute(id)`.
  static Future<bool> executeVote(BigInt proposalId) async {
    try {
      final txHash = await sendExecute(
        (proposalId: proposalId),
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );
      Log.i(_tag, 'execute($proposalId) tx sent: $txHash');
      return await TxUtils.waitForReceipt(txHash, label: 'execute($proposalId)');
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error executing proposal $proposalId: $e');
      return false;
    }
  }

  /// Bookkeeping only: end an expired proposal as Failed and free its slot
  /// (`Governor.close(id)`, public, touches nothing else).
  static Future<bool> closeVote(BigInt proposalId) async {
    try {
      final txHash = await PublicOSBsp.votingMechanismContract.close(
        (id: proposalId),
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );
      Log.i(_tag, 'close($proposalId) tx sent: $txHash');
      return await TxUtils.waitForReceipt(txHash, label: 'close($proposalId)');
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error closing proposal $proposalId: $e');
      return false;
    }
  }

  // ── Cancel · veto · withdraw (a chain without the vote-cancel contracts has
  //    none of this). Every path ends in Governor.cancel; a cancelled
  //    proposal reads back with status cancelled + cancelKind/cancelledBy/
  //    cancelReason. ──

  /// The contract's bound on a cancel reason (`Governor.MAX_CANCEL_REASON`), in UTF-8 bytes.
  static const int maxCancelReasonBytes = 500;

  /// Null when [reason] is acceptable, else why not (1..500 UTF-8 bytes).
  static String? cancelReasonError(String reason) {
    final n = utf8.encode(reason).length;
    if (n == 0) return 'A reason is required';
    if (n > maxCancelReasonBytes) return 'The reason is over $maxCancelReasonBytes bytes ($n)';
    return null;
  }

  static Future<bool> _cancelDoor(String fn, BigInt proposalId, String reason) async {
    final bad = cancelReasonError(reason);
    if (bad != null) {
      PublicOS.lastError = bad;
      return false;
    }
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication required');
      return false;
    }
    try {
      final credentials = PublicOS.currentBlockchainPrivateKey!;
      // The vote gas rule ([voteGasFloor]): estimate first so a refusal surfaces here.
      final tx = await _voteTransaction(fn, [proposalId, reason], credentials);
      final om = PublicOSBsp.orgManagerContract;
      final txHash = fn == 'veto'
          ? await om.veto((proposalId: proposalId, reason: reason), credentials: credentials, transaction: tx)
          : await om.cancelVote((proposalId: proposalId, reason: reason), credentials: credentials, transaction: tx);
      Log.i(_tag, '$fn($proposalId) tx sent: $txHash');
      return await TxUtils.waitForReceipt(txHash, label: '$fn($proposalId)');
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'Error in $fn($proposalId): $e');
      return false;
    }
  }

  /// The proposer withdraws their own proposal while it is open (a passed one
  /// waiting to run included; not an expired one). Membership is not needed.
  /// Starts the proposer's cooldown in that org ([getOrgCancelCooldown]).
  static Future<bool> withdrawVote(BigInt proposalId, String reason) =>
      _cancelDoor('cancelVote', proposalId, reason);

  /// The org's vetoer cancels an open proposal. Must be a member now; a
  /// SET_VETOER proposal can't be vetoed. No cooldown for the proposer.
  static Future<bool> vetoVote(BigInt proposalId, String reason) =>
      _cancelDoor('veto', proposalId, reason);

  /// Vote 58 CANCEL_VOTE: [orgAddress] proposes to cancel [proposalId], which must
  /// be open and belong to this org or a REAL descendant (a parent org cancels a
  /// child's vote with its own vote, never through EXECUTE_ON_DESCENDANT). It
  /// never waits: it runs the moment it passes, even in a wait-mode org.
  static Future<bool> startVoteCancelVote(String orgAddress, BigInt proposalId, String reason) {
    final bad = cancelReasonError(reason);
    if (bad != null) {
      PublicOS.lastError = bad;
      return Future.value(false);
    }
    return _startValueVote(orgAddress,
        actionType: VoteActionType.cancelVote, label: 'startVoteCancelVote($proposalId)', value: proposalId, valueString: reason);
  }

  /// Vote 57 SET_VETOER: appoint [member] (a current member) as the org's one
  /// vetoer, replacing any other; null clears it. Can't be vetoed.
  static Future<bool> startVoteSetVetoer(String orgAddress, EthereumAddress? member) =>
      _startValueVote(orgAddress,
          actionType: VoteActionType.setVetoer, label: 'startVoteSetVetoer(${member?.eip55With0x ?? 'none'})', target: member);

  /// The longest withdraw cooldown the contract accepts (30 days).
  static const int maxCancelCooldownSeconds = 30 * 24 * 60 * 60;

  /// Vote 59 SET_CANCEL_COOLDOWN: how long a proposer waits before proposing in
  /// this org again after withdrawing their own vote (0..30 days, 0 = none, the
  /// default; the root org starts at 2 days).
  static Future<bool> startVoteSetCancelCooldown(String orgAddress, int seconds) {
    if (seconds < 0 || seconds > maxCancelCooldownSeconds) {
      PublicOS.lastError = 'Cooldown must be 0..$maxCancelCooldownSeconds seconds';
      return Future.value(false);
    }
    return _startValueVote(orgAddress,
        actionType: VoteActionType.setCancelCooldown, label: 'startVoteSetCancelCooldown($seconds)', value: BigInt.from(seconds));
  }

  /// The org's vetoer, or null when it has none — or when the chain has no
  /// OrgCancelVoteMemory registered or the read fails.
  static Future<String?> getOrgVetoer(String orgAddress) async {
    if (PublicOSBsp.orgCancelVoteMemoryAddress == null) return null;
    try {
      final v = await PublicOSBsp.orgCancelVoteMemoryContract
          .vetoerOf((org: EthereumAddress.fromHex(orgAddress),));
      return v == EthereumAddress.fromHex('0x0000000000000000000000000000000000000000') ? null : v.eip55With0x;
    } catch (e) {
      Log.e(_tag, 'Error reading org vetoer: $e');
      return null;
    }
  }

  /// The org's withdraw cooldown in seconds (0 = none). Null on a read error
  /// (also on a chain without the vote-cancel contracts).
  static Future<int?> getOrgCancelCooldown(String orgAddress) async {
    try {
      final v = await PublicOSBsp.votingMechanismContract
          .orgCancelCooldown((orgAddress: EthereumAddress.fromHex(orgAddress),));
      return v.toInt();
    } catch (e) {
      Log.e(_tag, 'Error reading org cancel cooldown: $e');
      return null;
    }
  }

  /// When [account] may propose in [orgAddress] again after a withdraw; null when
  /// it already may (or on a read error).
  static Future<DateTime?> getProposerCooldownUntil(String orgAddress, String account) async {
    try {
      final v = await PublicOSBsp.votingMechanismContract.cooldownUntil(
          (orgAddress: EthereumAddress.fromHex(orgAddress), proposer: EthereumAddress.fromHex(account)));
      if (v == BigInt.zero) return null;
      final until = DateTime.fromMillisecondsSinceEpoch(v.toInt() * 1000);
      // The contract compares against block time, so do we: on a chain whose clock
      // differs from this device's (a devnet moved ahead, a skewed phone), wall-clock
      // "now" gives the wrong answer.
      final head = await PublicOS.web3Client.getBlockInformation(blockNumber: 'latest');
      return until.isAfter(head.timestamp) ? until : null;
    } catch (e) {
      Log.e(_tag, 'Error reading proposer cooldown: $e');
      return null;
    }
  }

  /// The bytes32 form of a human-readable vote tag. Tags are free-form —
  /// keccak256 of the UTF-8 string, no registry. The empty string maps to the
  /// untagged lane (0x0) that every base (untagged) proposal resolves on.
  static Uint8List voteTag(String tag) => tag.isEmpty ? Uint8List(32) : keccakUtf8(tag);

  /// Delegate the caller's voting weight ON one [tag] to [delegateeAddress]
  /// (null = clear the tag back to self). Per-tag only — there is no all-tags
  /// delegation. Takes effect for proposals created AFTER this call (snapshot-
  /// scoped); the delegatee must be a current org member; max 16 simultaneous
  /// tag-delegations per org.
  static Future<bool> delegateVote(
    String orgAddress, {
    String tag = '',
    String? delegateeAddress,
  }) async {
    try {
      final txHash = await PublicOSBsp.orgManagerContract.delegate(
        (
          orgAddress: EthereumAddress.fromHex(orgAddress),
          tag: voteTag(tag),
          delegatee: EthereumAddress.fromHex(
              delegateeAddress ?? '0x0000000000000000000000000000000000000000'),
        ),
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );
      Log.i(_tag, 'delegate(tag="$tag" → ${delegateeAddress ?? 'self'}) tx sent: $txHash');
      return await TxUtils.waitForReceipt(txHash, label: 'delegate($orgAddress, "$tag")');
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error delegating vote: $e');
      return false;
    }
  }

  /// Live weighted 3-way tally of ONE proposal (parallel votes: by id).
  static Future<({BigInt against, BigInt forVotes, BigInt abstain})?> getProposalVotes(
      BigInt proposalId) async {
    final v = await getVote(proposalId);
    if (v == null) return null;
    return (against: v.againstVotes, forVotes: v.forVotes, abstain: v.abstainVotes);
  }

  /// One proposal's frozen tag as raw bytes32 hex ('0x00…00' = untagged / none).
  /// Tags are hashes — the client maps known tag strings via [voteTag].
  static Future<String?> getProposalTag(BigInt proposalId) async {
    final v = await getVote(proposalId);
    return v?.tag;
  }

  /// The org's effective participation floor in basis points (its own override,
  /// else the global default). Changed by the org itself via a SET_QUORUM_BPS vote.
  static Future<BigInt?> getOrgQuorumBps(String orgAddress) async {
    try {
      return await PublicOSBsp.votingMechanismContract
          .orgQuorumBps((orgAddress: EthereumAddress.fromHex(orgAddress),));
    } catch (e) {
      Log.e(_tag, 'Error reading org quorum: $e');
      return null;
    }
  }

  /// The org's effective vote duration in seconds (override, else global).
  /// Changed by the org itself via a SET_VOTE_DURATION vote (bounds [1h, 30d]).
  static Future<BigInt?> getOrgVoteDuration(String orgAddress) async {
    try {
      return await PublicOSBsp.votingMechanismContract
          .orgVoteDuration((orgAddress: EthereumAddress.fromHex(orgAddress),));
    } catch (e) {
      Log.e(_tag, 'Error reading org vote duration: $e');
      return null;
    }
  }

  /// How many proposals this org may have open at once (1..5, default 2).
  /// Changed by the org's own SET_MAX_OPEN_VOTES vote (52).
  static Future<int?> getOrgMaxOpen(String orgAddress) async {
    try {
      final v = await PublicOSBsp.votingMechanismContract
          .orgMaxOpen((orgAddress: EthereumAddress.fromHex(orgAddress),));
      return v.toInt();
    } catch (e) {
      Log.e(_tag, 'Error reading org max open votes: $e');
      return null;
    }
  }

  /// On = passed proposals run only after their full period, by any member's
  /// `execute` (SET_WAIT_FULL_PERIOD, 53). Off (default) = the passing ballot runs it.
  static Future<bool?> getOrgWaitFullPeriod(String orgAddress) async {
    try {
      return await PublicOSBsp.votingMechanismContract
          .orgWaitFullPeriod((orgAddress: EthereumAddress.fromHex(orgAddress),));
    } catch (e) {
      Log.e(_tag, 'Error reading org wait switch: $e');
      return null;
    }
  }

  /// On (default) = one not-yet-passed proposal per member (SET_PROPOSER_CAP, 56).
  static Future<bool?> getOrgProposerCap(String orgAddress) async {
    try {
      return await PublicOSBsp.votingMechanismContract
          .orgProposerCap((orgAddress: EthereumAddress.fromHex(orgAddress),));
    } catch (e) {
      Log.e(_tag, 'Error reading org proposer cap: $e');
      return null;
    }
  }

  /// True when the org has as many open proposals as it allows, so a new
  /// `startVote` would be refused. False on any read error (let the contract decide).
  static Future<bool> isOrgAtOpenLimit(String orgAddress) async {
    final open = await getOpenVotes(orgAddress);
    final max = await getOrgMaxOpen(orgAddress);
    if (max == null) return false;
    return open.length >= max;
  }

  /// True when [account] has an open proposal in [orgAddress] that has not
  /// passed yet — i.e. a write it just made started a vote the other members
  /// still need to back (vs. a threshold-1 org where it ran at once). Replaces
  /// "is ANY vote open", which parallel votes made wrong.
  static Future<bool> hasPendingVoteBy(String orgAddress, String? account) async {
    if (account == null) return false;
    final open = await getOpenVotes(orgAddress);
    final me = account.toLowerCase();
    return open.any((v) => v.initiator.toLowerCase() == me && !v.passed);
  }

  /// Who currently carries [accountAddress]'s ballot on [tag] in this org
  /// (the account itself when not delegated).
  static Future<String?> getTagDelegatee(
      String orgAddress, String accountAddress, {String tag = ''}) async {
    try {
      final d = await PublicOSBsp.voteWeightContract.tagDelegateeOf((
        account: EthereumAddress.fromHex(accountAddress),
        org: EthereumAddress.fromHex(orgAddress),
        tag: voteTag(tag),
      ));
      return d.eip55With0x;
    } catch (e) {
      Log.e(_tag, 'Error reading tag delegatee: $e');
      return null;
    }
  }

  /// Does the org have at least one open proposal? (`Governor.openProposals`.)
  static Future<bool> hasActiveVote(String orgAddress) async {
    try {
      final ids = await PublicOSBsp.votingMechanismContract
          .openProposals((orgAddress: EthereumAddress.fromHex(orgAddress)));
      return ids.isNotEmpty;
    } catch (e) {
      Log.e(_tag, 'Error reading open proposals for $orgAddress: $e');
      return false;
    }
  }

  /// One engine event type for an org over a block range. The parallel-votes
  /// engine's events are `(proposalId indexed, orgAddress indexed, …)`, so the
  /// org is topic[2] and topic[1] (the id) is left open.
  static Future<List<FilterEvent>> _getEngineEvents(
    String eventName,
    EthereumAddress orgAddress,
    int fromBlock,
    int currentBlock,
  ) async {
    try {
      final contract = PublicOSBsp.votingMechanismContract.self;
      final event = contract.event(eventName);
      // web3dart's FilterOptions.topics cannot express a skipped position
      // (`[sig, null, org]`), and topic[1] is the proposal id, so filter by the
      // signature on the node and by the org (topic[2]) here. The engine's log
      // volume is small; the window is already bounded.
      final filter = FilterOptions(
        address: contract.address,
        fromBlock: BlockNum.exact(fromBlock),
        toBlock: BlockNum.exact(currentBlock),
        topics: [
          [bytesToHex(event.signature, include0x: true)], // topic 0: signature
        ],
      );
      final orgTopic = '0x${orgAddress.eip55With0x.substring(2).padLeft(64, '0')}'.toLowerCase();
      final logs = await PublicOS.web3Client.getLogs(filter);
      return logs
          .where((l) => l.topics != null && l.topics!.length > 2 && (l.topics![2] ?? '').toLowerCase() == orgTopic)
          .toList();
    } catch (e) {
      Log.e(_tag, 'Error querying $eventName events: $e');
      return [];
    }
  }

  /// Fold the engine's events into history items keyed by PROPOSAL ID. Exact
  /// matching — the old "most recent vote started before this ballot" time
  /// heuristics are gone with the one-vote-per-org engine.
  ///
  /// Status: `VoteExecuted` → executed · `VoteCancelled` → cancelled (kind, by,
  /// reason and the tallies at the cancel) · `VoteFailed` → failed (reason kept in
  /// `parameters['failReason']`) · `VoteRunFailed` → still active, the run is
  /// retryable (`parameters['lastRunFailed']`) · an item still active past its
  /// own expiration is flipped to expired locally (an expired proposal nobody
  /// closes gets no terminal event until the org's next `startVote` sweeps it).
  static Future<List<VoteHistoryItem>> _processVotingEvents(
    String orgAddress,
    List<FilterEvent> voteStartedEvents,
    List<FilterEvent> voteCastEvents,
    List<FilterEvent> voteExecutedEvents,
    List<FilterEvent> voteFailedEvents,
    List<FilterEvent> voteRunFailedEvents,
    List<FilterEvent> voteCancelledEvents,
  ) async {
    final engine = PublicOSBsp.votingMechanismContract.self;
    final Map<String, VoteHistoryItem> voteMap = {};

    Future<DateTime> blockTime(FilterEvent e) async {
      final block = await PublicOS.web3Client
          .getBlockInformation(blockNumber: '0x${e.blockNum!.toRadixString(16)}');
      return DateTime.fromMillisecondsSinceEpoch(block.timestamp.millisecondsSinceEpoch);
    }

    for (final event in voteStartedEvents) {
      try {
        // [0] proposalId [1] orgAddress [2] initiatorAccountAddress [3] actionType
        // [4] tag [5] expirationTimestamp [6] waitFullPeriod [7] requiredQuorum
        final d = engine.event('VoteStarted').decodeResults(event.topics!, event.data!);
        final proposalId = d[0] as BigInt;
        final initiatorAddr = d[2] as EthereumAddress;
        final actionTypeIndex = (d[3] as BigInt).toInt();
        final expirationTime = DateTime.fromMillisecondsSinceEpoch((d[5] as BigInt).toInt() * 1000);
        // The WEIGHTED QUORUM FLOOR frozen at start (snapshotTotal × quorumBps / 1e4).
        final requiredQuorum = (d[7] as BigInt).toInt();
        final startTime = await blockTime(event);

        // Every type: read the VoteActionParams back from the startVote tx input
        // (the engine keeps no getter). Restricted to some types, a
        // past settings vote would have no valueParam and its card would read
        // it as 0 ("wait the full period: ON → OFF" for a vote that turned it on).
        final Map<String, dynamic> parameters =
            await _extractSafeTxParameters(event.transactionHash!);

        voteMap[proposalId.toString()] = VoteHistoryItem(
          id: proposalId.toString(),
          proposalId: proposalId,
          orgAddress: orgAddress,
          actionType: _actionTypeFromIndex(actionTypeIndex),
          initiator: initiatorAddr.eip55With0x,
          startTime: startTime,
          endTime: null,
          expirationTime: expirationTime,
          status: VoteStatus.active,
          yesVotes: 0, // head-count accumulates from VoteCast (the proposer's auto-For included)
          requiredThreshold: requiredQuorum,
          forVotes: 0,
          againstVotes: 0,
          abstainVotes: 0,
          voters: const [],
          parameters: parameters,
          waitFullPeriod: d[6] as bool,
          tag: bytesToHex(d[4] as Uint8List, include0x: true),
        );
      } catch (e) {
        Log.e(_tag, 'Error processing VoteStarted event: $e');
      }
    }

    for (final event in voteCastEvents) {
      try {
        // [0] proposalId [1] orgAddress [2] voterAccountAddress [3] support [4] weight
        final d = engine.event('VoteCast').decodeResults(event.topics!, event.data!);
        final key = (d[0] as BigInt).toString();
        final vote = voteMap[key];
        if (vote == null) continue; // started before the window
        final voter = (d[2] as EthereumAddress).eip55With0x;
        final support = (d[3] as BigInt).toInt(); // 0 Against / 1 For / 2 Abstain
        final weight = (d[4] as BigInt).toInt();
        final voters = List<String>.from(vote.voters);
        if (!voters.contains(voter)) voters.add(voter);
        voteMap[key] = vote.copyWith(
          voters: voters,
          yesVotes: voters.length,
          forVotes: vote.forVotes + (support == 1 ? weight : 0),
          againstVotes: vote.againstVotes + (support == 0 ? weight : 0),
          abstainVotes: vote.abstainVotes + (support == 2 ? weight : 0),
        );
      } catch (e) {
        Log.e(_tag, 'Error processing VoteCast event: $e');
      }
    }

    for (final event in voteExecutedEvents) {
      try {
        final d = engine.event('VoteExecuted').decodeResults(event.topics!, event.data!);
        final key = (d[0] as BigInt).toString();
        final vote = voteMap[key];
        if (vote == null) continue;
        voteMap[key] = vote.copyWith(endTime: await blockTime(event), status: VoteStatus.executed);
      } catch (e) {
        Log.e(_tag, 'Error processing VoteExecuted event: $e');
      }
    }

    for (final event in voteFailedEvents) {
      try {
        // [0] proposalId [1] orgAddress [2] reason (raw revert data / 'defeated')
        final d = engine.event('VoteFailed').decodeResults(event.topics!, event.data!);
        final key = (d[0] as BigInt).toString();
        final vote = voteMap[key];
        if (vote == null) continue;
        voteMap[key] = vote.copyWith(
          endTime: await blockTime(event),
          status: VoteStatus.failed,
          parameters: {
            ...vote.parameters,
            'failReason': bytesToHex(d[2] as Uint8List, include0x: true),
          },
        );
      } catch (e) {
        Log.e(_tag, 'Error processing VoteFailed event: $e');
      }
    }

    for (final event in voteRunFailedEvents) {
      try {
        final d = engine.event('VoteRunFailed').decodeResults(event.topics!, event.data!);
        final key = (d[0] as BigInt).toString();
        final vote = voteMap[key];
        if (vote == null) continue;
        // Not terminal — the proposal stays open and passed, retryable.
        voteMap[key] = vote.copyWith(parameters: {
          ...vote.parameters,
          'lastRunFailed': bytesToHex(d[2] as Uint8List, include0x: true),
        });
      } catch (e) {
        Log.e(_tag, 'Error processing VoteRunFailed event: $e');
      }
    }

    for (final event in voteCancelledEvents) {
      try {
        // VoteCancelled: [0] proposalId [1] orgAddress [2] kind [3] by [4] reason
        // [5] forVotes [6] againstVotes [7] abstainVotes (the tallies at the cancel)
        final d = engine.event('VoteCancelled').decodeResults(event.topics!, event.data!);
        final key = (d[0] as BigInt).toString();
        final vote = voteMap[key];
        if (vote == null) continue;
        voteMap[key] = vote.copyWith(
          endTime: await blockTime(event),
          status: VoteStatus.cancelled,
          cancelKind: CancelKind.values[(d[2] as BigInt).toInt()],
          cancelledBy: (d[3] as EthereumAddress).eip55With0x,
          cancelReason: d[4] as String,
          forVotes: (d[5] as BigInt).toInt(),
          againstVotes: (d[6] as BigInt).toInt(),
          abstainVotes: (d[7] as BigInt).toInt(),
        );
      } catch (e) {
        Log.e(_tag, 'Error processing VoteCancelled event: $e');
      }
    }

    final now = DateTime.now();
    for (final key in voteMap.keys.toList()) {
      final vote = voteMap[key]!;
      if (vote.status == VoteStatus.active && vote.expirationTime != null && now.isAfter(vote.expirationTime!)) {
        voteMap[key] = vote.copyWith(endTime: vote.expirationTime, status: VoteStatus.expired);
      }
    }

    return voteMap.values.toList()..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  /// The VoteActionParams a proposal was started with. The engine keeps them in
  /// a private mapping with no getter, so find the `VoteStarted` log by id
  /// (topic[1]) within the last ~30 days (the longest vote duration) and decode
  /// the `startVote` tx input. `{}` when not found.
  static Future<Map<String, dynamic>> _paramsForProposal(BigInt proposalId) async {
    try {
      final contract = PublicOSBsp.votingMechanismContract.self;
      final event = contract.event('VoteStarted');
      final currentBlock = await PublicOS.web3Client.getBlockNumber();
      final fromBlock = (currentBlock - 1296000).clamp(0, currentBlock); // ~30 d at 2 s blocks
      final logs = await PublicOS.web3Client.getLogs(FilterOptions(
        address: contract.address,
        fromBlock: BlockNum.exact(fromBlock),
        toBlock: BlockNum.exact(currentBlock),
        topics: [
          [bytesToHex(event.signature, include0x: true)],
          ['0x' + proposalId.toRadixString(16).padLeft(64, '0')],
        ],
      ));
      if (logs.isEmpty || logs.first.transactionHash == null) return {};
      return await _extractSafeTxParameters(logs.first.transactionHash!);
    } catch (e) {
      Log.w(_tag, 'params for proposal $proposalId: $e');
      return {};
    }
  }

  /// Extract Safe transaction parameters from the startVote transaction
  static Future<Map<String, dynamic>> _extractSafeTxParameters(String transactionHash) async {
    try {
      Log.d(_tag, '[VOTE DEBUG] _extractSafeTxParameters called for tx: $transactionHash');
      final transaction = await PublicOS.web3Client.getTransactionByHash(transactionHash);
      if (transaction == null) {
        Log.w(_tag, '[VOTE DEBUG] Transaction is null for hash: $transactionHash');
        return {};
      }

      Log.d(_tag, '[VOTE DEBUG] Transaction found, input length: ${transaction.input?.length ?? 0}');

      // Decode the startVote transaction input data to get the parameters
      final orgManagerContract = PublicOSBsp.orgManagerContract.self;
      // Two overloads (with / without a tag): pick the one whose selector the
      // tx actually called, so the tuple decode below reads the right shape.
      final selectorHex = bytesToHex(transaction.input.sublist(0, 4));
      final startVoteFunction = orgManagerContract.abi.functions.firstWhere(
        (f) => f.name == 'startVote' && bytesToHex(f.selector) == selectorHex,
        orElse: () => orgManagerContract.abi.functions.firstWhere((f) => f.name == 'startVote'),
      );

      // Decode the input parameters using TupleType (decodeReturnValues uses outputs, which is empty for void functions)
      Log.d(_tag, '[VOTE DEBUG] inputBytes length: ${transaction.input.length}');
      final inputTuple = TupleType(startVoteFunction.parameters.map((p) => p.type).toList());
      Log.d(_tag, '[VOTE DEBUG] inputTuple param count: ${startVoteFunction.parameters.length}, types: ${startVoteFunction.parameters.map((p) => "${p.name}:${p.type.name}").toList()}');
      final decoded = inputTuple.decode(transaction.input.buffer, 4); // skip 4-byte selector
      final decodedParams = decoded.data;
      Log.d(_tag, '[VOTE DEBUG] decodedParams count: ${decodedParams.length}, types: ${decodedParams.map((p) => p.runtimeType).toList()}');

      // Extract the VoteActionParams struct (third parameter)
      if (decodedParams.length > 2) {
        final params = decodedParams[2] as List<dynamic>;
        Log.d(_tag, '[VOTE DEBUG] VoteActionParams length: ${params.length}, values: ${params.map((p) => "${p.runtimeType}: ${p.toString().length > 60 ? p.toString().substring(0, 60) : p}").toList()}');

        if (params.length >= 7) {
          final result = {
            'targetAddress': params[0] as EthereumAddress,
            'valueParam': params[1] as BigInt,
            'keyParam': params[2] as String,
            'valueStringParam': params[3] as String,
            'recordTypeValueParam': params[4] as BigInt,
            'customTypeParam': params[5] as String,
            'dataParam': params[6] as List<int>,
            'operationParam': params.length > 7 ? params[7] as BigInt : BigInt.zero,
          };
          Log.d(_tag, '[VOTE DEBUG] Returning params: keyParam="${result['keyParam']}", valueStringParam="${(result['valueStringParam'] as String).length > 40 ? (result['valueStringParam'] as String).substring(0, 40) : result['valueStringParam']}"');
          return result;
        } else {
          Log.w(_tag, '[VOTE DEBUG] params.length < 7: ${params.length}');
        }
      } else {
        Log.w(_tag, '[VOTE DEBUG] decodedParams.length <= 2: ${decodedParams.length}');
      }

      return {};
    } catch (e, st) {
      Log.e(_tag, '[VOTE DEBUG] Error extracting Safe transaction parameters: $e\n$st');
      return {};
    }
  }

  /// Convert contract action type index to enum
  static VoteActionType _actionTypeFromIndex(int index) {
    // Use .values for a safer conversion that won't crash on an unknown index
    if (index >= 0 && index < VoteActionType.values.length) {
      return VoteActionType.values[index];
    }
    return VoteActionType.setRecord; // Fallback for unknown action type
  }

  // ============================================================
  // Start Vote Methods for Management Actions
  // ============================================================

  /// Start a vote to register an additional wallet in the org's directory.
  ///
  /// Routes to `WalletDirectoryManager.addWalletForOrg`. Payload mapping
  /// (matches `OrgManager.sol` REGISTER_ADDITIONAL_WALLET dispatch):
  /// - `customTypeParam` ← protocol (e.g. "eip155", "solana", "cardano", "bitcoin")
  /// - `dataParam`       ← addressData (raw bytes; 20 for EVM)
  /// - `valueParam`      ← chainId (cast to uint64 on-chain)
  /// - `keyParam`        ← label
  /// - `recordTypeValueParam` ← walletType (0 NONE, 1 EOA, 2 SAFE). An eip155
  ///   wallet must be a 20-byte address typed EOA or SAFE, or the vote reverts
  ///   at propose (same rules as the session path).
  static Future<bool> startVoteRegisterWallet(
    String orgAddress, {
    required String protocol,
    required Uint8List addressData,
    required int chainId,
    required String label,
    int walletType = 1,
  }) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication required');
      return false;
    }

    try {
      Log.d(_tag, 'Starting vote to register wallet "$label" ($protocol/$chainId) for org $orgAddress');

      final txHash = await Future.any([
        sendStartVote(
          (
            orgAddress: EthereumAddress.fromHex(orgAddress),
            tag: Uint8List(32), // no topic: only the default delegations count
            actionType: VoteActionType.registerAdditionalWallet.chainIndex,
            params: [
              EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'), // targetAddress (unused)
              BigInt.from(chainId),                  // valueParam = chainId
              label,                                 // keyParam = label
              '',                                    // valueStringParam (unused)
              BigInt.from(walletType),               // recordTypeValueParam = walletType
              protocol,                              // customTypeParam = protocol
              addressData,                           // dataParam = addressData
              BigInt.zero,                           // operationParam
            ],
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException('Starting vote to register wallet timed out')),
      ]);

      Log.i(_tag, 'registerWallet vote tx sent: $txHash — polling for receipt...');
      return await TxUtils.waitForReceipt(txHash, label: 'startVoteRegisterWallet($label)');
    } catch (e) {
      Log.e(_tag, 'Error starting vote to register wallet: $e');
      return false;
    }
  }

  /// Start a vote to remove a wallet from the org's directory.
  ///
  /// Routes to `WalletDirectoryManager.removeWalletForOrg`. The contract
  /// rebuilds `walletKey = keccak256(abi.encodePacked(protocol, addressData))`
  /// internally, so callers just pass the (protocol, addressData, chainId)
  /// triple. Payload mapping matches `OrgManager.sol` REMOVE_WALLET dispatch:
  /// - `customTypeParam` ← protocol
  /// - `dataParam`       ← addressData
  /// - `valueParam`      ← chainId
  static Future<bool> startVoteRemoveWallet(
    String orgAddress, {
    required String protocol,
    required Uint8List addressData,
    required int chainId,
  }) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication required');
      return false;
    }

    try {
      Log.d(_tag, 'Starting vote to remove wallet ($protocol/$chainId) from org $orgAddress');

      final txHash = await Future.any([
        sendStartVote(
          (
            orgAddress: EthereumAddress.fromHex(orgAddress),
            tag: Uint8List(32), // no topic: only the default delegations count
            actionType: VoteActionType.removeWallet.chainIndex,
            params: [
              EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'), // targetAddress (unused)
              BigInt.from(chainId),                  // valueParam = chainId
              '',                                    // keyParam (unused for remove)
              '',                                    // valueStringParam (unused)
              BigInt.zero,                           // recordTypeValueParam
              protocol,                              // customTypeParam = protocol
              addressData,                           // dataParam = addressData
              BigInt.zero,                           // operationParam
            ],
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException('Starting vote to remove wallet timed out')),
      ]);

      Log.i(_tag, 'removeWallet vote tx sent: $txHash — polling for receipt...');
      return await TxUtils.waitForReceipt(txHash, label: 'startVoteRemoveWallet');
    } catch (e) {
      Log.e(_tag, 'Error starting vote to remove wallet: $e');
      return false;
    }
  }

  /// Start a vote to add a Safe module
  static Future<bool> startVoteAddSafeModule(
    String orgAddress,
    String moduleAddress,
  ) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication required');
      return false;
    }

    try {
      Log.d(_tag, 'Starting vote to add Safe module $moduleAddress for org $orgAddress');

      final txHash = await Future.any([
        sendStartVote(
          (
            orgAddress: EthereumAddress.fromHex(orgAddress),
            tag: Uint8List(32), // no topic: only the default delegations count
            actionType: VoteActionType.addSafeModule.chainIndex,
            params: [
              EthereumAddress.fromHex(moduleAddress), // targetAddress
              BigInt.zero,                            // valueParam
              '',                                     // keyParam
              '',                                     // valueStringParam
              BigInt.zero,                            // recordTypeValueParam
              '',                                     // customTypeParam
              Uint8List(0),                           // dataParam
              BigInt.zero,                            // operationParam
            ],
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException('Starting vote to add Safe module timed out')),
      ]);

      Log.i(_tag, 'addSafeModule vote tx sent: $txHash — polling for receipt...');
      return await TxUtils.waitForReceipt(txHash, label: 'startVoteAddSafeModule');
    } catch (e) {
      Log.e(_tag, 'Error starting vote to add Safe module: $e');
      return false;
    }
  }

  /// Start a vote to remove a Safe module
  static Future<bool> startVoteRemoveSafeModule(
    String orgAddress,
    String moduleAddress,
  ) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication required');
      return false;
    }

    try {
      Log.d(_tag, 'Starting vote to remove Safe module $moduleAddress from org $orgAddress');

      final txHash = await Future.any([
        sendStartVote(
          (
            orgAddress: EthereumAddress.fromHex(orgAddress),
            tag: Uint8List(32), // no topic: only the default delegations count
            actionType: VoteActionType.removeSafeModule.chainIndex,
            params: [
              EthereumAddress.fromHex(moduleAddress), // targetAddress
              BigInt.zero,                            // valueParam
              '',                                     // keyParam
              '',                                     // valueStringParam
              BigInt.zero,                            // recordTypeValueParam
              '',                                     // customTypeParam
              Uint8List(0),                           // dataParam
              BigInt.zero,                            // operationParam
            ],
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException('Starting vote to remove Safe module timed out')),
      ]);

      Log.i(_tag, 'removeSafeModule vote tx sent: $txHash — polling for receipt...');
      return await TxUtils.waitForReceipt(txHash, label: 'startVoteRemoveSafeModule');
    } catch (e) {
      Log.e(_tag, 'Error starting vote to remove Safe module: $e');
      return false;
    }
  }

  // No vote wrappers for ADD_SAFE_OWNER / REMOVE_SAFE_OWNER: the guard refuses any
  // owner change on an org Safe, so those votes can only end Failed.

  /// Start a vote to change the org's voting threshold
  /// This modifies OrgStorage.threshold (the voting quorum, e.g., "2 of 3 members")
  static Future<bool> startVoteSetThreshold(
    String orgAddress,
    int newThreshold,
  ) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication required');
      return false;
    }

    try {
      Log.d(_tag, 'Starting vote to set org threshold to $newThreshold for org $orgAddress');

      final txHash = await Future.any([
        sendStartVote(
          (
            orgAddress: EthereumAddress.fromHex(orgAddress),
            tag: Uint8List(32), // no topic: only the default delegations count
            actionType: VoteActionType.setThreshold.chainIndex,
            params: [
              EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'), // targetAddress (unused)
              BigInt.from(newThreshold),              // valueParam
              '',                                     // keyParam
              '',                                     // valueStringParam
              BigInt.zero,                            // recordTypeValueParam
              '',                                     // customTypeParam
              Uint8List(0),                           // dataParam
              BigInt.zero,                            // operationParam
            ],
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException('Starting vote to set org threshold timed out')),
      ]);

      Log.i(_tag, 'setThreshold vote tx sent: $txHash — polling for receipt...');
      return await TxUtils.waitForReceipt(txHash, label: 'startVoteSetThreshold($newThreshold)');
    } catch (e) {
      Log.e(_tag, 'Error starting vote to set org threshold: $e');
      return false;
    }
  }


  /// One generic value-only org vote: [actionType] with `valueParam` (and an
  /// optional `targetAddress`). The named wrappers below are thin aliases.
  static Future<bool> _startValueVote(
    String orgAddress, {
    required VoteActionType actionType,
    required String label,
    BigInt? value,
    EthereumAddress? target,
    String? valueString,
  }) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication required');
      return false;
    }
    try {
      Log.d(_tag, 'Starting vote $label for org $orgAddress');
      final txHash = await Future.any([
        sendStartVote(
          (
            orgAddress: EthereumAddress.fromHex(orgAddress),
            tag: Uint8List(32), // no topic: only the default delegations count
            actionType: actionType.chainIndex,
            params: [
              target ?? EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'),
              value ?? BigInt.zero, // valueParam
              '', // keyParam
              valueString ?? '', // valueStringParam (CANCEL_VOTE's reason)
              BigInt.zero, // recordTypeValueParam
              '', // customTypeParam
              Uint8List(0), // dataParam
              BigInt.zero, // operationParam
            ],
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15))
            .then((_) => throw TimeoutException('Starting vote $label timed out')),
      ]);
      Log.i(_tag, '$label vote tx sent: $txHash — polling for receipt...');
      return await TxUtils.waitForReceipt(txHash, label: label);
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'Error starting vote $label: $e');
      return false;
    }
  }

  /// Child lock (SET_CHILD_LOCK, 55): the voting org locks or unlocks one of
  /// its DIRECT children. A locked org takes no new children; existing ones
  /// stay.
  static Future<bool> startVoteSetChildLock(
          String orgAddress, EthereumAddress child, bool locked) =>
      _startValueVote(orgAddress,
          actionType: VoteActionType.setChildLock,
          label: 'startVoteSetChildLock(${child.eip55With0x}, $locked)',
          value: locked ? BigInt.one : BigInt.zero,
          target: child);

  /// Whether [org] is child-locked (its direct parent stopped it taking new
  /// children). Null when the read fails.
  static Future<bool?> isChildLocked(EthereumAddress org) async {
    try {
      return await PublicOSBsp.orgHierarchyStorageContract.isChildLocked((org: org));
    } catch (e) {
      Log.w(_tag, 'isChildLocked(${org.eip55With0x}) failed: $e');
      return null;
    }
  }

  /// Start a vote to add [member] to the org (ADD_MEMBER, 2).
  static Future<bool> startVoteAddMember(String orgAddress, EthereumAddress member) =>
      _startValueVote(orgAddress, actionType: VoteActionType.addMember, label: 'startVoteAddMember(${member.eip55With0x})', target: member);

  /// Start a vote to remove [member] from the org (REMOVE_MEMBER, 3).
  static Future<bool> startVoteRemoveMember(String orgAddress, EthereumAddress member) =>
      _startValueVote(orgAddress, actionType: VoteActionType.removeMember, label: 'startVoteRemoveMember(${member.eip55With0x})', target: member);

  /// Parallel votes: how many proposals the org may have open at once
  /// (SET_MAX_OPEN_VOTES, 52; 1..5, engine default 2).
  static Future<bool> startVoteSetMaxOpenVotes(String orgAddress, int maxOpen) =>
      _startValueVote(orgAddress, actionType: VoteActionType.setMaxOpenVotes, label: 'startVoteSetMaxOpenVotes($maxOpen)', value: BigInt.from(maxOpen));

  /// Parallel votes: the org's wait switch (SET_WAIT_FULL_PERIOD, 53). On =
  /// passed proposals run only after the full period, by any member's
  /// [executeVote]; off (default) = the ballot that passes a proposal runs it.
  static Future<bool> startVoteSetWaitFullPeriod(String orgAddress, bool on) =>
      _startValueVote(orgAddress, actionType: VoteActionType.setWaitFullPeriod, label: 'startVoteSetWaitFullPeriod($on)', value: on ? BigInt.one : BigInt.zero);

  /// Parallel votes: one not-yet-passed proposal per member (SET_PROPOSER_CAP,
  /// 56). valueParam 1 = on (the default), 0 = off.
  static Future<bool> startVoteSetProposerCap(String orgAddress, bool on) =>
      _startValueVote(orgAddress, actionType: VoteActionType.setProposerCap, label: 'startVoteSetProposerCap($on)', value: on ? BigInt.one : BigInt.zero);

  /// Start a vote to set this org's participation floor (SET_QUORUM_BPS, 50).
  /// [bps] is basis points of the org's snapshot weight that For+Abstain must
  /// clear (0 = pure majority of whoever votes; must be <= 10000). Applies to
  /// FUTURE proposals only — any in-flight vote keeps its frozen floor.
  static Future<bool> startVoteSetQuorumBps(String orgAddress, int bps) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication required');
      return false;
    }
    if (bps < 0 || bps > 10000) {
      Log.w(_tag, 'Invalid quorum bps $bps (must be 0..10000)');
      return false;
    }

    try {
      Log.d(_tag, 'Starting vote to set org quorum to $bps bps for org $orgAddress');

      final txHash = await Future.any([
        sendStartVote(
          (
            orgAddress: EthereumAddress.fromHex(orgAddress),
            tag: Uint8List(32), // no topic: only the default delegations count
            actionType: VoteActionType.setQuorumBps.chainIndex,
            params: [
              EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'), // targetAddress (unused)
              BigInt.from(bps),                       // valueParam = participation floor in bps
              '',                                     // keyParam
              '',                                     // valueStringParam
              BigInt.zero,                            // recordTypeValueParam
              '',                                     // customTypeParam
              Uint8List(0),                           // dataParam
              BigInt.zero,                            // operationParam
            ],
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException('Starting vote to set org quorum timed out')),
      ]);

      Log.i(_tag, 'setQuorumBps vote tx sent: $txHash — polling for receipt...');
      return await TxUtils.waitForReceipt(txHash, label: 'startVoteSetQuorumBps($bps)');
    } catch (e) {
      Log.e(_tag, 'Error starting vote to set org quorum: $e');
      return false;
    }
  }

  /// Start a vote to set this org's vote duration (SET_VOTE_DURATION, 51).
  /// [seconds] must be within the engine bounds [1h, 30d]; the 1h MIN is
  /// load-bearing (an instant-expiry duration would self-brick every future
  /// vote). Applies to FUTURE proposals only.
  static Future<bool> startVoteSetVoteDuration(String orgAddress, int seconds) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication required');
      return false;
    }
    const minSeconds = 3600; // 1 hour
    const maxSeconds = 2592000; // 30 days
    if (seconds < minSeconds || seconds > maxSeconds) {
      Log.w(_tag, 'Invalid vote duration $seconds (must be ${minSeconds}s..${maxSeconds}s)');
      return false;
    }

    try {
      Log.d(_tag, 'Starting vote to set org vote duration to ${seconds}s for org $orgAddress');

      final txHash = await Future.any([
        sendStartVote(
          (
            orgAddress: EthereumAddress.fromHex(orgAddress),
            tag: Uint8List(32), // no topic: only the default delegations count
            actionType: VoteActionType.setVoteDuration.chainIndex,
            params: [
              EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'), // targetAddress (unused)
              BigInt.from(seconds),                   // valueParam = duration in seconds
              '',                                     // keyParam
              '',                                     // valueStringParam
              BigInt.zero,                            // recordTypeValueParam
              '',                                     // customTypeParam
              Uint8List(0),                           // dataParam
              BigInt.zero,                            // operationParam
            ],
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException('Starting vote to set org vote duration timed out')),
      ]);

      Log.i(_tag, 'setVoteDuration vote tx sent: $txHash — polling for receipt...');
      return await TxUtils.waitForReceipt(txHash, label: 'startVoteSetVoteDuration($seconds)');
    } catch (e) {
      Log.e(_tag, 'Error starting vote to set org vote duration: $e');
      return false;
    }
  }

  // ---- GroupSplitter -------------------------
  // A standalone contract, not in the ModuleRegistry, so its address is pinned
  // here. An org drives it with two EXECUTE_SAFE_TX (5) votes: once
  // `OX.approve(splitter, max)` ("activate"), then `split(org, OX, amount)`
  // per split (the guard refuses DelegateCall, so they can't share one vote).

  /// The address follows from the deployer session and its nonce;
  /// `deploy-group-splitter.ts EXPECT_ADDR` refuses anywhere else. Re-derive
  /// it on a chain deployed with other keys.
  static const String groupSplitterAddress = '0xfAE2687e881B2135917dDd682A2c82372D47e6A0';
  static const String _selApprove = '095ea7b3'; // approve(address,uint256)
  static const String _selSplit = '3313be4e'; // split(address,address,uint256)
  static final BigInt _maxUint256 = (BigInt.one << 256) - BigInt.one;

  static String _word(String hexNo0x) => hexNo0x.toLowerCase().padLeft(64, '0');

  /// True once [orgSafe] has approved the splitter for OX (the "activate" vote
  /// ran). Null when the read fails.
  static Future<bool?> isSplitterActivated(EthereumAddress orgSafe) async {
    try {
      final a = await PublicOSBsp.publicOSTokenContract.allowance(
          (owner: orgSafe, spender: EthereumAddress.fromHex(groupSplitterAddress)));
      return a > BigInt.zero;
    } catch (e) {
      Log.w(_tag, 'isSplitterActivated failed: $e');
      return null;
    }
  }

  /// What an EXECUTE_SAFE_TX vote does with the splitter, or null when it is
  /// not a splitter vote. [to] / [data] = the vote's target and calldata.
  static ({String kind, BigInt amount})? decodeSplitterCall(String to, List<int> data) {
    if (data.length < 4) return null;
    final hex = bytesToHex(data).toLowerCase();
    final sel = hex.substring(0, 8);
    final args = hex.substring(8);
    final splitter = groupSplitterAddress.toLowerCase().substring(2);
    final token = PublicOSBsp.publicOSTokenAddress?.eip55With0x.toLowerCase();
    if (sel == _selApprove && args.length >= 128 &&
        to.toLowerCase() == token && args.substring(24, 64) == splitter) {
      return (kind: 'activate', amount: BigInt.parse(args.substring(64, 128), radix: 16));
    }
    if (sel == _selSplit && args.length >= 192 && to.toLowerCase() == '0x$splitter') {
      return (kind: 'split', amount: BigInt.parse(args.substring(128, 192), radix: 16));
    }
    return null;
  }

  /// Start the one-time "activate the splitter" vote: the org Safe approves the
  /// splitter for OX (max). Returns the vote tx hash, or null.
  static Future<String?> startVoteActivateSplitter(EthereumAddress orgAddress) {
    final data = '$_selApprove${_word(groupSplitterAddress.substring(2))}${_maxUint256.toRadixString(16).padLeft(64, '0')}';
    return _startSafeCallVote(orgAddress, PublicOSBsp.publicOSTokenAddress!, data, 'activateSplitter');
  }

  /// Start a vote to split [amountWei] OX from the org Safe equally among the
  /// current members (the splitter pays each member's MainSafe). Returns the
  /// vote tx hash, or null.
  static Future<String?> startVoteSplit(EthereumAddress orgAddress, BigInt amountWei) {
    final data = '$_selSplit${_word(orgAddress.eip55With0x.substring(2))}'
        '${_word(PublicOSBsp.publicOSTokenAddress!.eip55With0x.substring(2))}'
        '${amountWei.toRadixString(16).padLeft(64, '0')}';
    return _startSafeCallVote(
        orgAddress, EthereumAddress.fromHex(groupSplitterAddress), data, 'split($amountWei)');
  }

  static Future<String?> _startSafeCallVote(
      EthereumAddress orgAddress, EthereumAddress to, String dataHexNo0x, String label) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication required');
      return null;
    }
    try {
      final txHash = await sendStartVote(
        (
          orgAddress: orgAddress,
          tag: Uint8List(32), // no topic: only the default delegations count
          actionType: VoteActionType.executeSafeTx.chainIndex,
          params: [
            to,                              // targetAddress
            BigInt.zero,                     // valueParam (no native value)
            '',                              // keyParam
            '',                              // valueStringParam
            BigInt.zero,                     // recordTypeValueParam
            '',                              // customTypeParam
            hexToBytes(dataHexNo0x),         // dataParam
            BigInt.zero,                     // operationParam (0 = Call)
          ],
        ),
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );
      final ok = await TxUtils.waitForReceipt(txHash, label: label);
      return ok ? txHash : null;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error starting $label vote: $e');
      return null;
    }
  }

  /// How many distinct tags [accountAddress] currently delegates in this org,
  /// and the per-user cap. Each active `(org, tag)` delegation consumes one
  /// slot; `burn` (leaving the org) unwinds only the leaver's own list.
  static Future<({int used, int cap})?> getDelegationUsage(
      String orgAddress, String accountAddress) async {
    try {
      final results = await Future.wait([
        PublicOSBsp.voteWeightContract.delegatedTagsOf((
          account: EthereumAddress.fromHex(accountAddress),
          org: EthereumAddress.fromHex(orgAddress),
        )),
        PublicOSBsp.voteWeightContract.MAX_TAG_DELEGATIONS(),
      ]);
      final tags = results[0] as List<dynamic>;
      final cap = results[1] as BigInt;
      return (used: tags.length, cap: cap.toInt());
    } catch (e) {
      Log.e(_tag, 'Error reading delegation usage: $e');
      return null;
    }
  }

  /// Leave an org voluntarily (unilateral, no vote required).
  /// Auto-adjusts threshold if needed. Cannot leave as the last member.
  static Future<bool> leaveOrg(String orgAddress) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication required');
      return false;
    }

    try {
      Log.d(_tag, 'Leaving org $orgAddress');

      await PublicOSBsp.orgManagerContract.leaveOrg(
        (orgAddress: EthereumAddress.fromHex(orgAddress),),
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );

      Log.i(_tag, 'Successfully left org $orgAddress');
      return true;
    } catch (e) {
      Log.e(_tag, 'Error leaving org: $e');
      return false;
    }
  }

  // ==========================================================================
  // WHO CAN ADD ME TO GROUPS (OrgAddPermitsManager)
  // ==========================================================================
  // Every account has a switch, "anyone can add me", ON by default. With it
  // OFF, only the individuals on the account's list may add it to an org: as
  // the proposer of an ADD_MEMBER vote, or as the creator naming it in
  // createOrg. Each permit is [addPermitQuota] adds; every add that lands burns
  // one, and at zero the person drops off the list. Orgs are never on a list.
  // A refused add reverts: at propose "OrgManager: Proposer may not add this
  // account", in createOrg "OrgAddPermitsManager: adder is not permitted by the
  // account". Read [canAddToOrg] first so the UI can say it in words.

  /// The adds a fresh permit carries (`OrgAddPermitsManager.DEFAULT_QUOTA`).
  static const int addPermitQuota = 5;

  /// True when anyone may add [account] to an org (the switch is ON).
  static Future<bool> anyoneCanAddMe(EthereumAddress account) async {
    try {
      return await PublicOSBsp.orgAddPermitsManagerContract.anyoneCanAdd((account: account));
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'anyoneCanAdd(${account.eip55With0x}) failed: $e');
      rethrow;
    }
  }

  /// The individuals [account] has permitted to add it (each with adds left > 0).
  static Future<List<EthereumAddress>> getPermittedAdders(EthereumAddress account) async {
    try {
      return await PublicOSBsp.orgAddPermitsManagerContract.permittedAdders((target: account));
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'permittedAdders(${account.eip55With0x}) failed: $e');
      return [];
    }
  }

  /// Adds [adder] has left on [account] (0 = not on the list).
  static Future<int> getAddPermitQuota(EthereumAddress account, EthereumAddress adder) async {
    final q = await PublicOSBsp.orgAddPermitsManagerContract.quotaOf((target: account, adder: adder));
    return q.toInt();
  }

  /// True when [adder] may add [account] to an org right now (themselves,
  /// switch ON, or adds left). Check before proposing ADD_MEMBER or listing
  /// someone in [createOrg].
  static Future<bool> canAddToOrg(EthereumAddress account, EthereumAddress adder) =>
      PublicOSBsp.orgAddPermitsManagerContract.canAdd((target: account, adder: adder));

  /// Turns the signed-in account's "anyone can add me to groups" switch on or off.
  static Future<bool> setAnyoneCanAddMe(bool on) => _addPermitWrite(
        'setAnyoneCanAddMe($on)',
        () => PublicOSBsp.orgAddPermitsManagerContract.setAnyoneCanAddMe(
          (on: on),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
      );

  /// Lets [adder] (an individual) add the signed-in account to groups, with a
  /// full quota. Refills them if already on the list.
  static Future<bool> permitAdder(EthereumAddress adder) => _addPermitWrite(
        'permit(${adder.eip55With0x})',
        () => PublicOSBsp.orgAddPermitsManagerContract.permit(
          (adder: adder),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
      );

  /// Takes [adder] off the signed-in account's list.
  static Future<bool> revokeAdder(EthereumAddress adder) => _addPermitWrite(
        'revoke(${adder.eip55With0x})',
        () => PublicOSBsp.orgAddPermitsManagerContract.revoke(
          (adder: adder),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
      );

  static Future<bool> _addPermitWrite(String label, Future<String> Function() send) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication required');
      return false;
    }
    try {
      final txHash = await send();
      return await TxUtils.waitForReceipt(txHash, label: label);
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, '$label failed: $e');
      return false;
    }
  }

  // Note: startVoteChangeSafeThreshold was removed because CHANGE_SAFE_THRESHOLD
  // is architecturally meaningless - the Safe is always owned by 1 owner (the
  // org's AccountBlueprint) using module execution. The org's voting
  // threshold is stored in OrgStorage and managed via SET_THRESHOLD.
  // ==========================================================================
  // ORG QUERIES + CREATION
  // ==========================================================================
  ///*********************************************
  /// ORG MANAGEMENT METHODS
  ///*********************************************

  /// Get orgs that the specified account is a member of
  static Future<List<EthereumAddress>> getOrgsForAccount(EthereumAddress accountAddress) async {
    try {
      // Check if OrgStorage contract is using a placeholder address
      final orgs = await PublicOSBsp.orgStorageContract.getOrgsForAccount((memberAccountAddress: accountAddress));
      return orgs;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting orgs for account ${accountAddress.eip55With0x}: $e');
      return [];
    }
  }

  /// Check if an address is an org account
  static Future<bool> isOrgAccount(EthereumAddress accountAddress) async {
    try {
      final isOrg = await PublicOSBsp.accountManagerContract.isOrgAccount((accountAddress: accountAddress));
      return isOrg;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error checking if ${accountAddress.eip55With0x} is an org account: $e');
      return false;
    }
  }

  /// Create a new org and return its on-chain account address.
  ///
  /// The caller's account is automatically set as the org creator. If
  /// [isPublic] is true, only citizens can be members (enforced on-chain).
  ///
  /// Flow mirrors the records write-through pattern (`createAccount` /
  /// `setRecord`): send tx → wait for receipt → read the result from chain.
  /// A web3dart `write` only yields the tx hash, never the Solidity
  /// `returns (address)` value — so the new org's address is recovered by
  /// decoding the `OrgCreated` event the AccountManager emits in that tx.
  ///
  /// Returns null on revert, receipt timeout, a missing event, or any
  /// error — inspect [PublicOS.lastError] for the reason.
  static Future<EthereumAddress?> createOrg({
    required String displayName,
    required List<EthereumAddress> initialMembers,
    required int initialThreshold,
    bool isPublic = false,
    Duration receiptTimeout = const Duration(seconds: 45),
  }) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      throw Exception('Authentication and blockchain key required');
    }

    try {
      Log.d(_tag, 'Creating ${isPublic ? "public " : ""}org "$displayName" with ${initialMembers.length} members');

      final accountManager = PublicOSBsp.accountManagerContract;
      final contract = accountManager.self;
      final createOrgFn = contract.function('createOrg');
      final callParams = <dynamic>[
        displayName,
        initialMembers,
        BigInt.from(initialThreshold),
        isPublic,
      ];

      // Simulate the call via eth_call and return the decoded revert
      // reason (or null if it would succeed). Used both as a pre-flight
      // fail-fast and to recover the reason if a mined tx reverts.
      Future<String?> simulateRevertReason() async {
        try {
          await PublicOS.web3Client.call(
            sender: PublicOS.currentBlockchainPrivateKey!.address,
            contract: contract,
            function: createOrgFn,
            params: callParams,
          );
          return null;
        } catch (e) {
          return TxUtils.decodeRevertReason(e) ?? e.toString();
        }
      }

      // Pre-flight: a revert here surfaces the real require() reason
      // ("Display name fails charset/tier", "Org creation rate-limited",
      // etc.) instead of sending a doomed tx that yields only a generic
      // "transaction reverted". The chain runs gas-free so this is pure
      // upside — we never spend on a call that can't land.
      final preflightRevert = await simulateRevertReason();
      if (preflightRevert != null) {
        PublicOS.lastError = preflightRevert;
        Log.e(_tag, 'createOrg pre-flight revert: $preflightRevert');
        return null;
      }

      // Call the contract to create the org.
      // Creator is automatically derived from msg.sender by the contract.
      final txHash = await Future.any([
        accountManager.createOrg((
        displayName: displayName,
        initialMembers: initialMembers,
        initialThreshold: BigInt.from(initialThreshold),
        isPublic: isPublic,
        ), credentials: PublicOS.currentBlockchainPrivateKey!),
        Future.delayed(const Duration(seconds: 20)).then((_) => throw TimeoutException('Request timed out')),
      ]);

      Log.i(_tag, 'createOrg tx sent: $txHash — waiting for receipt...');

      // Pull the receipt via the canonical adaptive poll, then decode the
      // OrgCreated event log to recover the new org's address.
      final receipt = await TxUtils.waitForReceiptObject(
        txHash,
        label: 'createOrg',
        timeout: receiptTimeout,
      );

      if (receipt == null) {
        PublicOS.lastError =
            'createOrg: receipt timeout after ${receiptTimeout.inSeconds}s';
        return null;
      }

      if (!(receipt.status ?? false)) {
        // Mined but reverted — state moved between the pre-flight and the
        // send. Re-simulate to recover the reason.
        PublicOS.lastError =
            await simulateRevertReason() ?? 'createOrg: transaction reverted';
        Log.e(_tag, 'createOrg: tx $txHash reverted — ${PublicOS.lastError}');
        return null;
      }

      final event = contract.event('OrgCreated');
      final sigHex = bytesToHex(event.signature, include0x: true).toLowerCase();
      for (final log in receipt.logs) {
        final topics = log.topics;
        if (topics == null || topics.isEmpty) continue;
        final firstTopic = topics.first;
        if (firstTopic == null) continue;
        if (firstTopic.toLowerCase() != sigHex) continue;
        if (log.address != contract.address) continue;
        final decoded =
            event.decodeResults(topics.cast<String>(), log.data ?? '0x');
        final orgAddress = decoded[0] as EthereumAddress;
        Log.i(_tag, 'Org created: ${orgAddress.eip55With0x} (tx $txHash)');
        return orgAddress;
      }
      PublicOS.lastError =
          'createOrg: tx mined but no OrgCreated event found';
      Log.w(_tag, PublicOS.lastError!);
      return null;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error creating org: $e');
      return null;
    }
  }

  /// Check if an org is a public org (citizens-only membership)
  static Future<bool> isPublicOrg(EthereumAddress orgAddress) async {
    try {
      return await PublicOSBsp.orgStorageContract.isPublicOrg((orgAddress: orgAddress));
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error checking if org ${orgAddress.eip55With0x} is public: $e');
      return false;
    }
  }

  /// Get org members
  static Future<List<EthereumAddress>> getOrgMembers(EthereumAddress orgAddress) async {
    try {
      final members = await PublicOSBsp.orgStorageContract.getMembers((orgAddress: orgAddress));
      return members;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting members for org ${orgAddress.eip55With0x}: $e');
      return [];
    }
  }

  /// Get a paginated slice of org members.
  /// Used for large orgs where `getOrgMembers` would return too many addresses.
  static Future<List<EthereumAddress>> getOrgMembersPaginated(
    EthereumAddress orgAddress, {
    int offset = 0,
    int limit = 50,
  }) async {
    try {
      return await PublicOSBsp.orgStorageContract.getMembers$3((
        orgAddress: orgAddress,
        offset: BigInt.from(offset),
        limit: BigInt.from(limit),
      ));
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting paginated members for org ${orgAddress.eip55With0x}: $e');
      return [];
    }
  }

  /// Get org member count
  static Future<int> getOrgMemberCount(EthereumAddress orgAddress) async {
    try {
      final count = await PublicOSBsp.orgStorageContract.getMemberCount((orgAddress: orgAddress));
      // Check if the value is within int range to prevent RangeError
      if (count.bitLength > 63) {
        Log.w(_tag, 'Member count value too large for int conversion: $count');
        return 0;
      }
      return count.toInt();
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting member count for org ${orgAddress.eip55With0x}: $e');
      return 0;
    }
  }

  /// Check if an account is a member of an org
  static Future<bool> isOrgMember(EthereumAddress orgAddress, EthereumAddress memberAddress) async {
    try {
      final isMember = await PublicOSBsp.orgStorageContract.isMember((
        orgAddress: orgAddress,
        memberAccountAddress: memberAddress,
      ));
      return isMember;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error checking org membership: $e');
      return false;
    }
  }

  /// Get org voting threshold
  static Future<int> getOrgThreshold(EthereumAddress orgAddress) async {
    try {
      final threshold = await PublicOSBsp.orgStorageContract.getThreshold((orgAddress: orgAddress));
      // Check if the value is within int range to prevent RangeError
      if (threshold.bitLength > 63) {
        Log.w(_tag, 'Threshold value too large for int conversion: $threshold');
        return 0;
      }
      return threshold.toInt();
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting threshold for org ${orgAddress.eip55With0x}: $e');
      return 0;
    }
  }

  /// Get org creator address
  static Future<EthereumAddress?> getOrgCreator(EthereumAddress orgAddress) async {
    try {
      final creator = await PublicOSBsp.orgStorageContract.getCreator((orgAddress: orgAddress));
      return creator;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting creator for org ${orgAddress.eip55With0x}: $e');
      return null;
    }
  }

  // ==========================================================================
  // ORG HIERARCHY READS
  // ==========================================================================
  //
  // Thin wrappers around OrgHierarchyStorage view functions. Write paths
  // (REQUEST_PARENT / CANCEL_PARENT_REQUEST / ACCEPT_CHILD / RELEASE_CHILD /
  // EXECUTE_ON_DESCENDANT[_SAFE]) are not exposed yet.
  //
  // Returns are nullable for parent / pending-request reads — the storage
  // returns the zero address for "no parent" / "no pending request", which we
  // normalize to null so callers don't have to compare against the zero
  // sentinel everywhere.

  /// Get the parent org of [org], or null if [org] has no parent.
  static Future<EthereumAddress?> getParentOrg(EthereumAddress org) async {
    try {
      final parent = await PublicOSBsp.orgHierarchyStorageContract.getParent((org: org));
      if (parent.eip55With0x == '0x0000000000000000000000000000000000000000') return null;
      return parent;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting parent for org ${org.eip55With0x}: $e');
      return null;
    }
  }

  /// Get the children of [org]. Pass [offset] + [limit] for paginated reads
  /// (large orgs); omit both for the full list.
  static Future<List<EthereumAddress>> getChildOrgs(
    EthereumAddress org, {
    int? offset,
    int? limit,
  }) async {
    try {
      if (offset == null && limit == null) {
        return await PublicOSBsp.orgHierarchyStorageContract.getChildren((org: org));
      }
      return await PublicOSBsp.orgHierarchyStorageContract.getChildren$3((
        org: org,
        offset: BigInt.from(offset ?? 0),
        limit: BigInt.from(limit ?? 0),
      ));
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting children for org ${org.eip55With0x}: $e');
      return const [];
    }
  }

  /// Get the number of direct children of [org].
  static Future<int> getChildOrgCount(EthereumAddress org) async {
    try {
      final count = await PublicOSBsp.orgHierarchyStorageContract.getChildCount((org: org));
      if (count.bitLength > 63) {
        Log.w(_tag, 'Child count too large for int conversion: $count');
        return 0;
      }
      return count.toInt();
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting child count for org ${org.eip55With0x}: $e');
      return 0;
    }
  }

  /// Get the parent the child has requested but who hasn't yet accepted, or
  /// null if there's no pending request.
  static Future<EthereumAddress?> getPendingParentRequest(EthereumAddress child) async {
    try {
      final pending = await PublicOSBsp.orgHierarchyStorageContract.getPendingRequest((child: child));
      if (pending.eip55With0x == '0x0000000000000000000000000000000000000000') return null;
      return pending;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting pending parent request for ${child.eip55With0x}: $e');
      return null;
    }
  }

  /// True if [ancestor] is an ancestor of [descendant] (walks the parent
  /// chain up to MAX_DEPTH = 50 on the storage side). The root org is an
  /// ancestor of its own tree, like any org; a chain deployed from older
  /// contract source answers true for root against anything.
  static Future<bool> isAncestorOf(
    EthereumAddress ancestor,
    EthereumAddress descendant,
  ) async {
    try {
      return await PublicOSBsp.orgHierarchyStorageContract.isAncestor((
        ancestor: ancestor,
        descendant: descendant,
      ));
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error checking ancestry ${ancestor.eip55With0x} → ${descendant.eip55With0x}: $e');
      return false;
    }
  }

  // ==========================================================================
  // ORG XMTP INBOX MANAGEMENT
  // ==========================================================================
  // Group-specific XMTP functions

  /// Registers a new inbox ID for an org with a given label.
  static Future<bool> registerInboxIdForOrg(EthereumAddress orgAddress, Uint8List inboxId, String label) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication and private key required to register org inbox ID.');
      return false;
    }
    try {
      Log.d(_tag, 'Registering Org Inbox ID for org ${orgAddress.eip55With0x}: ${bytes32ToString(inboxId)}, Label: $label');
      await Future.any([
        sendStartVote(
          (
            orgAddress: orgAddress,
            tag: Uint8List(32), // no topic: only the default delegations count
            actionType: VoteActionType.registerInboxId.chainIndex,
            params: [
              EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'), // targetAddress
              BigInt.zero, // valueParam
              label, // keyParam
              '', // valueStringParam
              BigInt.zero, // recordTypeValueParam
              '', // customTypeParam
              inboxId, // dataParam
              BigInt.zero, // operationParam
            ],
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 10)).then((_) => throw TimeoutException('Registering org inbox ID timed out')),
      ]);
      Log.i(_tag, 'Group inbox ID registered successfully.');
      return true;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error registering org inbox ID: $e');
      return false;
    }
  }

  /// Removes an inbox ID for an org.
  static Future<bool> removeInboxIdForOrg(EthereumAddress orgAddress, Uint8List inboxId) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication and private key required to remove org inbox ID.');
      return false;
    }
    try {
      Log.d(_tag, 'Removing Org Inbox ID for org ${orgAddress.eip55With0x}: ${bytes32ToString(inboxId)}');
      await Future.any([
        sendStartVote(
          (
            orgAddress: orgAddress,
            tag: Uint8List(32), // no topic: only the default delegations count
            actionType: VoteActionType.removeInboxId.chainIndex,
            params: [
              EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'), // targetAddress
              BigInt.zero, // valueParam
              '', // keyParam
              '', // valueStringParam
              BigInt.zero, // recordTypeValueParam
              '', // customTypeParam
              inboxId, // dataParam
              BigInt.zero, // operationParam
            ],
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 10)).then((_) => throw TimeoutException('Removing org inbox ID timed out')),
      ]);
      Log.i(_tag, 'Group inbox ID removed successfully.');
      return true;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error removing org inbox ID: $e');
      return false;
    }
  }

  /// Updates the label for an existing inbox ID for an org.
  static Future<bool> updateInboxIdLabelForOrg(EthereumAddress orgAddress, Uint8List inboxId, String newLabel) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication and private key required to update org inbox ID label.');
      return false;
    }
    try {
      Log.d(_tag, 'Updating Org Inbox ID Label for org ${orgAddress.eip55With0x}: ${bytes32ToString(inboxId)} to $newLabel');
      await Future.any([
        PublicOSBsp.xmtpManagerContract.updateInboxIdLabelForOrg(
          (orgAddress: orgAddress, inboxId: inboxId, newLabel: newLabel),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 10)).then((_) => throw TimeoutException('Updating org inbox ID label timed out')),
      ]);
      Log.i(_tag, 'Group inbox ID label updated successfully.');
      return true;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error updating org inbox ID label: $e');
      return false;
    }
  }

  // ==========================================================================
  // ORG RECORD VOTES
  // ==========================================================================
  // Org records must go through OrgManager.startVote() — AccountManager's
  // setRecordForOrg / deleteRecordForOrg are gated `onlyOrgManager` and reject
  // direct calls. For threshold=1 orgs, startVote auto-executes without a
  // separate castVote.

  /// Starts a vote to set a record on an org account.
  /// Waits for tx receipt so the record exists on-chain before returning.
  ///
  /// [expiration] is an absolute unix timestamp in milliseconds.
  /// [recordType] is the enum int from Record.dart (0 text, 1 identity, etc.).
  /// [value] should be the JSON-encoded record value.
  static Future<bool> startVoteSetRecord(
    EthereumAddress orgAddress, {
    required String key,
    required String value,
    required BigInt expiration,
    required BigInt recordType,
    String customType = '',
  }) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication and private key required to start vote for org record.');
      return false;
    }
    // Same limits as Record.chainSizeProblem; here the value arrives already encoded.
    final valueBytes = utf8.encode(value).length;
    if (valueBytes > Record.maxChainValueBytes || utf8.encode(customType).length > Record.maxSubtypeBytes) {
      PublicOS.lastError = valueBytes > Record.maxChainValueBytes
          ? 'This is too long to save: ${valueBytes - Record.maxChainValueBytes} bytes over the limit. Shorten the text or the link.'
          : 'This record type name is too long to save.';
      Log.w(_tag, 'startVoteSetRecord: $key refused before sending ($valueBytes bytes)');
      return false;
    }
    try {
      Log.d(_tag, 'Starting vote to set record "$key" on org ${orgAddress.eip55With0x}');
      final txHash = await Future.any([
        sendStartVote(
          (
            orgAddress: orgAddress,
            tag: Uint8List(32), // no topic: only the default delegations count
            actionType: VoteActionType.setRecord.chainIndex,
            params: [
              EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'), // targetAddress (unused)
              expiration,          // valueParam (expiration)
              key,                 // keyParam
              value,               // valueStringParam
              recordType,          // recordTypeValueParam
              customType,          // customTypeParam
              Uint8List(0),        // dataParam (unused)
              BigInt.zero,         // operationParam (unused)
            ],
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException('Starting vote to set org record timed out')),
      ]);
      Log.i(_tag, 'setRecord vote tx sent: $txHash — polling for receipt...');
      return await TxUtils.waitForReceipt(txHash, label: 'setRecord($key)');
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error starting vote to set org record: $e');
      return false;
    }
  }

  /// Starts a vote to set **multiple** records on an org account in one batch.
  ///
  /// The whole layout lands in a single governance execution (one vote for a
  /// threshold-1 org) — this is the org-side of the profile "bake". The batch
  /// rides in the `dataParam` bytes slot, ABI-encoded as
  /// `(string[] keys, string[] values, uint256[] expirations, uint8[] recordTypes, string[] customTypes)`,
  /// decoded by OrgManager's `SET_MULTIPLE_RECORDS` action (47). Each record's
  /// value is JSON-encoded exactly like [startVoteSetRecord].
  static Future<bool> startVoteSetMultipleRecords(
    EthereumAddress orgAddress,
    List<Record> records,
  ) async {
    if (!PublicOS.isAuthenticated ||
        PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag,
          'Authentication and private key required to start batch-record vote.');
      return false;
    }
    if (records.isEmpty) {
      Log.w(_tag, 'startVoteSetMultipleRecords: empty batch, nothing to do');
      return false;
    }
    if (records.length > maxRecordsPerVote) {
      PublicOS.lastError = 'One vote writes at most $maxRecordsPerVote records';
      Log.w(_tag, 'startVoteSetMultipleRecords: ${records.length} records, over the $maxRecordsPerVote a vote carries');
      return false;
    }
    for (final r in records) {
      final tooBig = r.chainSizeProblem;
      if (tooBig != null) {
        PublicOS.lastError = tooBig;
        Log.w(_tag, 'startVoteSetMultipleRecords: ${r.key} refused before sending (${r.chainValueBytes} bytes)');
        return false;
      }
    }
    try {
      Log.d(_tag,
          'Starting vote to set ${records.length} records on org ${orgAddress.eip55With0x}');

      final keys = [for (final r in records) r.key];
      final values = [for (final r in records) r.toChainJson()];
      final expirations = [
        for (final r in records)
          r.chainExpiration
      ];
      final recordTypes = [for (final r in records) BigInt.from(r.type.index)];
      final customTypes = [for (final r in records) r.subtype ?? ''];

      // ABI-encode the batch into dataParam, matching the Solidity decode:
      // abi.decode(dataParam, (string[], string[], uint256[], uint8[], string[]))
      const batchAbi = TupleType([
        DynamicLengthArray<String>(type: StringType()),
        DynamicLengthArray<String>(type: StringType()),
        DynamicLengthArray<BigInt>(type: UintType()),
        DynamicLengthArray<BigInt>(type: UintType(length: 8)),
        DynamicLengthArray<String>(type: StringType()),
      ]);
      final sink = LengthTrackingByteSink();
      batchAbi.encode([keys, values, expirations, recordTypes, customTypes], sink);
      final Uint8List dataParam = sink.asBytes();

      final txHash = await Future.any([
        sendStartVote(
          (
            orgAddress: orgAddress,
            tag: Uint8List(32), // no topic: only the default delegations count
            actionType: VoteActionType.setMultipleRecords.chainIndex,
            params: [
              EthereumAddress.fromHex(
                  '0x0000000000000000000000000000000000000000'), // targetAddress (unused)
              BigInt.zero, // valueParam (unused)
              '', // keyParam (unused)
              '', // valueStringParam (unused)
              BigInt.zero, // recordTypeValueParam (unused)
              '', // customTypeParam (unused)
              dataParam, // dataParam = the ABI-encoded batch
              BigInt.zero, // operationParam (unused)
            ],
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 20)).then((_) =>
            throw TimeoutException('Starting batch-record vote timed out')),
      ]);
      Log.i(_tag,
          'setMultipleRecords vote tx sent: $txHash — polling for receipt...');
      return await TxUtils.waitForReceipt(txHash,
          label: 'setMultipleRecords(${records.length})');
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error starting batch-record vote: $e');
      return false;
    }
  }

  /// Starts a vote to delete a record from an org account.
  /// Waits for tx receipt so the deletion lands before returning.
  static Future<bool> startVoteDeleteRecord(
    EthereumAddress orgAddress,
    String key,
  ) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication and private key required to start vote for org record deletion.');
      return false;
    }
    try {
      Log.d(_tag, 'Starting vote to delete record "$key" from org ${orgAddress.eip55With0x}');
      final txHash = await Future.any([
        sendStartVote(
          (
            orgAddress: orgAddress,
            tag: Uint8List(32), // no topic: only the default delegations count
            actionType: VoteActionType.deleteRecord.chainIndex,
            params: [
              EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'), // targetAddress (unused)
              BigInt.zero,         // valueParam (unused)
              key,                 // keyParam
              '',                  // valueStringParam (unused)
              BigInt.zero,         // recordTypeValueParam (unused)
              '',                  // customTypeParam (unused)
              Uint8List(0),        // dataParam (unused)
              BigInt.zero,         // operationParam (unused)
            ],
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException('Starting vote to delete org record timed out')),
      ]);
      Log.i(_tag, 'deleteRecord vote tx sent: $txHash — polling for receipt...');
      return await TxUtils.waitForReceipt(txHash, label: 'deleteRecord($key)');
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error starting vote to delete org record: $e');
      return false;
    }
  }

  /// The most records one SET_MULTIPLE_RECORDS or DELETE_MULTIPLE_RECORDS vote
  /// may carry (`OrgManager.MAX_VOTE_RECORD_BATCH`; a larger batch is refused
  /// when the vote is proposed). Lower than an individual's own batch of 50,
  /// because a vote stores its batch in the proposal.
  static const int maxRecordsPerVote = 20;

  static const _recordKeyListAbi = TupleType([
    DynamicLengthArray<String>(type: StringType()),
  ]);

  /// Starts ONE vote that deletes several records from an org account
  /// (DELETE_MULTIPLE_RECORDS, 60). The key list rides in `dataParam` as
  /// `abi.encode(string[] keys)`. Reserved keys and keys that are not set are
  /// skipped by the contract, so a stale list does not fail the vote.
  /// On a chain without vote 60 the propose is refused.
  static Future<bool> startVoteDeleteMultipleRecords(
    EthereumAddress orgAddress,
    List<String> keys,
  ) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication and private key required to start batch-delete vote.');
      return false;
    }
    if (keys.isEmpty) {
      Log.w(_tag, 'startVoteDeleteMultipleRecords: empty list, nothing to do');
      return false;
    }
    if (keys.length > maxRecordsPerVote) {
      PublicOS.lastError = 'One vote deletes at most $maxRecordsPerVote records';
      return false;
    }
    try {
      Log.d(_tag, 'Starting vote to delete ${keys.length} records from org ${orgAddress.eip55With0x}');
      final Uint8List dataParam = encodeDeleteRecordKeys(keys);

      final txHash = await Future.any([
        sendStartVote(
          (
            orgAddress: orgAddress,
            tag: Uint8List(32), // no topic: only the default delegations count
            actionType: VoteActionType.deleteMultipleRecords.chainIndex,
            params: [
              EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'), // targetAddress (unused)
              BigInt.zero, // valueParam (unused)
              '', // keyParam (unused)
              '', // valueStringParam (unused)
              BigInt.zero, // recordTypeValueParam (unused)
              '', // customTypeParam (unused)
              dataParam, // dataParam = abi.encode(string[] keys)
              BigInt.zero, // operationParam (unused)
            ],
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 20)).then((_) =>
            throw TimeoutException('Starting batch-delete vote timed out')),
      ]);
      Log.i(_tag, 'deleteMultipleRecords vote tx sent: $txHash — polling for receipt...');
      return await TxUtils.waitForReceipt(txHash, label: 'deleteMultipleRecords(${keys.length})');
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'Error starting batch-delete vote: $e');
      return false;
    }
  }

  /// `abi.encode(string[] keys)`: the `dataParam` of a DELETE_MULTIPLE_RECORDS vote.
  static Uint8List encodeDeleteRecordKeys(List<String> keys) {
    final sink = LengthTrackingByteSink();
    _recordKeyListAbi.encode([keys], sink);
    return sink.asBytes();
  }

  /// The record keys a DELETE_MULTIPLE_RECORDS vote names, read back from its
  /// `dataParam`. Empty when the bytes are not a key list.
  static List<String> decodeDeleteRecordKeys(List<int> dataParam) {
    if (dataParam.isEmpty) return const [];
    try {
      final res = _recordKeyListAbi.decode(Uint8List.fromList(dataParam).buffer, 0).data;
      return (res[0] as List).cast<String>();
    } catch (_) {
      return const [];
    }
  }

  // ==========================================================================
  // ORG APP REGISTRY VOTES
  // ==========================================================================
  // ============================================
  // GROUP-SPECIFIC OPERATIONS (via voting)
  // Group app operations must go through OrgManager.startVote()
  // so they require org member consensus before execution.
  // ============================================

  /// Starts a vote to register a new app for an org.
  /// Waits for tx receipt so the app exists on-chain before returning.
  static Future<bool> startVoteRegisterApp(EthereumAddress orgAddress, String appName, String displayName) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication and private key required to start vote for org app.');
      return false;
    }
    try {
      Log.d(_tag, 'Starting vote to register app "$appName" for org ${orgAddress.eip55With0x}');
      final txHash = await Future.any([
        sendStartVote(
          (
            orgAddress: orgAddress,
            tag: Uint8List(32), // no topic: only the default delegations count
            actionType: VoteActionType.registerApp.chainIndex,
            params: [
              EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'), // targetAddress (unused)
              BigInt.zero,          // valueParam (unused)
              appName,              // keyParam (slug)
              displayName,          // valueStringParam (title)
              BigInt.zero,          // recordTypeValueParam (unused)
              '',                   // customTypeParam (unused)
              Uint8List(0),         // dataParam (unused)
              BigInt.zero,          // operationParam (unused)
            ],
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException('Starting vote to register org app timed out')),
      ]);
      Log.i(_tag, 'registerApp tx sent: $txHash — polling for receipt...');
      return await TxUtils.waitForReceipt(txHash, label: 'registerApp($appName)');
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error starting vote to register org app: $e');
      return false;
    }
  }

  /// Starts a vote to remove an app from a group.
  /// Waits for tx receipt so the vote is cleared before the next call.
  static Future<bool> startVoteRemoveApp(EthereumAddress orgAddress, String appName) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication and private key required to start vote for removing org app.');
      return false;
    }
    try {
      Log.d(_tag, 'Starting vote to remove app "$appName" from org ${orgAddress.eip55With0x}');
      final txHash = await Future.any([
        sendStartVote(
          (
            orgAddress: orgAddress,
            tag: Uint8List(32), // no topic: only the default delegations count
            actionType: VoteActionType.removeApp.chainIndex,
            params: [
              EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'), // targetAddress (unused)
              BigInt.zero,          // valueParam (unused)
              appName,              // keyParam (slug)
              '',                   // valueStringParam (unused)
              BigInt.zero,          // recordTypeValueParam (unused)
              '',                   // customTypeParam (unused)
              Uint8List(0),         // dataParam (unused)
              BigInt.zero,          // operationParam (unused)
            ],
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException('Starting vote to remove org app timed out')),
      ]);
      Log.i(_tag, 'removeApp tx sent: $txHash — polling for receipt...');
      return await TxUtils.waitForReceipt(txHash, label: 'removeApp($appName)');
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error starting vote to remove org app: $e');
      return false;
    }
  }

  /// Starts a vote to update the display name for an org app.
  /// Waits for tx receipt so the vote is cleared before the next call.
  static Future<bool> startVoteUpdateAppDisplayName(
      EthereumAddress orgAddress, String appName, String newDisplayName) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication and private key required to start vote for updating org app display name.');
      return false;
    }
    try {
      Log.d(_tag, 'Starting vote to update display name for "$appName" in org ${orgAddress.eip55With0x}');
      final txHash = await Future.any([
        sendStartVote(
          (
            orgAddress: orgAddress,
            tag: Uint8List(32), // no topic: only the default delegations count
            actionType: VoteActionType.updateAppDisplayName.chainIndex,
            params: [
              EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'), // targetAddress (unused)
              BigInt.zero,          // valueParam (unused)
              appName,              // keyParam (slug)
              newDisplayName,       // valueStringParam (newTitle)
              BigInt.zero,          // recordTypeValueParam (unused)
              '',                   // customTypeParam (unused)
              Uint8List(0),         // dataParam (unused)
              BigInt.zero,          // operationParam (unused)
            ],
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException('Starting vote to update org app display name timed out')),
      ]);
      Log.i(_tag, 'updateAppDisplayName tx sent: $txHash — polling for receipt...');
      return await TxUtils.waitForReceipt(txHash, label: 'updateAppDisplayName($appName)');
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error starting vote to update org app display name: $e');
      return false;
    }
  }

  /// Starts a vote to set a pointer for an org app.
  /// Waits for tx receipt so the previous vote is cleared before the next call.
  static Future<bool> startVoteSetAppPointer(
      EthereumAddress orgAddress, String appName, String pointerType, String value) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication and private key required to start vote for setting org app pointer.');
      return false;
    }
    try {
      Log.d(_tag, 'Starting vote to set pointer "$pointerType" for app "$appName" in org ${orgAddress.eip55With0x}');
      final txHash = await Future.any([
        sendStartVote(
          (
            orgAddress: orgAddress,
            tag: Uint8List(32), // no topic: only the default delegations count
            actionType: VoteActionType.setAppPointer.chainIndex,
            params: [
              EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'), // targetAddress (unused)
              BigInt.zero,          // valueParam (unused)
              appName,              // keyParam (slug)
              value,                // valueStringParam (pointer value)
              BigInt.zero,          // recordTypeValueParam (unused)
              pointerType,          // customTypeParam (pointer type key)
              Uint8List(0),         // dataParam (unused)
              BigInt.zero,          // operationParam (unused)
            ],
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException('Starting vote to set org app pointer timed out')),
      ]);
      Log.i(_tag, 'setAppPointer tx sent: $txHash — polling for receipt...');
      return await TxUtils.waitForReceipt(txHash, label: 'setAppPointer($appName.$pointerType)');
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error starting vote to set org app pointer: $e');
      return false;
    }
  }

  /// Starts a vote to remove a pointer from an org app.
  /// Waits for tx receipt so the vote is cleared before the next call.
  static Future<bool> startVoteRemoveAppPointer(EthereumAddress orgAddress, String appName, String pointerType) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication and private key required to start vote for removing org app pointer.');
      return false;
    }
    try {
      Log.d(_tag, 'Starting vote to remove pointer "$pointerType" for app "$appName" in org ${orgAddress.eip55With0x}');
      final txHash = await Future.any([
        sendStartVote(
          (
            orgAddress: orgAddress,
            tag: Uint8List(32), // no topic: only the default delegations count
            actionType: VoteActionType.removeAppPointer.chainIndex,
            params: [
              EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'), // targetAddress (unused)
              BigInt.zero,          // valueParam (unused)
              appName,              // keyParam (slug)
              '',                   // valueStringParam (unused)
              BigInt.zero,          // recordTypeValueParam (unused)
              pointerType,          // customTypeParam (pointer type key)
              Uint8List(0),         // dataParam (unused)
              BigInt.zero,          // operationParam (unused)
            ],
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException('Starting vote to remove org app pointer timed out')),
      ]);
      Log.i(_tag, 'removeAppPointer tx sent: $txHash — polling for receipt...');
      return await TxUtils.waitForReceipt(txHash, label: 'removeAppPointer($appName.$pointerType)');
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error starting vote to remove org app pointer: $e');
      return false;
    }
  }

}


/// Enum for different vote action types from the contract.
/// Order MUST match IOrgManager.VoteActionType in Solidity.
/// Hand-maintained mirror: index order MUST match the Solidity enum
/// (`IOrgManager.VoteActionType`). Values 57–60 exist only on a chain
/// deployed with the vote-cancel and batch-delete contracts.
enum VoteActionType {
  setRecord, // 0
  deleteRecord, // 1
  addMember, // 2
  removeMember, // 3
  setThreshold, // 4
  executeSafeTx, // 5
  registerInboxId, // 6
  removeInboxId, // 7
  updateInboxIdLabel, // 8
  registerAdditionalWallet, // 9
  removeWallet, // 10
  addSafeModule, // 11
  removeSafeModule, // 12
  addSafeOwner, // 13
  removeSafeOwner, // 14
  changeSafeThreshold, // 15
  registerApp, // 16
  removeApp, // 17
  updateAppDisplayName, // 18
  setAppPointer, // 19
  removeAppPointer, // 20
  // BSP registry
  registerBSP, // 21
  removeBSP, // 22
  updateBSPTitle, // 23
  setBSPPointer, // 24
  removeBSPPointer, // 25
  // Social server registry
  registerSocialServer, // 26
  removeSocialServer, // 27
  updateSocialServerTitle, // 28
  setSocialServerPointer, // 29
  removeSocialServerPointer, // 30
  // Org hierarchy
  requestParent, // 31
  cancelParentRequest, // 32
  acceptChild, // 33
  releaseChild, // 34
  executeOnDescendantSafe, // 35 — the Safe door
  executeOnDescendant, // 36 — the action door
  // Vouch management (root DAO only)
  removeAllVouches, // 37
  // Account suspension (root DAO only)
  suspendAccount, // 38
  unsuspendAccount, // 39
  // Recovery override (root DAO only) — break-glass when social recovery itself fails.
  // Atomically clears recovery contacts, resets threshold to `minRecoveryThreshold`,
  // and re-seeds the target account's session list with a single new session.
  daoRecoveryFullReset, // 40
  // System pause switches (root DAO only) — emergency brakes for early launch.
  grantingPaused, // 41 — toggles CitizenshipManager.grantingPaused (contract enum member SET_GRANTING_PAUSED)
  accountCreationPaused, // 42 — toggles AccountMemory.accountCreationPaused
  // Org subdomains
  createOrgSubdomain, // 43 — targetAddress = parentAcc, keyParam = slug
  renameOrgSubdomain, // 44 — targetAddress = subAcc, keyParam = newSlug
  deleteOrgSubdomain, // 45 — targetAddress = subAcc
  executeOnOwnSubSafe, // 46 — targetAddress = subAcc, dataParam = abi.encode(to,value,data,op)
  // Batch record write (org profile re-rank / bake)
  setMultipleRecords, // 47 — dataParam = abi.encode(string[] keys, values, expirations, recordTypes, customTypes)
  // Org domain economy
  payDomain, // 48 — valueParam = months. Pays the org's domain from its own MainSafe.
  changeName, // 49 — keyParam = newName, valueParam = months. Renames the org / recovers from eviction.
  // Per-org voting config — the org tunes itself
  setQuorumBps, // 50 — valueParam = participation floor in bps (<= 10000; 0 = pure majority)
  setVoteDuration, // 51 — valueParam = vote duration in seconds (engine bounds [1h, 30d])
  // Parallel votes
  setMaxOpenVotes, // 52 — valueParam = how many votes the org may have open at once
  setWaitFullPeriod, // 53 — valueParam = 1: passed votes run only after the full period
  // Penalties
  payPenalties, // 54 — targetAddress = the penalised account, valueParam = amount
  // Hierarchy child lock
  setChildLock, // 55 — targetAddress = a DIRECT child org, valueParam = 1 lock / 0 unlock
  // Proposer cap
  setProposerCap, // 56 — valueParam = 1: one not-yet-passed proposal per proposer
  // Cancel · veto · withdraw
  setVetoer, // 57 — targetAddress = a current member, or 0x0 = none
  cancelVote, // 58 — valueParam = proposal id (this org's or a real descendant's), valueStringParam = reason
  setCancelCooldown, // 59 — valueParam = seconds (0..30 d) a proposer waits after withdrawing
  // Batch record delete
  deleteMultipleRecords, // 60 — dataParam = abi.encode(string[] keys), 1..20 keys; reserved and missing keys are skipped
}

/// The number `OrgManager.startVote` takes for a vote: the value's position in
/// the Solidity enum. Every vote call reads it from here, never from a typed
/// literal (a literal goes stale the moment the enum is renumbered).
extension VoteActionTypeChain on VoteActionType {
  BigInt get chainIndex => BigInt.from(index);
}

/// Who cancelled a proposal. Order MUST match IVotingEngine.CancelKind:
/// the proposer withdrew · the org's vetoer vetoed · the org itself by vote 58 ·
/// a real ancestor org by vote 58 (or, in the guardian window, an org's Safe).
enum CancelKind {
  proposer, // 0
  vetoer, // 1
  org, // 2
  ancestor, // 3
}

/// 3-way vote support. Order MUST match IVotingEngine.VoteType in
/// Solidity (the Compound-Bravo convention): 0 = Against, 1 = For, 2 = Abstain.
/// Abstain counts toward quorum but never toward the majority.
enum VoteSupport {
  against, // 0
  inFavor, // 1
  abstain, // 2
}

/// Enum for vote status
enum VoteStatus {
  active,
  executed,
  cancelled, // Status.Cancelled / VoteCancelled — see cancelKind, cancelledBy, cancelReason
  expired,
  failed, // parallel votes: VoteFailed (defeated early, or a wait-mode run that reverted / was never executed)
}

/// Data model for vote history items.
///
/// New-engine semantics (Governor — quorum voting, not
/// member thresholds): [requiredThreshold] is the WEIGHTED QUORUM FLOOR frozen
/// at startVote (snapshotTotal × quorumBps / 1e4); [forVotes]/[againstVotes]/
/// [abstainVotes] are the weighted 3-way tallies from the engine's VoteCast
/// events (parallel votes: `VoteCast(id, org, voter, support, weight)`). Pass rule: For > Against AND For + Abstain >= floor. [yesVotes]
/// (the voter count) is kept for display of participation head-count.
class VoteHistoryItem {
  /// Parallel votes: the engine's proposal id (also [id] as a string). Null
  /// only for items built by older code paths.
  final BigInt? proposalId;
  /// Frozen at start: on = the vote runs only after its full period (any member
  /// calls `execute`); off = the ballot that passes it runs it.
  final bool waitFullPeriod;
  /// The proposal's frozen tag as bytes32 hex ('0x00…00' = untagged).
  final String tag;
  final String id;
  final String orgAddress;
  final VoteActionType actionType;
  final String initiator;
  final DateTime startTime;
  final DateTime? endTime;

  /// The proposal's real expiration, from the VoteStarted event.
  final DateTime? expirationTime;
  final VoteStatus status;
  final int yesVotes;
  final int requiredThreshold;
  final int forVotes;
  final int againstVotes;
  final int abstainVotes;
  final List<String> voters;
  final Map<String, dynamic> parameters;
  /// Set only when [status] is cancelled (from `VoteCancelled`).
  final CancelKind? cancelKind;
  final String? cancelledBy;
  final String? cancelReason;

  VoteHistoryItem({
    this.proposalId,
    this.waitFullPeriod = false,
    this.tag = '0x0000000000000000000000000000000000000000000000000000000000000000',
    required this.id,
    required this.orgAddress,
    required this.actionType,
    required this.initiator,
    required this.startTime,
    this.endTime,
    this.expirationTime,
    required this.status,
    required this.yesVotes,
    required this.requiredThreshold,
    this.forVotes = 0,
    this.againstVotes = 0,
    this.abstainVotes = 0,
    required this.voters,
    required this.parameters,
    this.cancelKind,
    this.cancelledBy,
    this.cancelReason,
  });

  bool get isActive => status == VoteStatus.active;
  bool get isExecuted => status == VoteStatus.executed;
  bool get isCancelled => status == VoteStatus.cancelled;
  bool get isExpired => status == VoteStatus.expired;
  bool get isFailed => status == VoteStatus.failed;

  /// Weight that counts toward the quorum floor (Against never does).
  int get quorumParticipation => forVotes + abstainVotes;

  /// Quorum progress: participating weight vs the frozen floor. Falls back to
  /// the legacy voter-count ratio when no 3-way tallies were found.
  double get progressPercentage {
    if (requiredThreshold <= 0) return 0.0;
    final tallied = forVotes + againstVotes + abstainVotes;
    if (tallied > 0) return (quorumParticipation / requiredThreshold).clamp(0.0, 1.0);
    return (yesVotes / requiredThreshold).clamp(0.0, 1.0);
  }

  /// The majority half of the pass rule (quorum is [progressPercentage]).
  bool get hasMajority => forVotes > againstVotes;

  /// Check if a specific account has already voted
  bool hasVoted(String accountAddress) {
    final normalizedAddress = accountAddress.toLowerCase();
    return voters.any((voter) => voter.toLowerCase() == normalizedAddress);
  }

  // Added copyWith for easier state updates
  VoteHistoryItem copyWith({
    BigInt? proposalId,
    bool? waitFullPeriod,
    String? tag,
    String? id,
    String? orgAddress,
    VoteActionType? actionType,
    String? initiator,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? expirationTime,
    VoteStatus? status,
    int? yesVotes,
    int? requiredThreshold,
    int? forVotes,
    int? againstVotes,
    int? abstainVotes,
    List<String>? voters,
    Map<String, dynamic>? parameters,
    CancelKind? cancelKind,
    String? cancelledBy,
    String? cancelReason,
  }) {
    return VoteHistoryItem(
      proposalId: proposalId ?? this.proposalId,
      waitFullPeriod: waitFullPeriod ?? this.waitFullPeriod,
      tag: tag ?? this.tag,
      id: id ?? this.id,
      orgAddress: orgAddress ?? this.orgAddress,
      actionType: actionType ?? this.actionType,
      initiator: initiator ?? this.initiator,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      expirationTime: expirationTime ?? this.expirationTime,
      status: status ?? this.status,
      yesVotes: yesVotes ?? this.yesVotes,
      requiredThreshold: requiredThreshold ?? this.requiredThreshold,
      forVotes: forVotes ?? this.forVotes,
      againstVotes: againstVotes ?? this.againstVotes,
      abstainVotes: abstainVotes ?? this.abstainVotes,
      voters: voters ?? this.voters,
      parameters: parameters ?? this.parameters,
      cancelKind: cancelKind ?? this.cancelKind,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancelReason: cancelReason ?? this.cancelReason,
    );
  }

  String get actionDisplayName {
    switch (actionType) {
      case VoteActionType.addMember:
        return 'Add Member';
      case VoteActionType.removeMember:
        return 'Remove Member';
      case VoteActionType.setRecord:
        final key = parameters['keyParam'] as String?;
        if (key != null && key.isNotEmpty) {
          final label = key.split('.').last.replaceAllMapped(
            RegExp(r'_([a-z])'), (m) => ' ${m.group(1)!.toUpperCase()}',
          );
          return 'Set ${label[0].toUpperCase()}${label.substring(1)}';
        }
        return 'Update Profile';
      case VoteActionType.deleteRecord:
        final key = parameters['keyParam'] as String?;
        if (key != null && key.isNotEmpty) {
          final label = key.split('.').last.replaceAllMapped(
            RegExp(r'_([a-z])'), (m) => ' ${m.group(1)!.toUpperCase()}',
          );
          return 'Delete ${label[0].toUpperCase()}${label.substring(1)}';
        }
        return 'Delete Profile Record';
      case VoteActionType.setThreshold:
        return 'Change Voting Threshold';
      case VoteActionType.registerInboxId:
        return 'Add Chat Inbox';
      case VoteActionType.removeInboxId:
        return 'Remove Chat Inbox';
      case VoteActionType.updateInboxIdLabel:
        return 'Update Inbox Label';
      case VoteActionType.registerAdditionalWallet:
        return 'Register Wallet';
      case VoteActionType.removeWallet:
        return 'Remove Wallet';
      case VoteActionType.addSafeModule:
        return 'Add Safe Module';
      case VoteActionType.removeSafeModule:
        return 'Remove Safe Module';
      case VoteActionType.addSafeOwner:
        return 'Add Safe Owner';
      case VoteActionType.removeSafeOwner:
        return 'Remove Safe Owner';
      case VoteActionType.executeSafeTx:
        return 'Execute Safe Transaction';
      case VoteActionType.changeSafeThreshold:
        return 'Change Safe Threshold';
      case VoteActionType.registerApp:
        return 'Register App';
      case VoteActionType.removeApp:
        return 'Remove App';
      case VoteActionType.updateAppDisplayName:
        return 'Update App Name';
      case VoteActionType.setAppPointer:
        return 'Set App Pointer';
      case VoteActionType.removeAppPointer:
        return 'Remove App Pointer';
      // BSP registry
      case VoteActionType.registerBSP:
        return 'Register BSP';
      case VoteActionType.removeBSP:
        return 'Remove BSP';
      case VoteActionType.updateBSPTitle:
        return 'Update BSP Title';
      case VoteActionType.setBSPPointer:
        return 'Set BSP Pointer';
      case VoteActionType.removeBSPPointer:
        return 'Remove BSP Pointer';
      // Social server registry
      case VoteActionType.registerSocialServer:
        return 'Register Social Server';
      case VoteActionType.removeSocialServer:
        return 'Remove Social Server';
      case VoteActionType.updateSocialServerTitle:
        return 'Update Social Server Title';
      case VoteActionType.setSocialServerPointer:
        return 'Set Social Server Pointer';
      case VoteActionType.removeSocialServerPointer:
        return 'Remove Social Server Pointer';
      // Org hierarchy
      case VoteActionType.requestParent:
        return 'Request Parent Org';
      case VoteActionType.cancelParentRequest:
        return 'Cancel Parent Request';
      case VoteActionType.acceptChild:
        return 'Accept Child Org';
      case VoteActionType.releaseChild:
        return 'Release Child Org';
      case VoteActionType.executeOnDescendantSafe:
        return 'Execute on Descendant Safe';
      case VoteActionType.executeOnDescendant:
        return 'Execute on Descendant';
      // Vouch management (root DAO)
      case VoteActionType.removeAllVouches:
        return 'Remove All Vouches';
      // Account suspension (root DAO)
      case VoteActionType.suspendAccount:
        return 'Suspend Account';
      case VoteActionType.unsuspendAccount:
        return 'Unsuspend Account';
      // Recovery override (root DAO break-glass)
      case VoteActionType.daoRecoveryFullReset:
        return 'DAO Recovery Override';
      // System pause switches (root DAO)
      case VoteActionType.grantingPaused:
        return 'Pause Citizenship Granting';
      case VoteActionType.accountCreationPaused:
        return 'Pause Account Creation';
      // Org subdomains
      case VoteActionType.createOrgSubdomain:
        return 'Create Org Subdomain';
      case VoteActionType.renameOrgSubdomain:
        return 'Rename Org Subdomain';
      case VoteActionType.deleteOrgSubdomain:
        return 'Delete Org Subdomain';
      case VoteActionType.executeOnOwnSubSafe:
        return 'Execute on Sub-Account Safe';
      // Batch record write
      case VoteActionType.setMultipleRecords:
        return 'Update Profile Records';
      // Org domain economy
      case VoteActionType.payDomain:
        return 'Pay Domain';
      case VoteActionType.changeName:
        return 'Change Name';
      case VoteActionType.setQuorumBps:
        return 'Set Voting Quorum';
      case VoteActionType.setVoteDuration:
        return 'Set Vote Duration';
      case VoteActionType.setMaxOpenVotes:
        return 'Set Max Open Votes';
      case VoteActionType.setWaitFullPeriod:
        return 'Set Wait Full Period';
      case VoteActionType.payPenalties:
        return 'Pay Penalties';
      case VoteActionType.setChildLock:
        return 'Set Child Lock';
      case VoteActionType.setProposerCap:
        return 'Set Proposer Cap';
      case VoteActionType.setVetoer:
        return 'Set Vetoer';
      case VoteActionType.cancelVote:
        return 'Cancel a Vote';
      case VoteActionType.setCancelCooldown:
        return 'Set Withdraw Cooldown';
      case VoteActionType.deleteMultipleRecords:
        return 'Delete Profile Records';
    }
  }

  /// Human-readable parameters for UI display.
  /// Filters out technical fields and formats values nicely.
  Map<String, String> get displayParameters {
    Log.d('VoteHistory', '[VOTE DEBUG] displayParameters called: actionType=$actionType, parameters.keys=${parameters.keys.toList()}, parameters.isEmpty=${parameters.isEmpty}');
    if (parameters.isEmpty) {
      Log.d('VoteHistory', '[VOTE DEBUG] displayParameters returning EMPTY — parameters map is empty');
      return {};
    }

    final result = <String, String>{};

    if (actionType == VoteActionType.setRecord ||
        actionType == VoteActionType.deleteRecord) {
      final key = parameters['keyParam'] as String?;
      Log.d('VoteHistory', '[VOTE DEBUG] setRecord/deleteRecord: keyParam="$key"');
      if (key != null && key.isNotEmpty) {
        result['Record'] = key;
      }
      if (actionType == VoteActionType.setRecord) {
        final value = parameters['valueStringParam'] as String?;
        Log.d('VoteHistory', '[VOTE DEBUG] setRecord valueStringParam length: ${value?.length ?? 0}');
        if (value != null && value.isNotEmpty) {
          // Truncate long values (e.g. base64 images, JSON blobs)
          result['Value'] = value.length > 80
              ? '${value.substring(0, 80)}...'
              : value;
        }
      }
      Log.d('VoteHistory', '[VOTE DEBUG] displayParameters returning: $result');
      return result;
    }

    if (actionType == VoteActionType.deleteMultipleRecords) {
      final data = parameters['dataParam'];
      final keys = data is List<int> ? PublicOSGovernance.decodeDeleteRecordKeys(data) : const <String>[];
      if (keys.isNotEmpty) result['Records'] = keys.join(', ');
      return result;
    }

    // For other action types, show all non-empty string/num params
    for (final entry in parameters.entries) {
      final val = entry.value;
      if (val == null) continue;
      final str = val.toString();
      if (str.isEmpty) continue;
      result[entry.key] = str.length > 80 ? '${str.substring(0, 80)}...' : str;
    }
    Log.d('VoteHistory', '[VOTE DEBUG] displayParameters returning (generic): $result');
    return result;
  }

  String get statusDisplayName {
    switch (status) {
      case VoteStatus.active:
        return 'Active';
      case VoteStatus.executed:
        return 'Executed';
      case VoteStatus.cancelled:
        return 'Cancelled';
      case VoteStatus.expired:
        return 'Expired';
      case VoteStatus.failed:
        return 'Failed';
    }
  }
}

/// Data model for active vote information.
///
/// New-engine semantics (Governor): [requiredThreshold]
/// is the WEIGHTED QUORUM FLOOR frozen at startVote — NOT a member-count
/// threshold — and [yesVotes] is the weighted For tally the engine surfaces on
/// the legacy field. The real pass rule is: For > Against AND
/// For + Abstain >= floor ([hasMajority] + [progressPercentage] reaching 1.0).
class ActiveVoteInfo {
  /// Parallel votes: the engine's proposal id — what [PublicOSGovernance.castVote],
  /// [PublicOSGovernance.executeVote] and [PublicOSGovernance.closeVote] take.
  final BigInt proposalId;
  final String orgAddress;
  final VoteActionType actionType;
  final DateTime expirationTime;
  /// Voter head-count. The engine's `ProposalView` carries weights, not heads,
  /// so this is 0 on a live read; [VoteHistoryItem.yesVotes] has the count.
  final int yesVotes;
  /// The WEIGHTED QUORUM FLOOR frozen at start (For + Abstain must reach it).
  final int requiredThreshold;
  /// Weighted 3-way tallies (live `getProposal` read).
  final BigInt forVotes;
  final BigInt againstVotes;
  final BigInt abstainVotes;
  /// The proposal's frozen tag as bytes32 hex ('0x00…00' = untagged).
  final String tag;
  final Map<String, dynamic> parameters;
  /// Engine status: active (Open) · executed · failed. [isExpired] is local time.
  final VoteStatus status;
  final bool waitFullPeriod;
  /// The engine's own verdicts on the current tally / clock.
  final bool passed;
  final bool executable;
  final bool closable;
  final String initiator;
  final int snapshotBlock;
  final BigInt snapshotTotal;
  final int quorumBps;
  /// Set only when [status] is cancelled (stored on the proposal).
  final CancelKind? cancelKind;
  final String? cancelledBy;
  final String? cancelReason;

  ActiveVoteInfo({
    BigInt? proposalId,
    required this.orgAddress,
    required this.actionType,
    required this.expirationTime,
    required this.yesVotes,
    required this.requiredThreshold,
    BigInt? forVotes,
    BigInt? againstVotes,
    BigInt? abstainVotes,
    this.tag = '0x0000000000000000000000000000000000000000000000000000000000000000',
    required this.parameters,
    this.status = VoteStatus.active,
    this.waitFullPeriod = false,
    this.passed = false,
    this.executable = false,
    this.closable = false,
    this.initiator = '',
    this.snapshotBlock = 0,
    BigInt? snapshotTotal,
    this.quorumBps = 0,
    this.cancelKind,
    this.cancelledBy,
    this.cancelReason,
  })  : proposalId = proposalId ?? BigInt.zero,
        forVotes = forVotes ?? BigInt.zero,
        againstVotes = againstVotes ?? BigInt.zero,
        abstainVotes = abstainVotes ?? BigInt.zero,
        snapshotTotal = snapshotTotal ?? BigInt.zero;

  /// Decode the engine's `IVotingEngine.ProposalView` tuple
  /// (`Governor.getProposal(id)`). Returns null for status None (no such id).
  ///
  ///   [0] id  [1] org  [2] status (0 None · 1 Open · 2 Executed · 3 Failed · 4 Cancelled)
  ///   [3] waitFullPeriod  [4] snapshotBlock  [5] expirationTimestamp
  ///   [6] initiator  [7] actionType  [8] tag (bytes32)  [9] snapshotTotal
  ///   [10] quorumBps  [11] requiredQuorum  [12] forVotes  [13] againstVotes
  ///   [14] abstainVotes  [15] passed  [16] executable  [17] closable
  ///   [18] params  [19] cancelledBy  [20] cancelKind  [21] cancelReason (the last three
  ///   set only when status is 4)
  static ActiveVoteInfo? fromProposalView(
    dynamic view, {
    Map<String, dynamic> parameters = const {},
  }) {
    try {
      final v = view as List<dynamic>;
      final statusIndex = (v[2] as BigInt).toInt();
      if (statusIndex == 0) return null;
      final status = switch (statusIndex) {
        1 => VoteStatus.active,
        2 => VoteStatus.executed,
        3 => VoteStatus.failed,
        4 => VoteStatus.cancelled,
        _ => VoteStatus.failed,
      };
      final cancelled = status == VoteStatus.cancelled && v.length > 21;
      return ActiveVoteInfo(
        proposalId: v[0] as BigInt,
        orgAddress: (v[1] as EthereumAddress).eip55With0x,
        status: status,
        waitFullPeriod: v[3] as bool,
        snapshotBlock: (v[4] as BigInt).toInt(),
        expirationTime: DateTime.fromMillisecondsSinceEpoch((v[5] as BigInt).toInt() * 1000),
        initiator: (v[6] as EthereumAddress).eip55With0x,
        actionType: PublicOSGovernance._actionTypeFromIndex((v[7] as BigInt).toInt()),
        tag: bytesToHex(v[8] as Uint8List, include0x: true),
        snapshotTotal: v[9] as BigInt,
        quorumBps: (v[10] as BigInt).toInt(),
        yesVotes: 0,
        requiredThreshold: (v[11] as BigInt).toInt(),
        forVotes: v[12] as BigInt,
        againstVotes: v[13] as BigInt,
        abstainVotes: v[14] as BigInt,
        passed: v[15] as bool,
        executable: v[16] as bool,
        closable: v[17] as bool,
        parameters: parameters,
        cancelledBy: cancelled ? (v[19] as EthereumAddress).eip55With0x : null,
        cancelKind: cancelled ? CancelKind.values[(v[20] as BigInt).toInt()] : null,
        cancelReason: cancelled ? v[21] as String : null,
      );
    } catch (e) {
      Log.e('Orgs', 'Error parsing ProposalView: $e');
      return null;
    }
  }

  bool get isOpen => status == VoteStatus.active;
  bool get isCancelled => status == VoteStatus.cancelled;
  bool get isExpired => DateTime.now().isAfter(expirationTime);
  Duration get timeRemaining => isExpired ? Duration.zero : expirationTime.difference(DateTime.now());

  /// Weight that counts toward the quorum floor (Against never does).
  BigInt get quorumParticipation => forVotes + abstainVotes;

  /// Quorum progress: participating weight vs the frozen floor.
  double get progressPercentage {
    if (requiredThreshold <= 0) return 0.0;
    return (quorumParticipation.toDouble() / requiredThreshold).clamp(0.0, 1.0);
  }

  /// The majority half of the pass rule (quorum is [progressPercentage]).
  bool get hasMajority => forVotes > againstVotes;

  /// True when the proposal would pass if it closed right now — the engine's
  /// own verdict ([passed]), with the local rule as the fallback.
  bool get isPassing => passed || (hasMajority && quorumParticipation >= BigInt.from(requiredThreshold));
}
