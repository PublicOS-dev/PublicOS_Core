import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';
import 'package:meta/meta.dart';
import 'package:publicos_core/src/utils/log.dart';
import 'package:xmtp_plugin/codecs.dart';


/// Defines the types of messages that can be sent/received
enum MessageType {
  text,
  attachment,
  remoteAttachment,
  group_updated,
  reply,
  reaction,
  readReceipt,
  // Appended, never reordered: stored rows carry these names.
  multiRemoteAttachment;

  @override
  String toString() => name.toLowerCase();

  static MessageType fromString(String value) {
    return values.firstWhere(
      (type) => type.toString() == value.toLowerCase(),
      orElse: () => MessageType.text,
    );
  }
}

/// Represents the content of a message with its type and value
@immutable
class MessageContent {
  static const _tag = 'Messages';

  final MessageType type;
  final dynamic value;
  final String? authorityId;
  final String? typeId;
  final Map<String, dynamic>? metadata;

  const MessageContent({
    required this.type,
    required this.value,
    this.authorityId,
    this.typeId,
    this.metadata,
  });
// In message.dart - Improved MessageContent.fromJson
  factory MessageContent.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type']?.toString() ?? '';
    final type = MessageType.fromString(typeStr);
    final typeId = json['typeId']?.toString();

    // Initialize content value
    dynamic contentValue;

    // Handle different types of content based on typeId
    if (typeId == 'attachment') {
      if (json['value'] is Map<String, dynamic>) {
        // Directly use the map structure for AttachmentContent
        contentValue = AttachmentContent.fromJson(json['value'] as Map<String, dynamic>);
      } else if (json['value'] is String && json['value'].toString().startsWith('{')) {
        // Try to parse JSON string
        try {
          final Map<String, dynamic> parsed = jsonDecode(json['value'].toString());
          contentValue = AttachmentContent.fromJson(parsed);
        } catch (e) {
          Log.e(_tag, 'Error parsing attachment JSON: $e');
          contentValue = json['value'];
        }
      } else {
        // Keep original value
        contentValue = json['value'];
      }
    } else if (typeId == 'remoteStaticAttachment') {
      if (json['value'] is Map<String, dynamic>) {
        contentValue = RemoteAttachmentContent.fromJson(json['value'] as Map<String, dynamic>);
      } else if (json['value'] is String) {
        try {
          // First try to parse as JSON
          final Map<String, dynamic> parsed = jsonDecode(json['value'].toString());
          contentValue = RemoteAttachmentContent.fromJson(parsed);
        } catch (e) {
          // Not JSON, could be just the URL string
          contentValue = json['value'];
        }
      } else {
        contentValue = json['value'];
      }
    } else if (typeId == 'multiRemoteStaticAttachment') {
      final raw = json['value'];
      try {
        final Map<String, dynamic>? parsed = raw is Map
            ? Map<String, dynamic>.from(raw)
            : (raw is String && raw.startsWith('{'))
                ? jsonDecode(raw) as Map<String, dynamic>
                : null;
        contentValue = parsed != null ? MultiRemoteAttachmentContent.fromJson(parsed) : raw;
      } catch (e) {
        Log.e(_tag, 'Error parsing multi-attachment JSON: $e');
        contentValue = raw;
      }
    } else if (typeId == 'reply') {
      if (json['value'] is Map<String, dynamic>) {
        contentValue = Reply.fromJson(json['value'] as Map<String, dynamic>);
      } else if (json['value'] is String) {
        try {
          final Map<String, dynamic> parsed = jsonDecode(json['value'].toString());
          contentValue = Reply.fromJson(parsed);
        } catch (e) {
          Log.e(_tag, 'Error parsing reply JSON: $e');
          contentValue = json['value'];
        }
      } else {
        contentValue = json['value'];
      }
    } else if (typeId == 'actions') {
      if (json['value'] is Map<String, dynamic>) {
        contentValue = ActionsContent.fromJson(json['value'] as Map<String, dynamic>);
      } else if (json['value'] is String && json['value'].toString().startsWith('{')) {
        try {
          final Map<String, dynamic> parsed = jsonDecode(json['value'].toString());
          contentValue = ActionsContent.fromJson(parsed);
        } catch (e) {
          Log.e(_tag, 'Error parsing actions JSON: $e');
          contentValue = json['value'];
        }
      } else {
        contentValue = json['value'];
      }
    } else if (typeId == 'intent') {
      if (json['value'] is Map<String, dynamic>) {
        contentValue = IntentContent.fromJson(json['value'] as Map<String, dynamic>);
      } else if (json['value'] is String && json['value'].toString().startsWith('{')) {
        try {
          final Map<String, dynamic> parsed = jsonDecode(json['value'].toString());
          contentValue = IntentContent.fromJson(parsed);
        } catch (e) {
          Log.e(_tag, 'Error parsing intent JSON: $e');
          contentValue = json['value'];
        }
      } else {
        contentValue = json['value'];
      }
    } else if (typeId == 'reaction') {
      if (json['value'] is Map<String, dynamic>) {
        contentValue = Reaction.fromJson(json['value'] as Map<String, dynamic>);
      } else if (json['value'] is String) {
        try {
          final Map<String, dynamic> parsed = jsonDecode(json['value'].toString());
          contentValue = Reaction.fromJson(parsed);
        } catch (e) {
          Log.e(_tag, 'Error parsing reaction JSON: $e');
          contentValue = json['value'];
        }
      } else {
        contentValue = json['value'];
      }
    } else {
      // Default for text and other types
      contentValue = json['value'];
    }

