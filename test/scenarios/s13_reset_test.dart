// S13 — Reset and re-init.
//
// Validates that PublicOS.reset() clears all state and the system can be
// re-initialized cleanly afterwards.
//
// Note: Because we use initCoreForTesting() (not the real PublicOS.init()),
// the "re-init" leg also goes through initCoreForTesting().

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

import '../fixtures/test_fixtures.dart';

void main() {
  group('S13 — Reset and re-init', () {
    setUpAll(() async {
      await TestFixtures.bootstrap();
    });

    tearDownAll(() async {
      await TestFixtures.teardown();
    });

    test('reset clears all state, re-init restores', () async {
      // ── First init ────────────────────────────────────────────────
      final jmsl = await TestFixtures.setupWithJmsl();
      if (jmsl == null) return;

      // Sanity: state is populated
      expect(PublicOS.isAuthenticated, isTrue);
      expect(PublicOS.isInitialized, isTrue);
      expect(PublicOS.myPublicosAddress, equals(jmsl.eip55With0x));
      expect(PublicOS.sessionBlockchainAddress, isNotNull);
      expect(PublicOS.currentBlockchainPrivateKey, isNotNull);
      expect(PublicOS.web3Connected, isTrue);
      expect(PublicOS.activeRpcSource, equals('local'));

      // ── Reset ─────────────────────────────────────────────────────
      await PublicOS.reset();

      expect(PublicOS.isAuthenticated, isFalse);
      expect(PublicOS.isInitialized, isFalse);
      expect(PublicOS.myPublicosAddress, isNull);
      expect(PublicOS.sessionBlockchainAddress, isNull);
      expect(PublicOS.currentBlockchainPrivateKey, isNull);
      expect(PublicOS.currentBlockchainDbKey, isNull);
      expect(PublicOS.activeRpcUrl, equals(PublicOS.PUBLIC_RPC_URL));
      expect(PublicOS.activeRpcSource, equals('public'));

      // ── Re-init from scratch ──────────────────────────────────────
      // (clear the rpc override too — reset() doesn't touch overrides)
      PublicOS.clearRpcOverride();

      final jmsl2 = await TestFixtures.setupWithJmsl();
      if (jmsl2 == null) return;

      expect(jmsl2, equals(jmsl), reason: 'same on-chain account address');
      expect(PublicOS.isAuthenticated, isTrue);
      expect(PublicOS.myPublicosAddress, equals(jmsl.eip55With0x));

      // Contact should be back in the (fresh in-memory) DB
      final myContact = await PublicOSContacts.getContact(jmsl);
      expect(myContact, isNotNull);
      expect(myContact!.publicosDisplayName, equals('jmsl'));
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
