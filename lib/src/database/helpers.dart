import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:publicos_core/src/database/database.dart';
import 'package:publicos_core/src/models/contact.dart' as models;
import 'package:publicos_core/src/models/xmtp_conversation.dart' as models;
import 'package:publicos_core/src/models/member.dart';
import 'package:publicos_core/src/utils/log.dart';
import 'package:publicos_core/src/models/record_model.dart';
import 'package:wallet/wallet.dart';

/// Helper class to convert between Drift database rows and model objects.
class DatabaseHelpers {
  // ── CONTACTS ────────────────────────────────────────────────────────────

  /// Convert a Drift Contact row into a Contact model.
  static models.Contact contactFromRow(Contact row) {
    // records
    List<Record> records = const [];
    if (row.records != null && row.records!.isNotEmpty) {
      try {
        final recordsJson = jsonDecode(row.records!) as List;
        records = recordsJson
            .map((r) => Record.fromJson(r as Map<String, dynamic>))
            .toList();
      } catch (e) {
        Log.e('Database', 'Error parsing records: $e');
      }
    }

    // sessions
    List<models.ContactSession>? sessions;
    if (row.sessions != null && row.sessions!.isNotEmpty) {
      try {
        final sessionsJson = jsonDecode(row.sessions!) as List;
        sessions = sessionsJson
            .map((c) => models.ContactSession.fromJson(c as Map<String, dynamic>))
            .toList();
      } catch (e) {
        Log.e('Database', 'Error parsing sessions: $e');
      }
    }

    // registeredInboxIDs
    List<models.InboxEntry>? registeredInboxIDs;
    if (row.registeredInboxIDs != null && row.registeredInboxIDs!.isNotEmpty) {
      try {
        final idsJson = jsonDecode(row.registeredInboxIDs!) as List;
        registeredInboxIDs = idsJson
            .map((e) => models.InboxEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        Log.e('Database', 'Error parsing registeredInboxIDs: $e');
      }
    }

    // orgMembers
    List<EthereumAddress>? orgMembers;
    if (row.orgMembers != null && row.orgMembers!.isNotEmpty) {
      try {
        final membersJson = jsonDecode(row.orgMembers!) as List;
        orgMembers = membersJson
            .map((a) => EthereumAddress.fromHex(a as String))
            .toList();
      } catch (e) {
        Log.e('Database', 'Error parsing orgMembers: $e');
      }
    }

    return models.Contact(
      displayName: row.displayName,
      publicosDisplayName: row.publicosDisplayName,
      publicosAddress: row.publicosAddress != null
          ? EthereumAddress.fromHex(row.publicosAddress!)
          : null,
      isOrgAccount: row.isOrgAccount,
      sessions: sessions,
      records: records,
      registeredInboxIDs: registeredInboxIDs,
      orgMembers: orgMembers,
      orgMemberCount: row.orgMemberCount,
      isBlocked: row.isBlocked,
      isSupport: row.isSupport,
      createdBy: row.createdBy,
      founderAddress: row.founderAddress != null
          ? EthereumAddress.fromHex(row.founderAddress!)
          : null,
      createdAt: row.createdAt != null ? DateTime.parse(row.createdAt!) : null,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
      xmtpConversationTopic: row.xmtpConversationTopic,
      isCitizen: row.isCitizen,
      isPublicOrg: row.isPublicOrg,
      verifiedNftAvatar: row.verifiedNftAvatar,
      verifiedNftBanner: row.verifiedNftBanner,
      bookmarked: row.bookmarked,
    );
  }

  /// Convert a Contact model into a map for insertion via `saveContactRaw`.
  static Map<String, dynamic> contactToMap(
      models.Contact contact, String sessionAddress) {
    return {
      'displayName': contact.displayName,
      'publicosDisplayName': contact.publicosDisplayName,
      'publicosAddress': contact.publicosAddress?.eip55With0x,
      'isOrgAccount': contact.isOrgAccount,
      'sessions': contact.sessions != null
          ? jsonEncode(contact.sessions!.map((c) => c.toJson()).toList())
          : null,
      'records': contact.records.isNotEmpty
          ? jsonEncode(contact.records.map((r) => r.toJson()).toList())
          : null,
      'registeredInboxIDs': contact.registeredInboxIDs != null
          ? jsonEncode(contact.registeredInboxIDs!.map((e) => e.toJson()).toList())
          : null,
      'orgMembers': contact.orgMembers != null
          ? jsonEncode(contact.orgMembers!.map((a) => a.eip55With0x).toList())
          : null,
      'orgMemberCount': contact.orgMemberCount,
      'isBlocked': contact.isBlocked,
      'isSupport': contact.isSupport,
      'createdBy': contact.createdBy,
      'founderAddress': contact.founderAddress?.eip55With0x,
      'createdAt': contact.createdAt?.toIso8601String(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'sessionAddress': sessionAddress,
      'xmtpConversationTopic': contact.xmtpConversationTopic,
      'isCitizen': contact.isCitizen,
      'isPublicOrg': contact.isPublicOrg,
      'verifiedNftAvatar': contact.verifiedNftAvatar,
      'verifiedNftBanner': contact.verifiedNftBanner,
      'bookmarked': contact.bookmarked,
    };
  }

  // ── CONVERSATIONS ───────────────────────────────────────────────────────

  /// Convert a Drift Conversation row into an XmtpConversation model.
  static models.XmtpConversation conversationFromRow(Conversation row) {
    List<Member>? members;
    if (row.membersJson != null && row.membersJson!.isNotEmpty) {
      try {
        final membersList = jsonDecode(row.membersJson!) as List;
        members = membersList
            .map((m) => Member.fromJson(m as Map<String, dynamic>))
            .toList();
      } catch (e) {
        Log.e('Database', 'Error parsing conversation members: $e');
      }
    }

    return models.XmtpConversation(
      topic: row.topic,
      type: row.type == 'group'
          ? models.ConversationType.group
          : models.ConversationType.dm,
      peerInboxId: row.peerInboxId,
      groupName: row.groupName,
      groupImageUrl: row.groupImageUrl,
      groupDescription: row.groupDescription,
      pinnedFrameUrl: row.pinnedFrameUrl,
      members: members,
      createdAt: row.createdAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.createdAt!)
          : null,
    );
  }

  /// Convert an XmtpConversation model into a ConversationsCompanion for upsert.
  static ConversationsCompanion conversationToCompanion(
      models.XmtpConversation conversation,
      String sessionAddress,
      String ownerInboxId) {
    return ConversationsCompanion.insert(
      topic: conversation.topic,
      type: conversation.type.name,
      peerInboxId: Value(conversation.peerInboxId),
      groupName: Value(conversation.groupName),
      groupImageUrl: Value(conversation.groupImageUrl),
      groupDescription: Value(conversation.groupDescription),
      pinnedFrameUrl: Value(conversation.pinnedFrameUrl),
      membersJson: Value(conversation.members != null
          ? jsonEncode(conversation.members!.map((m) => m.toJson()).toList())
          : null),
      createdAt: Value(conversation.createdAt?.millisecondsSinceEpoch),
      sessionAddress: sessionAddress,
      ownerInboxId: ownerInboxId,
    );
  }
}
