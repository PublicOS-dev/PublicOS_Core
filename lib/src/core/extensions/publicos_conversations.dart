import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform;
import 'dart:typed_data';
import 'package:crypto/crypto.dart' show sha256;
import 'package:drift/drift.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide Message;
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln show Message;
import 'package:zero_cached_image/zero_cached_image.dart' show ZeroCacheManager;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xmtp_plugin/codecs.dart';
import 'package:publicos_core/src/core/core.dart';
import 'package:publicos_core/src/core/publicos_core.dart';
import 'package:publicos_core/src/database/database.dart' as db;
import 'package:publicos_core/src/database/helpers.dart';
import 'package:publicos_core/src/models/contact.dart';
import 'package:publicos_core/src/models/member.dart';
import 'package:publicos_core/src/models/message.dart';
import 'package:publicos_core/src/models/xmtp_conversation.dart';
import 'package:publicos_core/src/utils/log.dart';

/// XMTP conversation + message management.
///
/// After the 1.0 consolidation, this single extension owns everything that
/// touches XMTP channels (DMs + groups) and the messages flowing through
/// them: list/create/save/delete conversations, send/receive messages,
/// group management, drafts, notifications, and remote attachment
/// encryption. The message stream subscription lives here too.
///
/// Low-level XMTP client / inbox-ID operations (chain registration,
/// installations, account management) stay in `publicos_xmtp.dart`.
///
/// The view layer is responsible for populating `conversation.contact` by
/// calling `PublicOSContacts.findContactByInboxId(conv.peerInboxId)` for
/// DMs. Group member display is per-message: render-time lookup of the
/// sender's inbox ID via `findContactByInboxId`.
extension PublicOSConversations on PublicOS {
  static const _tag = 'Conversations';

  // ==========================================================================
  // CONVERSATION STORE
  // ==========================================================================

  /// Fetch all conversations (DMs + groups) from XMTP, sync them to the
  /// local DB, return the merged list. Chat list's entry point.
  /// Requires `xmtpConnected`. Does NOT resolve peer contacts — the view
  /// layer handles that by calling `PublicOSContacts.findContactByInboxId`.
  static Future<List<XmtpConversation>> getConversations({
    String? consentState,
  }) async {
    if (!PublicOS.xmtpConnected || PublicOS.xmtpClient == null) {
      Log.w(_tag, 'Cannot list conversations: XMTP not initialized');
      return [];
    }
    if (PublicOS.sessionBlockchainAddress == null) return [];

    final sw = Stopwatch()..start();
    try {
      final dms = await PublicOS.xmtpClient!.listDms(consentState: consentState);
      final groups = await PublicOS.xmtpClient!.listGroups(consentState: consentState);

      final conversations = <XmtpConversation>[];

      // DMs
      for (final raw in dms) {
        try {
          final topic = raw['topic'] as String?;
          final peerInboxId = raw['peerInboxId'] as String?;
          if (topic == null || peerInboxId == null) continue;

          final conv = XmtpConversation(
            topic: topic,
            type: ConversationType.dm,
            peerInboxId: peerInboxId,
          );
          await saveConversation(conv);
          conversations.add(conv);
        } catch (e) {
          Log.e(_tag, '[LIST] DM parse error: $e');
        }
      }

      // Groups
      for (final raw in groups) {
        try {
          final topic = raw['topic'] as String?;
          if (topic == null) continue;

          List<Member>? members;
          if (raw['membersContacts'] != null) {
            members = (raw['membersContacts'] as List).map((m) {
              return Member(
                inboxId: m['inboxId'] as String,
                addresses: (m['addresses'] as List).cast<String>(),
              );
            }).toList();
          }

          final conv = XmtpConversation(
            topic: topic,
            type: ConversationType.group,
            groupName: raw['name'] as String?,
            groupImageUrl: raw['imageUrlSquare'] as String?,
            groupDescription: raw['description'] as String?,
            pinnedFrameUrl: raw['pinnedFrameUrl'] as String?,
            members: members,
            createdAt: raw['createdAtNs'] is int
                ? DateTime.fromMicrosecondsSinceEpoch(
                    (raw['createdAtNs'] as int) ~/ 1000)
                : null,
          );
          await saveConversation(conv);
          // Ensure a group-stub Contact exists so the Browser / ContactIcon
          // can render the group as a familiar contact row. Idempotent.
          await PublicOSContacts.ensureGroupStub(
            topic: conv.topic,
            groupName: conv.groupName ?? 'Unnamed Group',
            groupImageUrl: conv.groupImageUrl,
          );
          conversations.add(conv);
        } catch (e) {
          Log.e(_tag, '[LIST] Group parse error: $e');
        }
      }

      sw.stop();
      Log.i(
          _tag,
          '[LIST] ${conversations.length} conversations '
          '(${dms.length} DMs, ${groups.length} groups) in ${sw.elapsedMilliseconds}ms');

      return conversations;
    } catch (e) {
      Log.e(_tag, '[LIST] Error: $e');
      return [];
    }
  }

  /// Get a conversation by topic: the stored row, or, when there is none,
  /// the conversation as the XMTP client knows it (saved on the way).
  ///
  /// The second step is what a notification tap on a brand-new conversation
  /// needs: the welcome push puts the conversation in the XMTP client's own
  /// database and shows the popup, but nothing has written our row yet (the
  /// chat list does that when it loads). Without it the Browser has no peer
  /// to open and says "contact not found".
  static Future<XmtpConversation?> getConversation(String topic) async {
    if (PublicOS.sessionBlockchainAddress == null ||
        PublicOS.clientXmtpInboxId == null) return null;
    try {
      var row = await _storedRow(topic);
      if (row == null && PublicOS.xmtpConnected && PublicOS.xmtpClient != null) {
        // What the client already holds (a local read; saves every row).
        await getConversations();
        row = await _storedRow(topic);
        if (row == null) {
          // Not delivered to this device yet: pull once from the network.
          await PublicOS.xmtpClient!
              .syncAll(consentStates: const ['allowed', 'unknown'])
              .timeout(const Duration(seconds: 15));
          await getConversations();
          row = await _storedRow(topic);
        }
        Log.i(_tag, '[GET] no stored row for the topic; '
            '${row == null ? 'the XMTP client has none either' : 'taken from the XMTP client'}');
      }
      if (row == null) return null;
      return DatabaseHelpers.conversationFromRow(row);
    } catch (e) {
      Log.e(_tag, '[GET] Error: $e');
      return null;
    }
  }

  static Future<db.Conversation?> _storedRow(String topic) =>
      PublicOS.database.getConversationByTopic(
        topic,
        PublicOS.sessionBlockchainAddress!,
        PublicOS.clientXmtpInboxId!,
      );

  /// Get a stored DM conversation by peer inbox ID.
  /// Used by the contact profile view to check if a DM already exists
  /// for a given inbox tab.
  static Future<XmtpConversation?> getConversationByPeerInboxId(
    String peerInboxId,
  ) async {
    if (PublicOS.sessionBlockchainAddress == null ||
        PublicOS.clientXmtpInboxId == null) return null;
    try {
      final row = await PublicOS.database.getConversationByPeerInboxId(
        peerInboxId,
        PublicOS.sessionBlockchainAddress!,
        PublicOS.clientXmtpInboxId!,
      );
      if (row == null) return null;
      return DatabaseHelpers.conversationFromRow(row);
    } catch (e) {
      Log.e(_tag, '[GET_BY_PEER] Error: $e');
      return null;
    }
  }

  /// Get all stored conversations for the current session (DB only, no XMTP sync).
  static Future<List<XmtpConversation>> getStoredConversations() async {
    if (PublicOS.sessionBlockchainAddress == null ||
        PublicOS.clientXmtpInboxId == null) return [];
    try {
      final rows = await PublicOS.database.getConversationsForSession(
        PublicOS.sessionBlockchainAddress!,
        PublicOS.clientXmtpInboxId!,
      );
      return rows.map(DatabaseHelpers.conversationFromRow).toList();
    } catch (e) {
      Log.e(_tag, '[STORED] Error: $e');
      return [];
    }
  }

  /// Find or create a DM conversation for the given peer inbox ID.
  /// Returns a persisted `XmtpConversation`. Requires `xmtpConnected`.
  static Future<XmtpConversation> ensureConversation(String peerInboxId) async {
    if (!PublicOS.xmtpConnected || PublicOS.xmtpClient == null) {
      throw StateError('Cannot create conversation: XMTP not initialized');
    }
    if (PublicOS.sessionBlockchainAddress == null) {
      throw StateError('Cannot create conversation: no active session');
    }

    // 1. Check for existing conversation by peer inbox id
    final existing = await getConversationByPeerInboxId(peerInboxId);
    if (existing != null) return existing;

    // 2. Create on XMTP
    final dmData = await PublicOS.xmtpClient!.findOrCreateDMWithInboxId(peerInboxId);
    final topic = dmData['topic'] as String?;
    if (topic == null || topic.isEmpty) {
      throw Exception('XMTP returned no topic for inbox $peerInboxId');
    }

    // 3. Persist
    final conversation = XmtpConversation(
      topic: topic,
      type: ConversationType.dm,
      peerInboxId: peerInboxId,
      createdAt: DateTime.now(),
    );
    await saveConversation(conversation);
    // Register the new DM's topic with the notif server so push arrives
    // without waiting for next app boot's subscribeAll. Plugin returns
    // raw-hex topic; push API wants full XMTP wire. Fire-and-forget.
    unawaited(PublicOSPush.subscribeNewConversation(topic));
    Log.i(
        _tag,
        '[ENSURE] Created DM for $peerInboxId → '
        'topic=${topic.substring(0, topic.length > 16 ? 16 : topic.length)}...');
    return conversation;
  }

  /// Heal a stale DM topic onto the live one. Send is find-or-create, so the
  /// topic a send returns is authoritative; this re-points local state when the
  /// cached topic is dead (post-reset / duplicate-DM):
  ///   1. migrate every stored message oldTopic → newTopic
  ///   2. drop the stale conversation row, upsert the live one
  ///   3. allow the live conversation (mirrors first-send auto-allow), which
  ///      also clears the consent banner the dead topic could never clear.
  static Future<void> _healDmTopic({
    required String oldTopic,
    required String newTopic,
    required String peerInboxId,
  }) async {
    if (PublicOS.sessionBlockchainAddress == null ||
        PublicOS.clientXmtpInboxId == null) return;
    try {
      final session = PublicOS.sessionBlockchainAddress!;
      final owner = PublicOS.clientXmtpInboxId!;

      final moved = await PublicOS.database
          .migrateConversationTopic(oldTopic, newTopic, session, owner);

      await PublicOS.database.deleteConversationByTopic(oldTopic, session, owner);
      await saveConversation(XmtpConversation(
        topic: newTopic,
        type: ConversationType.dm,
        peerInboxId: peerInboxId,
        createdAt: DateTime.now(),
      ));

      // Mirror what a first send does: auto-allow. Targets the LIVE topic now,
      // so it succeeds where the dead topic raised CONVERSATION_NOT_FOUND.
      try {
        await PublicOS.xmtpClient!
            .setConversationConsentState(newTopic, 'allowed');
      } catch (e) {
        Log.w(_tag, '[HEAL] consent allow failed (non-fatal): $e');
      }

      if (activeConversationTopic == oldTopic) {
        activeConversationTopic = newTopic;
      }

      Log.i(_tag,
          '[HEAL] DM topic migrated: $moved msg(s) re-pointed to live topic');
    } catch (e) {
      Log.e(_tag, '[HEAL] Error migrating DM topic: $e');
    }
  }

