// S11 — BSP / SSP subscription resolution (read-only).
//
// Validates the on-chain subscription lookup chain:
//   - PublicOSBsp.getBSPRpcInfo() → resolves jmsl's active BSP (if any)
//   - PublicOSSsp.getSSPServerInfo() → resolves jmsl's active SSP (if any)
//   - PublicOSBsp.buildRpcEndpointList() → UI list builder
//   - PublicOSSsp.buildFeedServerList() → UI list builder
//
// We do NOT perform subscription writes — that would persist on-chain
// across runs and break idempotency. We only validate that the lookup
// methods return sensible values (either subscription info or null) and
// don't crash.

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

import '../fixtures/test_fixtures.dart';

void main() {
  group('S11 — BSP / SSP subscription resolution', () {
    setUpAll(() async {
      await TestFixtures.bootstrap();
    });

    tearDownAll(() async {
      await TestFixtures.teardown();
    });

    test('BSP + SSP info reads + UI list builders', () async {
      final jmsl = await TestFixtures.setupWithJmsl();
      if (jmsl == null) return;

      // ── BSP subscription ──────────────────────────────────────────
      final bspInfo = await PublicOSBsp.getBSPRpcInfo();
      if (bspInfo != null) {
        // ignore: avoid_print
        print('jmsl active BSP: ${bspInfo.slug} (${bspInfo.title}) → ${bspInfo.rpcUrl}');
        expect(bspInfo.slug, isNotEmpty);
        expect(bspInfo.rpcUrl, isNotEmpty);
      } else {
        // ignore: avoid_print
        print('jmsl has no active BSP subscription (expected for test chain)');
      }

      // ── SSP subscription ──────────────────────────────────────────
      final sspInfo = await PublicOSSsp.getSSPServerInfo();
      if (sspInfo != null) {
        // ignore: avoid_print
        print('jmsl active SSP: ${sspInfo.slug} (${sspInfo.title}) → ${sspInfo.apiUrl}');
        expect(sspInfo.slug, isNotEmpty);
        expect(sspInfo.apiUrl, isNotEmpty);
      } else {
        // ignore: avoid_print
        print('jmsl has no active SSP subscription');
      }

      // ── RPC endpoint list ─────────────────────────────────────────
      // Should always include at least the public node (non-removable),
      // possibly the BSP entry, possibly any custom RPCs.
      final rpcList = await PublicOSBsp.buildRpcEndpointList();
      expect(rpcList, isNotEmpty,
          reason: 'RPC list should always have at least the public node');
      // ignore: avoid_print
      print('RPC endpoints: ${rpcList.length}');
      for (final entry in rpcList) {
        // ignore: avoid_print
        print('  ${entry.source}: ${entry.label} → ${entry.url}'
            '${entry.isActive ? " [ACTIVE]" : ""}');
        expect(entry.url, isNotEmpty);
        expect(entry.source, anyOf(['public', 'bsp', 'custom']));
      }

      // The active RPC (set by setRpcOverride to local) is NOT in the list
      // because the override path bypasses buildRpcEndpointList. That's OK
      // — list builders are for UI display, not the override.

      // ── Feed server list ──────────────────────────────────────────
      final feedList = await PublicOSSsp.buildFeedServerList();
      // Feed list may be empty if no SSP and no custom servers — that's OK.
      // ignore: avoid_print
      print('Feed servers: ${feedList.length}');
      for (final entry in feedList) {
        // ignore: avoid_print
        print('  ${entry.source}: ${entry.label} → ${entry.url}'
            '${entry.isActive ? " [ACTIVE]" : ""}');
        expect(entry.url, isNotEmpty);
      }

      // ── activeSsp* fields should be set (default if no subscription) ──
      expect(PublicOS.activeSspUrl, isNotEmpty);
      expect(PublicOS.activeSspSource,
          anyOf(['default', 'subscription', 'custom', 'override']));
      // ignore: avoid_print
      print('active SSP: ${PublicOS.activeSspUrl} (${PublicOS.activeSspSource})');
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
