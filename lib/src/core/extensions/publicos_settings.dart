import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:publicos_core/src/core/core.dart';
import 'package:publicos_core/src/core/extensions/publicos_bsp.dart';
import 'package:publicos_core/src/database/database.dart';
import 'package:publicos_core/src/models/record_model.dart';
import 'package:publicos_core/src/utils/log.dart';

/// Settings management extension for PublicOS.
/// Handles local settings storage and retrieval with session isolation.
extension PublicOSSettings on PublicOS {
  static const _tag = 'Settings';

  /// Set a setting record
  static Future<bool> setSetting(String key, Record record) async {
    if (!PublicOS.isAuthenticated || PublicOS.sessionBlockchainAddress == null) {
      throw Exception('Authentication required');
    }

    try {
      await PublicOS.database.upsertSetting(
        SettingsCompanion(
          key: Value(key),
          record: Value(jsonEncode(record.toJson())),
          sessionAddress: Value(PublicOS.sessionBlockchainAddress!),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

      Log.d(_tag, 'Setting stored - key: $key');
      return true;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error storing setting: $e');
      return false;
    }
  }

  /// Get a setting record by key
  static Future<Record?> getSetting(String key) async {
    if (!PublicOS.isAuthenticated || PublicOS.sessionBlockchainAddress == null) {
      throw Exception('Authentication required');
    }

    try {
      final result = await PublicOS.database.getSetting(
        key,
        PublicOS.sessionBlockchainAddress!,
      );

      if (result == null) return null;

      final recordJson = jsonDecode(result.record);
      return Record.fromJson(recordJson);
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting setting: $e');
      return null;
    }
  }

  /// Delete a setting
  static Future<bool> deleteSetting(String key) async {
    if (!PublicOS.isAuthenticated || PublicOS.sessionBlockchainAddress == null) {
      throw Exception('Authentication required');
    }

    try {
      final count = await PublicOS.database.deleteSetting(
        key,
        PublicOS.sessionBlockchainAddress!,
      );

      Log.d(_tag, 'Setting deleted - key: $key');
      return count > 0;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error deleting setting: $e');
      return false;
    }
  }

  /// Get all settings for current session
  static Future<Map<String, Record>> getAllSettings() async {
    if (!PublicOS.isAuthenticated || PublicOS.sessionBlockchainAddress == null) {
      throw Exception('Authentication required');
    }

    try {
      final results = await PublicOS.database.getSettingsForSession(
        PublicOS.sessionBlockchainAddress!,
      );

      return Map.fromEntries(
        results.map((row) {
          final recordJson = jsonDecode(row.record);
          return MapEntry(
            row.key,
            Record.fromJson(recordJson),
          );
        }),
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting all settings: $e');
      return {};
    }
  }

  ///*********************************************
  /// CONVENIENCE METHODS FOR SPECIFIC SETTINGS
  ///*********************************************

  /// Reader-wide default for feed sign-in:
  /// ON = sign every channel the user has not denied; writes NO
  /// per-channel decision. Default OFF. Local, per session.
  ///
  /// A typed wrapper (not a UI-only key): Core's own
  /// `PublicOSChannelSignin.shouldSign` reads it on every fetch — so it must
  /// answer OFF, never throw, for an unauthenticated session.
  static Future<bool> getFeedsAutoSignin() async {
    try {
      final record = await getSetting(feedsAutoSigninKey);
      return record?.value == 'on';
    } catch (_) {
      return false;
    }
  }

  static const feedsAutoSigninKey = 'feeds.auto_signin';

  static Future<bool> setFeedsAutoSignin(bool on) async {
    try {
      final record = Record.asSettings(
        key: feedsAutoSigninKey,
        value: on ? 'on' : 'off',
        isExpired: false,
        isSystem: true,
      );
      return await setSetting(feedsAutoSigninKey, record);
    } catch (e) {
      Log.e(_tag, 'Error setting feeds auto sign-in: $e');
      return false;
    }
  }

  /// Get/Set post creation mode (update vs article)
  /// 'update' = short form (title, content only)
  /// 'article' = long form (all fields including summary, external_url, tags, image)
  static Future<String> getPostMode() async {
    try {
      final record = await getSetting('post_mode');
      if (record == null) {
        return 'update'; // Default to update mode
      }
      return record.value;
    } catch (e) {
      Log.e(_tag, 'Error getting post mode: $e');
      return 'update';
    }
  }

  static Future<bool> setPostMode(String mode) async {
    if (mode != 'update' && mode != 'article') {
      Log.w(_tag, 'Invalid post mode: $mode');
      return false;
    }
    try {
      final record = Record.asSettings(
        key: 'post_mode',
        value: mode,
        isExpired: false,
        isSystem: true,
      );
      return await setSetting('post_mode', record);
    } catch (e) {
      Log.e(_tag, 'Error setting post mode: $e');
      return false;
    }
  }

  ///*********************************************
  /// NOTIFICATION SETTINGS (Two independent toggles)
  ///*********************************************

  /// Get live notifications setting (in-app notifications while app is active)
  /// Default: true
  static Future<bool> getLiveNotifications() async {
    try {
      final record = await getSetting('live_notifications');
      if (record == null) {
        return true; // Default to enabled
      }
      return record.value == 'true';
    } catch (e) {
      Log.e(_tag, 'Error getting live notifications: $e');
      return true;
    }
  }

  /// Set live notifications setting
  static Future<bool> setLiveNotifications(bool enabled) async {
    try {
      final record = Record.asSettings(
        key: 'live_notifications',
        value: enabled.toString(),
        isExpired: false,
        isSystem: true,
      );
      return await setSetting('live_notifications', record);
    } catch (e) {
      Log.e(_tag, 'Error setting live notifications: $e');
      return false;
    }
  }

  /// Get chain-notifications setting — the master switch for the background
  /// on-chain activity sweep (vouches/citizenship/profile edits popped as OS
  /// notifications while the app is closed). Mobile (publicos_client). Default:
  /// false. Separate key from [getBackgroundNotifications] (desktop's message
  /// background sync) — different feature on a different platform.
  static Future<bool> getChainNotifications() async {
    try {
      final record = await getSetting('chain_notifications');
      if (record == null) {
        return false; // Default to disabled
      }
      return record.value == 'true';
    } catch (e) {
      Log.e(_tag, 'Error getting chain notifications: $e');
      return false;
    }
  }

  /// Get background notifications setting (periodic message checks when the app
  /// is closed). Used by publicos_desktop + the FCM push path. Default: false.
  static Future<bool> getBackgroundNotifications() async {
    try {
      final record = await getSetting('background_notifications');
      if (record == null) {
        return false; // Default to disabled
      }
      return record.value == 'true';
    } catch (e) {
      Log.e(_tag, 'Error getting background notifications: $e');
      return false;
    }
  }

  ///*********************************************
  /// MODULE POLLING SETTINGS
  ///*********************************************

  /// Get module polling interval in minutes (default: 60, range: 1-1440)
  static Future<int> getModulePollingMinutes() async {
    try {
      final record = await getSetting('module_polling_minutes');
      if (record == null) return 60;
      final value = int.tryParse(record.value);
      if (value == null || value < 1 || value > 1440) return 60;
      return value;
    } catch (e) {
      Log.e(_tag, 'Error getting module polling minutes: $e');
      return 60;
    }
  }

  /// Set module polling interval in minutes (range: 1-1440).
  /// Reconfigures the active polling timer.
  static Future<bool> setModulePollingMinutes(int minutes) async {
    if (minutes < 1 || minutes > 1440) {
      Log.w(_tag, 'Invalid polling minutes: $minutes (must be 1-1440)');
      return false;
    }
    try {
      final record = Record.asSettings(
        key: 'module_polling_minutes',
        value: minutes.toString(),
        isExpired: false,
        isSystem: true,
      );
      final success = await setSetting('module_polling_minutes', record);
      if (success) {
        PublicOSBsp.reconfigurePolling(Duration(minutes: minutes));
      }
      return success;
    } catch (e) {
      Log.e(_tag, 'Error setting module polling minutes: $e');
      return false;
    }
  }

  ///*********************************************
  /// VIDEO PLAYBACK SETTINGS
  ///*********************************************

  /// Auto-load videos with `Content-Length <= threshold` (in MiB).
  /// Above the threshold, the player gates with a "Tap to load" affordance.
  /// Range: 0–500. Defaults to 35.
  /// Sentinel: 0 = always ask. 500 = effectively always auto-load.
  static Future<int> getVideoAutoloadThresholdMb() async {
    try {
      final record = await getSetting('video_autoload_threshold_mb');
      if (record == null) return 35;
      final value = int.tryParse(record.value);
      if (value == null || value < 0 || value > 500) return 35;
      return value;
    } catch (e) {
      Log.e(_tag, 'Error getting video autoload threshold: $e');
      return 35;
    }
  }

  static Future<bool> setVideoAutoloadThresholdMb(int mb) async {
    if (mb < 0 || mb > 500) {
      Log.w(_tag, 'Invalid video threshold: $mb (must be 0-500)');
      return false;
    }
    try {
      final record = Record.asSettings(
        key: 'video_autoload_threshold_mb',
        value: mb.toString(),
        isExpired: false,
        isSystem: true,
      );
      return await setSetting('video_autoload_threshold_mb', record);
    } catch (e) {
      Log.e(_tag, 'Error setting video autoload threshold: $e');
      return false;
    }
  }

  /// Whether feed videos at or under the auto-load threshold play by
  /// themselves (muted). Off = every feed video waits for a tap. Defaults to
  /// TRUE.
  static Future<bool> getVideoAutoplayInFeed() async {
    try {
      final record = await getSetting('video_autoplay_in_feed');
      if (record == null) return true;
      return record.value == 'true';
    } catch (e) {
      Log.e(_tag, 'Error getting video autoplay: $e');
      return true;
    }
  }

  static Future<bool> setVideoAutoplayInFeed(bool enabled) async {
    try {
      final record = Record.asSettings(
        key: 'video_autoplay_in_feed',
        value: enabled.toString(),
        isExpired: false,
        isSystem: true,
      );
      return await setSetting('video_autoplay_in_feed', record);
    } catch (e) {
      Log.e(_tag, 'Error setting video autoplay: $e');
      return false;
    }
  }

  /// Whether FCM push notifications are enabled. Defaults to true — push is
  /// the primary delivery path; users who explicitly disable get only the
  /// 15-min Workmanager sweep (also kept always-on as a safety net).
  static Future<bool> getPushNotifications() async {
    try {
      final record = await getSetting('push_notifications');
      if (record == null) return true; // default ON for new installs
      return record.value == 'true';
    } catch (e) {
      Log.e(_tag, 'Error getting push notifications: $e');
      return true;
    }
  }

  /// Set push notifications setting. Side effects (register / unregister
  /// with the notif server, attach FirebaseMessaging listeners) live in
  /// publicos_client's `PushNotificationsService` because they require the
  /// `firebase_messaging` plugin which isn't a Core dep. Caller is
  /// responsible for invoking `PushNotificationsService.bootstrap()` when
  /// toggling ON and `PublicOSPush.unregister()` when toggling OFF.
  static Future<bool> setPushNotifications(bool enabled) async {
    try {
      final record = Record.asSettings(
        key: 'push_notifications',
        value: enabled.toString(),
        isExpired: false,
        isSystem: true,
      );
      return await setSetting('push_notifications', record);
    } catch (e) {
      Log.e(_tag, 'Error setting push notifications: $e');
      return false;
    }
  }

  /// Set chain-notifications setting. Registers/cancels the background sweep
  /// automatically. On enable, seeds the activity cursor to chain head so the
  /// first sweep only notifies events that happen AFTER the user opts in (no
  /// cold-start dump of ~3 days of history as a notification burst).
  static Future<bool> setChainNotifications(bool enabled) async {
    try {
      final record = Record.asSettings(
        key: 'chain_notifications',
        value: enabled.toString(),
        isExpired: false,
        isSystem: true,
      );
      final success = await setSetting('chain_notifications', record);

      if (success) {
        if (enabled) {
          // Seed BOTH sweeps' cursors — the contract-event feed and the wallet
          // transfer feed each carry their own. Miss either and opting in dumps
          // that feed's cold-start window (~3 days) as a notification burst.
          await PublicOSActivity.seedCursorToHead();
          await PublicOSWalletActivity.seedCursorToHead();
        }
        await syncBackgroundTask();
      }

      return success;
    } catch (e) {
      Log.e(_tag, 'Error setting chain notifications: $e');
      return false;
    }
  }

  /// Social notifications: the master switch for
  /// replies, comments, mentions and follow requests from any server. Default
  /// ON. It gates the 15-min inbox pull (the worker's social half) and the
  /// official target's `enabled` flag, which the app writes; the push
  /// transport itself is `push_notifications`.
  static Future<bool> getSocialNotifications() async {
    try {
      final record = await getSetting('social_notifications');
      if (record == null) return true; // default ON
      return record.value == 'true';
    } catch (e) {
      Log.e(_tag, 'Error getting social notifications: $e');
      return true;
    }
  }

  static Future<bool> setSocialNotifications(bool enabled) async {
    try {
      final record = Record.asSettings(
        key: 'social_notifications',
        value: enabled.toString(),
        isExpired: false,
        isSystem: true,
      );
      final success = await setSetting('social_notifications', record);
      if (success) await syncBackgroundTask();
      return success;
    } catch (e) {
      Log.e(_tag, 'Error setting social notifications: $e');
      return false;
    }
  }

  /// The ONE place that decides whether the 15-min Workmanager task runs
  /// (one worker, two jobs, two switches). Registered
  /// when either `chain_notifications` or `social_notifications` is on,
  /// cancelled when both are off; inside the task each job checks its own
  /// switch (publicos_client::runChainNotificationSync). The app's boot
  /// re-asserts the same rule.
  static Future<void> syncBackgroundTask() async {
    final chain = await getChainNotifications();
    final social = await getSocialNotifications();
    if (chain || social) {
      await PublicOS.registerBackgroundSync();
    } else {
      await PublicOS.cancelBackgroundSync();
    }
  }

  /// Set background notifications setting (desktop / message background sync).
  /// Handles registering/cancelling background sync automatically.
  static Future<bool> setBackgroundNotifications(bool enabled) async {
    try {
      final record = Record.asSettings(
        key: 'background_notifications',
        value: enabled.toString(),
        isExpired: false,
        isSystem: true,
      );
      final success = await setSetting('background_notifications', record);

      // Handle background sync registration/cancellation
      if (success) {
        if (enabled) {
          await PublicOS.registerBackgroundSync();
        } else {
          await PublicOS.cancelBackgroundSync();
        }
      }

      return success;
    } catch (e) {
      Log.e(_tag, 'Error setting background notifications: $e');
      return false;
    }
  }
}
