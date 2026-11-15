import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart' show EthPrivateKey;
import 'package:xmtp_plugin/xmtp_plugin.dart';
import 'package:xmtp_plugin/codecs.dart';

import 'package:publicos_core/src/core/publicos_core.dart';
import 'package:publicos_core/src/core/extensions/publicos_activity.dart';
import 'package:publicos_core/src/core/extensions/publicos_conversations.dart';
import 'package:publicos_core/src/core/extensions/publicos_ssp.dart';
import 'package:publicos_core/src/models/activity_event.dart';
import 'package:publicos_core/src/models/social_notification.dart';
import 'package:publicos_core/src/utils/log.dart';
import 'package:publicos_core/src/utils/social_crypto.dart';

/// FCM/APNs push notification lifecycle and decryption.
///
/// Wraps the 5 push APIs added to `xmtp_plugin` 1.0.6:
///   - [registerWithNotifServer]      / DeleteInstallation
///   - [subscribeAllConversations]    / SubscribeWithMetadata
///   - [subscribeNewConversation]     / incremental SubscribeWithMetadata
///   - [unregister]                   / DeleteInstallation
///   - [handleIncomingPush]           / processPushMessage + processWelcome
///
/// Talks to our notification server deployed at
/// [_notifServerBase]. The server speaks Connect-RPC over HTTP/1.1; we hit it
/// with `Content-Type: application/json` requests, which the Connect server
/// accepts natively (no proto runtime needed in Dart).
///
/// Topic format throughout is the full XMTP wire form
/// (`/xmtp/mls/1/g-${hex}/proto`, `/xmtp/mls/1/w-${id}/proto`) — exactly what
/// FCM payloads carry and what `SubscribeWithMetadata` expects.
extension PublicOSPush on PublicOS {
  static const _tag = 'Push';

  /// The notification server endpoint. Fork-per-app pattern: ecosystem apps
  /// running their own client should swap this to their own deployment.
  static const _notifServerBase = 'https://push.publicos.dev';

  /// Connect-RPC service path prefix.
  static const _rpcPath = '/notifications.v1.Notifications';

  /// PAYLOAD_FORMAT_V3 from notifications/v1/service.proto. V3 is MLS.
  static const _payloadFormatV3 = 'PAYLOAD_FORMAT_V3';

  // ==========================================================================
  // REGISTRATION
  // ==========================================================================

  /// Register this installation with the notification server, binding our
  /// FCM token so push deliveries reach this device. Call on login (after
  /// XMTP client is initialized + FCM token is available) and again on
  /// `FirebaseMessaging.onTokenRefresh`.
  static Future<void> registerWithNotifServer({
    required String fcmToken,
  }) async {
    final installationId = await _installationId();
    if (installationId == null) return;

    final body = {
      'installationId': installationId,
      'deliveryMechanism': {
        'firebaseDeviceToken': fcmToken,
      },
      'payloadFormat': _payloadFormatV3,
    };

    try {
      final resp = await _post('/RegisterInstallation', body);
      Log.i(_tag, 'registerWithNotifServer OK installation=$installationId '
          'status=${resp.statusCode}');
    } catch (e) {
      Log.e(_tag, 'registerWithNotifServer failed: $e');
    }
  }

  /// Tear down the installation registration. Call on logout (adjacent to
  /// `PublicOS.reset()`).
  static Future<void> unregister() async {
    final installationId = await _installationId();
    if (installationId == null) return;

    try {
      final resp = await _post('/DeleteInstallation', {
        'installationId': installationId,
      });
      Log.i(_tag, 'unregister OK installation=$installationId '
          'status=${resp.statusCode}');
    } catch (e) {
      Log.e(_tag, 'unregister failed: $e');
    }
  }

  // ==========================================================================
  // SUBSCRIPTIONS
  // ==========================================================================

  /// Subscribe to push for every conversation the client knows about, plus
  /// the welcome topic. Call after [registerWithNotifServer] on login.
  ///
  /// Resilient to topic-set growth — re-callable as a "resync subscriptions"
  /// safety net (idempotent server-side).
  static Future<void> subscribeAllConversations() async {
    final installationId = await _installationId();
    if (installationId == null) return;
    final client = PublicOS.xmtpClient;
    if (client == null) {
      Log.w(_tag, 'subscribeAllConversations: xmtpClient is null');
      return;
    }

    try {
      final subs = await client.getAllPushTopics();
      final payload = {
        'installationId': installationId,
        'subscriptions': subs.map(_toSubscriptionJson).toList(),
      };
      final resp = await _post('/SubscribeWithMetadata', payload);
      Log.i(_tag, 'subscribeAllConversations OK ${subs.length} topics '
          'status=${resp.statusCode}');
    } catch (e) {
      Log.e(_tag, 'subscribeAllConversations failed: $e');
    }
  }