  /// Persist a conversation to the local DB.
  static Future<void> saveConversation(XmtpConversation conversation) async {
    if (PublicOS.sessionBlockchainAddress == null ||
        PublicOS.clientXmtpInboxId == null) return;
    try {
      final companion = DatabaseHelpers.conversationToCompanion(
        conversation,
        PublicOS.sessionBlockchainAddress!,
        PublicOS.clientXmtpInboxId!,
      );
      await PublicOS.database.upsertConversation(companion);
    } catch (e) {
      Log.e(_tag, '[SAVE] Error: $e');
      rethrow;
    }
  }

  /// Update local group metadata. Network-side updates are a separate
  /// call to [updateGroup].
  static Future<void> updateGroupMetadata(
    String topic, {
    String? groupName,
    String? groupImageUrl,
    String? groupDescription,
    String? pinnedFrameUrl,
  }) async {
    final existing = await getConversation(topic);
    if (existing == null || existing.type != ConversationType.group) return;

    final updated = existing.copyWith(
      groupName: groupName ?? existing.groupName,
      groupImageUrl: groupImageUrl ?? existing.groupImageUrl,
      groupDescription: groupDescription ?? existing.groupDescription,
      pinnedFrameUrl: pinnedFrameUrl ?? existing.pinnedFrameUrl,
    );
    await saveConversation(updated);
  }

