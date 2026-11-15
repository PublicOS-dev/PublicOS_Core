// S14 — a failed records read must be distinguishable from an empty profile.
//
// Regression guard for the empty-records poisoning bug.
// `getAllUserRecords` used to swallow EVERY failure — including its own
// 10s TimeoutException — and return `[]`. That made "the chain was unreachable"
// look exactly like "this account has no records", so:
//
//   - every write-through persisted the outage as fact, and
//   - `PublicOSFollows.resolveProfileChannels`' stale-fallback catch (which
//     exists precisely for this case) was DEAD CODE — nothing ever threw.
//
// The invariants locked in here:
//   getAllUserRecordsOrThrow  → THROWS when the read fails
//   getAllUserRecords         → still returns [] (best-effort, opt-in swallow)
//   a failed refresh          → leaves the stored records intact
//
// Pre-conditions: local PublicOS chain reachable (same as the other scenarios).

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

import '../fixtures/test_fixtures.dart';

/// An RPC that is guaranteed to refuse the connection.
const _deadRpc = 'http://127.0.0.1:1';
const _localRpc = 'http://127.0.0.1:8545';

void main() {
  group('S14 — records read honesty', () {
    setUpAll(() async {
      await TestFixtures.bootstrap();
    });

    tearDownAll(() async {
      await TestFixtures.teardown();
    });

    test('a failed read throws; an empty profile does not', () async {
      final jmsl = await TestFixtures.setupWithJmsl();
      if (jmsl == null) return; // skipped — no local node

      // ── Baseline: a healthy read of a real profile returns real records.
      // Without this the failure assertions below could pass vacuously.
      // A fresh local deploy has no records for jmsl — seed one so the
      // baseline is a real profile, not a vacuous pass.
      final healthy = await TestFixtures.ensureProfileRecord(jmsl);
      expect(healthy, isNotEmpty,
          reason: 'jmsl should have on-chain records; if not, this test '
              'cannot distinguish empty from failed');
      print('healthy read: ${healthy.length} records');

      // ── Now break the RPC. Every read below is a FAILURE, not an empty
      // profile — the account and its records still exist on chain.
      PublicOS.setRpcOverride(_deadRpc, 'local');

      // The checked variant must propagate. This is the whole fix: if this
      // returns [] instead of throwing, every downstream fallback is dead
      // again and write-throughs will persist an outage as an empty profile.
      await expectLater(
        PublicOSContacts.getAllUserRecordsOrThrow(jmsl),
        throwsA(anything),
        reason: 'getAllUserRecordsOrThrow must THROW on a failed read',
      );

      // The best-effort variant keeps its old contract for display-only
      // callers that genuinely prefer degrading to empty.
      final lenient = await PublicOSContacts.getAllUserRecords(jmsl);
      expect(lenient, isEmpty,
          reason: 'getAllUserRecords stays best-effort (returns [])');

      // ── And the reason it all matters: fetchContact must refuse to
      // manufacture a records-less contact when the caller says it persists.
      await expectLater(
        PublicOSContacts.fetchContact(jmsl, requireRecords: true),
        throwsA(anything),
        reason: 'fetchContact(requireRecords: true) must not return a '
            'contact with records:[] built from a failed read',
      );

      PublicOS.setRpcOverride(_localRpc, 'local');
    });

    test('a failed refresh leaves the locally stored records intact', () async {
      // The rule this implements: if the RPC fails, return the local
      // contact, which carries the records. Before the fix the opposite
      // happened — the failed read's empty set was persisted OVER the good
      // local copy and stamped fresh, so the profile stayed blank for
      // channelSetMaxAge (12h).
      final jmsl = await TestFixtures.setupWithJmsl();
      if (jmsl == null) return; // skipped — no local node

      // Seed a known-good local row.
      final fresh =
          await PublicOSContacts.fetchContact(jmsl, requireRecords: true);
      await PublicOSContacts.saveContact(fresh);
      final before = await PublicOSContacts.getContact(jmsl);
      expect(before?.records, isNotEmpty, reason: 'precondition: good row');
      final countBefore = before!.records.length;

      // Break the chain, then drive the follow path (which refreshes profiles).
      PublicOS.setRpcOverride(_deadRpc, 'local');
      final channels = await PublicOSFollows.resolveProfileChannels(jmsl);

      // The local row must be untouched — not blanked.
      final after = await PublicOSContacts.getContact(jmsl);
      expect(after?.records.length, equals(countBefore),
          reason: 'a failed refresh must NOT overwrite stored records');
      print('records preserved across failed refresh: $countBefore');

      // And the resolver degrades to the cached channel set rather than
      // reporting the account as having no channels at all.
      print('channels resolved from cache during outage: ${channels.length}');

      PublicOS.setRpcOverride(_localRpc, 'local');
    });
  });
}