  /// The full wire form of a conversation topic; a topic already in it is
  /// returned unchanged.
  static String wireTopic(String topic) =>
      topic.startsWith('/xmtp/') ? topic : '/xmtp/mls/1/g-$topic/proto';

  /// Incrementally subscribe to push for one newly-created conversation.
  /// Saves a round-trip vs calling [subscribeAllConversations] every time.
  /// Call from the finalizer of every new-DM / new-group flow.
  ///
  /// [topic] may be the bare hex id (what the Rust path hands out) or already
  /// the wire form (what Android and iOS hand out). Wrapping it blindly
  /// would wrap the topic twice on the phones, match no key, and leave a new
  /// conversation without push until the next boot.
  static Future<void> subscribeNewConversation(String topic) async {
    topic = wireTopic(topic);
    final installationId = await _installationId();
    if (installationId == null) return;
    final client = PublicOS.xmtpClient;
    if (client == null) return;

    try {
      // Pull all HMAC keys then filter to this one topic (group_id-keyed
      // server-side; cheaper than chaining a new plugin API).
      final all = await client.getAllHmacKeys();
      final matched = all.where((e) => e.topic == topic).toList();
      if (matched.isEmpty) {
        Log.w(_tag, 'subscribeNewConversation: no HMAC keys for $topic');
        return;
      }
      final payload = {
        'installationId': installationId,
        'subscriptions': [
          {
            'topic': topic,
            'hmacKeys': matched
                .map((e) => {
                      'thirtyDayPeriodsSinceEpoch':
                          e.thirtyDayPeriodsSinceEpoch,
                      'key': base64.encode(e.hmacKey),
                    })
                .toList(),
            'isSilent': false,
          }
        ],
      };
      final resp = await _post('/SubscribeWithMetadata', payload);
      Log.i(_tag, 'subscribeNewConversation OK topic=$topic '
          'status=${resp.statusCode}');
    } catch (e) {
      Log.e(_tag, 'subscribeNewConversation failed: $e');
    }
  }

  // ==========================================================================
  // PUSH-ARRIVAL HANDLING
  // ==========================================================================

  /// Decrypt + render an incoming FCM push payload. Called from both the
  /// foreground `onMessage` handler and the background-isolate
  /// `onBackgroundMessage` handler in `publicos_client/main.dart`.
  ///
  /// `data` is the `RemoteMessage.data` map. Required keys: `topic`,
  /// `encryptedMessage` (base64). Optional: `messageType`, `payloadFormat`,
  /// `topicBytesB64`.
  ///
  /// In the background isolate, [PublicOS.xmtpClient] may not yet be
  /// initialized — caller is responsible for ensuring init (typically via
  /// the same path `executeBackgroundSync` already uses).
  static Future<void> handleIncomingPush(Map<String, dynamic> data) async {
    final client = PublicOS.xmtpClient;
    if (client == null) {
      Log.w(_tag, 'handleIncomingPush: xmtpClient is null, dropping push');
      return;
    }

    final topic = data['topic'] as String?;
    final encryptedB64 = data['encryptedMessage'] as String?;
    if (topic == null || encryptedB64 == null) {
      Log.w(_tag, 'handleIncomingPush: missing topic or encryptedMessage');
      return;
    }

    final Uint8List bytes;
    try {
      bytes = base64.decode(encryptedB64);
    } catch (e) {
      Log.e(_tag, 'handleIncomingPush: bad base64: $e');
      return;
    }

    try {
      final welcomeTopic = await client.getWelcomeTopic();
      if (topic == welcomeTopic) {
        await _handleWelcomePush(client, bytes);
      } else {
        await _handleConversationPush(client, topic, bytes);
      }
    } catch (e) {
      // A push for a chat this device has not pulled yet (typical right after a
      // reinstall or on a second device): pull the chat list once, then retry
      // the decrypt, so the notification shows the real sender and text
      // (not "You have a new request" on a plain DM).
      if (e.toString().contains('CONVERSATION_NOT_FOUND')) {
        try {
          await client
              .syncAll(consentStates: const ['allowed', 'unknown'])
              .timeout(const Duration(seconds: 15));
          await _handleConversationPush(client, topic, bytes);
          return;
        } catch (e2) {
          Log.e(_tag, 'handleIncomingPush retry after sync failed for topic=$topic: $e2');
        }
      } else {
        Log.e(_tag, 'handleIncomingPush failed for topic=$topic: $e');
      }
      // Last resort: a neutral line. It is a message we could not decrypt here,
      // not a "request" (that word means a message request in the inbox UI).
      await PublicOSConversations.showMessageNotification(
        senderName: 'PublicOS',
        messagePreview: 'New message',
        conversationTopic: topic,
      );
    }
  }

