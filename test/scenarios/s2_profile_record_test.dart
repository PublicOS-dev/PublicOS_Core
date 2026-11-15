// S2 — Profile record set/delete with write-through.
//
// Validates that:
//   1. setRecord sends a chain transaction
//   2. The transaction is awaited (TxUtils.waitForReceipt)
//   3. After confirmation, the contact is re-fetched from chain
//   4. The fresh contact is saved to the local DB
//   5. Subsequent getContact() reads see the new value
//
// Pre-conditions:
//   - Local PublicOS chain reachable
//   - jmsl session key has signing rights (gas, registered session)
//
// Cleanup: restores the original bio (if there was one) so re-runs work.

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

import '../fixtures/test_fixtures.dart';

void main() {
  group('S2 — Profile record write-through', () {
    setUpAll(() async {
      await TestFixtures.bootstrap();
    });

    tearDownAll(() async {
      await TestFixtures.teardown();
    });

    test('setRecord(profile.bio) → chain → DB refresh', () async {
      final jmsl = await TestFixtures.setupWithJmsl();
      if (jmsl == null) return; // skipped — no local node

      // ── Read the current bio (if any) ─────────────────────────────
      final before = await PublicOSContacts.getContact(jmsl);
      expect(before, isNotNull, reason: 'jmsl contact should be in DB after init');

      final originalBio = before!.getRecord('profile.bio');
      // ignore: avoid_print
      print('Original bio: ${originalBio?.value ?? "(none)"}');

      // ── Set a new bio ─────────────────────────────────────────────
      final testBio = 'S2 test bio @ ${DateTime.now().toIso8601String()}';
      final newBioRecord = Record.asProfile(
        key: 'profile.bio',
        value: testBio,
        expiration: DateTime.now().add(const Duration(days: 365)),
      );

      final ok = await PublicOSContacts.setRecord(newBioRecord);
      expect(ok, isTrue,
          reason: 'setRecord should return true after on-chain confirmation');

      // ── Verify write-through: re-read from DB, expect new value ──
      final after = await PublicOSContacts.getContact(jmsl);
      expect(after, isNotNull);
      final afterBio = after!.getRecord('profile.bio');
      expect(afterBio, isNotNull,
          reason: 'profile.bio should exist after setRecord');
      expect(afterBio!.value, equals(testBio),
          reason: 'DB should reflect the new bio after write-through refresh');
      // ignore: avoid_print
      print('New bio confirmed in DB: ${afterBio.value}');

      // ── Cleanup: restore original (or delete if there was none) ──
      if (originalBio != null) {
        await PublicOSContacts.setRecord(originalBio);
      } else {
        await PublicOSContacts.deleteRecord('profile.bio');
      }
    }, timeout: const Timeout(Duration(seconds: 90)));
  });
}
