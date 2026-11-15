// S18 — Agreements: versioned texts published by root, acceptances recorded
// per account; a new version un-agrees everyone.
//
//   1. root publishes v1 of protocol / operator / citizen (if not yet)
//   2. an account created AFTER v1 has the PROTOCOL agreement recorded
//      (createAccount binds the version into the consent)
//   3. it has NOT accepted the OPERATOR one; it accepts it; now it has
//   4. root publishes operator v2 → not agreed again → accepts v2

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

import '../fixtures/test_fixtures.dart';

void main() {
  group('S18 — agreements', () {
    setUpAll(() async {
      await TestFixtures.bootstrap();
    });

    tearDownAll(() async {
      await TestFixtures.teardown();
    });

    test('protocol at creation, operator by choice, a new version resets', () async {
      final jmsl = await TestFixtures.setupWithJmsl();
      if (jmsl == null) return;
      final v = await TestFixtures.ensureAgreementsPublished();
      expect(v[1]!, greaterThan(BigInt.zero));
      expect(v[2]!, greaterThan(BigInt.zero));

      final p = await TestFixtures.ensureAccount('s18-p');
      final pKey = TestFixtures.actorKey('s18-p');
      expect(await PublicOSAgreements.hasAgreed(PublicOSAgreements.kindProtocol, p), isTrue,
          reason: 'createAccount records the protocol agreement');

      final opBefore = await PublicOSAgreements.currentVersion(PublicOSAgreements.kindOperator);
      await TestFixtures.actAs(p, pKey);
      final agreedOp = await PublicOSAgreements.hasAgreed(PublicOSAgreements.kindOperator, p);
      if (!agreedOp) {
        expect(await PublicOSAgreements.agree(PublicOSAgreements.kindOperator), isTrue,
            reason: 'agree(operator) failed: ${PublicOS.lastError}');
      }
      expect(await PublicOSAgreements.hasAgreed(PublicOSAgreements.kindOperator, p), isTrue);

      // a new version resets the acceptance
      final opNew = await TestFixtures.publishAgreement(
          PublicOSAgreements.kindOperator, 'operator agreement v${opBefore + BigInt.one} (scenario)');
      expect(opNew, equals(opBefore + BigInt.one));
      expect(await PublicOSAgreements.hasAgreed(PublicOSAgreements.kindOperator, p), isFalse);
      expect(await PublicOSAgreements.agree(PublicOSAgreements.kindOperator), isTrue,
          reason: 'agree(operator v$opNew) failed: ${PublicOS.lastError}');
      expect(await PublicOSAgreements.hasAgreed(PublicOSAgreements.kindOperator, p), isTrue);
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