  static Future<void> _handleConversationPush(
    XmtpPlugin client,
    String topic,
    Uint8List bytes,
  ) async {
    final messages = await client.processPushMessage(topic, bytes);
    if (messages.isEmpty) {
      Log.i(_tag, 'processPushMessage returned 0 messages for $topic '
          '(commit-only?)');
      return;
    }
    for (final msg in messages) {
      await _renderMessage(topic, msg);
    }
  }

  static Future<void> _handleWelcomePush(
    XmtpPlugin client,
    Uint8List bytes,
  ) async {
    final convos = await client.processWelcome(bytes);
    if (convos.isEmpty) {
      Log.i(_tag, 'processWelcome returned 0 conversations');
      return;
    }
    for (final conv in convos) {
      // Brand-new conversation: subscribe to push for it now so future
      // messages flow through the same path without waiting for the next
      // resync.
      final topic = conv['topic'] as String?;
      if (topic != null) {
        // Fire-and-forget; don't block the welcome render on subscription.
        // (subscribeNewConversation puts the topic in wire form itself.)
        unawaited(subscribeNewConversation(topic));
      }
      // A brand-new conversation: the peer may already be a known contact
      // (resolve name + avatar via the shared resolver), but its group stub
      // doesn't exist yet — so for the group title prefer the name carried on
      // the welcome envelope (conv['name']) over the resolver's stub lookup.
      final peerInboxId = conv['peerInboxId'] as String?;
      final convName = conv['name'] as String?;
      String senderName;
      String? avatarUrl;
      if (peerInboxId != null) {
        final id = await PublicOSConversations.resolveNotificationIdentity(
          senderInboxId: peerInboxId,
          topic: topic ?? '',
        );
        senderName = id.name;
        avatarUrl = id.avatarUrl;
      } else {
        senderName = convName ?? 'Someone';
      }
      await PublicOSConversations.showMessageNotification(
        senderName: senderName,
        messagePreview: 'started a new conversation',
        conversationTopic: topic ?? '',
        avatarUrl: avatarUrl,
        groupName: convName,
        senderInboxId: peerInboxId,
      );
    }
  }

