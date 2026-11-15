// S20 — Orgs and votes on the parallel-votes engine (Governor).
//
// Local hardhat deploy; serial. Members are the citizens S17 made.
//
//   A. every org shape: private 1-of-1, public 1-of-1, private 3 members
//      threshold 2, public 3 members threshold 3 (jmsl creates; the devnet
//      steps over the creation cooldown)
//   B. on the private 3-member org, with quorum raised to 100 % so nothing
//      passes at start:
//      B1. two proposals open at once; a third is refused (max open = 2)
//      B2. For + Against with quorum out of reach → early defeat (Failed)
//      B3. For + Abstain → passes → auto-run → Executed
//      B4. wait-full-period on → a passed proposal waits; any member runs it
//          after the period (executeVote)
//      B5. an expired, never-passed proposal is closed (closeVote)
//      B6. delegation: a member's weight rides on another's ballot
//      B7. max open raised to 3 → three open at once

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;

import '../fixtures/test_fixtures.dart';

void main() {
  group('S20 — orgs + votes', () {
    setUpAll(() async {
      await TestFixtures.bootstrap();
    });

    tearDownAll(() async {
      await TestFixtures.teardown();
    });

    Future<EthereumAddress> createOrg(EthereumAddress jmsl, String name, List<EthereumAddress> members, int threshold, bool public) async {
      await TestFixtures.actAsJmsl();
      await TestFixtures.skipOrgCreationCooldown(jmsl);
      final org = await PublicOSGovernance.createOrg(
        displayName: '${name}_${DateTime.now().millisecondsSinceEpoch % 100000}',
        initialMembers: members,
        initialThreshold: threshold,
        isPublic: public,
      );
      expect(org, isNotNull, reason: 'createOrg($name) failed: ${PublicOS.lastError}');
      final storage = PublicOSBsp.orgStorageContract;
      expect(await storage.isPublicOrg((orgAddress: org!)), public);
      expect((await storage.getThreshold((orgAddress: org))).toInt(), threshold);
      expect((await storage.getMemberCount((orgAddress: org))).toInt(), members.length);
      return org;
    }

    /// Switch the live session to an actor ('jmsl' or an S17 citizen label).
    Future<void> as(String actor) async {
      if (actor == 'jmsl') {
        await TestFixtures.actAsJmsl();
      } else {
        await TestFixtures.actAs(await TestFixtures.ensureAccount(actor), TestFixtures.actorKey(actor));
      }
    }

    /// A cheap proposal by [proposer]: set a profile record on the org.
    /// (Proposer cap: one not-yet-passed proposal per member, so proposers rotate.)
    Future<ActiveVoteInfo> propose(String org, String key, {String proposer = 'jmsl'}) async {
      await as(proposer);
      final before = (await PublicOSGovernance.getOpenVotes(org)).map((v) => v.proposalId).toSet();
      final ok = await PublicOSGovernance.startVoteSetRecord(EthereumAddress.fromHex(org),
          key: key,
          value: 'v-$key',
          expiration: BigInt.from(DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch),
          recordType: BigInt.from(RecordType.profile.index));
      expect(ok, isTrue, reason: 'startVoteSetRecord($key) failed: ${PublicOS.lastError}');
      // A ballot cannot be simulated in the start block (VW_FutureLookup).
      await TestFixtures.advanceChainTime(const Duration(seconds: 2));
      final open = await PublicOSGovernance.getOpenVotes(org);
      final mine = open.where((v) => !before.contains(v.proposalId)).toList();
      expect(mine, hasLength(1), reason: 'exactly one new open proposal after start');
      return mine.single;
    }

    Future<void> ballot(String who, BigInt id, VoteSupport s) async {
      await as(who);
      expect(await PublicOSGovernance.castVote(id, s), isTrue,
          reason: 'castVote($id, ${s.name}) by $who failed: ${PublicOS.lastError}');
    }

    test('every org shape; every vote kind', () async {
      final jmsl = await TestFixtures.setupWithJmsl();
      if (jmsl == null) return;
      final c0 = await TestFixtures.ensureAccount('s17-c0');
      final c1 = await TestFixtures.ensureAccount('s17-c1');
      final jmslKeyHex = TestFixtures.jmslSessionAddress;
      expect(jmslKeyHex, isNotNull);
      expect(await PublicOSAccounts.isCitizen(c0), isTrue, reason: 'run S17 first on this chain');

      // ── A. org shapes ────────────────────────────────────────────────────
      final orgsBefore = (await PublicOSGovernance.getOrgsForAccount(jmsl)).length;
      await createOrg(jmsl, 'priv11', [jmsl], 1, false);
      await createOrg(jmsl, 'pub11', [jmsl], 1, true);
      final org3 = await createOrg(jmsl, 'priv32', [jmsl, c0, c1], 2, false);
      await createOrg(jmsl, 'pub33', [jmsl, c0, c1], 3, true);
      expect((await PublicOSGovernance.getOrgsForAccount(jmsl)).length, orgsBefore + 4);
      final orgHex = org3.eip55With0x;

      // quorum 100 % so a proposal never passes at start (this vote itself
      // passes at start: the floor is still the default when it opens)
      await TestFixtures.actAsJmsl();
      expect(await PublicOSGovernance.startVoteSetQuorumBps(orgHex, 10000), isTrue,
          reason: 'setQuorumBps: ${PublicOS.lastError}');
      expect((await PublicOSGovernance.getOrgQuorumBps(orgHex))!.toInt(), 10000);
      final duration = (await PublicOSGovernance.getOrgVoteDuration(orgHex))!.toInt();
      print('org $orgHex: quorum 100 %, duration $duration s');

      // ── B1. two open at once; a third refused ─────────────────────────
      final p1 = await propose(orgHex, 'profile.p1');
      // Proposer cap: jmsl already has an unpassed proposal open
      await as('jmsl');
      final capped = await PublicOSGovernance.startVoteSetRecord(org3,
          key: 'profile.px', value: 'x', expiration: BigInt.one, recordType: BigInt.zero);
      expect(capped, isFalse, reason: 'one not-yet-passed proposal per member');
      final p2 = await propose(orgHex, 'profile.p2', proposer: 's17-c0');
      expect((await PublicOSGovernance.getOpenVotes(orgHex)).length, 2);
      await as('s17-c1');
      final third = await PublicOSGovernance.startVoteSetRecord(org3,
          key: 'profile.p3', value: 'x', expiration: BigInt.one, recordType: BigInt.zero);
      expect(third, isFalse, reason: 'max open is 2 by default');

      // ── B2. For + Against, quorum out of reach → early defeat ──────────
      await ballot('s17-c0', p1.proposalId, VoteSupport.inFavor);
      await ballot('s17-c1', p1.proposalId, VoteSupport.against);
      final p1Now = (await PublicOSGovernance.getVote(p1.proposalId))!;
      expect(p1Now.status, VoteStatus.failed, reason: 'For 2 + Against 1 can never reach a 3-weight quorum');
      expect(p1Now.forVotes.toInt(), 2);
      expect(p1Now.againstVotes.toInt(), 1);

      // ── B3. For + Abstain → passes → auto-run → Executed ──────────────
      await ballot('jmsl', p2.proposalId, VoteSupport.inFavor);
      await ballot('s17-c1', p2.proposalId, VoteSupport.abstain);
      final p2Now = (await PublicOSGovernance.getVote(p2.proposalId))!;
      expect(p2Now.status, VoteStatus.executed, reason: 'Abstain counts toward quorum; the deciding ballot runs it');
      expect(p2Now.abstainVotes.toInt(), 1);
      expect(await PublicOSGovernance.getOpenVotes(orgHex), isEmpty);

      // history sees both, keyed by proposal id
      final history = await PublicOSGovernance.getVotingHistory(orgHex);
      expect(history.where((h) => h.proposalId == p1.proposalId).single.status, VoteStatus.failed);
      expect(history.where((h) => h.proposalId == p2.proposalId).single.status, VoteStatus.executed);

      // ── B4. wait-full-period → execute after the period ───────────────
      await TestFixtures.actAsJmsl();
      expect(await PublicOSGovernance.startVoteSetWaitFullPeriod(orgHex, true), isTrue,
          reason: 'setWaitFullPeriod: ${PublicOS.lastError}');
      await TestFixtures.advanceChainTime(const Duration(seconds: 2));
      final wait = (await PublicOSGovernance.getOpenVotes(orgHex)).single;
      await ballot('s17-c0', wait.proposalId, VoteSupport.inFavor);
      await ballot('s17-c1', wait.proposalId, VoteSupport.inFavor);
      expect((await PublicOSGovernance.getVote(wait.proposalId))!.status, VoteStatus.executed);
      expect(await PublicOSBsp.votingMechanismContract.orgWaitFullPeriod((orgAddress: org3)), isTrue);

      await TestFixtures.actAsJmsl();
      final p4 = await propose(orgHex, 'profile.p4');
      expect(p4.waitFullPeriod, isTrue);
      await ballot('s17-c0', p4.proposalId, VoteSupport.inFavor);
      await ballot('s17-c1', p4.proposalId, VoteSupport.inFavor);
      var p4Now = (await PublicOSGovernance.getVote(p4.proposalId))!;
      expect(p4Now.passed, isTrue);
      expect(p4Now.status, VoteStatus.active, reason: 'wait mode: passed proposals do not run on the ballot');
      expect(p4Now.executable, isFalse);
      await TestFixtures.advanceChainTime(Duration(seconds: duration + 5));
      p4Now = (await PublicOSGovernance.getVote(p4.proposalId))!;
      expect(p4Now.executable, isTrue);
      await as('s17-c0');
      expect(await PublicOSGovernance.executeVote(p4.proposalId), isTrue, reason: 'execute: ${PublicOS.lastError}');
      expect((await PublicOSGovernance.getVote(p4.proposalId))!.status, VoteStatus.executed);

      // ── B5. expired, never passed → close ─────────────────────────────
      await TestFixtures.actAsJmsl();
      final p5 = await propose(orgHex, 'profile.p5');
      await TestFixtures.advanceChainTime(Duration(seconds: duration + 5));
      final p5Now = (await PublicOSGovernance.getVote(p5.proposalId))!;
      expect(p5Now.closable, isTrue);
      expect(await PublicOSGovernance.closeVote(p5.proposalId), isTrue, reason: 'close: ${PublicOS.lastError}');
      expect((await PublicOSGovernance.getVote(p5.proposalId))!.status, VoteStatus.failed);
      expect(await PublicOSGovernance.getOpenVotes(orgHex), isEmpty);

      // ── B6. delegation: c1 → c0 on the untagged lane ──────────────────
      await as('s17-c1');
      expect(await PublicOSGovernance.delegateVote(orgHex, delegateeAddress: c0.eip55With0x), isTrue,
          reason: 'delegate: ${PublicOS.lastError}');
      await TestFixtures.actAsJmsl();
      final p6 = await propose(orgHex, 'profile.p6');
      await ballot('s17-c0', p6.proposalId, VoteSupport.inFavor); // weight 2: own + c1's
      final p6Now = (await PublicOSGovernance.getVote(p6.proposalId))!;
      expect(p6Now.forVotes.toInt(), 3, reason: 'jmsl 1 + c0 carrying c1 = 3');
      expect(p6Now.passed, isTrue);
      // clear the delegation for later files
      await as('s17-c1');
      expect(await PublicOSGovernance.delegateVote(orgHex, delegateeAddress: null), isTrue);

      // ── B7. max open 3 ────────────────────────────────────────────────
      await TestFixtures.advanceChainTime(Duration(seconds: duration + 5));
      await as('s17-c0');
      expect(await PublicOSGovernance.executeVote(p6.proposalId), isTrue);
      await TestFixtures.actAsJmsl();
      expect(await PublicOSGovernance.startVoteSetMaxOpenVotes(orgHex, 3), isTrue,
          reason: 'setMaxOpenVotes: ${PublicOS.lastError}');
      await TestFixtures.advanceChainTime(const Duration(seconds: 2));
      final cap = (await PublicOSGovernance.getOpenVotes(orgHex)).single;
      await ballot('s17-c0', cap.proposalId, VoteSupport.inFavor);
      await ballot('s17-c1', cap.proposalId, VoteSupport.inFavor);
      await TestFixtures.advanceChainTime(Duration(seconds: duration + 5));
      await as('s17-c0');
      expect(await PublicOSGovernance.executeVote(cap.proposalId), isTrue);
      expect((await PublicOSBsp.votingMechanismContract.orgMaxOpen((orgAddress: org3))).toInt(), 3);
      await TestFixtures.actAsJmsl();
      await propose(orgHex, 'profile.p7');
      await propose(orgHex, 'profile.p8', proposer: 's17-c0');
      await propose(orgHex, 'profile.p9', proposer: 's17-c1');
      expect((await PublicOSGovernance.getOpenVotes(orgHex)).length, 3);
      // tidy: let them expire and close them so the org is clean for re-runs
      await TestFixtures.advanceChainTime(Duration(seconds: duration + 5));
      for (final v in await PublicOSGovernance.getOpenVotes(orgHex)) {
        expect(await PublicOSGovernance.closeVote(v.proposalId), isTrue);
      }
      expect(await PublicOSGovernance.getOpenVotes(orgHex), isEmpty);
    }, timeout: const Timeout(Duration(minutes: 15)));

    // ── C. cancel · veto · withdraw ──
    //   C1 the proposer withdraws (record on the proposal + in history)
    //   C2 a reason is required (client check, nothing sent)
    //   C3 vote 59: a withdraw cooldown, then the proposer is refused until it passes
    //   C4 vote 57: a vetoer, who vetoes another member's proposal (no cooldown)
    //   C5 vote 58: the org cancels a proposal by vote (kind org, by = the org)
    test('cancel · veto · withdraw', () async {
      final jmsl = await TestFixtures.setupWithJmsl();
      if (jmsl == null) return;
      final c0 = await TestFixtures.ensureAccount('s17-c0');
      final c1 = await TestFixtures.ensureAccount('s17-c1');
      expect(await PublicOSAccounts.isCitizen(c0), isTrue, reason: 'run S17 first on this chain');

      final org = await createOrg(jmsl, 'cancel3', [jmsl, c0, c1], 2, false);
      final orgHex = org.eip55With0x;
      await TestFixtures.actAsJmsl();
      expect(await PublicOSGovernance.startVoteSetQuorumBps(orgHex, 10000), isTrue,
          reason: 'setQuorumBps: ${PublicOS.lastError}');
      expect(await PublicOSGovernance.getOrgVetoer(orgHex), isNull, reason: 'no vetoer by default');
      expect(await PublicOSGovernance.getOrgCancelCooldown(orgHex), 0, reason: 'cooldown defaults to 0');

      /// The newest open proposal, after a one-block wait (VW_FutureLookup).
      Future<ActiveVoteInfo> newest() async {
        await TestFixtures.advanceChainTime(const Duration(seconds: 2));
        return (await PublicOSGovernance.getOpenVotes(orgHex)).first;
      }

      /// c0 and c1 vote For: at quorum 100 % that passes and runs it.
      Future<void> passByOthers(BigInt id) async {
        await ballot('s17-c0', id, VoteSupport.inFavor);
        await ballot('s17-c1', id, VoteSupport.inFavor);
        expect((await PublicOSGovernance.getVote(id))!.status, VoteStatus.executed);
      }

      // C1. withdraw
      final w = await propose(orgHex, 'profile.c1');
      await as('jmsl');
      expect(await PublicOSGovernance.withdrawVote(w.proposalId, 'changed my mind'), isTrue,
          reason: 'withdraw: ${PublicOS.lastError}');
      final wNow = (await PublicOSGovernance.getVote(w.proposalId))!;
      expect(wNow.status, VoteStatus.cancelled);
      expect(wNow.cancelKind, CancelKind.proposer);
      expect(wNow.cancelledBy!.toLowerCase(), jmsl.eip55With0x.toLowerCase());
      expect(wNow.cancelReason, 'changed my mind');
      final hist = (await PublicOSGovernance.getVotingHistory(orgHex))
          .where((h) => h.proposalId == w.proposalId).single;
      expect(hist.status, VoteStatus.cancelled);
      expect(hist.cancelKind, CancelKind.proposer);
      expect(hist.cancelReason, 'changed my mind');

      // C2. a reason is required
      final r = await propose(orgHex, 'profile.c2');
      await as('jmsl');
      expect(await PublicOSGovernance.withdrawVote(r.proposalId, ''), isFalse);
      expect(PublicOS.lastError, 'A reason is required');
      expect(await PublicOSGovernance.withdrawVote(r.proposalId, 'tidy'), isTrue);

      // C3. vote 59: one hour of cooldown; a withdraw then blocks jmsl here
      await as('jmsl');
      expect(await PublicOSGovernance.startVoteSetCancelCooldown(orgHex, 3600), isTrue,
          reason: 'setCancelCooldown: ${PublicOS.lastError}');
      await passByOthers((await newest()).proposalId);
      expect(await PublicOSGovernance.getOrgCancelCooldown(orgHex), 3600);
      final cd = await propose(orgHex, 'profile.c3');
      await as('jmsl');
      expect(await PublicOSGovernance.withdrawVote(cd.proposalId, 'cooldown test'), isTrue);
      expect(await PublicOSGovernance.getProposerCooldownUntil(orgHex, jmsl.eip55With0x), isNotNull);
      final blocked = await PublicOSGovernance.startVoteSetRecord(org,
          key: 'profile.cx', value: 'x', expiration: BigInt.one, recordType: BigInt.zero);
      expect(blocked, isFalse, reason: 'the proposer is in cooldown');
      await TestFixtures.advanceChainTime(const Duration(seconds: 3601));
      expect(await PublicOSGovernance.getProposerCooldownUntil(orgHex, jmsl.eip55With0x), isNull);

      // C4. vote 57: c0 is the vetoer and vetoes c1's proposal; c1 gets no cooldown
      await as('jmsl');
      expect(await PublicOSGovernance.startVoteSetVetoer(orgHex, c0), isTrue,
          reason: 'setVetoer: ${PublicOS.lastError}');
      await passByOthers((await newest()).proposalId);
      expect((await PublicOSGovernance.getOrgVetoer(orgHex))!.toLowerCase(), c0.eip55With0x.toLowerCase());
      final v = await propose(orgHex, 'profile.c4', proposer: 's17-c1');
      await as('s17-c1');
      expect(await PublicOSGovernance.vetoVote(v.proposalId, 'not the vetoer'), isFalse,
          reason: 'only the vetoer may veto');
      await as('s17-c0');
      expect(await PublicOSGovernance.vetoVote(v.proposalId, 'vetoed'), isTrue, reason: 'veto: ${PublicOS.lastError}');
      final vNow = (await PublicOSGovernance.getVote(v.proposalId))!;
      expect(vNow.status, VoteStatus.cancelled);
      expect(vNow.cancelKind, CancelKind.vetoer);
      expect(await PublicOSGovernance.getProposerCooldownUntil(orgHex, c1.eip55With0x), isNull);

      // C5. vote 58: c1 proposes to cancel jmsl's proposal; the others' For runs it
      final t = await propose(orgHex, 'profile.c5');
      await as('s17-c1');
      expect(await PublicOSGovernance.startVoteCancelVote(orgHex, t.proposalId, 'duplicate'), isTrue,
          reason: 'startVoteCancelVote: ${PublicOS.lastError}');
      await TestFixtures.advanceChainTime(const Duration(seconds: 2));
      final c = (await PublicOSGovernance.getOpenVotes(orgHex)).firstWhere((x) => x.actionType == VoteActionType.cancelVote);
      await ballot('jmsl', c.proposalId, VoteSupport.inFavor);
      await ballot('s17-c0', c.proposalId, VoteSupport.inFavor);
      expect((await PublicOSGovernance.getVote(c.proposalId))!.status, VoteStatus.executed);
      final tNow = (await PublicOSGovernance.getVote(t.proposalId))!;
      expect(tNow.status, VoteStatus.cancelled);
      expect(tNow.cancelKind, CancelKind.org);
      expect(tNow.cancelledBy!.toLowerCase(), orgHex.toLowerCase());
      expect(tNow.cancelReason, 'duplicate');
      expect(await PublicOSGovernance.getOpenVotes(orgHex), isEmpty);
    }, timeout: const Timeout(Duration(minutes: 15)));
  });
}