  /// Delete a conversation from the local DB. Does not affect XMTP network
  /// state — XMTP conversations can't be deleted, only removed from view.
  static Future<void> deleteConversation(String topic) async {
    if (PublicOS.sessionBlockchainAddress == null ||
        PublicOS.clientXmtpInboxId == null) return;
    try {
      await PublicOS.database.deleteConversationByTopic(
        topic,
        PublicOS.sessionBlockchainAddress!,
        PublicOS.clientXmtpInboxId!,
      );
    } catch (e) {
      Log.e(_tag, '[DELETE] Error: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // XMTP SYNC (conversation-scoped)
  // ==========================================================================

  /// Sync all XMTP conversations from the network. Call on startup /
  /// pull-to-refresh. Defaults to filtering by `['allowed']` consent.
  static Future<Map<String, int>> syncAll({
    List<String> consentStates = const ['allowed'],
  }) async {
    if (PublicOS.xmtpClient == null) return {'numGroupsSynced': 0};
    try {
      final result = await PublicOS.xmtpClient!.syncAll(consentStates: consentStates);
      Log.i(_tag, '[SYNC] syncAll complete — ${result['numGroupsSynced']}');
      return result;
    } catch (e) {
      Log.e(_tag, '[SYNC] syncAll failed: $e');
      return {'numGroupsSynced': 0};
    }
  }

  /// Sync a single conversation by topic. Call when entering the chat view.
  static Future<void> syncConversation(String topic) async {
    if (PublicOS.xmtpClient == null) return;
    try {
      await PublicOS.xmtpClient!.syncConversation(topic);
    } catch (e) {
      Log.e(_tag, '[SYNC] syncConversation($topic) failed: $e');
    }
  }

  // ==========================================================================
  // STREAM LIFECYCLE
  // ==========================================================================

  static bool _isStreamInitialized = false;

  /// Conversation topic the user is currently viewing. The chat screen sets
  /// this on open and clears it on dispose. Listeners skip incrementing
  /// unread count when a message matches this value.
  static String? activeConversationTopic;

  // Reconnect state
  static int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const List<Duration> _reconnectDelays = [
    Duration(seconds: 1),
    Duration(seconds: 3),
    Duration(seconds: 8),
    Duration(seconds: 20),
    Duration(seconds: 45),
  ];
  static Timer? _reconnectTimer;
  static DateTime? _lastStreamEventTime;

  static final _streamStatusController = StreamController<bool>.broadcast();

  /// Stream status for consumers (true = connected, false = disconnected/reconnecting).
  static Stream<bool> get streamStatus => _streamStatusController.stream;

  /// Whether the incoming-message subscription is active.
  static bool get isStreamActive =>
      _isStreamInitialized && PublicOS.xmtpSubscription != null;

  /// Initialize the incoming-message subscription. Idempotent — calling
  /// again disposes the previous stream first.
  static Future<void> initializeMessages() async {
    if (!PublicOS.isAuthenticated || PublicOS.sessionBlockchainAddress == null) {
      throw Exception('Authentication and session address required');
    }
    if (PublicOS.xmtpClient == null) {
      throw Exception('XMTP client not initialized — call initXMTP() first');
    }

    Log.i(_tag, 'Initializing message stream...');
    if (_isStreamInitialized) {
      await disposeMessages();
    }

    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    await _subscribeToMessages();
    _isStreamInitialized = true;
    Log.i(_tag, 'Message stream initialized');
  }

  /// Dispose the incoming-message subscription. Safe to call when
  /// switching accounts or logging out.
  static Future<void> disposeMessages() async {
    Log.i(_tag, 'Disposing message stream');
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    await PublicOS.xmtpSubscription?.cancel();
    PublicOS.xmtpSubscription = null;
    // Also stop the NATIVE stream loop. On Android/iOS the Dart-subscription
    // cancel above does NOT reach the native coroutine/Task — without this the
    // stream keeps running after every account switch / logout (a leak), and a
    // local libxmtp op (archive import) can be starved by it on the shared
    // single tokio runtime. No-op on Windows/Web (Dart cancel already stops it).
    await PublicOS.xmtpClient?.stopMessageStream();
    _isStreamInitialized = false;
    _streamStatusController.add(false);
  }

  static Future<void> _subscribeToMessages() async {
    await PublicOS.xmtpSubscription?.cancel();
    PublicOS.xmtpSubscription = null;
    _reconnectTimer?.cancel();

    Log.i(_tag, 'Setting up new XMTP subscription');

    PublicOS.xmtpSubscription =
        PublicOS.xmtpClient!.subscribeToAllMessages().listen(
      (xmtpMessage) async {
        _lastStreamEventTime = DateTime.now();
        _reconnectAttempts = 0;

        if (PublicOS.isSending) {
          // Send in progress — buffer until send completes
          final idx = PublicOS.messageCache
              .indexWhere((m) => m['id'] == xmtpMessage['id']);
          if (idx != -1) {
            PublicOS.messageCache[idx] = xmtpMessage;
          } else {
            PublicOS.messageCache.add(xmtpMessage);
          }
          return;
        }

        await _processIncomingMessage(xmtpMessage, true);
      },
      onError: (error) {
        Log.e(_tag, 'XMTP subscription error: $error');
        _streamStatusController.add(false);
        _scheduleReconnect();
      },
      onDone: () {
        Log.w(_tag, 'XMTP subscription stream closed');
        PublicOS.xmtpSubscription = null;
        _streamStatusController.add(false);
        _scheduleReconnect();
      },
    );

    _streamStatusController.add(true);
  }

  static void _scheduleReconnect() {
    if (!_isStreamInitialized) return;
    if (!PublicOS.isAuthenticated) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      Log.w(
          _tag,
          'Max reconnect attempts ($_maxReconnectAttempts) reached. '
          'Call initializeMessages() to retry manually.');
      return;
    }

    _reconnectTimer?.cancel();
    final delay = _reconnectDelays[_reconnectAttempts];
    _reconnectAttempts++;

    Log.i(
        _tag,
        'Reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts '
        'in ${delay.inSeconds}s');

    _reconnectTimer = Timer(delay, () async {
      if (!_isStreamInitialized || !PublicOS.isAuthenticated) return;
      try {
        await _subscribeToMessages();
        if (_lastStreamEventTime != null) {
          try {
            await PublicOS.xmtpClient!.syncAll();
          } catch (e) {
            Log.w(_tag, 'Post-reconnect sync failed: $e');
          }
        }
        _reconnectAttempts = 0;
        Log.i(_tag, 'Reconnected successfully');
      } catch (e) {
        Log.e(_tag, 'Reconnect attempt failed: $e');
        _scheduleReconnect();
      }
    });
  }

  // ==========================================================================
  // JSON SERIALIZATION (XMTP message maps)
  // ==========================================================================

  static String _jsonEncodeXmtpMessage(Map<String, dynamic> xmtpMessage) {
    return json.encode(xmtpMessage, toEncodable: (obj) {
      if (obj is Reply) return {'__type': 'Reply', ...obj.toJson()};
      if (obj is Reaction) return {'__type': 'Reaction', ...obj.toJson()};
      if (obj is AttachmentContent) {
        return {'__type': 'AttachmentContent', ...obj.toJson()};
      }
      if (obj is RemoteAttachmentContent) {
        return {'__type': 'RemoteAttachmentContent', ...obj.toJson()};
      }
      if (obj is MultiRemoteAttachmentContent) {
        return {'__type': 'MultiRemoteAttachmentContent', ...obj.toJson()};
      }
      if (obj is GroupUpdated) {
        return {'__type': 'GroupUpdated', 'data': base64Encode(obj.writeToBuffer())};
      }
      if (obj is ReadReceipt) return {'__type': 'ReadReceipt'};
      if (obj is ActionsContent) {
        return {'__type': 'ActionsContent', ...obj.toJson()};
      }
      if (obj is IntentContent) {
        return {'__type': 'IntentContent', ...obj.toJson()};
      }
      if (obj is TransactionReference) {
        return {'__type': 'TransactionReference', ...obj.toJson()};
      }
      if (obj is WalletSendCalls) {
        return {'__type': 'WalletSendCalls', ...obj.toJson()};
      }
      if (obj is Uint8List) {
        return {'__type': 'Uint8List', 'data': base64Encode(obj)};
      }
      return obj;
    });
  }

  static Map<String, dynamic> _jsonDecodeXmtpMessage(String jsonString) {
    final decoded = json.decode(jsonString) as Map<String, dynamic>;
    return _reconstructContent(decoded);
  }

  static Map<String, dynamic> _reconstructContent(Map<String, dynamic> map) {
    return map.map((key, value) {
      if (value is Map && value['__type'] != null) {
        switch (value['__type']) {
          case 'Reply':
            return MapEntry(
                key, Reply.fromJson(Map<String, dynamic>.from(value)));
          case 'Reaction':
            return MapEntry(
                key, Reaction.fromJson(Map<String, dynamic>.from(value)));
          case 'AttachmentContent':
            return MapEntry(
                key,
                AttachmentContent.fromJson(Map<String, dynamic>.from(value)));
          case 'RemoteAttachmentContent':
            return MapEntry(
                key,
                RemoteAttachmentContent.fromJson(
                    Map<String, dynamic>.from(value)));
          case 'MultiRemoteAttachmentContent':
            return MapEntry(
                key,
                MultiRemoteAttachmentContent.fromJson(
                    Map<String, dynamic>.from(value)));
          case 'GroupUpdated':
            return MapEntry(
                key, GroupUpdated.fromBuffer(base64Decode(value['data'])));
          case 'ReadReceipt':
            return MapEntry(key, const ReadReceipt());
          case 'ActionsContent':
            return MapEntry(key,
                ActionsContent.fromJson(Map<String, dynamic>.from(value)));
          case 'IntentContent':
            return MapEntry(
                key, IntentContent.fromJson(Map<String, dynamic>.from(value)));
          case 'TransactionReference':
            return MapEntry(
                key,
                TransactionReference.fromJson(
                    Map<String, dynamic>.from(value)));
          case 'WalletSendCalls':
            return MapEntry(
                key,
                WalletSendCalls.fromJson(Map<String, dynamic>.from(value)));
          case 'Uint8List':
            return MapEntry(key, base64Decode(value['data']));
        }
      }
      if (value is Map) {
        return MapEntry(
            key, _reconstructContent(Map<String, dynamic>.from(value)));
      }
      return MapEntry(key, value);
    });
  }

  static String _extractTypeId(dynamic decodedContent) {
    if (decodedContent is String) return 'text';
    if (decodedContent is Reply) return 'reply';
    if (decodedContent is Reaction) return 'reaction';
    if (decodedContent is AttachmentContent) return 'attachment';
    if (decodedContent is RemoteAttachmentContent) {
      return 'remoteStaticAttachment';
    }
    if (decodedContent is MultiRemoteAttachmentContent) {
      return 'multiRemoteStaticAttachment';
    }
    if (decodedContent is GroupUpdated) return 'group_updated';
    if (decodedContent is LeaveRequest) return 'leave_request';
    if (decodedContent is ReadReceipt) return 'readReceipt';
    if (decodedContent is ActionsContent) return 'actions';
    if (decodedContent is IntentContent) return 'intent';
    return 'text';
  }

  static String _extractBodyText(dynamic content) {
    if (content is String) return content;
    if (content is Reply) return content.content.toString();
    if (content is Reaction) return content.content;
    if (content is AttachmentContent) return '[Attachment: ${content.filename}]';
    if (content is RemoteAttachmentContent) return '[Remote: ${content.filename}]';
    if (content is IntentContent) {
      return 'Tapped: ${content.metadata?['actionLabel'] as String? ?? content.actionId}';
    }
    if (content is ActionsContent) return content.description;
    if (content is MultiRemoteAttachmentContent) return _multiAttachmentLabel(content);
    return '';
  }

  /// Plain-text line for a multi-attachment message (search / body text).
  /// The caption wins when there is one.
  static String _multiAttachmentLabel(MultiRemoteAttachmentContent m) {
    final caption = m.description;
    if (caption != null && caption.isNotEmpty) return caption;
    final n = m.attachments.length;
    return '📎 $n attachment${n == 1 ? '' : 's'}';
  }

  // ==========================================================================
  // MESSAGE STORAGE
  // ==========================================================================

  /// Insert or update an XMTP message in the database.
  static Future<int> insertOrUpdateXmtpMessage(
    Map<String, dynamic> xmtpMessage, {
    bool isPending = false,
    bool sendFailed = false,
  }) async {
    if (PublicOS.sessionBlockchainAddress == null ||
        PublicOS.clientXmtpInboxId == null) {
      throw StateError('Cannot store message: no active session');
    }
    final typeId = _extractTypeId(xmtpMessage['decodedContent']);
    final existingId = xmtpMessage['id'] as int?;

    if (existingId != null) {
      await PublicOS.database.customStatement(
        '''UPDATE messages SET
             id_xmtp = ?,
             xmtp_message_data = ?,
             timestamp = ?,
             conversation_topic = ?,
             sender_inbox_id = ?,
             type_id = ?,
             is_pending = ?,
             send_failed = ?
           WHERE id = ? AND session_address = ? AND owner_inbox_id = ?''',
        [
          xmtpMessage['id_xmtp'] as String?,
          _jsonEncodeXmtpMessage(xmtpMessage),
          xmtpMessage['sent'] as int,
          xmtpMessage['conversationTopic'] as String,
          xmtpMessage['senderInboxId'] as String?,
          typeId,
          isPending ? 1 : 0,
          sendFailed ? 1 : 0,
          existingId,
          PublicOS.sessionBlockchainAddress!,
          PublicOS.clientXmtpInboxId!,
        ],
      );
      return existingId;
    }

    final companion = db.MessagesCompanion(
      idXmtp: Value(xmtpMessage['id_xmtp'] as String?),
      xmtpMessageData: Value(_jsonEncodeXmtpMessage(xmtpMessage)),
      timestamp: Value(xmtpMessage['sent'] as int),
      conversationTopic: Value(xmtpMessage['conversationTopic'] as String),
      senderInboxId: Value(xmtpMessage['senderInboxId'] as String?),
      sessionAddress: Value(PublicOS.sessionBlockchainAddress!),
      ownerInboxId: Value(PublicOS.clientXmtpInboxId!),
      typeId: Value(typeId),
      isPending: Value(isPending),
      sendFailed: Value(sendFailed),
    );

    return PublicOS.database.upsertMessage(companion);
  }

  /// Pending XMTP map used before send confirms.
  ///
  /// `sent` here is the DEVICE clock — a placeholder for the optimistic
  /// bubble only. The network assigns the authoritative sentAt at publish;
  /// it is adopted at the confirmed write ([_adoptNetworkSentFromEcho]) or
  /// healed from the echo in [_processIncomingMessage]. A device clock
  /// running ahead of the network otherwise makes peers' read receipts sort
  /// BEFORE the message they acknowledge ("seen" sticks on the previous
  /// message).
  static Map<String, dynamic> createPendingXmtpMap({
    required dynamic content,
    required String conversationTopic,
    required String senderInboxId,
  }) {
    return {
      'id': null,
      'id_xmtp': null,
      'body': _extractBodyText(content),
      'sent': DateTime.now().millisecondsSinceEpoch,
      'conversationTopic': conversationTopic,
      'senderInboxId': senderInboxId,
      'encodedContent': null,
      'decodedContent': content,
    };
  }

  /// Adopt libxmtp's authoritative network `sent` for a just-sent message,
  /// if its self-echo is already buffered in [PublicOS.messageCache] (it
  /// usually streams in before the native send call even returns).
  ///
  /// NB on keys: raw stream maps carry the XMTP hex id under `'id'` — the
  /// remap to `'id_xmtp'` (and `'id'` becoming the drift row id) happens
  /// later, inside [_processIncomingMessage].
  static void _adoptNetworkSentFromEcho(
      Map<String, dynamic> pendingXmtpMap, String idXmtp) {
    for (final cached in PublicOS.messageCache) {
      if (cached['id'] == idXmtp && cached['sent'] is int) {
        pendingXmtpMap['sent'] = cached['sent'];
        return;
      }
    }
  }

  /// Convert an XMTP map (from plugin or DB) into a [Message].
  static Message _convertXmtpMapToMessage(Map<String, dynamic> xmtpMessage) {
    final decodedContent = xmtpMessage['decodedContent'];
    final body = xmtpMessage['body'] as String?;

    MessageType messageType = MessageType.text;
    if (decodedContent is Reply) {
      messageType = MessageType.reply;
    } else if (decodedContent is Reaction) {
      messageType = MessageType.reaction;
    } else if (decodedContent is AttachmentContent) {
      messageType = MessageType.attachment;
    } else if (decodedContent is RemoteAttachmentContent) {
      messageType = MessageType.remoteAttachment;
    } else if (decodedContent is MultiRemoteAttachmentContent) {
      messageType = MessageType.multiRemoteAttachment;
    } else if (decodedContent is GroupUpdated) {
      messageType = MessageType.group_updated;
    } else if (decodedContent is ReadReceipt) {
      messageType = MessageType.readReceipt;
    }

    Uint8List? encodedContentBytes;
    if (xmtpMessage['encodedContent'] != null) {
      if (xmtpMessage['encodedContent'] is Uint8List) {
        encodedContentBytes = xmtpMessage['encodedContent'];
      } else if (xmtpMessage['encodedContent'] is List) {
        encodedContentBytes =
            Uint8List.fromList(List<int>.from(xmtpMessage['encodedContent']));
      }
    }

    String? originalAuthorityId;
    String? originalTypeId;
    if (encodedContentBytes != null) {
      try {
        final encoded = EncodedContent.fromBuffer(encodedContentBytes);
        originalAuthorityId = encoded.type.authorityId;
        originalTypeId = encoded.type.typeId;
      } catch (_) {}
    }

    dynamic contentValue = decodedContent ?? body;
    if (contentValue == null && encodedContentBytes != null) {
      try {
        final encoded = EncodedContent.fromBuffer(encodedContentBytes);
        switch (encoded.type.typeId) {
          case 'text':
            contentValue = utf8.decode(encoded.content);
            break;
          case 'readReceipt':
            messageType = MessageType.readReceipt;
            contentValue = const ReadReceipt();
            break;
          case 'actions':
            try {
              contentValue = ActionsContent.fromJson(
                  jsonDecode(utf8.decode(encoded.content)));
            } catch (_) {
              contentValue = encoded.hasFallback() ? encoded.fallback : '';
            }
            break;
          case 'intent':
            try {
              contentValue = IntentContent.fromJson(
                  jsonDecode(utf8.decode(encoded.content)));
            } catch (_) {
              contentValue = encoded.hasFallback() ? encoded.fallback : '';
            }
            break;
          default:
            try {
              contentValue = utf8.decode(encoded.content);
            } catch (_) {
              if (encoded.hasFallback() && encoded.fallback.isNotEmpty) {
                contentValue = encoded.fallback;
              }
            }
            break;
        }
      } catch (_) {}
    }

    if (contentValue is String && originalTypeId != null) {
      if (originalTypeId == 'actions') {
        try {
          contentValue = ActionsContent.fromJson(jsonDecode(contentValue));
        } catch (_) {}
      } else if (originalTypeId == 'intent') {
        try {
          contentValue = IntentContent.fromJson(jsonDecode(contentValue));
        } catch (_) {}
      } else if (originalTypeId == 'transactionReference') {
        // Re-decode a stored receipt body into a structured object. fromJson is
        // wire-tolerant (canonical flat OR wrapped envelope, optional metadata).
        try {
          contentValue = TransactionReference.fromJson(
              Map<String, dynamic>.from(jsonDecode(contentValue)));
        } catch (_) {}
      } else if (originalTypeId == 'walletSendCalls') {
        try {
          contentValue = WalletSendCalls.fromJson(
              Map<String, dynamic>.from(jsonDecode(contentValue)));
        } catch (_) {}
      }
    }

    String? referenceMessageId;
    if (decodedContent is Reply) {
      referenceMessageId = decodedContent.reference;
    } else if (decodedContent is Reaction) {
      referenceMessageId = decodedContent.reference;
    }

    return Message(
      id: xmtpMessage['id'] ?? 0,
      idXmtp: xmtpMessage['id_xmtp'],
      xmtpConversationTopic: xmtpMessage['conversationTopic'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(xmtpMessage['sent']),
      body: body,
      content: MessageContent(
        type: messageType,
        value: contentValue,
        authorityId: originalAuthorityId,
        typeId: originalTypeId,
      ),
      senderAddress: xmtpMessage['senderAddress'] ?? '',
      senderInboxId: xmtpMessage['senderInboxId'],
      isPending: false,
      sendFailed: false,
      encodedContent: encodedContentBytes,
      referenceMessageId: referenceMessageId,
    );
  }

  // ==========================================================================
  // MESSAGE QUERIES
  // ==========================================================================

  static const Duration messageSyncWindow = Duration(hours: 48);
  static const int defaultPageSize = 30;

  /// Get local messages by conversation topic.
  static Future<List<Message>> getLocalMessagesByTopic(
    String topic,
    int? limit,
    bool desc, {
    DateTime? before,
    DateTime? after,
  }) async {
    if (PublicOS.sessionBlockchainAddress == null ||
        PublicOS.clientXmtpInboxId == null) {
      return [];
    }
    try {
      String sql = '''
        SELECT * FROM messages
        WHERE conversation_topic = ?
          AND send_failed = 0
          AND is_pending = 0
          AND session_address = ?
          AND owner_inbox_id = ?
      ''';
      final args = <dynamic>[
        topic,
        PublicOS.sessionBlockchainAddress,
        PublicOS.clientXmtpInboxId,
      ];

      if (before != null) {
        sql += ' AND timestamp < ?';
        args.add(before.millisecondsSinceEpoch);
      }
      if (after != null) {
        sql += ' AND timestamp > ?';
        args.add(after.millisecondsSinceEpoch);
      }

      sql += ' ORDER BY timestamp ${desc ? 'DESC' : 'ASC'}';
      // A null limit means "no cap" (the caller wants the full conversation,
      // e.g. export / media scan). Only fall back to a page when a bound was
      // requested but left implicit. Capping a null limit at defaultPageSize
      // would silently truncate exports to one page.
      if (limit != null) {
        sql += ' LIMIT $limit';
      }

      final results = await PublicOS.database.customSelect(
        sql,
        variables: args.map((a) => Variable(a)).toList(),
        readsFrom: {PublicOS.database.messages},
      ).get();

      Log.d(_tag, 'getLocalMessagesByTopic: ${results.length} rows for topic '
          '$topic (limit=${limit ?? 'none'}, desc=$desc)');

      final messages = <Message>[];
      var skippedSystem = 0;
      var failedRows = 0;
      for (var i = 0; i < results.length; i++) {
        final row = results[i];
        try {
          final xmtpMessage =
              _jsonDecodeXmtpMessage(row.read<String>('xmtp_message_data'));
          final isRead = row.read<bool>('is_read');
          final message =
              _convertXmtpMapToMessage(xmtpMessage).copyWith(isRead: isRead);
          // leave_request is XMTP plumbing: a self-removal request that the
          // libxmtp PendingSelfRemoveWorker auto-honors (~2s) into a
          // group_updated removal. We surface the removal, not the request.
          // group_updated is now surfaced (rendered as a centered system line
          // by sessions) instead of skipped.
          if (message.content.typeId == 'leave_request') {
            skippedSystem++;
            continue;
          }
          messages.add(message);
        } catch (e) {
          // A single malformed row (e.g. an unparseable reply payload) must not
          // discard the entire conversation. Log it and keep going.
          failedRows++;
          Log.w(_tag, 'getLocalMessagesByTopic: failed to parse row $i '
              '(id=${row.data['id']}, type=${row.data['content_type']}): $e');
        }
      }
      Log.d(_tag, 'getLocalMessagesByTopic: parsed ${messages.length} messages '
          '($skippedSystem leave_request skipped, $failedRows failed)');
      return messages;
    } catch (e) {
      Log.e(_tag, 'Error loading messages: $e');
      return [];
    }
  }

  /// Mark a conversation as read (bookmark on latest message).
  /// Returns the bookmark timestamp.
  static Future<int?> markAsRead(String conversationTopic) async {
    if (PublicOS.sessionBlockchainAddress == null ||
        PublicOS.clientXmtpInboxId == null) return null;
    try {
      return await PublicOS.database.markConversationAsRead(
        conversationTopic,
        PublicOS.sessionBlockchainAddress!,
        PublicOS.clientXmtpInboxId!,
      );
    } catch (e) {
      Log.e(_tag, 'markAsRead error: $e');
      return null;
    }
  }

  /// Get unread counts per conversation (only non-zero entries).
  static Future<Map<String, int>> getUnreadCounts() async {
    if (PublicOS.sessionBlockchainAddress == null ||
        PublicOS.clientXmtpInboxId == null) {
      return {};
    }
    try {
      return await PublicOS.database.getUnreadCounts(
        PublicOS.sessionBlockchainAddress!,
        PublicOS.clientXmtpInboxId!,
        PublicOS.clientXmtpInboxId!,
      );
    } catch (e) {
      Log.e(_tag, 'getUnreadCounts error: $e');
      return {};
    }
  }

  /// Get the read bookmark timestamp for a conversation.
  static Future<DateTime?> getReadBookmark(String conversationTopic) async {
    if (PublicOS.sessionBlockchainAddress == null ||
        PublicOS.clientXmtpInboxId == null) return null;
    try {
      final ts = await PublicOS.database.getReadBookmarkTimestamp(
        conversationTopic,
        PublicOS.sessionBlockchainAddress!,
        PublicOS.clientXmtpInboxId!,
      );
      return ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
    } catch (e) {
      Log.e(_tag, 'getReadBookmark error: $e');
      return null;
    }
  }

  /// Return the local message ID if an XMTP message exists, else 0.
  static Future<int> messageExists(String? xmtpId) async {
    if (xmtpId == null) return 0;
    if (PublicOS.sessionBlockchainAddress == null ||
        PublicOS.clientXmtpInboxId == null) return 0;
    try {
      final result = await PublicOS.database.customSelect(
        'SELECT id FROM messages WHERE id_xmtp = ? AND session_address = ? AND owner_inbox_id = ? LIMIT 1',
        variables: [
          Variable.withString(xmtpId),
          Variable.withString(PublicOS.sessionBlockchainAddress!),
          Variable.withString(PublicOS.clientXmtpInboxId!),
        ],
        readsFrom: {PublicOS.database.messages},
      ).getSingleOrNull();
      return result?.read<int>('id') ?? 0;
    } catch (e) {
      Log.e(_tag, 'messageExists error: $e');
      return 0;
    }
  }

  /// Get a message by its XMTP ID (used for reply/reaction reference lookup).
  static Future<Message?> getMessageByXmtpId(String? xmtpId) async {
    if (xmtpId == null || xmtpId.isEmpty) return null;
    if (PublicOS.sessionBlockchainAddress == null ||
        PublicOS.clientXmtpInboxId == null) return null;
    try {
      final result = await PublicOS.database.customSelect(
        'SELECT * FROM messages WHERE id_xmtp = ? AND session_address = ? AND owner_inbox_id = ? LIMIT 1',
        variables: [
          Variable.withString(xmtpId),
          Variable.withString(PublicOS.sessionBlockchainAddress!),
          Variable.withString(PublicOS.clientXmtpInboxId!),
        ],
        readsFrom: {PublicOS.database.messages},
      ).getSingleOrNull();
      if (result == null) return null;
      final xmtpMessage =
          _jsonDecodeXmtpMessage(result.read<String>('xmtp_message_data'));
      return _convertXmtpMapToMessage(xmtpMessage);
    } catch (e) {
      Log.e(_tag, 'getMessageByXmtpId error: $e');
      return null;
    }
  }

  /// Total message count for a topic (excludes pending/failed).
  static Future<int> getMessageCount(String topic) async {
    if (PublicOS.sessionBlockchainAddress == null ||
        PublicOS.clientXmtpInboxId == null) return 0;
    try {
      final result = await PublicOS.database.customSelect(
        '''SELECT COUNT(*) as count FROM messages
           WHERE conversation_topic = ?
             AND session_address = ?
             AND owner_inbox_id = ?
             AND send_failed = 0
             AND is_pending = 0''',
        variables: [
          Variable.withString(topic),
          Variable.withString(PublicOS.sessionBlockchainAddress!),
          Variable.withString(PublicOS.clientXmtpInboxId!),
        ],
        readsFrom: {PublicOS.database.messages},
      ).getSingle();
      return result.read<int>('count');
    } catch (e) {
      Log.e(_tag, 'getMessageCount error: $e');
      return 0;
    }
  }

  /// Sync recent messages for a topic (48h window, 50-message batches).
  ///
  /// [emit] pushes each row that is NEW to the local DB onto
  /// [PublicOS.messageStream] (already-stored rows are skipped before the
  /// emit). Used for the resume catch-up, so an open chat appends only what
  /// arrived while backgrounded instead of reloading.
  static Future<void> syncMessagesByTopic(String topic, {bool emit = false}) async {
    if (!PublicOS.isAuthenticated) {
      throw Exception('Authentication required');
    }
    if (PublicOS.xmtpClient == null) return;

    // xmtp_plugin declares a non-nullable return but the method-channel
    // wrapper casts `List<dynamic> result = await invokeMethod(...)` —
    // which throws `type 'Null' is not a subtype of type 'List<dynamic>'`
    // when the plugin returns null (topic unknown to this XMTP key).
    // Absorb that specific fetch failure so chat init doesn't crash.
    List<Map<String, dynamic>> messages;
    try {
      messages = await PublicOS.xmtpClient!.getMessagesAfterDateByTopic(
        topic,
        DateTime.now().subtract(messageSyncWindow),
      );
    } catch (e) {
      Log.w(_tag, 'syncMessagesByTopic: no history for topic (likely unknown to current key): $e');
      return;
    }

    try {
      const batchSize = 50;
      for (var i = 0; i < messages.length; i += batchSize) {
        final end = (i + batchSize < messages.length) ? i + batchSize : messages.length;
        final batch = messages.sublist(i, end);
        await Future.wait(batch.map((m) => _processIncomingMessage(m, emit)));
      }
      Log.i(_tag, 'syncMessagesByTopic complete — ${messages.length} messages');
    } catch (e) {
      Log.e(_tag, 'syncMessagesByTopic error: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // SEND
  // ==========================================================================

  /// Send a message by inbox ID with pending→confirmed flow.
  static Future<Message?> sendMessageByInboxId(
    String targetInboxId,
    String conversationTopic,
    dynamic content,
    String authorityId,
    String typeId,
  ) async {
    if (!PublicOS.isAuthenticated || PublicOS.clientXmtpInboxId == null) {
      throw Exception('Authentication and session inbox ID required');
    }
    if (PublicOS.xmtpClient == null) {
      throw Exception('XMTP client not initialized');
    }

    PublicOS.isSending = true;
    PublicOS.messageCache.clear();

    final pendingXmtpMap = createPendingXmtpMap(
      content: content,
      conversationTopic: conversationTopic,
      senderInboxId: PublicOS.clientXmtpInboxId!,
    );

    Message? finalMessage;
    String? idXmtp;

    try {
      final id = await insertOrUpdateXmtpMessage(pendingXmtpMap, isPending: true);
      Message pendingMessage = _convertXmtpMapToMessage(pendingXmtpMap);
      pendingXmtpMap['id'] = id;
      pendingMessage = pendingMessage.copyWith(id: id);
      PublicOS.messageStreamController.add(pendingMessage);

      final sendResult = await PublicOS.xmtpClient!.sendMessageByInboxId(
        targetInboxId,
        content,
        authorityId,
        typeId,
      );
      idXmtp = sendResult?['messageId'] as String?;
      final liveTopic = sendResult?['topic'] as String?;

      if (idXmtp == null || idXmtp!.isEmpty) {
        throw Exception('Failed to send message: no ID returned');
      }

      // Heal a stale cached topic. Send is find-or-create, so `liveTopic` is
      // always the canonical live DM. If it differs from the topic we were
      // given (e.g. after a reset / duplicate-DM left a dead row behind),
      // migrate the local thread onto the live topic BEFORE persisting the
      // final echo, so everything lands under the right conversation.
      if (liveTopic != null &&
          liveTopic.isNotEmpty &&
          liveTopic != conversationTopic) {
        await _healDmTopic(
          oldTopic: conversationTopic,
          newTopic: liveTopic,
          peerInboxId: targetInboxId,
        );
        pendingXmtpMap['conversationTopic'] = liveTopic;
      }

      pendingXmtpMap['id_xmtp'] = idXmtp;
      _adoptNetworkSentFromEcho(pendingXmtpMap, idXmtp);
      final idSent =
          await insertOrUpdateXmtpMessage(pendingXmtpMap, isPending: false);

      finalMessage = _convertXmtpMapToMessage(pendingXmtpMap).copyWith(id: idSent);
      PublicOS.messageStreamController.add(finalMessage!);
    } catch (e) {
      Log.e(_tag, 'sendMessageByInboxId error: $e');
      if (finalMessage == null) {
        PublicOS.isSending = false;
        PublicOS.messageCache.clear();
        await insertOrUpdateXmtpMessage(pendingXmtpMap,
            isPending: false, sendFailed: true);
        final failedMessage = _convertXmtpMapToMessage(pendingXmtpMap)
            .copyWith(sendFailed: true);
        PublicOS.messageStreamController.add(failedMessage);
        rethrow;
      }
      Log.w(_tag, 'Post-confirmation error (message IS sent): $e');
    }

    // Cache processing: drain buffered incoming messages, skip own echo
    try {
      final cache = List<Map<String, dynamic>>.from(PublicOS.messageCache);
      PublicOS.messageCache.clear();
      PublicOS.isSending = false;

      for (final cached in cache) {
        // Own echo included on purpose: if it landed after the confirmed
        // write adopted its timestamp, the confirmed-echo branch in
        // _processIncomingMessage heals the row to the network sentAt;
        // when already adopted it no-ops.
        await _processIncomingMessage(cached, true);
      }
    } catch (e) {
      Log.e(_tag, 'Cache processing error (send was successful): $e');
      PublicOS.messageCache.clear();
      PublicOS.isSending = false;
    }

    return finalMessage;
  }

  /// Legacy send by ETH address.
  static Future<Message?> sendMessage(
    String recipientAddress,
    String xmtpConversationTopic,
    dynamic content,
    String authorityId,
    String typeId,
  ) async {
    if (!PublicOS.isAuthenticated || PublicOS.clientXmtpInboxId == null) {
      throw Exception('Authentication and session inbox ID required');
    }
    if (PublicOS.xmtpClient == null) {
      throw Exception('XMTP client not initialized');
    }

    PublicOS.isSending = true;
    PublicOS.messageCache.clear();

    Map<String, dynamic> pendingXmtpMap = createPendingXmtpMap(
      content: content,
      conversationTopic: xmtpConversationTopic,
      senderInboxId: PublicOS.clientXmtpInboxId!,
    );

    Message? finalMessage;
    String? idXmtp;

    try {
      final id = await insertOrUpdateXmtpMessage(pendingXmtpMap, isPending: true);
      pendingXmtpMap['id'] = id;
      Message pendingMessage =
          _convertXmtpMapToMessage(pendingXmtpMap).copyWith(id: id);
      PublicOS.messageStreamController.add(pendingMessage);

      idXmtp = await PublicOS.xmtpClient!.sendMessage(
        recipientAddress,
        content,
        authorityId,
        typeId,
      );

      if (idXmtp == null || idXmtp!.isEmpty) {
        throw Exception('Failed to send message: no ID returned');
      }

      pendingXmtpMap['id_xmtp'] = idXmtp;
      _adoptNetworkSentFromEcho(pendingXmtpMap, idXmtp);
      await insertOrUpdateXmtpMessage(pendingXmtpMap, isPending: false);
      finalMessage = _convertXmtpMapToMessage(pendingXmtpMap);
      PublicOS.messageStreamController.add(finalMessage!);
    } catch (e) {
      Log.e(_tag, 'sendMessage error: $e');
      if (finalMessage == null) {
        PublicOS.isSending = false;
        PublicOS.messageCache.clear();
        await insertOrUpdateXmtpMessage(pendingXmtpMap,
            isPending: false, sendFailed: true);
        final failedMessage = _convertXmtpMapToMessage(pendingXmtpMap)
            .copyWith(sendFailed: true);
        PublicOS.messageStreamController.add(failedMessage);
        return null;
      }
      Log.w(_tag, 'Post-confirmation error: $e');
    }

    try {
      final cache = List<Map<String, dynamic>>.from(PublicOS.messageCache);
      PublicOS.messageCache.clear();
      PublicOS.isSending = false;
      for (final cached in cache) {
        // Own echo included on purpose (the old `cached['id_xmtp']` skip
        // never matched — raw stream maps carry the XMTP id under 'id'):
        // the confirmed-echo branch heals the timestamp or no-ops.
        await _processIncomingMessage(cached, true);
      }
    } catch (e) {
      Log.e(_tag, 'Cache processing error: $e');
      PublicOS.messageCache.clear();
      PublicOS.isSending = false;
    }

    return finalMessage;
  }

  /// Send a message to a group topic.
  static Future<Message?> sendGroupMessage(
    String topic,
    dynamic content,
    String authorityId,
    String typeId,
  ) async {
    if (!PublicOS.isAuthenticated || PublicOS.clientXmtpInboxId == null) {
      throw Exception('Authentication and session inbox ID required');
    }
    if (PublicOS.xmtpClient == null) {
      throw Exception('XMTP client not initialized');
    }

    PublicOS.isSending = true;
    PublicOS.messageCache.clear();

    Map<String, dynamic> pendingXmtpMap = createPendingXmtpMap(
      content: content,
      conversationTopic: topic,
      senderInboxId: PublicOS.clientXmtpInboxId!,
    );

    Message? finalMessage;
    String? idXmtp;

    try {
      final id = await insertOrUpdateXmtpMessage(pendingXmtpMap, isPending: true);
      pendingXmtpMap['id'] = id;
      Message pendingMessage =
          _convertXmtpMapToMessage(pendingXmtpMap).copyWith(id: id);
      PublicOS.messageStreamController.add(pendingMessage);

      idXmtp = await PublicOS.xmtpClient!.sendGroupMessage(
        topic,
        content,
        authorityId,
        typeId,
      );

      if (idXmtp == null || idXmtp!.isEmpty) {
        throw Exception('Failed to send group message: no ID returned');
      }

      pendingXmtpMap['id_xmtp'] = idXmtp;
      _adoptNetworkSentFromEcho(pendingXmtpMap, idXmtp);
      await insertOrUpdateXmtpMessage(pendingXmtpMap, isPending: false);
      finalMessage = _convertXmtpMapToMessage(pendingXmtpMap);
      PublicOS.messageStreamController.add(finalMessage!);
    } catch (e) {
      Log.e(_tag, 'sendGroupMessage error: $e');
      if (finalMessage == null) {
        PublicOS.isSending = false;
        PublicOS.messageCache.clear();
        await insertOrUpdateXmtpMessage(pendingXmtpMap,
            isPending: false, sendFailed: true);
        final failedMessage = _convertXmtpMapToMessage(pendingXmtpMap)
            .copyWith(sendFailed: true);
        PublicOS.messageStreamController.add(failedMessage);
        rethrow;
      }
      Log.w(_tag, 'Post-confirmation error: $e');
    }

    try {
      final cache = List<Map<String, dynamic>>.from(PublicOS.messageCache);
      PublicOS.messageCache.clear();
      PublicOS.isSending = false;
      for (final cached in cache) {
        // Own echo included on purpose (the old `cached['id_xmtp']` skip
        // never matched — raw stream maps carry the XMTP id under 'id'):
        // the confirmed-echo branch heals the timestamp or no-ops.
        await _processIncomingMessage(cached, true);
      }
    } catch (e) {
      Log.e(_tag, 'Cache processing error: $e');
      PublicOS.messageCache.clear();
      PublicOS.isSending = false;
    }

    return finalMessage;
  }

  // ==========================================================================
  // INCOMING MESSAGE PROCESSING
  // ==========================================================================

  static Future<void> _processIncomingMessage(
      Map<String, dynamic> xmtpMessage, bool streamAfter) async {
    try {
      final senderInboxId = xmtpMessage['senderInboxId'] as String?;
      if (senderInboxId == null || senderInboxId.isEmpty) return;

      xmtpMessage['id_xmtp'] = xmtpMessage['id'];
      xmtpMessage['id'] = null;

      // Force-update stale read receipt records (migration hack)
      if (xmtpMessage['decodedContent'] is ReadReceipt) {
        final existingId = await messageExists(xmtpMessage['id_xmtp'] as String?);
        if (existingId > 0) {
          await PublicOS.database.customStatement(
            'UPDATE messages SET xmtp_message_data = ?, type_id = ? WHERE id = ?',
            [_jsonEncodeXmtpMessage(xmtpMessage), 'readReceipt', existingId],
          );
          return;
        }
      }

      // Echo suppression: skip if already confirmed (but heal send_failed)
      final existingMessageId = await messageExists(xmtpMessage['id_xmtp'] as String?);
      if (existingMessageId > 0) {
        final existingResult = await PublicOS.database.customSelect(
          'SELECT is_pending, send_failed, timestamp, xmtp_message_data FROM messages WHERE id = ? AND session_address = ?',
          variables: [
            Variable.withInt(existingMessageId),
            Variable.withString(PublicOS.sessionBlockchainAddress!),
          ],
          readsFrom: {PublicOS.database.messages},
        ).getSingleOrNull();

        final isPending = existingResult?.read<int>('is_pending') == 1;
        final isSendFailed = existingResult?.read<int>('send_failed') == 1;
        final storedTimestamp = existingResult?.read<int>('timestamp');
        // The blob is what Message.timestamp is parsed from on load — it can
        // disagree with the column (an older heal wrote the column
        // only), so the heal condition must look at BOTH.
        int? blobTimestamp;
        try {
          final rawBlob = existingResult?.read<String>('xmtp_message_data');
          if (rawBlob != null) {
            blobTimestamp =
                (json.decode(rawBlob) as Map<String, dynamic>)['sent'] as int?;
          }
        } catch (_) {}

        if (isSendFailed) {
          Log.w(_tag, 'Echo healing send_failed message (id: $existingMessageId)');
          xmtpMessage['id'] = existingMessageId;
          await insertOrUpdateXmtpMessage(xmtpMessage,
              isPending: false, sendFailed: false);
          final healed = _convertXmtpMapToMessage(xmtpMessage)
              .copyWith(id: existingMessageId);
          PublicOS.messageStreamController.add(healed);
          return;
        }

        if (!isPending) {
          // Confirmed-message echo. Our own row was stamped with the DEVICE
          // clock at send (createPendingXmtpMap) unless the confirmed write
          // already adopted the echo; the echo carries libxmtp's authoritative
          // network sentAt. Rewrite the whole row — sort column AND blob —
          // so seen placement and chat order stop depending on
          // device-vs-network clock skew. syncMessagesByTopic re-runs recent
          // history through here, so stale rows converge on their first
          // re-sync and then no-op.
          final isFromSelf = senderInboxId == PublicOS.clientXmtpInboxId;
          final echoSent = xmtpMessage['sent'];
          if (isFromSelf &&
              echoSent is int &&
              (storedTimestamp != echoSent || blobTimestamp != echoSent)) {
            xmtpMessage['id'] = existingMessageId;
            await insertOrUpdateXmtpMessage(xmtpMessage, isPending: false);
            if (streamAfter) {
              final updated = _convertXmtpMapToMessage(xmtpMessage)
                  .copyWith(id: existingMessageId);
              PublicOS.messageStreamController.add(updated);
            }
          }
          return;
        }
      }

      await insertOrUpdateXmtpMessage(xmtpMessage);

      if (streamAfter) {
        final message = _convertXmtpMapToMessage(xmtpMessage);
        // leave_request is plumbing (auto-honored into a group_updated removal
        // by libxmtp's PendingSelfRemoveWorker); never surface it. group_updated
        // now streams through so membership/metadata events appear live as
        // centered system lines.
        if (message.content.typeId == 'leave_request') return;
        PublicOS.messageStreamController.add(message);

        // No FG live-stream notification rendering here, on purpose. Push
        // notifications (via PublicOSPush.handleIncomingPush → FCM onMessage
        // when FG, onBackgroundMessage when killed/bg) are the canonical
        // notification source for all message arrivals. Running the live
        // path alongside push produces double-renders (same message appended
        // twice to the per-topic MessagingStyle thread) and the live path's
        // contact lookup (findContactByInboxId, local-only) often misses
        // when the push path's resolution would hit. If push is OFF,
        // the 15-min Workmanager sweep covers killed/bg state; the FG
        // "different tab" case goes unnotified, which we judge acceptable
        // because the in-app message stream still updates that conversation.
        // Add a live path here if a no-push deployment ever needs FG-tab
        // notifications. The logic above — message persistence
        // (insertOrUpdateXmtpMessage above) + stream emission
        // (messageStreamController.add) — is unaffected.
      }
    } catch (e) {
      Log.e(_tag, '_processIncomingMessage error: $e');
    }
  }

  // ==========================================================================
  // GROUP MANAGEMENT (XMTP network)
  // ==========================================================================

  static Future<Map<String, dynamic>> createGroup(
    List<String> inboxIds,
    Map<String, String> options,
  ) async {
    _requireXmtpAuth();
    try {
      final result = await PublicOS.xmtpClient!.newGroup(inboxIds, options);
      // Seed a conversation row + stub Contact immediately so the Browser
      // can resolve the new group without waiting for the next syncAll.
      final topic = result['topic'] as String?;
      if (topic != null && topic.isNotEmpty) {
        try {
          final conv = XmtpConversation(
            topic: topic,
            type: ConversationType.group,
            groupName: (result['name'] as String?) ?? options['name'],
            groupImageUrl:
                (result['imageUrlSquare'] as String?) ?? options['imageUrl'],
            groupDescription:
                (result['description'] as String?) ?? options['description'],
            pinnedFrameUrl: result['pinnedFrameUrl'] as String?,
            createdAt: DateTime.now(),
          );
          await saveConversation(conv);
          await PublicOSContacts.ensureGroupStub(
            topic: conv.topic,
            groupName: conv.groupName ?? 'Unnamed Group',
            groupImageUrl: conv.groupImageUrl,
          );
          // Register the new group's topic with the notif server so push
          // arrives without waiting for next app boot's subscribeAll.
          // Plugin returns raw-hex topic; push API wants full XMTP wire.
          // Fire-and-forget — notif server unreachable doesn't block UX.
          unawaited(PublicOSPush.subscribeNewConversation(topic));
        } catch (e) {
          Log.w(_tag, 'createGroup: post-create seed failed (will re-sync): $e');
        }
      }
      return result;
    } catch (e) {
      Log.e(_tag, 'createGroup error: $e');
      rethrow;
    }
  }

  static Future<bool> addGroupMembers(String groupId, List<String> inboxIds) async {
    _requireXmtpAuth();
    try {
      return await PublicOS.xmtpClient!.addGroupMembers(groupId, inboxIds);
    } catch (e) {
      Log.e(_tag, 'addGroupMembers error: $e');
      rethrow;
    }
  }

  static Future<bool> removeGroupMembers(
      String groupId, List<String> inboxIds) async {
    _requireXmtpAuth();
    try {
      return await PublicOS.xmtpClient!.removeGroupMembers(groupId, inboxIds);
    } catch (e) {
      Log.e(_tag, 'removeGroupMembers error: $e');
      rethrow;
    }
  }

  static Future<bool> addGroupAdmin(String groupId, String inboxId) async {
    _requireXmtpAuth();
    try {
      return await PublicOS.xmtpClient!.addGroupAdmin(groupId, inboxId);
    } catch (e) {
      Log.e(_tag, 'addGroupAdmin error: $e');
      rethrow;
    }
  }

  static Future<bool> removeGroupAdmin(String groupId, String inboxIds) async {
    _requireXmtpAuth();
    try {
      return await PublicOS.xmtpClient!.removeGroupAdmin(groupId, inboxIds);
    } catch (e) {
      Log.e(_tag, 'removeGroupAdmin error: $e');
      rethrow;
    }
  }

  static Future<bool> addGroupSuperAdmin(String groupId, String inboxIds) async {
    _requireXmtpAuth();
    try {
      return await PublicOS.xmtpClient!.addGroupSuperAdmin(groupId, inboxIds);
    } catch (e) {
      Log.e(_tag, 'addGroupSuperAdmin error: $e');
      rethrow;
    }
  }

  static Future<bool> removeGroupSuperAdmin(
      String groupId, String inboxIds) async {
    _requireXmtpAuth();
    try {
      return await PublicOS.xmtpClient!.removeGroupSuperAdmin(groupId, inboxIds);
    } catch (e) {
      Log.e(_tag, 'removeGroupSuperAdmin error: $e');
      rethrow;
    }
  }

  static Future<bool> updateGroup(
      String groupId, Map<String, String> updates) async {
    _requireXmtpAuth();
    try {
      final ok = await PublicOS.xmtpClient!.updateGroup(groupId, updates);
      if (ok) {
        // Mirror the edit locally: refresh the XmtpConversation row and the
        // group-stub Contact so every surface (messages list, Browser,
        // ContactIcon) picks up the new values immediately.
        await updateGroupMetadata(
          groupId,
          groupName: updates['name'],
          groupImageUrl: updates['imageUrl'],
          groupDescription: updates['description'],
        );
        final existingStub = await PublicOSContacts.findContactByTopic(groupId);
        if (existingStub != null) {
          await PublicOSContacts.ensureGroupStub(
            topic: groupId,
            groupName: updates['name'] ?? existingStub.displayName,
            groupImageUrl: updates['imageUrl'],
          );
        }
      }
      return ok;
    } catch (e) {
      Log.e(_tag, 'updateGroup error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getGroupMemberRole(
      String groupId, String inboxIds) async {
    _requireXmtpAuth();
    try {
      return await PublicOS.xmtpClient!.getGroupMemberRole(groupId, inboxIds);
    } catch (e) {
      Log.e(_tag, 'getGroupMemberRole error: $e');
      rethrow;
    }
  }

  static Future<List<Map<dynamic, dynamic>>> listGroupMembers(
      String groupId) async {
    _requireXmtpAuth();
    try {
      return await PublicOS.xmtpClient!.listGroupMembers(groupId);
    } catch (e) {
      Log.e(_tag, 'listGroupMembers error: $e');
      rethrow;
    }
  }

  static Future<List<Map<dynamic, dynamic>>> listGroupAdmins(
      String groupId) async {
    _requireXmtpAuth();
    try {
      return await PublicOS.xmtpClient!.listGroupAdmins(groupId);
    } catch (e) {
      Log.e(_tag, 'listGroupAdmins error: $e');
      rethrow;
    }
  }

  static Future<List<Map<dynamic, dynamic>>> listGroupSuperAdmins(
      String groupId) async {
    _requireXmtpAuth();
    try {
      return await PublicOS.xmtpClient!.listGroupSuperAdmins(groupId);
    } catch (e) {
      Log.e(_tag, 'listGroupSuperAdmins error: $e');
      rethrow;
    }
  }

  static void _requireXmtpAuth() {
    if (!PublicOS.isAuthenticated ||
        PublicOS.sessionBlockchainAddress == null ||
        PublicOS.xmtpClient == null) {
      throw Exception('Authentication + XMTP client required');
    }
  }

  // ==========================================================================
  // NETWORK QUERIES (can this address/inbox be messaged?)
  // ==========================================================================

  static Future<bool> canMessage(String address) async {
    if (PublicOS.xmtpClient == null) return false;
    try {
      return await PublicOS.xmtpClient!.canMessageByAddress(address);
    } catch (e) {
      Log.e(_tag, 'canMessage error: $e');
      return false;
    }
  }

  static Future<String?> inboxIdFromAddress(String address) async {
    if (PublicOS.xmtpClient == null) return null;
    try {
      return await PublicOS.xmtpClient!.inboxIdFromAddress(address);
    } catch (e) {
      Log.e(_tag, 'inboxIdFromAddress error: $e');
      return null;
    }
  }

  static Future<bool> canMessageByAddress(String address) async {
    if (PublicOS.xmtpClient == null) return false;
    try {
      return await PublicOS.xmtpClient!.canMessageByAddress(address);
    } catch (e) {
      Log.e(_tag, 'canMessageByAddress error: $e');
      return false;
    }
  }

  static Future<bool> canMessageByInboxId(String inboxId) async {
    if (PublicOS.xmtpClient == null) return false;
    try {
      return await PublicOS.xmtpClient!.canMessageByInboxId(inboxId);
    } catch (e) {
      Log.e(_tag, 'canMessageByInboxId error: $e');
      return false;
    }
  }

  // ==========================================================================
  // DRAFTS (per conversation topic, SharedPreferences-backed)
  // ==========================================================================

  static final Map<String, String> _drafts = {};
  static final Map<String, Timer> _draftTimers = {};
  static const _draftPrefix = 'draft_';

  /// Load all drafts from SharedPreferences into memory. Call once at startup.
  static Future<void> loadDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_draftPrefix));
    for (final key in keys) {
      final topic = key.substring(_draftPrefix.length);
      final value = prefs.getString(key);
      if (value != null && value.isNotEmpty) {
        _drafts[topic] = value;
      }
    }
    Log.d(_tag, 'Loaded ${_drafts.length} drafts');
  }

  static String? getDraft(String topic) => _drafts[topic];

  static bool hasDraft(String topic) => _drafts.containsKey(topic);

  /// Save a draft (memory immediate, disk 500ms debounce).
  static void saveDraft(String topic, String text) {
    if (text.isEmpty) {
      deleteDraft(topic);
      return;
    }
    _drafts[topic] = text;
    _draftTimers[topic]?.cancel();
    _draftTimers[topic] = Timer(const Duration(milliseconds: 500), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_draftPrefix$topic', text);
    });
  }

  static void deleteDraft(String topic) {
    _drafts.remove(topic);
    _draftTimers[topic]?.cancel();
    _draftTimers.remove(topic);
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('$_draftPrefix$topic');
    });
  }

  // ==========================================================================
  // NOTIFICATIONS
  // ==========================================================================

  /// Resolve the on-disk cached avatar file path. Returns null if the avatar
  /// isn't pre-cached (notification still renders, just iconless — no time
  /// to fetch in this hot path).
  ///
  /// Returns a path, not bytes: callers either pass the path straight to the
  /// system (Android `BitmapFilePathAndroidIcon`, iOS
  /// `DarwinNotificationAttachment`) or persist the path into notification
  /// history. Persisting bytes blew up SharedPreferences (one prefs entry hit
  /// 53 MB → OOM at app boot); paths stay tiny and the system reads bitmaps
  /// from disk on demand.
  static Future<String?> _resolveCachedAvatarPath(String? avatarUrl) async {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;
    try {
      return await ZeroCacheManager.instance.getCachedFilePath(avatarUrl);
    } catch (e) {
      Log.e(_tag, 'Could not resolve cached avatar path: $e');
      return null;
    }
  }

  /// Stable notification ID per conversation topic. MessagingStyle replaces
  /// the existing notification when reused with the same ID — that's what
  /// gives us Telegram-style threading (5 new msgs from Alice = 1 notif
  /// showing 5 lines, not 5 stacked notifs).
  static int _notificationIdForTopic(String topic) {
    final bytes = sha256.convert(utf8.encode(topic)).bytes;
    int n = 0;
    for (int i = 0; i < 4; i++) {
      n = (n << 8) | bytes[i];
    }
    return n & 0x7FFFFFFF;
  }

  static const String _notifHistoryPrefPrefix = 'notif_history_';
  static const int _maxNotifHistoryPerTopic = 7;

  /// Build a `Person.icon` from a history entry. Prefers the modern
  /// `avatarPath` field (file path read by the system at notify-time);
  /// silently ignores legacy `avatarBase64` entries left over from before
  /// the OOM fix — they're scrubbed at init by [scrubLegacyNotifHistory]
  /// but a freshly-rebuilt list may still see one if a new notif arrives
  /// before the scrubber lands. Missing files render as no icon → Android
  /// falls back to initials, same as today's chat rows.
  static BitmapFilePathAndroidIcon? _iconForHistoryEntry(
      Map<String, dynamic> entry) {
    final path = entry['avatarPath'];
    if (path is! String || path.isEmpty) return null;
    try {
      if (!File(path).existsSync()) return null;
    } catch (_) {
      return null;
    }
    return BitmapFilePathAndroidIcon(path);
  }

  /// One-shot migration: drop any `notif_history_*` keys carrying the
  /// legacy `avatarBase64` field. Pre-fix entries persisted full-res base64
  /// PNGs (with embedded C2PA metadata on Pixel screenshots) — enough to
  /// reach a 53 MB SharedPreferences XML, which Android's legacy plugin
  /// reads in one allocation at boot → OOM before any Dart code runs.
  ///
  /// Called from [PublicOS.init]. Cheap (one prefs read + per-key string
  /// scan); safe to call on every launch — becomes a no-op once scrubbed.
  ///
  /// Remove after a couple of releases, when no installed app is likely
  /// to still carry pre-fix entries.
  static Future<void> scrubLegacyNotifHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final victims = prefs
          .getKeys()
          .where((k) => k.startsWith(_notifHistoryPrefPrefix))
          .where((k) {
        final v = prefs.getString(k);
        return v != null && v.contains('"avatarBase64"');
      }).toList();
      if (victims.isEmpty) return;
      for (final k in victims) {
        await prefs.remove(k);
      }
      Log.i(_tag,
          'Scrubbed ${victims.length} legacy notif_history_* entries (avatarBase64)');
    } catch (e) {
      Log.e(_tag, 'scrubLegacyNotifHistory error: $e');
    }
  }