  static Future<void> _renderMessage(
    String topic,
    Map<String, dynamic> msg,
  ) async {
    final senderInboxId = msg['senderInboxId'] as String?;
    final body = msg['body'] as String?;
    final decodedContent = msg['decodedContent'];

    // Don't notify for content types that carry no user-visible message
    // (read receipts, group metadata updates) or for un-reactions — mirrors
    // the background sweep's filter (publicos_core.executeBackgroundSync).
    if (decodedContent is ReadReceipt || decodedContent is GroupUpdated) return;
    if (decodedContent is Reaction &&
        decodedContent.action == ReactionAction.removed) {
      return;
    }

    // For reactions, resolve the parent-message preview so the body reads
    // "reacted ❤️ to '<snippet>'" instead of dumping the raw reaction payload.
    // Safe in the background isolate: previewForReactedMessage returns null
    // when the session globals / local DB aren't available.
    String? reactionParentPreview;
    if (decodedContent is Reaction) {
      try {
        reactionParentPreview =
            await PublicOSConversations.previewForReactedMessage(
          decodedContent.reference,
        );
      } catch (_) {}
    }

    // Build the preview from the decoded content (never the raw native `body`,
    // which is unreliable for non-text types). Fall back to `body` only when the
    // formatter produced nothing.
    final preview = PublicOSConversations.formatMessagePreview(
      body,
      decodedContent,
      reactionParentPreview: reactionParentPreview,
    );
    final messagePreview = preview.isNotEmpty ? preview : (body ?? '(empty)');

    if (senderInboxId == null) {
      await PublicOSConversations.showMessageNotification(
        senderName: 'Someone',
        messagePreview: messagePreview,
        conversationTopic: topic,
      );
      return;
    }

    // Resolve sender name + avatar + group name from the local DB via the
    // shared resolver — the same path the 15-min sweep uses — so the fast
    // direct-decrypt render matches it instead of falling back to a truncated
    // inbox ID. (isGroup omitted → resolver infers from group-stub existence.)
    final id = await PublicOSConversations.resolveNotificationIdentity(
      senderInboxId: senderInboxId,
      topic: topic,
    );

    await PublicOSConversations.showMessageNotification(
      senderName: id.name,
      messagePreview: messagePreview,
      conversationTopic: topic,
      avatarUrl: id.avatarUrl,
      groupName: id.groupName,
      senderInboxId: senderInboxId,
    );
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  static Future<String?> _installationId() async {
    final client = PublicOS.xmtpClient;
    if (client == null) {
      Log.w(_tag, 'no xmtpClient — cannot derive installation id');
      return null;
    }
    try {
      return await client.getInstallationId();
    } catch (e) {
      Log.e(_tag, 'getInstallationId failed: $e');
      return null;
    }
  }

  static Map<String, dynamic> _toSubscriptionJson(PushSubscription sub) {
    return {
      'topic': sub.topic,
      'hmacKeys': sub.hmacKeys
          .map((k) => {
                'thirtyDayPeriodsSinceEpoch': k.thirtyDayPeriodsSinceEpoch,
                'key': base64.encode(k.key),
              })
          .toList(),
      'isSilent': false,
    };
  }

  static Future<http.Response> _post(
    String methodPath,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('$_notifServerBase$_rpcPath$methodPath');
    final resp = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode >= 400) {
      throw Exception(
          'notif server $methodPath returned ${resp.statusCode}: ${resp.body}');
    }
    return resp;
  }

  // ==========================================================================
  // SOCIAL NOTIFICATIONS
  //
  // A reply, a comment, a mention, a reaction or a follow request on any
  // registered SSP lands in the account's inbox on its HOME SSP, which pushes
  // to every "deliver me here" target. The official gateway is this same
  // server, as a second, BLIND process: it sees a handle, a throwaway key and
  // ciphertext, never an account. The verbs below are the home half (signed
  // by the session key, through PublicOSSsp) and the gateway half (signed by
  // the device's throwaway key R, never the session).
  // ==========================================================================

  /// The official gateway: the social process of our push server. Fork-per-app
  /// like [_notifServerBase]; a third-party app points at its own.
  static const officialGateway = _notifServerBase;

  static const _socialKsPrefix = 'social_ks_'; // + session address → base64 K_s
  static const _socialRPrefix = 'social_r_'; // + session address → hex R

  /// This device's social keys, minted once per session and kept in secure
  /// storage: K_s (the blob key the home seals with) and R (the throwaway
  /// signer the gateway sees). On iOS the app mirrors K_s into the App Group
  /// keychain so the notification extension can open blobs (client side).
  static Future<({Uint8List ks, EthPrivateKey r})?> socialDeviceKeys(
      {bool mint = true}) async {
    final session = PublicOS.sessionBlockchainAddress;
    if (session == null) return null;
    const storage = FlutterSecureStorage();
    final ksB64 = await storage.read(key: '$_socialKsPrefix$session');
    final rHex = await storage.read(key: '$_socialRPrefix$session');
    if (ksB64 != null && rHex != null) {
      return (ks: base64Decode(ksB64), r: EthPrivateKey.fromHex(rHex));
    }
    if (!mint) return null;
    final ks = SocialCrypto.newKey();
    final r = SocialCrypto.newThrowawayKey();
    await storage.write(key: '$_socialKsPrefix$session', value: base64Encode(ks));
    await storage.write(
        key: '$_socialRPrefix$session', value: r.privateKeyInt.toRadixString(16).padLeft(64, '0'));
    Log.i(_tag, 'social device keys minted for session $session');
    return (ks: ks, r: r);
  }

  /// The secure-storage key the app mirrors into the iOS App Group keychain
  /// for the extension (value: base64 K_s).
  static String socialKsStorageKey(String session) => '$_socialKsPrefix$session';

