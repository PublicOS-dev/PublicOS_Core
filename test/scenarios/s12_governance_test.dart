// S12 — Governance / org lifecycle.
//
// Exercises the governance extension against the live local chain:
//   1. Snapshot jmsl's current orgs (baseline)
//   2. createOrg(name, [jmsl], threshold=1, isPublic=false)
//   3. Wait for new org to show up in getOrgsForAccount(jmsl)
//   4. Verify each query against the new org:
//      - isOrgAccount → true
//      - isPublicOrg  → false
//      - getOrgMembers → [jmsl]
//      - getOrgMemberCount → 1
//      - isOrgMember(jmsl) → true
//      - getOrgThreshold → 1
//      - getOrgCreator → jmsl
//
// Uniqueness note: org display names must be globally unique on chain.
// Test uses a timestamped name so re-runs don't collide. Each run leaves
// a new org on the test chain permanently — acceptable for local dev.
//
// We do NOT exercise voting writes in this test — those need multi-sig
// member quorums that a single-member test org can't meaningfully test.

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

import '../fixtures/test_fixtures.dart';

void main() {
  group('S12 — Governance / org creation', () {
    setUpAll(() async {
      await TestFixtures.bootstrap();
    });

    tearDownAll(() async {
      await TestFixtures.teardown();
    });

    test('jmsl creates a private org + reads back all metadata', () async {
      final jmsl = await TestFixtures.setupWithJmsl();
      if (jmsl == null) return;

      // ── 1. Snapshot existing orgs ─────────────────────────────────
      final orgsBefore = await PublicOSGovernance.getOrgsForAccount(jmsl);
      // ignore: avoid_print
      print('jmsl is a member of ${orgsBefore.length} orgs before createOrg');

      // The alpha deploy created the root org with jmsl minutes ago, so a
      // fresh local chain starts inside the org-creation cooldown. Hardhat
      // lets the scenario step over it.
      await TestFixtures.skipOrgCreationCooldown(jmsl);

      // ── 2. Create a new private org ───────────────────────────────
      final displayName =
          's12org_${DateTime.now().millisecondsSinceEpoch}';
      final newOrgAddress = await PublicOSGovernance.createOrg(
        displayName: displayName,
        initialMembers: [jmsl],
        initialThreshold: 1,
        isPublic: false,
      );
      expect(newOrgAddress, isNotNull,
          reason: 'createOrg should return the new org address on success. '
              'Last error: ${PublicOS.lastError}');
      // ignore: avoid_print
      print('createOrg returned org address: ${newOrgAddress!.eip55With0x}');

      // ── 3. Cross-check: the returned address shows up as a new org ──
      bool appeared = false;
      for (var i = 0; i < 30; i++) {
        await Future<void>.delayed(const Duration(seconds: 1));
        final orgsNow = await PublicOSGovernance.getOrgsForAccount(jmsl);
        final beforeSet = orgsBefore.map((a) => a.eip55With0x).toSet();
        if (orgsNow.any((a) =>
            !beforeSet.contains(a.eip55With0x) &&
            a.eip55With0x.toLowerCase() ==
                newOrgAddress.eip55With0x.toLowerCase())) {
          // ignore: avoid_print
          print('Returned org appeared in jmsl\'s org list after ${i + 1}s');
          appeared = true;
          break;
        }
      }
      expect(appeared, isTrue,
          reason: "createOrg's returned address should appear in jmsl's "
              'org list within 30s');

      // ── 4. Read back all org metadata ────────────────────────────
      final isOrg = await PublicOSGovernance.isOrgAccount(newOrgAddress);
      expect(isOrg, isTrue, reason: 'new address should be recognized as org');

      final isPublic = await PublicOSGovernance.isPublicOrg(newOrgAddress);
      expect(isPublic, isFalse, reason: 'we created a private org');

      final members = await PublicOSGovernance.getOrgMembers(newOrgAddress);
      expect(members, hasLength(1),
          reason: 'org has exactly one initial member');
      expect(members.first.eip55With0x.toLowerCase(),
          equals(jmsl.eip55With0x.toLowerCase()),
          reason: 'the single member should be jmsl');

      final memberCount =
          await PublicOSGovernance.getOrgMemberCount(newOrgAddress);
      expect(memberCount, equals(1));

      final isJmslMember =
          await PublicOSGovernance.isOrgMember(newOrgAddress, jmsl);
      expect(isJmslMember, isTrue);

      final threshold =
          await PublicOSGovernance.getOrgThreshold(newOrgAddress);
      expect(threshold, equals(1), reason: 'threshold set to 1 at creation');

      final creator = await PublicOSGovernance.getOrgCreator(newOrgAddress);
      expect(creator, isNotNull);
      expect(creator!.eip55With0x.toLowerCase(),
          equals(jmsl.eip55With0x.toLowerCase()),
          reason: 'jmsl (as caller) should be the creator');

      // ignore: avoid_print
      print('Org "$displayName" (${newOrgAddress.eip55With0x}) verified:');
      // ignore: avoid_print
      print('  isOrg=$isOrg isPublic=$isPublic members=$memberCount '
          'threshold=$threshold');

      // ── 5. The new org should also fetch cleanly via fetchContact ──
      final orgContact =
          await PublicOSContacts.fetchContact(newOrgAddress);
      expect(orgContact.publicosDisplayName, equals(displayName));
      expect(orgContact.isOrgAccount, isTrue,
          reason: 'fetchContact should mark the result as an org');
    }, timeout: const Timeout(Duration(seconds: 120)));
  });
}