  /// Append [entry] to the per-topic notification history (used to rebuild
  /// MessagingStyle's messages list on each new notif). Caps at
  /// [_maxNotifHistoryPerTopic] entries — older ones drop off the bottom.
  static Future<List<Map<String, dynamic>>> _appendNotifHistoryEntry(
    String topic,
    Map<String, dynamic> entry,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_notifHistoryPrefPrefix$topic';
    final existing = prefs.getString(key);
    final entries = existing != null
        ? List<Map<String, dynamic>>.from(
            (jsonDecode(existing) as List).map((e) => Map<String, dynamic>.from(e as Map)))
        : <Map<String, dynamic>>[];
    entries.add(entry);
    if (entries.length > _maxNotifHistoryPerTopic) {
      entries.removeRange(0, entries.length - _maxNotifHistoryPerTopic);
    }
    await prefs.setString(key, jsonEncode(entries));
    return entries;
  }

  /// Clear the per-topic notification history. Call this when the user
  /// opens the conversation (publicos_client `browser.dart` conversation
  /// route) so the next message starts a fresh thread instead of stacking
  /// onto already-read context.
  static Future<void> clearNotifHistory(String topic) async {
    if (topic.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_notifHistoryPrefPrefix$topic');
    if (PublicOS.notificationsPlugin != null) {
      try {
        await PublicOS.notificationsPlugin!.cancel(_notificationIdForTopic(topic));
      } catch (_) {}
    }
  }

  /// Resolve a notification's display identity from the local DB — the single
  /// place both the bg sweep ([PublicOS.executeBackgroundSync]) and the FCM
  /// direct-decrypt path ([PublicOSPush.handleIncomingPush]) call, so they
  /// render identically (sender display name + avatar + group name).
  ///
  /// Group-ness: a contact stub keyed by topic exists ONLY for groups
  /// (`xmtpConversationTopic` is null for people), so a non-null
  /// `getContactByTopic` result means group. Callers that already know it's a
  /// group (the sweep, from `listGroups`) pass [isGroup] so a group whose stub
  /// doesn't exist yet still gets the `Group <topic>…` fallback name; the push
  /// path leaves [isGroup] null and lets stub-existence decide.
  ///
  /// [database] / [sessionAddress] default to the PublicOS statics (set on the
  /// main isolate at boot, on the bg isolate by
  /// [PublicOS.ensureBackgroundIsolateReady]).
  static Future<({String name, String? avatarUrl, String? groupName})>
      resolveNotificationIdentity({
    required String senderInboxId,
    required String topic,
    bool? isGroup,
    db.AppDatabase? database,
    String? sessionAddress,
  }) async {
    final resolvedDb = database ?? PublicOS.database;
    final sessionAddr = sessionAddress ?? PublicOS.sessionBlockchainAddress;

    String groupFallback() =>
        'Group ${topic.length >= 8 ? topic.substring(0, 8) : topic}…';

    // Group name (only for groups). isGroup==false → skip; null → infer from
    // stub existence; true → stub name or fallback.
    String? groupName;
    if (isGroup != false && sessionAddr != null) {
      try {
        final stub = await resolvedDb.getContactByTopic(topic, sessionAddr);
        if (stub != null) {
          groupName = stub.displayName;
        } else if (isGroup == true) {
          groupName = groupFallback();
        }
      } catch (e) {
        Log.w(_tag, 'resolveNotificationIdentity: group lookup failed: $e');
        if (isGroup == true) groupName = groupFallback();
      }
    }

    // Sender name + avatar. Normalize the inbox ID first — registeredInboxIDs
    // are stored as normalized 64-char lowercase hex.
    String name = senderInboxId.length >= 6
        ? '${senderInboxId.substring(0, 6)}...'
        : senderInboxId;
    String? avatarUrl;
    if (sessionAddr != null) {
      try {
        final normalized = Contact.normalizeInboxId(senderInboxId);
        final row = normalized == null
            ? null
            : await resolvedDb.getContactByRegisteredInboxId(normalized, sessionAddr);
        if (row != null) {
          final contact = DatabaseHelpers.contactFromRow(row);
          name = contact.displayName;
          avatarUrl = contact.resolvedAvatarUrl;
        }
      } catch (e) {
        Log.w(_tag, 'resolveNotificationIdentity: sender lookup failed: $e');
      }
    }

    return (name: name, avatarUrl: avatarUrl, groupName: groupName);
  }

  /// Show an OS notification for an incoming message via Android's
  /// `MessagingStyle` (avatar on the left, threaded per conversation, free
  /// rendering of group + sender semantics).
  ///
  /// Threading: each call appends to a per-topic SharedPreferences-backed
  /// history (cap 7) and reuses the same notification ID, so the next
  /// message stacks into the existing notif instead of spawning a new one.
  /// [clearNotifHistory] resets the thread when the conversation is opened.
  ///
  /// Gated by `live_notifications` setting and `bg_last_sync` dedup.
  static Future<void> showMessageNotification({
    required String senderName,
    required String messagePreview,
    required String conversationTopic,
    String? avatarUrl,
    String? groupName,
    String? senderInboxId,
    bool bypassSettingsGate = false,
  }) async {
    if (!PublicOS.notificationsInitialized ||
        PublicOS.notificationsPlugin == null) {
      return;
    }
    if (conversationTopic.isEmpty) return;

    // FG callers gate on `live_notifications`; bg callers (the sweep, which
    // already lives behind its own user toggle in publicos_client settings)
    // bypass — set bypassSettingsGate: true.
    if (!bypassSettingsGate) {
      try {
        final liveEnabled = await PublicOSSettings.getLiveNotifications();
        if (!liveEnabled) return;
      } catch (e) {
        Log.e(_tag, 'Error checking live_notifications setting: $e');
        return;
      }
    }

    final ts = DateTime.now();
    final avatarPath = await _resolveCachedAvatarPath(avatarUrl);
    final senderKey = senderInboxId ?? senderName;

    final newEntry = <String, dynamic>{
      'text': messagePreview,
      'ts': ts.millisecondsSinceEpoch,
      'senderName': senderName,
      'senderKey': senderKey,
      if (avatarPath != null) 'avatarPath': avatarPath,
    };
    final history = await _appendNotifHistoryEntry(conversationTopic, newEntry);

    final isGroup = groupName != null;
    final styleMessages = <fln.Message>[
      for (final h in history)
        fln.Message(
          h['text'] as String,
          DateTime.fromMillisecondsSinceEpoch(h['ts'] as int),
          Person(
            key: h['senderKey'] as String?,
            name: h['senderName'] as String?,
            icon: _iconForHistoryEntry(h),
          ),
        ),
    ];

    const selfPerson = Person(key: 'self', name: 'You');
    final styleInformation = MessagingStyleInformation(
      selfPerson,
      conversationTitle: isGroup ? groupName : null,
      groupConversation: isGroup,
      messages: styleMessages,
    );

    final androidDetails = AndroidNotificationDetails(
      'publicos_messages',
      'Messages',
      channelDescription: 'Notifications for new messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: 'ic_stat_notification',
      styleInformation: styleInformation,
    );

    // iOS keeps the simple attachment path (raw avatar, no badge composite —
    // iOS won't reposition either way and attachment thumbnails are tiny).
    DarwinNotificationAttachment? iosAttachment;
    if (Platform.isIOS && avatarUrl != null && avatarUrl.isNotEmpty) {
      try {
        final cachedPath = await ZeroCacheManager.instance.getCachedFilePath(avatarUrl);
        if (cachedPath != null) {
          iosAttachment = DarwinNotificationAttachment(cachedPath);
        }
      } catch (_) {}
    }
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      attachments: iosAttachment != null ? [iosAttachment] : null,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    // Fallback title/body for platforms that don't render MessagingStyle
    // (iOS, macOS, older Android). Android with MessagingStyle ignores these.
    final fallbackTitle = isGroup ? groupName : senderName;
    final fallbackBody = isGroup ? '$senderName: $messagePreview' : messagePreview;

    try {
      await PublicOS.notificationsPlugin!.show(
        _notificationIdForTopic(conversationTopic),
        fallbackTitle,
        fallbackBody.length > 120 ? '${fallbackBody.substring(0, 120)}...' : fallbackBody,
        notificationDetails,
        payload: PublicOS.notificationPayload('message', conversationTopic),
      );

      // Update bg_last_sync so background sync doesn't re-notify
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          PublicOS.bgLastSyncKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      Log.e(_tag, 'showMessageNotification error: $e');
    }
  }

  /// Format a notification preview string for incoming messages.
  ///
  /// For reactions, [reactionParentPreview] is the formatted preview of the
  /// message being reacted to (passed in by the caller so this stays pure —
  /// the lookup needs DB access).
  static String formatMessagePreview(
    String? body,
    dynamic decodedContent, {
    String? reactionParentPreview,
  }) {
    if (decodedContent is AttachmentContent) {
      return _attachmentPreview(decodedContent.mimeType, decodedContent.filename);
    }
    if (decodedContent is RemoteAttachmentContent) {
      // RemoteAttachmentContent carries filename but no MIME — infer from ext.
      return _attachmentPreview(null, decodedContent.filename);
    }
    if (decodedContent is MultiRemoteAttachmentContent) {
      final items = decodedContent.attachments;
      if (items.length == 1) return _attachmentPreview(null, items.first.filename);
      final allImages = items.every(
          (a) => _attachmentPreview(null, a.filename) == 'sent an image 🖼️');
      return allImages
          ? 'sent ${items.length} photos 🖼️'
          : 'sent ${items.length} files 📎';
    }

    if (decodedContent is Reaction) {
      final emoji = decodedContent.content;
      if (reactionParentPreview != null && reactionParentPreview.isNotEmpty) {
        final snippet = reactionParentPreview.length > 40
            ? '${reactionParentPreview.substring(0, 40)}…'
            : reactionParentPreview;
        return 'reacted $emoji to ‘$snippet’';
      }
      return 'reacted $emoji to a message';
    }

    // Reply: preview the inner (replied-with) content. The clean value lives
    // on decodedContent.content (decoded by ReplyCodec); never use the raw
    // `body`, which on Android is the native SDK's TextCodec-default
    // stringification of the nested EncodedContent (literally
    // "xmtp.org…text…UTF-8…") for any non-text type.
    if (decodedContent is Reply) {
      final inner = decodedContent.content;
      return formatMessagePreview(inner is String ? inner : null, inner);
    }

    if (decodedContent is ActionsContent) {
      final desc = decodedContent.description;
      return desc.isNotEmpty
          ? (desc.length > 100 ? '${desc.substring(0, 100)}...' : desc)
          : 'Menu';
    }
    if (decodedContent is IntentContent) {
      final label = decodedContent.metadata?['actionLabel'] as String? ??
          decodedContent.actionId;
      return 'Tapped: $label';
    }

    // Money. Without this branch both would fall through to the text branch
    // below and render as an EMPTY notification — `body` for a non-String content type is
    // the wire `fallback` field, which is a proto3 string and is simply "" when
    // the sender never set one (xmtp_plugin's send path never does). So a
    // PublicOS payment would produce a blank line under the sender's name.
    //
    // NOT the codecs' own `getFallback()`: it is dead code (never called), and
    // WalletSendCallsCodec's dumps the entire request as raw JSON.
    if (decodedContent is TransactionReference) {
      return _receiptPreview(decodedContent);
    }
    if (decodedContent is WalletSendCalls) {
      return _paymentRequestPreview(decodedContent);
    }

    // Plain text: prefer the codec-decoded String over the native `body`.
    // They match for genuine text; for anything the native SDK mis-stringified
    // the decoded String is the trustworthy source.
    final text = decodedContent is String ? decodedContent : body;
    if (text != null && text.isNotEmpty) {
      final urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);
      if (urlPattern.hasMatch(text)) {
        final trimmed = text.trim();
        if (urlPattern.stringMatch(trimmed) == trimmed) {
          return 'shared a link 🔗';
        }
      }
      return text.length > 100 ? '${text.substring(0, 100)}...' : text;
    }

    return '';
  }