  /// Drop this device's social keys (account removal). The home's device row
  /// and the gateway's registration die with the next refresh they never get.
  static Future<void> forgetSocialDeviceKeys() async {
    final session = PublicOS.sessionBlockchainAddress;
    if (session == null) return;
    const storage = FlutterSecureStorage();
    await storage.delete(key: '$_socialKsPrefix$session');
    await storage.delete(key: '$_socialRPrefix$session');
  }

  static String get _me {
    final me = PublicOS.myPublicosAddress;
    if (me == null) throw Exception('no account loaded');
    return me;
  }

  // ---- the home half: signed by the session key, owner-only, no SSP gate ----

  /// GET /api/{me}/notifications?after=&limit= — items ascending by seq after
  /// the cursor; the server's `next` is the last seq returned. [serverAddress]
  /// lets the background worker pass the home it resolved.
  static Future<({List<SocialNotification> items, int next})> listNotifications({
    int after = 0,
    int limit = 50,
    String? serverAddress,
  }) async {
    final r = await PublicOSSsp.signedRequest(
      method: 'GET',
      action: 'list_notifications',
      endpoint: '/api/$_me/notifications?after=$after&limit=$limit',
      serverAddress: serverAddress,
    );
    if (r.statusCode != 200) {
      throw Exception('list_notifications ${r.statusCode}: ${r.body}');
    }
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    return (
      items: SocialNotification.listFromJson(j['items']),
      next: (j['next'] as num?)?.toInt() ?? after,
    );
  }

  /// POST /api/{me}/notifications/read {up_to}: the server-side read marker,
  /// so every app agrees on what is read. Best effort.
  static Future<void> markNotificationsRead(int upToSeq) async {
    try {
      await PublicOSSsp.signedRequest(
        method: 'POST',
        action: 'read_notifications',
        endpoint: '/api/$_me/notifications/read',
        data: {'up_to': upToSeq},
      );
    } catch (e) {
      Log.w(_tag, 'markNotificationsRead failed: $e');
    }
  }

  /// GET /api/{me}/notif_targets: the "deliver me here" list. The official
  /// entry always exists. For every target this device is registered on the
  /// server repeats a fresh ticket: this is the boot refresh.
  static Future<List<NotifTarget>> listNotifTargets() async {
    final r = await PublicOSSsp.signedRequest(
      method: 'GET',
      action: 'list_notif_targets',
      endpoint: '/api/$_me/notif_targets',
    );
    if (r.statusCode != 200) {
      throw Exception('list_notif_targets ${r.statusCode}: ${r.body}');
    }
    return NotifTarget.listFromJson(
        (jsonDecode(r.body) as Map<String, dynamic>)['targets']);
  }

