import 'package:publicos_core/src/models/contact.dart';
import 'package:publicos_core/src/models/member.dart';

/// The type of an XMTP conversation.
enum ConversationType { dm, group }

/// Represents an XMTP conversation — a messaging channel.
///
/// A conversation is either a DM (1:1 between inbox IDs) or a group.
/// Person identity is decoupled: DMs have a [peerInboxId] that the view layer
/// resolves to a [Contact] and stores in [contact] for display.
///
/// Groups carry their own metadata (name, image, description, members) and
/// don't have a single "peer" — member identities are resolved per-sender
/// when displayed in the chat screen.
class XmtpConversation {
  /// XMTP topic string. Primary key together with [sessionAddress].
  final String topic;

  /// DM or group.
  final ConversationType type;

  /// For DMs: the peer's inbox ID (64-char hex).
  /// For groups: null.
  final String? peerInboxId;

  /// For groups: the group name.
  final String? groupName;

  /// For groups: image URL (square).
  final String? groupImageUrl;

  /// For groups: description.
  final String? groupDescription;

  /// For groups: pinned frame URL.
  final String? pinnedFrameUrl;

  /// For groups: participant list (inbox IDs + addresses).
  final List<Member>? members;

  /// When the conversation was created (group creation time, or DM
  /// first-message time). Nullable because XMTP doesn't always provide it.
  final DateTime? createdAt;

  /// Resolved peer contact. Populated by the view layer via
  /// `PublicOSContacts.findContactByInboxId(peerInboxId)`.
  /// NOT persisted in the database — always re-resolved on load.
  Contact? contact;

  XmtpConversation({
    required this.topic,
    required this.type,
    this.peerInboxId,
    this.groupName,
    this.groupImageUrl,
    this.groupDescription,
    this.pinnedFrameUrl,
    this.members,
    this.createdAt,
    this.contact,
  });

  /// Convenience: a displayable name for the conversation.
  /// Cascades: resolved contact → group name → truncated inbox ID → 'Unknown'.
  String get displayName {
    if (contact != null) return contact!.displayName;
    if (type == ConversationType.group && groupName != null && groupName!.isNotEmpty) {
      return groupName!;
    }
    if (peerInboxId != null && peerInboxId!.length >= 12) {
      return '${peerInboxId!.substring(0, 6)}..${peerInboxId!.substring(peerInboxId!.length - 6)}';
    }
    return 'Unknown';
  }

  /// Convenience: an avatar URL for the conversation.
  /// DMs use the resolved contact's avatar. Groups use the group image.
  String? get avatarUrl {
    if (type == ConversationType.dm) return contact?.avatarUrl;
    return groupImageUrl;
  }

  /// Convenience: is this a DM?
  bool get isDm => type == ConversationType.dm;

  /// Convenience: is this a group?
  bool get isGroup => type == ConversationType.group;

  XmtpConversation copyWith({
    String? topic,
    ConversationType? type,
    String? peerInboxId,
    String? groupName,
    String? groupImageUrl,
    String? groupDescription,
    String? pinnedFrameUrl,
    List<Member>? members,
    DateTime? createdAt,
    Contact? contact,
  }) {
    return XmtpConversation(
      topic: topic ?? this.topic,
      type: type ?? this.type,
      peerInboxId: peerInboxId ?? this.peerInboxId,
      groupName: groupName ?? this.groupName,
      groupImageUrl: groupImageUrl ?? this.groupImageUrl,
      groupDescription: groupDescription ?? this.groupDescription,
      pinnedFrameUrl: pinnedFrameUrl ?? this.pinnedFrameUrl,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      contact: contact ?? this.contact,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topic': topic,
      'type': type.name,
      if (peerInboxId != null) 'peerInboxId': peerInboxId,
      if (groupName != null) 'groupName': groupName,
      if (groupImageUrl != null) 'groupImageUrl': groupImageUrl,
      if (groupDescription != null) 'groupDescription': groupDescription,
      if (pinnedFrameUrl != null) 'pinnedFrameUrl': pinnedFrameUrl,
      if (members != null) 'members': members!.map((m) => m.toJson()).toList(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  factory XmtpConversation.fromJson(Map<String, dynamic> json) {
    return XmtpConversation(
      topic: json['topic'] as String,
      type: ConversationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ConversationType.dm,
      ),
      peerInboxId: json['peerInboxId'] as String?,
      groupName: json['groupName'] as String?,
      groupImageUrl: json['groupImageUrl'] as String?,
      groupDescription: json['groupDescription'] as String?,
      pinnedFrameUrl: json['pinnedFrameUrl'] as String?,
      members: (json['members'] as List?)
          ?.map((m) => Member.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}