  /// A **receipt** (`transactionReference`) — "someone paid you".
  ///
  /// The amount comes from `metadata`, which is **sender-supplied and only
  /// advisory**. Our own session writes the RAW on-chain integer paired with
  /// `decimals` (message_input.dart), which formats correctly — but a
  /// non-conformant sender stamps the *human* value (`4.0`) alongside
  /// `decimals: 18`, which divides down to ~0. [PublicOSWallets.previewAmountText]
  /// returns null in that case and we drop to the amount-less sentence.
  ///
  /// **A preview must never announce a payment of zero.** The chat card can
  /// afford to decode the true amount from the tx on chain
  /// ([PublicOSWallets.fetchTxTransferRawAmount]); a preview is synchronous and
  /// runs per-message in the notification loop, so it cannot — it degrades
  /// instead.
  static String _receiptPreview(TransactionReference ref) {
    final m = ref.metadata;
    final amount = m?.amount;
    final decimals = m?.decimals;
    if (amount != null && decimals != null) {
      // `amount` is a double on the wire but semantically an integer count of
      // base units; toStringAsFixed(0) avoids scientific notation on big values.
      final raw = BigInt.tryParse(amount.toStringAsFixed(0));
      if (raw != null) {
        final text =
            PublicOSWallets.previewAmountText(raw, decimals, m?.currency);
        if (text != null) return 'sent you $text 💸';
      }
    }
    return 'sent you a payment 💸';
  }