  /// PUT /api/{me}/notif_targets: find-or-create by gateway (the handle is
  /// minted once), update label / enabled / kinds. With [registerDevice] the
  /// call carries this device's K_s + R_pub, so the answer carries its ticket
  /// (403 DOMAIN_NOT_PAID when the domain lapsed).
  static Future<NotifTarget> putNotifTarget({
    String gateway = officialGateway,
    String? label,
    bool? enabled,
    Map<String, bool>? kinds,
    bool registerDevice = true,
  }) async {
    final data = <String, dynamic>{'gateway': gateway};
    if (label != null) data['label'] = label;
    if (enabled != null) data['enabled'] = enabled;
    if (kinds != null) data['kinds'] = kinds;
    if (registerDevice) {
      final keys = await socialDeviceKeys();
      if (keys == null) throw Exception('no session for social keys');
      data['k_s'] = base64Encode(keys.ks);
      data['r_pub'] = keys.r.address.eip55With0x;
    }
    final r = await PublicOSSsp.signedRequest(
      method: 'PUT',
      action: 'put_notif_target',
      endpoint: '/api/$_me/notif_targets',
      data: data,
    );
    if (r.statusCode != 200) {
      throw Exception('put_notif_target ${r.statusCode}: ${r.body}');
    }
    return NotifTarget.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  /// DELETE /api/{me}/notif_targets/{id}. The official entry answers 409:
  /// switch it off instead.
  static Future<void> deleteNotifTarget(String id) async {
    final r = await PublicOSSsp.signedRequest(
      method: 'DELETE',
      action: 'delete_notif_target',
      endpoint: '/api/$_me/notif_targets/$id',
    );
    if (r.statusCode != 200) {
      throw Exception('delete_notif_target ${r.statusCode}: ${r.body}');
    }
  }

  // ---- the gateway half: signed by R, never the session ----

  /// Bind this device's SOCIAL token (the second Firebase app's) to the
  /// handle, at [gateway], with the home's [ticket]. The envelope is signed by
  /// R: the gateway verifies the ticket against the home's notif_key on chain
  /// and never resolves a session. Call after [putNotifTarget], at every boot
  /// (that boot call IS the ticket refresh) and on token refresh. Returns the
  /// gateway's row expiry (unix seconds) or null on failure (logged).
  static Future<int?> registerSocialHandle({
    required String handle,
    required String socialToken,
    required NotifTicket ticket,
    String gateway = officialGateway,
  }) async {
    final keys = await socialDeviceKeys(mint: false);
    if (keys == null) {
      Log.w(_tag, 'registerSocialHandle: no device keys');
      return null;
    }
    final endpoint = '$gateway/social/register';
    final body = SocialCrypto.envelopeSignedBy(
      keys.r,
      action: 'social_register',
      target: PublicOSSsp.computeTarget('POST', endpoint),
      nonce: PublicOSSsp.generateNonce(),
      data: {'handle': handle, 'token': socialToken, 'kind': 'fcm', 'ticket': ticket.toJson()},
    );
    try {
      final resp = await http
          .post(Uri.parse(endpoint),
              headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        Log.w(_tag, 'social register ${resp.statusCode}: ${resp.body}');
        return null;
      }
      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      Log.i(_tag, 'social register OK handle=${handle.substring(0, 8)}…');
      return (j['exp'] as num?)?.toInt();
    } catch (e) {
      Log.e(_tag, 'social register failed: $e');
      return null;
    }
  }

  /// DELETE {gateway}/social/register: drop this device's token behind the
  /// handle (the push toggle, account removal). Signed by R.
  static Future<void> unregisterSocialHandle({
    required String handle,
    required String socialToken,
    String gateway = officialGateway,
  }) async {
    final keys = await socialDeviceKeys(mint: false);
    if (keys == null) return;
    final endpoint = '$gateway/social/register';
    final body = SocialCrypto.envelopeSignedBy(
      keys.r,
      action: 'social_unregister',
      target: PublicOSSsp.computeTarget('DELETE', endpoint),
      nonce: PublicOSSsp.generateNonce(),
      data: {'handle': handle, 'token': socialToken},
    );
    try {
      final req = http.Request('DELETE', Uri.parse(endpoint))
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);
      final resp = await http.Response.fromStream(
          await req.send().timeout(const Duration(seconds: 15)));
      Log.i(_tag, 'social unregister ${resp.statusCode}');
    } catch (e) {
      Log.e(_tag, 'social unregister failed: $e');
    }
  }

  // ---- the device: open the blob, store the row ----

  /// Open a social push (`{type: social, id, handle, blob}`) with this
  /// device's K_s. Null when the key is missing (a reinstall: the OS already
  /// showed the placeholder) or the blob does not open.
  static Future<Map<String, dynamic>?> openSocialPush(Map<String, dynamic> data) async {
    final blob = data['blob'] as String?;
    final id = data['id'] as String?;
    if (blob == null || id == null) return null;
    final keys = await socialDeviceKeys(mint: false);
    if (keys == null) {
      Log.w(_tag, 'openSocialPush: no K_s on this device');
      return null;
    }
    try {
      final fields = SocialCrypto.openBlobJson(keys.ks, blob);
      fields['id'] = id;
      return fields;
    } catch (e) {
      Log.e(_tag, 'openSocialPush: blob did not open: $e');
      return null;
    }
  }

  /// Open a social push and store it as an activity row, idempotent on the
  /// notification id. Returns the event when it was new (the caller pops the
  /// notification), null when already stored or unreadable. The 15-min pull
  /// stores the same rows through [PublicOSActivity.storeIfNew], so a push
  /// and a pull never show one event twice.
  static Future<ActivityEvent?> storeSocialPush(Map<String, dynamic> data) async {
    final fields = await openSocialPush(data);
    if (fields == null || fields['kind'] == null || fields['actor'] == null) {
      return null;
    }
    final ev = ActivityEvent.social(fields);
    final inserted = await PublicOSActivity.storeIfNew(ev);
    return inserted ? ev : null;
  }
}
