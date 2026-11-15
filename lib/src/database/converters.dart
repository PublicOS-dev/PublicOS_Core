import 'dart:convert';
import 'dart:typed_data';
import 'package:drift/drift.dart';
import 'package:publicos_core/src/models/contact.dart';
import 'package:publicos_core/src/models/member.dart';
import 'package:publicos_core/src/models/record_model.dart';
import 'package:publicos_core/src/utils/log.dart';

/// Converts List<Record> to/from JSON string for database storage
class RecordsConverter extends TypeConverter<List<Record>, String> {
  const RecordsConverter();

  @override
  List<Record> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(fromDb);
      return jsonList
          .map((json) => Record.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      Log.e('Database', 'Error parsing records: $e');
      return [];
    }
  }

  @override
  String toSql(List<Record> value) {
    return jsonEncode(value.map((r) => r.toJson()).toList());
  }
}

/// Converts List<ContactSession> (messaging addresses) to/from JSON string
class SessionsConverter extends TypeConverter<List<ContactSession>, String> {
  const SessionsConverter();

  @override
  List<ContactSession> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(fromDb);
      return jsonList
          .map((json) => ContactSession.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      Log.e('Database', 'Error parsing sessions: $e');
      return [];
    }
  }

  @override
  String toSql(List<ContactSession> value) {
    return jsonEncode(value.map((c) => c.toJson()).toList());
  }
}

/// Converts List<Member> to/from JSON string
class MembersConverter extends TypeConverter<List<Member>, String> {
  const MembersConverter();

  @override
  List<Member> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(fromDb);
      return jsonList
          .map((json) => Member.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      Log.e('Database', 'Error parsing members: $e');
      return [];
    }
  }

  @override
  String toSql(List<Member> value) {
    return jsonEncode(value.map((m) => m.toJson()).toList());
  }
}

/// Converts List<Map<String, String>> (registeredInboxIDs) to/from JSON string
class RegisteredInboxIDsConverter
    extends TypeConverter<List<Map<String, String>>, String> {
  const RegisteredInboxIDsConverter();

  @override
  List<Map<String, String>> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(fromDb);
      return jsonList
          .map((item) => Map<String, String>.from(item as Map))
          .toList();
    } catch (e) {
      Log.e('Database', 'Error parsing registered inbox IDs: $e');
      return [];
    }
  }

  @override
  String toSql(List<Map<String, String>> value) {
    return jsonEncode(value);
  }
}

/// Converts Map<String, dynamic> (XMTP message data) to/from JSON string
class XmtpMessageDataConverter
    extends TypeConverter<Map<String, dynamic>, String> {
  const XmtpMessageDataConverter();

  @override
  Map<String, dynamic> fromSql(String fromDb) {
    if (fromDb.isEmpty) return {};
    try {
      return jsonDecode(fromDb) as Map<String, dynamic>;
    } catch (e) {
      Log.e('Database', 'Error parsing XMTP message data: $e');
      return {};
    }
  }

  @override
  String toSql(Map<String, dynamic> value) {
    return jsonEncode(value);
  }
}

/// Converts Uint8List to/from Uint8List (for BLOB storage)
/// Drift handles Uint8List natively, but this is for explicit conversion if needed
class BlobConverter extends TypeConverter<Uint8List, Uint8List> {
  const BlobConverter();

  @override
  Uint8List fromSql(Uint8List fromDb) => fromDb;

  @override
  Uint8List toSql(Uint8List value) => value;
}