  /// A **payment request** (`walletSendCalls`) — an invoice.
  ///
  /// Unlike a receipt, this carries **no amount in its metadata** — the amount
  /// lives in the ERC-20 calldata. [PublicOSWallets.decodeErc20Transfer] is a
  /// pure calldata decode with **no network call**, so the real figure is
  /// available even here in a synchronous preview.
  static String _paymentRequestPreview(WalletSendCalls wsc) {
    final chainId = PublicOSWallets.parseChainId(wsc.chainId);

    // 1. The CALLDATA — authoritative. It cannot lie about the amount, unlike
    //    the sender-supplied metadata. Needs the token registry to turn the
    //    contract address into a symbol + decimals, so it only works for tokens
    //    we know locally (which includes OX, whose address is runtime-resolved).
    for (final call in wsc.calls) {
      final token = call.to;
      if (token == null || chainId == null) continue;
      final transfer = PublicOSWallets.decodeErc20Transfer(token, call.data);
      if (transfer == null) continue;
      final meta = PublicOSWallets.tokenMetaSync(chainId, token);
      if (meta == null) continue; // unknown token — fall through to metadata
      final text = PublicOSWallets.previewAmountText(
          transfer.rawAmount, meta.decimals, meta.symbol);
      if (text != null) return 'requested $text 🧾';
    }

    // 2. The self-describing METADATA our sender writes (currency / raw amount /
    //    decimals — message_input.dart). Advisory, so it gets the same zero
    //    guard. This is the only route the iOS NSE has (no registry, no chain
    //    read), and it's also what rescues a token missing from our registry.
    for (final call in wsc.calls) {
      final extra = call.metadata?.extra;
      if (extra == null) continue;
      final raw = _bigIntFrom(extra['amount']);
      final decimals = (extra['decimals'] as num?)?.toInt();
      if (raw == null || decimals == null) continue;
      final text = PublicOSWallets.previewAmountText(
          raw, decimals, extra['currency'] as String?);
      if (text != null) return 'requested $text 🧾';
    }

    // 3. An agent's own invoice line.
    for (final call in wsc.calls) {
      final d = call.metadata?.description?.trim();
      if (d != null && d.isNotEmpty) {
        return d.length > 100 ? '${d.substring(0, 100)}...' : d;
      }
    }
    return 'requested a payment 🧾';
  }

