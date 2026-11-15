// S0 — 4-stage init test with jmsl.
//
// Validates the entire boot pipeline:
//   1. PublicOS.init()                  — infrastructure (DB, secure storage, public RPC)
//   2. PublicOSAuth.authenticate()      — biometric gate (mocked to always pass)
//   3. PublicOSAccounts.restoreSession(jmsl) — load keys, verify on chain, save own contact
//   4. PublicOS.initBSP()               — module resolution, RPC upgrade, polling
//   5. PublicOS.initSSP()               — feed server resolution
//   6. PublicOS.initXMTP()              — XMTP key load (likely skipped, no key)
//
// Pre-conditions:
//   - Local PublicOS chain reachable at the URL in manager secrets
//     (defaults to http://127.0.0.1:8545 — a hardhat node)
//   - jmsl session key + on-chain account exist
//   - the local key file read by test/fixtures/test_fixtures.dart
//
// This test does NOT exercise XMTP or messaging — that's S0 + later scenarios.

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

import '../fixtures/test_fixtures.dart';

void main() {
  group('S0 — 4-stage init', () {
    setUpAll(() async {
      await TestFixtures.bootstrap();
    });

    tearDownAll(() async {
      await TestFixtures.teardown();
    });

    test('init → auth → initBSP → initSSP → initXMTP', () async {
      // ── Stage 1: manual infrastructure setup ──────────────────────
      // We bypass PublicOS.init() because it would create a real sqlite
      // database via path_provider/drift_flutter, which doesn't work in
      // headless tests. initCoreForTesting installs an in-memory DB and
      // initializes the late service fields (secureStorage, localAuth, http).
      await TestFixtures.initCoreForTesting();
      expect(PublicOS.database, isNotNull);
      expect(PublicOS.isInitialized, isTrue);

      // Authenticate with debug-no-auth (skips the biometric prompt entirely)
      PublicOS.debugNoAuthNeeded = true;
      final authed = await PublicOSAuth.authenticate();
      expect(authed, isTrue, reason: 'Auth should pass with debugNoAuthNeeded=true');
      expect(PublicOS.isAuthenticated, isTrue);

      // Set the local RPC override BEFORE initBSP so we never hit the public node.
      // We need to read the local RPC URL from the manager secrets.
      // First we have to load the manager secrets (which needs web3 to look
      // up the account address). To break the chicken-and-egg: directly point
      // web3Client at the local node from secrets without loading jmsl yet.
      //
      // For the first run we just hardcode the URL — TestFixtures will read
      // the manager secrets, but we need an RPC up first to call
      // getAccountAddressForSession. Use the well-known local node URL.
      const fallbackLocalRpc = 'http://127.0.0.1:8545';
      PublicOS.setRpcOverride(fallbackLocalRpc, 'local');

      // Verify the override took effect
      expect(PublicOS.activeRpcUrl, equals(fallbackLocalRpc));
      expect(PublicOS.activeRpcSource, equals('local'));

      // Test the RPC connection
      final reachable = await PublicOS.testRpcUrl(fallbackLocalRpc);
      if (!reachable) {
        // Local node isn't running — this test can't proceed.
        // Mark as skipped via expect with a message rather than failing.
        markTestSkipped('Local PublicOS node at $fallbackLocalRpc unreachable');
        return;
      }
      PublicOS.setWeb3Connected(true);

      // ── Load jmsl from manager (now that we have a working RPC) ───
      // Fresh local deploy: resolve the modules from the registry first (the
      // PublicOSBsp fallbacks are the live chain's addresses).
      await PublicOSBsp.resolveModuleAddresses();
      final jmslAccount = await TestFixtures.loadJmslFromManager();
      expect(jmslAccount, isNotNull);
      print('jmsl account: ${jmslAccount.eip55With0x}');
      print('jmsl session:  ${TestFixtures.jmslSessionAddress?.eip55With0x}');

      // ── Stage 2a: restoreSession ───────────────────────────────────
      // Load jmsl's keys, verify on chain, fetch and save own contact.
      // Must run before initBSP so myPublicosAddress is set for the BSP
      // stage to resolve the subscription.
      final restored = await PublicOSAccounts.restoreSession(jmslAccount);
      expect(restored, isTrue, reason: 'restoreSession should succeed for jmsl');
      expect(PublicOS.myPublicosAddress, equals(jmslAccount.eip55With0x));
      expect(PublicOS.sessionBlockchainAddress, isNotNull);

      // Read jmsl's contact from the DB to confirm restoreSession saved it.
      final myContact = await PublicOSContacts.getContact(jmslAccount);
      expect(myContact, isNotNull, reason: 'jmsl contact should be in DB after restoreSession');
      expect(myContact!.publicosDisplayName, equals('jmsl'));

      // ── Stage 2b: initBSP ──────────────────────────────────────────
      final bspOk = await PublicOS.initBSP();
      expect(bspOk, isTrue, reason: 'initBSP should succeed');
      expect(PublicOS.web3Connected, isTrue);
      print('jmsl displayName: ${myContact.publicosDisplayName}');
      print('jmsl records:    ${myContact.records.length}');

      // ── Stage 3: initSSP ───────────────────────────────────────────
      final sspOk = await PublicOS.initSSP();
      // SSP may or may not succeed depending on whether the local feed server
      // is running. Either way it should not throw.
      print('SSP active: ${PublicOS.activeSspUrl} (source: ${PublicOS.activeSspSource})');
      print('SSP connected: ${PublicOS.sspConnected}');
      // We don't assert sspOk — the local feed server may not be up.

      // ── Stage 4: initXMTP ──────────────────────────────────────────
      // jmsl's XMTP key is NOT in our test secureStorage, so this should
      // return false but not throw.
      final xmtpOk = await PublicOS.initXMTP();
      expect(xmtpOk, isFalse,
          reason: 'initXMTP should skip cleanly when no key is stored');
      expect(PublicOS.xmtpConnected, isFalse);

      // ── Status streams should be active ────────────────────────────
      expect(PublicOS.web3Status, isNotNull);
      expect(PublicOS.sspStatus, isNotNull);
      expect(PublicOS.xmtpStatus, isNotNull);
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
