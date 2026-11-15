// S3 — Settings CRUD (local DB only).
//
// Validates the per-account settings layer:
//   - getPostMode / setPostMode
//   - getLiveNotifications / setLiveNotifications
//   - getModulePollingMinutes / setModulePollingMinutes
//   - Generic getSetting / setSetting / deleteSetting
//
// Settings are scoped per `sessionBlockchainAddress`. We need a session,
// but no chain calls.

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

import '../fixtures/test_fixtures.dart';

void main() {
  group('S3 — Settings CRUD', () {
    setUpAll(() async {
      await TestFixtures.bootstrap();
    });

    tearDownAll(() async {
      await TestFixtures.teardown();
    });

    test('post mode + notifications + polling interval', () async {
      final jmsl = await TestFixtures.setupWithJmsl();
      if (jmsl == null) return;

      // ── Post mode ─────────────────────────────────────────────────
      // Default is 'update'
      final initialMode = await PublicOSSettings.getPostMode();
      expect(initialMode, equals('update'),
          reason: 'fresh DB should default to "update" post mode');

      await PublicOSSettings.setPostMode('article');
      expect(await PublicOSSettings.getPostMode(), equals('article'));

      await PublicOSSettings.setPostMode('update');
      expect(await PublicOSSettings.getPostMode(), equals('update'));

      // ── Live notifications ────────────────────────────────────────
      // Default is true
      final initialLive = await PublicOSSettings.getLiveNotifications();
      expect(initialLive, isTrue);

      await PublicOSSettings.setLiveNotifications(false);
      expect(await PublicOSSettings.getLiveNotifications(), isFalse);

      await PublicOSSettings.setLiveNotifications(true);
      expect(await PublicOSSettings.getLiveNotifications(), isTrue);

      // ── Module polling minutes ────────────────────────────────────
      // Default is 60
      final initialPolling = await PublicOSSettings.getModulePollingMinutes();
      expect(initialPolling, equals(60));

      await PublicOSSettings.setModulePollingMinutes(30);
      expect(await PublicOSSettings.getModulePollingMinutes(), equals(30));

      // Restore default
      await PublicOSSettings.setModulePollingMinutes(60);
      expect(await PublicOSSettings.getModulePollingMinutes(), equals(60));

      // ── Generic setting (custom key) ──────────────────────────────
      final customRecord = Record.asSettings(
        key: 'test_custom_key',
        value: 'hello world',
        isSystem: false,
        expiration: DateTime.now().add(const Duration(days: 1)),
      );
      await PublicOSSettings.setSetting('test_custom_key', customRecord);

      final fetched = await PublicOSSettings.getSetting('test_custom_key');
      expect(fetched, isNotNull);
      expect(fetched!.value, equals('hello world'));

      final deleted = await PublicOSSettings.deleteSetting('test_custom_key');
      expect(deleted, isTrue);

      final afterDelete = await PublicOSSettings.getSetting('test_custom_key');
      expect(afterDelete, isNull);
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
