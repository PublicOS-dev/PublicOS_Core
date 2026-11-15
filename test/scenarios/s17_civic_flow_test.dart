// S17 — The civic flow: privates → vouches → citizenship, both paths.
//
// Local hardhat deploy of the current source; serial. Actors are derived keys
// (TestFixtures.actorKey) so they are the same across files.
//
//   A. jmsl sponsors a private (A). jmsl's vouch tops A up to the threshold
//      with one weighted edge (genesis path). A claims (opt-in) and accepts
//      the citizen agreement in the same call → citizen.
//   B. The individual path: `threshold` citizens (bootstrapped the same way)
//      each vouch once for private B — regular budgeted edges — until B is
//      eligible; the next vouch is refused ("already eligible"); B claims.
//   C. Rules on the way: a private cannot vouch; a citizen cannot be vouched;
//      claiming below the threshold is refused.

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart' show EthPrivateKey;

import '../fixtures/test_fixtures.dart';

/// Core's `vouch` rethrows the chain's revert so callers can show the reason.
/// True when the vouch was REFUSED (reverted), false when it landed.
Future<bool> vouchRefused(EthereumAddress target) async {
  try {
    final tx = await PublicOSAccounts.vouch(target);
    return tx == null;
  } catch (_) {
    return true;
  }
}

void main() {
  group('S17 — civic flow', () {
    setUpAll(() async {
      await TestFixtures.bootstrap();
    });

    tearDownAll(() async {
      await TestFixtures.teardown();
    });

    test('genesis vouch → claim; individual vouches → claim; the refusals', () async {
      final jmsl = await TestFixtures.setupWithJmsl();
      if (jmsl == null) return;
      final versions = await TestFixtures.ensureAgreementsPublished();
      expect(versions[3]!, greaterThan(BigInt.zero), reason: 'citizen agreement v1 published by root');
      final threshold = (await PublicOSAccounts.getVouchThreshold()).toInt();
      print('vouch threshold today: $threshold');

      // A and B are fresh every run (the chain keeps state between runs; a
      // claimed citizen cannot play the private again); the 25 bulk citizens
      // below are deterministic and reused.
      final run = await PublicOS.web3Client.getBlockNumber();
      // ── A. a private, the genesis vouch, the claim ─────────────────────
      final a = await TestFixtures.ensureAccount('s17-a-$run');
      final aKey = TestFixtures.actorKey('s17-a-$run');
      expect(await PublicOSAccounts.isCitizen(a), isFalse, reason: 'a fresh account is private');

      // C1. a private cannot vouch (onlyRegisteredCitizen)
      await TestFixtures.actAs(a, aKey);
      expect(await vouchRefused(jmsl), isTrue, reason: 'a private must not be able to vouch');
      // C3. claiming below the threshold is refused
      expect(await PublicOSAccounts.claimCitizenship(), isFalse);
      expect(PublicOS.lastError, isNotNull);

      await TestFixtures.actAsJmsl();
      if (!await PublicOSAccounts.isCitizen(a)) {
        final count0 = (await PublicOSAccounts.getVouchCount(a)).toInt();
        if (count0 < threshold) {
          expect(await PublicOSAccounts.vouch(a), isNotNull, reason: 'jmsl vouch failed: ${PublicOS.lastError}');
        }
        final count1 = (await PublicOSAccounts.getVouchCount(a)).toInt();
        expect(count1, equals(threshold), reason: 'the genesis vouch tops up to the threshold');
        final vouchers = await PublicOSAccounts.getVouchersOf(a);
        expect(vouchers.map((v) => v.eip55With0x), contains(jmsl.eip55With0x));

        // C2. an eligible target takes no more vouches
        expect(await vouchRefused(a), isTrue, reason: 'already eligible → refused');

        await TestFixtures.actAs(a, aKey);
        expect(await PublicOSAccounts.claimCitizenship(), isTrue, reason: 'claim failed: ${PublicOS.lastError}');
      }
      expect(await PublicOSAccounts.isCitizen(a), isTrue);
      expect(await PublicOSAgreements.hasAgreed(PublicOSAgreements.kindCitizen, a), isTrue);

      // ── B. the individual path: `threshold` citizens vouch for B ───────
      await TestFixtures.actAsJmsl();
      final b = await TestFixtures.ensureAccount('s17-b-$run');
      final bKey = TestFixtures.actorKey('s17-b-$run');
      final citizens = <EthereumAddress>[];
      final citizenKeys = <EthPrivateKey>[];
      for (var i = 0; i < threshold; i++) {
        await TestFixtures.actAsJmsl();
        final c = await TestFixtures.ensureAccount('s17-c$i');
        final cKey = TestFixtures.actorKey('s17-c$i');
        if (!await PublicOSAccounts.isCitizen(c)) {
          if ((await PublicOSAccounts.getVouchCount(c)).toInt() < threshold) {
            expect(await PublicOSAccounts.vouch(c), isNotNull, reason: 'jmsl vouch for c$i failed: ${PublicOS.lastError}');
          }
          // bulk claim through the binding with the actor's own key (no session swap)
          final version = await PublicOSAgreements.currentVersion(PublicOSAgreements.kindCitizen);
          final tx = await PublicOSBsp.citizenshipManagerContract
              .agreeTermsAndClaimCitizenship((version: version), credentials: cKey);
          expect(await TxUtils.waitForReceipt(tx, label: 'claim c$i'), isTrue);
        }
        citizens.add(c);
        citizenKeys.add(cKey);
      }
      expect(citizens.length, threshold);

      if (!await PublicOSAccounts.isCitizen(b)) {
        var count = (await PublicOSAccounts.getVouchCount(b)).toInt();
        for (var i = 0; i < citizens.length && count < threshold; i++) {
          final already = await PublicOSBsp.vouchManagerContract
              .hasVouched((voucher: citizens[i], target: b));
          if (already) continue;
          final tx = await PublicOSBsp.vouchManagerContract
              .vouch((target: b), credentials: citizenKeys[i]);
          expect(await TxUtils.waitForReceipt(tx, label: 'c$i vouches b'), isTrue);
          count = (await PublicOSAccounts.getVouchCount(b)).toInt();
        }
        expect(count, equals(threshold), reason: 'every edge weighs 1 on the individual path');
        // one more is refused: B is eligible now
        await TestFixtures.actAsJmsl();
        expect(await vouchRefused(b), isTrue);

        await TestFixtures.actAs(b, bKey);
        expect(await PublicOSAccounts.claimCitizenship(), isTrue, reason: 'B claim failed: ${PublicOS.lastError}');
      }
      expect(await PublicOSAccounts.isCitizen(b), isTrue);
      final vouchersB = await PublicOSAccounts.getVouchersOf(b);
      expect(vouchersB.length, greaterThanOrEqualTo(threshold));
      // C4. a citizen cannot be vouched for
      await TestFixtures.actAsJmsl();
      expect(await vouchRefused(b), isTrue);
      print('citizens now: ${await PublicOSBsp.citizenshipManagerContract.citizenCount()}');
    }, timeout: const Timeout(Duration(minutes: 15)));
  });
}