  /// A raw base-unit amount off the wire. It rides as a decimal STRING (a JSON
  /// number loses precision past 2^53, and an 18-decimal amount blows through
  /// that immediately) — but tolerate a number from a sender that used one.
  static BigInt? _bigIntFrom(dynamic v) {
    if (v == null) return null;
    if (v is String) return BigInt.tryParse(v.trim());
    if (v is int) return BigInt.from(v);
    if (v is num) return BigInt.tryParse(v.toStringAsFixed(0));
    return null;
  }

  /// Classify an attachment by MIME (preferred) or filename extension and
  /// return the notification body string. Image / video / GIF get distinct
  /// labels; everything else falls through to "sent a file".
  static String _attachmentPreview(String? mimeType, String filename) {
    final mime = mimeType?.toLowerCase() ?? '';
    final name = filename.toLowerCase();
    final isGif = mime == 'image/gif' || name.endsWith('.gif');
    if (isGif) return 'sent a GIF 🎞️';
    final isVideo = mime.startsWith('video/') ||
        const {'.mp4', '.webm', '.mov', '.m4v'}
            .any((ext) => name.endsWith(ext));
    if (isVideo) return 'sent a video 🎬';
    final isImage = mime.startsWith('image/') ||
        const {'.jpg', '.jpeg', '.png', '.webp', '.bmp', '.svg', '.heic', '.heif'}
            .any((ext) => name.endsWith(ext));
    if (isImage) return 'sent an image 🖼️';
    return 'sent a file 📎';
  }