    return MessageContent(
      type: type,
      value: contentValue,
      authorityId: json['authorityId'],
      typeId: typeId,
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
    );
  }

// In message.dart - Improved MessageContent.toJson
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {
      'type': type.toString(),
      'authorityId': authorityId,
      'typeId': typeId,
      'metadata': metadata,
    };

    // Handle specialized types for serialization
    if (value is AttachmentContent) {
      // Store AttachmentContent as a full JSON object
      result['value'] = (value as AttachmentContent).toJson();
    } else if (value is RemoteAttachmentContent) {
      // Store RemoteAttachmentContent as a full JSON object
      result['value'] = (value as RemoteAttachmentContent).toJson();
    } else if (value is MultiRemoteAttachmentContent) {
      result['value'] = (value as MultiRemoteAttachmentContent).toJson();
    } else if (value is Reply) {
      // Store Reply as a full JSON object
      result['value'] = (value as Reply).toJson();
    } else if (value is Reaction) {
      // Store Reaction as a full JSON object
      result['value'] = (value as Reaction).toJson();
    } else if (value is ActionsContent) {
      result['value'] = (value as ActionsContent).toJson();
    } else if (value is IntentContent) {
      result['value'] = (value as IntentContent).toJson();
    } else if (value is Map) {
      // If it's already a map, keep it as is
      result['value'] = value;
    } else {
      // For primitive types
      result['value'] = value;
    }

    return result;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageContent && other.type == type && other.value == value && other.authorityId == authorityId && other.typeId == typeId;
  }

  @override
  int get hashCode => Object.hash(type, value, authorityId, typeId);

  MessageContent copyWith({
    MessageType? type,
    dynamic value,
    String? authorityId,
    String? typeId,
    Map<String, dynamic>? metadata,
  }) {
    return MessageContent(
      type: type ?? this.type,
      value: value ?? this.value,
      authorityId: authorityId ?? this.authorityId,
      typeId: typeId ?? this.typeId,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Data structure for displaying reactions on a message
class MessageReactionSummary {
  final String emoji;
  final int count;
  final bool hasMyReaction;
  final List<String> senderInboxIds;

  const MessageReactionSummary({
    required this.emoji,
    required this.count,
    required this.hasMyReaction,
    this.senderInboxIds = const [],
  });
}

/// Represents a chat message with all its properties and metadata
@immutable
class Message {
  static const _tag = 'Messages';

  final int id;
  final String? idXmtp;
  final String xmtpConversationTopic;
  final DateTime timestamp;
  final String? body; // Plain text body from XMTP
  final MessageContent content;
  final String senderAddress;
  final String? senderInboxId; // Added for new messaging logic
  final bool isPending;
  final bool sendFailed;
  final Uint8List? encodedContent;
  final Map<String, dynamic>? parameters;
  final String? referenceMessageId; // Added for replies and reactions
  final List<MessageReactionSummary>? reactions; // Reaction display data
  final bool isRead; // Unread tracking bookmark

  const Message({
    required this.id,
    this.idXmtp,
    required this.xmtpConversationTopic,
    required this.timestamp,
    this.body,
    required this.content,
    required this.senderAddress,
    this.senderInboxId,
    this.isPending = false,
    this.sendFailed = false,
    this.isRead = false,
    this.encodedContent,
    this.parameters,
    this.referenceMessageId,
    this.reactions,
  });
// In message.dart - Improved Message.fromJson
  factory Message.fromJson(Map<String, dynamic> json) {
    MessageContent content;

    try {
      // Parse content based on its type
      if (json['content'] is String) {
        try {
          // Try to parse as JSON string
          final Map<String, dynamic> contentData = jsonDecode(json['content']);
          content = MessageContent.fromJson(contentData);
        } catch (e) {
          Log.e(_tag, 'Error parsing content JSON: $e');
          // Fallback for plain text
          content = MessageContent(
            type: MessageType.text,
            value: json['content']?.toString() ?? '',
            authorityId: json['authority_id'],
            typeId: json['type_id'],
          );
        }
      } else if (json['content'] is Map) {
        // Content is already a Map
        final contentMap = Map<String, dynamic>.from(json['content'] as Map);
        content = MessageContent.fromJson(contentMap);
      } else {
        // Fallback for other content types
        content = MessageContent(
          type: MessageType.text,
          value: json['content']?.toString() ?? '',
          authorityId: json['authority_id'],
          typeId: json['type_id'],
        );
      }
    } catch (e) {
      Log.e(_tag, 'Error creating MessageContent: $e');
      // Default fallback
      content = MessageContent(
        type: MessageType.text,
        value: json['content']?.toString() ?? '',
        authorityId: json['authority_id'],
        typeId: json['type_id'],
      );
    }

    // Handle encoded content
    Uint8List? encodedBytes;
    if (json['encoded_content'] != null) {
      if (json['encoded_content'] is Uint8List) {
        encodedBytes = json['encoded_content'];
      } else if (json['encoded_content'] is List) {
        encodedBytes = Uint8List.fromList(List<int>.from(json['encoded_content']));
      } else if (json['encoded_content'] is String) {
        try {
          encodedBytes = base64Decode(json['encoded_content']);
        } catch (e) {
          Log.e(_tag, 'Error decoding encoded content: $e');
        }
      }
    }

    // Handle parameters
    Map<String, dynamic>? parameters;
    if (json['parameters'] != null) {
      try {
        if (json['parameters'] is String) {
          parameters = jsonDecode(json['parameters']);
        } else if (json['parameters'] is Map) {
          parameters = Map<String, dynamic>.from(json['parameters']);
        }
      } catch (e) {
        Log.e(_tag, 'Error decoding parameters: $e');
      }
    }

    return Message(
      id: json['id'] as int,
      idXmtp: json['id_xmtp'] as String?,
      xmtpConversationTopic: json['xmtpConversationTopic'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp'] is String ? int.parse(json['timestamp']) : json['timestamp'] as int,
      ),
      body: json['body'] as String?,
      content: content,
      senderAddress: json['senderAddress'] as String,
      senderInboxId: json['sender_inbox_id'] as String?,
      isPending: json['is_pending'] == 1,
      sendFailed: json['send_failed'] == 1,
      isRead: json['is_read'] == 1,
      encodedContent: encodedBytes,
      parameters: parameters,
      referenceMessageId: json['reference_message_id'] as String?,
    );
  }

// In message.dart - Improved Message.toJson
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {
      'id': id,
      'id_xmtp': idXmtp,
      'xmtpConversationTopic': xmtpConversationTopic,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'body': body,
      'senderAddress': senderAddress,
      'sender_inbox_id': senderInboxId,
      'is_pending': isPending ? 1 : 0,
      'send_failed': sendFailed ? 1 : 0,
      'is_read': isRead ? 1 : 0,
      'reference_message_id': referenceMessageId,
    };

    // Properly serialize content
    try {
      // First convert to JSON object, then to string
      // This preserves the structure for proper parsing later
      final contentJson = content.toJson();
      result['content'] = jsonEncode(contentJson);

      // Also store direct values for query purposes
      result['authority_id'] = content.authorityId;
      result['type_id'] = content.typeId;
    } catch (e) {
      Log.e(_tag, 'Error encoding content: $e');
      // Fallback to string representation
      result['content'] = content.value?.toString() ?? '';
    }

    // Handle encoded content
    if (encodedContent != null) {
      result['encoded_content'] = base64Encode(encodedContent!);
    }

    // Handle parameters
    if (parameters != null) {
      result['parameters'] = jsonEncode(parameters);
    }

    return result;
  }

  /// Creates a new Message with updated properties
  Message copyWith({
    int? id,
    String? idXmtp,
    String? xmtpConversationTopic,
    DateTime? timestamp,
    String? body,
    MessageContent? content,
    String? senderAddress,
    String? senderInboxId,
    bool? isPending,
    bool? sendFailed,
    bool? isRead,
    Uint8List? encodedContent,
    Map<String, dynamic>? parameters,
    String? referenceMessageId,
    List<MessageReactionSummary>? reactions,
  }) {
    return Message(
      id: id ?? this.id,
      idXmtp: idXmtp ?? this.idXmtp,
      xmtpConversationTopic: xmtpConversationTopic ?? this.xmtpConversationTopic,
      timestamp: timestamp ?? this.timestamp,
      body: body ?? this.body,
      content: content ?? this.content,
      senderAddress: senderAddress ?? this.senderAddress,
      senderInboxId: senderInboxId ?? this.senderInboxId,
      isPending: isPending ?? this.isPending,
      sendFailed: sendFailed ?? this.sendFailed,
      isRead: isRead ?? this.isRead,
      encodedContent: encodedContent ?? this.encodedContent,
      parameters: parameters ?? this.parameters,
      referenceMessageId: referenceMessageId ?? this.referenceMessageId,
      reactions: reactions ?? this.reactions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message &&
        other.id == id &&
        other.idXmtp == idXmtp &&
        other.xmtpConversationTopic == xmtpConversationTopic &&
        other.timestamp == timestamp &&
        other.body == body &&
        other.content == content &&
        other.senderAddress == senderAddress &&
        other.senderInboxId == senderInboxId &&
        other.isPending == isPending &&
        other.sendFailed == sendFailed &&
        other.isRead == isRead &&
        other.referenceMessageId == referenceMessageId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        idXmtp,
        xmtpConversationTopic,
        timestamp,
        body,
        content,
        senderAddress,
        senderInboxId,
        isPending,
        sendFailed,
        isRead,
        referenceMessageId,
      );

  /// Returns a string representation of the Message for debugging
  @override
  String toString() => 'Message('
      'id: $id, '
      'idXmtp: $idXmtp, '
      'topic: $xmtpConversationTopic, '
      'timestamp: $timestamp, '
      'body: $body, '
      'senderAddress: $senderAddress, '
      'senderInboxId: $senderInboxId, '
      'content: ${content.value}, '
      'isPending: $isPending, '
      'sendFailed: $sendFailed)';
}