  /// Look up the locally-stored XMTP message identified by [xmtpMessageId]
  /// (the `reference` field on a [Reaction]) and return a short preview of
  /// it via [formatMessagePreview]. Returns null if the parent isn't in the
  /// local DB or decoding fails — caller should fall back to a generic
  /// "reacted to a message" string.
  ///
  /// All three context args are optional and default to PublicOS globals so
  /// FG callers don't have to pass anything. Bg sweep — which runs in a
  /// fresh isolate without the globals set — must pass its own [database],
  /// [sessionAddress], and [ownerInboxId] explicitly.
  static Future<String?> previewForReactedMessage(
    String xmtpMessageId, {
    db.AppDatabase? database,
    String? sessionAddress,
    String? ownerInboxId,
  }) async {
    final dbInstance = database ?? PublicOS.database;
    final sessionAddr = sessionAddress ?? PublicOS.sessionBlockchainAddress;
    final inboxId = ownerInboxId ?? PublicOS.clientXmtpInboxId;
    if (sessionAddr == null || inboxId == null) return null;
    try {
      final row = await (dbInstance.select(dbInstance.messages)
            ..where((m) =>
                m.idXmtp.equals(xmtpMessageId) &
                m.sessionAddress.equals(sessionAddr) &
                m.ownerInboxId.equals(inboxId))
            ..limit(1))
          .getSingleOrNull();
      if (row == null) return null;
      final raw = jsonDecode(row.xmtpMessageData) as Map<String, dynamic>;
      final inflated = _reconstructContent(raw);
      final body = inflated['body'] as String?;
      final content = inflated['decodedContent'];
      final preview = formatMessagePreview(body, content);
      return preview.isEmpty ? null : preview;
    } catch (e) {
      Log.w(_tag, '[notif] previewForReactedMessage failed: $e');
      return null;
    }
  }

  // ==========================================================================
  // READ RECEIPTS (throttled, setting-gated)
  // ==========================================================================

  static final Map<String, DateTime> _readReceiptThrottle = {};

  /// Send a read receipt if enabled and not throttled (30s per conversation).
  static Future<bool> sendReadReceipt(
      String conversationTopic, String targetInboxId) async {
    final sendSetting = await PublicOSSettings.getSetting('read_receipt_send');
    final sendEnabled = sendSetting?.value == 'true';
    if (!sendEnabled) return false;

    final lastSent = _readReceiptThrottle[conversationTopic];
    final now = DateTime.now();
    if (lastSent != null && now.difference(lastSent).inSeconds < 30) {
      return false;
    }

    try {
      await sendMessageByInboxId(
        targetInboxId,
        conversationTopic,
        const ReadReceipt(),
        'xmtp.org',
        'readReceipt',
      );
      _readReceiptThrottle[conversationTopic] = now;
      return true;
    } catch (e) {
      Log.e(_tag, 'sendReadReceipt error: $e');
      return false;
    }
  }

  // ==========================================================================
  // REMOTE ATTACHMENT ENCRYPTION
  // ==========================================================================

  /// Wrap a file in a spec-compliant XMTP RemoteStaticAttachment envelope,
  /// upload the ciphertext to the user's feed server, and return a
  /// ready-to-send [RemoteAttachmentContent].
  ///
  /// The encrypted payload is an `EncodedContent` protobuf of type
  /// `xmtp.org/attachment` wrapping an [AttachmentContent] — the exact shape
  /// produced by xmtp-android / xmtp-ios / xmtp-js. Receivers running any of
  /// those SDKs decode our payload through their normal codec registry path.
  ///
  /// Encrypting the raw file bytes directly (what xmtp_plugin before 1.0.5
  /// did) decrypts into bare bytes (not a protobuf), and every spec-compliant
  /// receiver throws on parse with no fallback.
  static Future<RemoteAttachmentContent> prepareRemoteAttachment(
    Uint8List fileBytes,
    String filename, {
    String? mimeType,
    String? serverUrl,
    String? description,
  }) async {
    // Wrap the file in the standard Attachment envelope, serialize to an
    // EncodedContent protobuf, and AES-256-GCM encrypt the result. Output is
    // byte-identical to the canonical native-SDK `encodeEncrypted` path.
    final encrypted = await RemoteAttachmentCodec.encodeEncrypted(
      AttachmentContent(
        data: fileBytes,
        mimeType: mimeType ?? 'application/octet-stream',
        filename: filename,
      ),
      AttachmentCodec(),
      filename: filename,
    );

    // Encrypted ciphertext defeats both magic-byte and content-sniff paths on
    // the server. Pass the explicit MIME so the upload's allow-list check uses
    // the original media type, not whatever the random-looking ciphertext would
    // sniff to.
    final result = await PublicOSSsp.uploadMedia(
      encrypted.payload,
      filename,
      mimeType: mimeType,
      serverAddress: serverUrl,
    );

    if (!result.success || result.data == null) {
      final msg = result.error?['message'] ?? 'Upload failed';
      throw Exception(msg);
    }

    final uploadedUrl = result.data!.url;
    final scheme = Uri.parse(uploadedUrl).scheme;

    return RemoteAttachmentContent(
      url: uploadedUrl,
      contentDigest: encrypted.contentDigest,
      secret: encrypted.secret,
      salt: encrypted.salt,
      nonce: encrypted.nonce,
      scheme: scheme,
      contentLength: encrypted.payload.length,
      filename: filename,
      description: description,
    );
  }
}
