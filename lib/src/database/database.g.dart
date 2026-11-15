// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idXmtpMeta = const VerificationMeta('idXmtp');
  @override
  late final GeneratedColumn<String> idXmtp = GeneratedColumn<String>(
      'id_xmtp', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _xmtpMessageDataMeta =
      const VerificationMeta('xmtpMessageData');
  @override
  late final GeneratedColumn<String> xmtpMessageData = GeneratedColumn<String>(
      'xmtp_message_data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _conversationTopicMeta =
      const VerificationMeta('conversationTopic');
  @override
  late final GeneratedColumn<String> conversationTopic =
      GeneratedColumn<String>('conversation_topic', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _senderInboxIdMeta =
      const VerificationMeta('senderInboxId');
  @override
  late final GeneratedColumn<String> senderInboxId = GeneratedColumn<String>(
      'sender_inbox_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sessionAddressMeta =
      const VerificationMeta('sessionAddress');
  @override
  late final GeneratedColumn<String> sessionAddress = GeneratedColumn<String>(
      'session_address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerInboxIdMeta =
      const VerificationMeta('ownerInboxId');
  @override
  late final GeneratedColumn<String> ownerInboxId = GeneratedColumn<String>(
      'owner_inbox_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeIdMeta = const VerificationMeta('typeId');
  @override
  late final GeneratedColumn<String> typeId = GeneratedColumn<String>(
      'type_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isPendingMeta =
      const VerificationMeta('isPending');
  @override
  late final GeneratedColumn<bool> isPending = GeneratedColumn<bool>(
      'is_pending', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_pending" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sendFailedMeta =
      const VerificationMeta('sendFailed');
  @override
  late final GeneratedColumn<bool> sendFailed = GeneratedColumn<bool>(
      'send_failed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("send_failed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_read" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        idXmtp,
        xmtpMessageData,
        timestamp,
        conversationTopic,
        senderInboxId,
        sessionAddress,
        ownerInboxId,
        typeId,
        isPending,
        sendFailed,
        isRead
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(Insertable<Message> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('id_xmtp')) {
      context.handle(_idXmtpMeta,
          idXmtp.isAcceptableOrUnknown(data['id_xmtp']!, _idXmtpMeta));
    }
    if (data.containsKey('xmtp_message_data')) {
      context.handle(
          _xmtpMessageDataMeta,
          xmtpMessageData.isAcceptableOrUnknown(
              data['xmtp_message_data']!, _xmtpMessageDataMeta));
    } else if (isInserting) {
      context.missing(_xmtpMessageDataMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('conversation_topic')) {
      context.handle(
          _conversationTopicMeta,
          conversationTopic.isAcceptableOrUnknown(
              data['conversation_topic']!, _conversationTopicMeta));
    } else if (isInserting) {
      context.missing(_conversationTopicMeta);
    }
    if (data.containsKey('sender_inbox_id')) {
      context.handle(
          _senderInboxIdMeta,
          senderInboxId.isAcceptableOrUnknown(
              data['sender_inbox_id']!, _senderInboxIdMeta));
    }
    if (data.containsKey('session_address')) {
      context.handle(
          _sessionAddressMeta,
          sessionAddress.isAcceptableOrUnknown(
              data['session_address']!, _sessionAddressMeta));
    } else if (isInserting) {
      context.missing(_sessionAddressMeta);
    }
    if (data.containsKey('owner_inbox_id')) {
      context.handle(
          _ownerInboxIdMeta,
          ownerInboxId.isAcceptableOrUnknown(
              data['owner_inbox_id']!, _ownerInboxIdMeta));
    } else if (isInserting) {
      context.missing(_ownerInboxIdMeta);
    }
    if (data.containsKey('type_id')) {
      context.handle(_typeIdMeta,
          typeId.isAcceptableOrUnknown(data['type_id']!, _typeIdMeta));
    }
    if (data.containsKey('is_pending')) {
      context.handle(_isPendingMeta,
          isPending.isAcceptableOrUnknown(data['is_pending']!, _isPendingMeta));
    }
    if (data.containsKey('send_failed')) {
      context.handle(
          _sendFailedMeta,
          sendFailed.isAcceptableOrUnknown(
              data['send_failed']!, _sendFailedMeta));
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {idXmtp, ownerInboxId},
      ];
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      idXmtp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id_xmtp']),
      xmtpMessageData: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}xmtp_message_data'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp'])!,
      conversationTopic: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}conversation_topic'])!,
      senderInboxId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender_inbox_id']),
      sessionAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}session_address'])!,
      ownerInboxId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_inbox_id'])!,
      typeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type_id']),
      isPending: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_pending'])!,
      sendFailed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}send_failed'])!,
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final int id;
  final String? idXmtp;
  final String xmtpMessageData;
  final int timestamp;
  final String conversationTopic;
  final String? senderInboxId;
  final String sessionAddress;
  final String ownerInboxId;
  final String? typeId;
  final bool isPending;
  final bool sendFailed;
  final bool isRead;
  const Message(
      {required this.id,
      this.idXmtp,
      required this.xmtpMessageData,
      required this.timestamp,
      required this.conversationTopic,
      this.senderInboxId,
      required this.sessionAddress,
      required this.ownerInboxId,
      this.typeId,
      required this.isPending,
      required this.sendFailed,
      required this.isRead});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || idXmtp != null) {
      map['id_xmtp'] = Variable<String>(idXmtp);
    }
    map['xmtp_message_data'] = Variable<String>(xmtpMessageData);
    map['timestamp'] = Variable<int>(timestamp);
    map['conversation_topic'] = Variable<String>(conversationTopic);
    if (!nullToAbsent || senderInboxId != null) {
      map['sender_inbox_id'] = Variable<String>(senderInboxId);
    }
    map['session_address'] = Variable<String>(sessionAddress);
    map['owner_inbox_id'] = Variable<String>(ownerInboxId);
    if (!nullToAbsent || typeId != null) {
      map['type_id'] = Variable<String>(typeId);
    }
    map['is_pending'] = Variable<bool>(isPending);
    map['send_failed'] = Variable<bool>(sendFailed);
    map['is_read'] = Variable<bool>(isRead);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      idXmtp:
          idXmtp == null && nullToAbsent ? const Value.absent() : Value(idXmtp),
      xmtpMessageData: Value(xmtpMessageData),
      timestamp: Value(timestamp),
      conversationTopic: Value(conversationTopic),
      senderInboxId: senderInboxId == null && nullToAbsent
          ? const Value.absent()
          : Value(senderInboxId),
      sessionAddress: Value(sessionAddress),
      ownerInboxId: Value(ownerInboxId),
      typeId:
          typeId == null && nullToAbsent ? const Value.absent() : Value(typeId),
      isPending: Value(isPending),
      sendFailed: Value(sendFailed),
      isRead: Value(isRead),
    );
  }

  factory Message.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<int>(json['id']),
      idXmtp: serializer.fromJson<String?>(json['idXmtp']),
      xmtpMessageData: serializer.fromJson<String>(json['xmtpMessageData']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      conversationTopic: serializer.fromJson<String>(json['conversationTopic']),
      senderInboxId: serializer.fromJson<String?>(json['senderInboxId']),
      sessionAddress: serializer.fromJson<String>(json['sessionAddress']),
      ownerInboxId: serializer.fromJson<String>(json['ownerInboxId']),
      typeId: serializer.fromJson<String?>(json['typeId']),
      isPending: serializer.fromJson<bool>(json['isPending']),
      sendFailed: serializer.fromJson<bool>(json['sendFailed']),
      isRead: serializer.fromJson<bool>(json['isRead']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'idXmtp': serializer.toJson<String?>(idXmtp),
      'xmtpMessageData': serializer.toJson<String>(xmtpMessageData),
      'timestamp': serializer.toJson<int>(timestamp),
      'conversationTopic': serializer.toJson<String>(conversationTopic),
      'senderInboxId': serializer.toJson<String?>(senderInboxId),
      'sessionAddress': serializer.toJson<String>(sessionAddress),
      'ownerInboxId': serializer.toJson<String>(ownerInboxId),
      'typeId': serializer.toJson<String?>(typeId),
      'isPending': serializer.toJson<bool>(isPending),
      'sendFailed': serializer.toJson<bool>(sendFailed),
      'isRead': serializer.toJson<bool>(isRead),
    };
  }

  Message copyWith(
          {int? id,
          Value<String?> idXmtp = const Value.absent(),
          String? xmtpMessageData,
          int? timestamp,
          String? conversationTopic,
          Value<String?> senderInboxId = const Value.absent(),
          String? sessionAddress,
          String? ownerInboxId,
          Value<String?> typeId = const Value.absent(),
          bool? isPending,
          bool? sendFailed,
          bool? isRead}) =>
      Message(
        id: id ?? this.id,
        idXmtp: idXmtp.present ? idXmtp.value : this.idXmtp,
        xmtpMessageData: xmtpMessageData ?? this.xmtpMessageData,
        timestamp: timestamp ?? this.timestamp,
        conversationTopic: conversationTopic ?? this.conversationTopic,
        senderInboxId:
            senderInboxId.present ? senderInboxId.value : this.senderInboxId,
        sessionAddress: sessionAddress ?? this.sessionAddress,
        ownerInboxId: ownerInboxId ?? this.ownerInboxId,
        typeId: typeId.present ? typeId.value : this.typeId,
        isPending: isPending ?? this.isPending,
        sendFailed: sendFailed ?? this.sendFailed,
        isRead: isRead ?? this.isRead,
      );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      idXmtp: data.idXmtp.present ? data.idXmtp.value : this.idXmtp,
      xmtpMessageData: data.xmtpMessageData.present
          ? data.xmtpMessageData.value
          : this.xmtpMessageData,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      conversationTopic: data.conversationTopic.present
          ? data.conversationTopic.value
          : this.conversationTopic,
      senderInboxId: data.senderInboxId.present
          ? data.senderInboxId.value
          : this.senderInboxId,
      sessionAddress: data.sessionAddress.present
          ? data.sessionAddress.value
          : this.sessionAddress,
      ownerInboxId: data.ownerInboxId.present
          ? data.ownerInboxId.value
          : this.ownerInboxId,
      typeId: data.typeId.present ? data.typeId.value : this.typeId,
      isPending: data.isPending.present ? data.isPending.value : this.isPending,
      sendFailed:
          data.sendFailed.present ? data.sendFailed.value : this.sendFailed,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('idXmtp: $idXmtp, ')
          ..write('xmtpMessageData: $xmtpMessageData, ')
          ..write('timestamp: $timestamp, ')
          ..write('conversationTopic: $conversationTopic, ')
          ..write('senderInboxId: $senderInboxId, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('ownerInboxId: $ownerInboxId, ')
          ..write('typeId: $typeId, ')
          ..write('isPending: $isPending, ')
          ..write('sendFailed: $sendFailed, ')
          ..write('isRead: $isRead')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      idXmtp,
      xmtpMessageData,
      timestamp,
      conversationTopic,
      senderInboxId,
      sessionAddress,
      ownerInboxId,
      typeId,
      isPending,
      sendFailed,
      isRead);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.idXmtp == this.idXmtp &&
          other.xmtpMessageData == this.xmtpMessageData &&
          other.timestamp == this.timestamp &&
          other.conversationTopic == this.conversationTopic &&
          other.senderInboxId == this.senderInboxId &&
          other.sessionAddress == this.sessionAddress &&
          other.ownerInboxId == this.ownerInboxId &&
          other.typeId == this.typeId &&
          other.isPending == this.isPending &&
          other.sendFailed == this.sendFailed &&
          other.isRead == this.isRead);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<int> id;
  final Value<String?> idXmtp;
  final Value<String> xmtpMessageData;
  final Value<int> timestamp;
  final Value<String> conversationTopic;
  final Value<String?> senderInboxId;
  final Value<String> sessionAddress;
  final Value<String> ownerInboxId;
  final Value<String?> typeId;
  final Value<bool> isPending;
  final Value<bool> sendFailed;
  final Value<bool> isRead;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.idXmtp = const Value.absent(),
    this.xmtpMessageData = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.conversationTopic = const Value.absent(),
    this.senderInboxId = const Value.absent(),
    this.sessionAddress = const Value.absent(),
    this.ownerInboxId = const Value.absent(),
    this.typeId = const Value.absent(),
    this.isPending = const Value.absent(),
    this.sendFailed = const Value.absent(),
    this.isRead = const Value.absent(),
  });
  MessagesCompanion.insert({
    this.id = const Value.absent(),
    this.idXmtp = const Value.absent(),
    required String xmtpMessageData,
    required int timestamp,
    required String conversationTopic,
    this.senderInboxId = const Value.absent(),
    required String sessionAddress,
    required String ownerInboxId,
    this.typeId = const Value.absent(),
    this.isPending = const Value.absent(),
    this.sendFailed = const Value.absent(),
    this.isRead = const Value.absent(),
  })  : xmtpMessageData = Value(xmtpMessageData),
        timestamp = Value(timestamp),
        conversationTopic = Value(conversationTopic),
        sessionAddress = Value(sessionAddress),
        ownerInboxId = Value(ownerInboxId);
  static Insertable<Message> custom({
    Expression<int>? id,
    Expression<String>? idXmtp,
    Expression<String>? xmtpMessageData,
    Expression<int>? timestamp,
    Expression<String>? conversationTopic,
    Expression<String>? senderInboxId,
    Expression<String>? sessionAddress,
    Expression<String>? ownerInboxId,
    Expression<String>? typeId,
    Expression<bool>? isPending,
    Expression<bool>? sendFailed,
    Expression<bool>? isRead,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (idXmtp != null) 'id_xmtp': idXmtp,
      if (xmtpMessageData != null) 'xmtp_message_data': xmtpMessageData,
      if (timestamp != null) 'timestamp': timestamp,
      if (conversationTopic != null) 'conversation_topic': conversationTopic,
      if (senderInboxId != null) 'sender_inbox_id': senderInboxId,
      if (sessionAddress != null) 'session_address': sessionAddress,
      if (ownerInboxId != null) 'owner_inbox_id': ownerInboxId,
      if (typeId != null) 'type_id': typeId,
      if (isPending != null) 'is_pending': isPending,
      if (sendFailed != null) 'send_failed': sendFailed,
      if (isRead != null) 'is_read': isRead,
    });
  }

  MessagesCompanion copyWith(
      {Value<int>? id,
      Value<String?>? idXmtp,
      Value<String>? xmtpMessageData,
      Value<int>? timestamp,
      Value<String>? conversationTopic,
      Value<String?>? senderInboxId,
      Value<String>? sessionAddress,
      Value<String>? ownerInboxId,
      Value<String?>? typeId,
      Value<bool>? isPending,
      Value<bool>? sendFailed,
      Value<bool>? isRead}) {
    return MessagesCompanion(
      id: id ?? this.id,
      idXmtp: idXmtp ?? this.idXmtp,
      xmtpMessageData: xmtpMessageData ?? this.xmtpMessageData,
      timestamp: timestamp ?? this.timestamp,
      conversationTopic: conversationTopic ?? this.conversationTopic,
      senderInboxId: senderInboxId ?? this.senderInboxId,
      sessionAddress: sessionAddress ?? this.sessionAddress,
      ownerInboxId: ownerInboxId ?? this.ownerInboxId,
      typeId: typeId ?? this.typeId,
      isPending: isPending ?? this.isPending,
      sendFailed: sendFailed ?? this.sendFailed,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (idXmtp.present) {
      map['id_xmtp'] = Variable<String>(idXmtp.value);
    }
    if (xmtpMessageData.present) {
      map['xmtp_message_data'] = Variable<String>(xmtpMessageData.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (conversationTopic.present) {
      map['conversation_topic'] = Variable<String>(conversationTopic.value);
    }
    if (senderInboxId.present) {
      map['sender_inbox_id'] = Variable<String>(senderInboxId.value);
    }
    if (sessionAddress.present) {
      map['session_address'] = Variable<String>(sessionAddress.value);
    }
    if (ownerInboxId.present) {
      map['owner_inbox_id'] = Variable<String>(ownerInboxId.value);
    }
    if (typeId.present) {
      map['type_id'] = Variable<String>(typeId.value);
    }
    if (isPending.present) {
      map['is_pending'] = Variable<bool>(isPending.value);
    }
    if (sendFailed.present) {
      map['send_failed'] = Variable<bool>(sendFailed.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('idXmtp: $idXmtp, ')
          ..write('xmtpMessageData: $xmtpMessageData, ')
          ..write('timestamp: $timestamp, ')
          ..write('conversationTopic: $conversationTopic, ')
          ..write('senderInboxId: $senderInboxId, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('ownerInboxId: $ownerInboxId, ')
          ..write('typeId: $typeId, ')
          ..write('isPending: $isPending, ')
          ..write('sendFailed: $sendFailed, ')
          ..write('isRead: $isRead')
          ..write(')'))
        .toString();
  }
}

class $ContactsTable extends Contacts with TableInfo<$ContactsTable, Contact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _publicosDisplayNameMeta =
      const VerificationMeta('publicosDisplayName');
  @override
  late final GeneratedColumn<String> publicosDisplayName =
      GeneratedColumn<String>('publicos_display_name', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _publicosAddressMeta =
      const VerificationMeta('publicosAddress');
  @override
  late final GeneratedColumn<String> publicosAddress = GeneratedColumn<String>(
      'publicos_address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isOrgAccountMeta =
      const VerificationMeta('isOrgAccount');
  @override
  late final GeneratedColumn<bool> isOrgAccount = GeneratedColumn<bool>(
      'is_org_account', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_org_account" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sessionsMeta =
      const VerificationMeta('sessions');
  @override
  late final GeneratedColumn<String> sessions = GeneratedColumn<String>(
      'sessions', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _recordsMeta =
      const VerificationMeta('records');
  @override
  late final GeneratedColumn<String> records = GeneratedColumn<String>(
      'records', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _registeredInboxIDsMeta =
      const VerificationMeta('registeredInboxIDs');
  @override
  late final GeneratedColumn<String> registeredInboxIDs =
      GeneratedColumn<String>('registered_inbox_i_ds', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _orgMembersMeta =
      const VerificationMeta('orgMembers');
  @override
  late final GeneratedColumn<String> orgMembers = GeneratedColumn<String>(
      'org_members', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _orgMemberCountMeta =
      const VerificationMeta('orgMemberCount');
  @override
  late final GeneratedColumn<int> orgMemberCount = GeneratedColumn<int>(
      'org_member_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isBlockedMeta =
      const VerificationMeta('isBlocked');
  @override
  late final GeneratedColumn<bool> isBlocked = GeneratedColumn<bool>(
      'is_blocked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_blocked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isSupportMeta =
      const VerificationMeta('isSupport');
  @override
  late final GeneratedColumn<bool> isSupport = GeneratedColumn<bool>(
      'is_support', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_support" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdByMeta =
      const VerificationMeta('createdBy');
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
      'created_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _founderAddressMeta =
      const VerificationMeta('founderAddress');
  @override
  late final GeneratedColumn<String> founderAddress = GeneratedColumn<String>(
      'founder_address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sessionAddressMeta =
      const VerificationMeta('sessionAddress');
  @override
  late final GeneratedColumn<String> sessionAddress = GeneratedColumn<String>(
      'session_address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _xmtpConversationTopicMeta =
      const VerificationMeta('xmtpConversationTopic');
  @override
  late final GeneratedColumn<String> xmtpConversationTopic =
      GeneratedColumn<String>('xmtp_conversation_topic', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isCitizenMeta =
      const VerificationMeta('isCitizen');
  @override
  late final GeneratedColumn<bool> isCitizen = GeneratedColumn<bool>(
      'is_citizen', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_citizen" IN (0, 1))'));
  static const VerificationMeta _isPublicOrgMeta =
      const VerificationMeta('isPublicOrg');
  @override
  late final GeneratedColumn<bool> isPublicOrg = GeneratedColumn<bool>(
      'is_public_org', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_public_org" IN (0, 1))'));
  static const VerificationMeta _verifiedNftAvatarMeta =
      const VerificationMeta('verifiedNftAvatar');
  @override
  late final GeneratedColumn<String> verifiedNftAvatar =
      GeneratedColumn<String>('verified_nft_avatar', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _verifiedNftBannerMeta =
      const VerificationMeta('verifiedNftBanner');
  @override
  late final GeneratedColumn<String> verifiedNftBanner =
      GeneratedColumn<String>('verified_nft_banner', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bookmarkedMeta =
      const VerificationMeta('bookmarked');
  @override
  late final GeneratedColumn<bool> bookmarked = GeneratedColumn<bool>(
      'bookmarked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("bookmarked" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        publicosDisplayName,
        publicosAddress,
        displayName,
        isOrgAccount,
        sessions,
        records,
        registeredInboxIDs,
        orgMembers,
        orgMemberCount,
        isBlocked,
        isSupport,
        createdBy,
        founderAddress,
        createdAt,
        updatedAt,
        sessionAddress,
        xmtpConversationTopic,
        isCitizen,
        isPublicOrg,
        verifiedNftAvatar,
        verifiedNftBanner,
        bookmarked
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contacts';
  @override
  VerificationContext validateIntegrity(Insertable<Contact> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('publicos_display_name')) {
      context.handle(
          _publicosDisplayNameMeta,
          publicosDisplayName.isAcceptableOrUnknown(
              data['publicos_display_name']!, _publicosDisplayNameMeta));
    }
    if (data.containsKey('publicos_address')) {
      context.handle(
          _publicosAddressMeta,
          publicosAddress.isAcceptableOrUnknown(
              data['publicos_address']!, _publicosAddressMeta));
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('is_org_account')) {
      context.handle(
          _isOrgAccountMeta,
          isOrgAccount.isAcceptableOrUnknown(
              data['is_org_account']!, _isOrgAccountMeta));
    }
    if (data.containsKey('sessions')) {
      context.handle(_sessionsMeta,
          sessions.isAcceptableOrUnknown(data['sessions']!, _sessionsMeta));
    }
    if (data.containsKey('records')) {
      context.handle(_recordsMeta,
          records.isAcceptableOrUnknown(data['records']!, _recordsMeta));
    }
    if (data.containsKey('registered_inbox_i_ds')) {
      context.handle(
          _registeredInboxIDsMeta,
          registeredInboxIDs.isAcceptableOrUnknown(
              data['registered_inbox_i_ds']!, _registeredInboxIDsMeta));
    }
    if (data.containsKey('org_members')) {
      context.handle(
          _orgMembersMeta,
          orgMembers.isAcceptableOrUnknown(
              data['org_members']!, _orgMembersMeta));
    }
    if (data.containsKey('org_member_count')) {
      context.handle(
          _orgMemberCountMeta,
          orgMemberCount.isAcceptableOrUnknown(
              data['org_member_count']!, _orgMemberCountMeta));
    }
    if (data.containsKey('is_blocked')) {
      context.handle(_isBlockedMeta,
          isBlocked.isAcceptableOrUnknown(data['is_blocked']!, _isBlockedMeta));
    }
    if (data.containsKey('is_support')) {
      context.handle(_isSupportMeta,
          isSupport.isAcceptableOrUnknown(data['is_support']!, _isSupportMeta));
    }
    if (data.containsKey('created_by')) {
      context.handle(_createdByMeta,
          createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta));
    }
    if (data.containsKey('founder_address')) {
      context.handle(
          _founderAddressMeta,
          founderAddress.isAcceptableOrUnknown(
              data['founder_address']!, _founderAddressMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('session_address')) {
      context.handle(
          _sessionAddressMeta,
          sessionAddress.isAcceptableOrUnknown(
              data['session_address']!, _sessionAddressMeta));
    } else if (isInserting) {
      context.missing(_sessionAddressMeta);
    }
    if (data.containsKey('xmtp_conversation_topic')) {
      context.handle(
          _xmtpConversationTopicMeta,
          xmtpConversationTopic.isAcceptableOrUnknown(
              data['xmtp_conversation_topic']!, _xmtpConversationTopicMeta));
    }
    if (data.containsKey('is_citizen')) {
      context.handle(_isCitizenMeta,
          isCitizen.isAcceptableOrUnknown(data['is_citizen']!, _isCitizenMeta));
    }
    if (data.containsKey('is_public_org')) {
      context.handle(
          _isPublicOrgMeta,
          isPublicOrg.isAcceptableOrUnknown(
              data['is_public_org']!, _isPublicOrgMeta));
    }
    if (data.containsKey('verified_nft_avatar')) {
      context.handle(
          _verifiedNftAvatarMeta,
          verifiedNftAvatar.isAcceptableOrUnknown(
              data['verified_nft_avatar']!, _verifiedNftAvatarMeta));
    }
    if (data.containsKey('verified_nft_banner')) {
      context.handle(
          _verifiedNftBannerMeta,
          verifiedNftBanner.isAcceptableOrUnknown(
              data['verified_nft_banner']!, _verifiedNftBannerMeta));
    }
    if (data.containsKey('bookmarked')) {
      context.handle(
          _bookmarkedMeta,
          bookmarked.isAcceptableOrUnknown(
              data['bookmarked']!, _bookmarkedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Contact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Contact(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      publicosDisplayName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}publicos_display_name']),
      publicosAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}publicos_address']),
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      isOrgAccount: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_org_account'])!,
      sessions: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sessions']),
      records: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}records']),
      registeredInboxIDs: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}registered_inbox_i_ds']),
      orgMembers: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}org_members']),
      orgMemberCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}org_member_count']),
      isBlocked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_blocked'])!,
      isSupport: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_support'])!,
      createdBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_by']),
      founderAddress: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}founder_address']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      sessionAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}session_address'])!,
      xmtpConversationTopic: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}xmtp_conversation_topic']),
      isCitizen: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_citizen']),
      isPublicOrg: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_public_org']),
      verifiedNftAvatar: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}verified_nft_avatar']),
      verifiedNftBanner: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}verified_nft_banner']),
      bookmarked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}bookmarked'])!,
    );
  }

  @override
  $ContactsTable createAlias(String alias) {
    return $ContactsTable(attachedDatabase, alias);
  }
}

class Contact extends DataClass implements Insertable<Contact> {
  final int id;
  final String? publicosDisplayName;
  final String? publicosAddress;
  final String displayName;
  final bool isOrgAccount;
  final String? sessions;
  final String? records;
  final String? registeredInboxIDs;
  final String? orgMembers;
  final int? orgMemberCount;
  final bool isBlocked;
  final bool isSupport;
  final String? createdBy;

  /// For orgs: founder's account address (eip55 hex). Immutable once set —
  /// the view layer silently resolves it into a Contact for display.
  final String? founderAddress;
  final String? createdAt;
  final int updatedAt;
  final String sessionAddress;

  /// Present only on group-chat stubs; null for people.
  final String? xmtpConversationTopic;

  /// On-chain citizenship, lazily enriched on profile view. null = unknown.
  final bool? isCitizen;

  /// Orgs only — public-org flag (admits only citizens). The org analog of
  /// [isCitizen]; lazily enriched, cached. null = unknown.
  final bool? isPublicOrg;

  /// Icon-managed NFT-avatar verdict cache (JSON: pointer + metadata +
  /// verifiedOwnership + checkedAt). Written by the contact icon. null = none.
  final String? verifiedNftAvatar;
  final String? verifiedNftBanner;

  /// User-set bookmark flag (default false). Reserved for an upcoming
  /// real-vs-searched contact distinction; not wired to UI yet.
  final bool bookmarked;
  const Contact(
      {required this.id,
      this.publicosDisplayName,
      this.publicosAddress,
      required this.displayName,
      required this.isOrgAccount,
      this.sessions,
      this.records,
      this.registeredInboxIDs,
      this.orgMembers,
      this.orgMemberCount,
      required this.isBlocked,
      required this.isSupport,
      this.createdBy,
      this.founderAddress,
      this.createdAt,
      required this.updatedAt,
      required this.sessionAddress,
      this.xmtpConversationTopic,
      this.isCitizen,
      this.isPublicOrg,
      this.verifiedNftAvatar,
      this.verifiedNftBanner,
      required this.bookmarked});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || publicosDisplayName != null) {
      map['publicos_display_name'] = Variable<String>(publicosDisplayName);
    }
    if (!nullToAbsent || publicosAddress != null) {
      map['publicos_address'] = Variable<String>(publicosAddress);
    }
    map['display_name'] = Variable<String>(displayName);
    map['is_org_account'] = Variable<bool>(isOrgAccount);
    if (!nullToAbsent || sessions != null) {
      map['sessions'] = Variable<String>(sessions);
    }
    if (!nullToAbsent || records != null) {
      map['records'] = Variable<String>(records);
    }
    if (!nullToAbsent || registeredInboxIDs != null) {
      map['registered_inbox_i_ds'] = Variable<String>(registeredInboxIDs);
    }
    if (!nullToAbsent || orgMembers != null) {
      map['org_members'] = Variable<String>(orgMembers);
    }
    if (!nullToAbsent || orgMemberCount != null) {
      map['org_member_count'] = Variable<int>(orgMemberCount);
    }
    map['is_blocked'] = Variable<bool>(isBlocked);
    map['is_support'] = Variable<bool>(isSupport);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    if (!nullToAbsent || founderAddress != null) {
      map['founder_address'] = Variable<String>(founderAddress);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    map['session_address'] = Variable<String>(sessionAddress);
    if (!nullToAbsent || xmtpConversationTopic != null) {
      map['xmtp_conversation_topic'] = Variable<String>(xmtpConversationTopic);
    }
    if (!nullToAbsent || isCitizen != null) {
      map['is_citizen'] = Variable<bool>(isCitizen);
    }
    if (!nullToAbsent || isPublicOrg != null) {
      map['is_public_org'] = Variable<bool>(isPublicOrg);
    }
    if (!nullToAbsent || verifiedNftAvatar != null) {
      map['verified_nft_avatar'] = Variable<String>(verifiedNftAvatar);
    }
    if (!nullToAbsent || verifiedNftBanner != null) {
      map['verified_nft_banner'] = Variable<String>(verifiedNftBanner);
    }
    map['bookmarked'] = Variable<bool>(bookmarked);
    return map;
  }

  ContactsCompanion toCompanion(bool nullToAbsent) {
    return ContactsCompanion(
      id: Value(id),
      publicosDisplayName: publicosDisplayName == null && nullToAbsent
          ? const Value.absent()
          : Value(publicosDisplayName),
      publicosAddress: publicosAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(publicosAddress),
      displayName: Value(displayName),
      isOrgAccount: Value(isOrgAccount),
      sessions: sessions == null && nullToAbsent
          ? const Value.absent()
          : Value(sessions),
      records: records == null && nullToAbsent
          ? const Value.absent()
          : Value(records),
      registeredInboxIDs: registeredInboxIDs == null && nullToAbsent
          ? const Value.absent()
          : Value(registeredInboxIDs),
      orgMembers: orgMembers == null && nullToAbsent
          ? const Value.absent()
          : Value(orgMembers),
      orgMemberCount: orgMemberCount == null && nullToAbsent
          ? const Value.absent()
          : Value(orgMemberCount),
      isBlocked: Value(isBlocked),
      isSupport: Value(isSupport),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      founderAddress: founderAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(founderAddress),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: Value(updatedAt),
      sessionAddress: Value(sessionAddress),
      xmtpConversationTopic: xmtpConversationTopic == null && nullToAbsent
          ? const Value.absent()
          : Value(xmtpConversationTopic),
      isCitizen: isCitizen == null && nullToAbsent
          ? const Value.absent()
          : Value(isCitizen),
      isPublicOrg: isPublicOrg == null && nullToAbsent
          ? const Value.absent()
          : Value(isPublicOrg),
      verifiedNftAvatar: verifiedNftAvatar == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedNftAvatar),
      verifiedNftBanner: verifiedNftBanner == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedNftBanner),
      bookmarked: Value(bookmarked),
    );
  }

  factory Contact.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Contact(
      id: serializer.fromJson<int>(json['id']),
      publicosDisplayName:
          serializer.fromJson<String?>(json['publicosDisplayName']),
      publicosAddress: serializer.fromJson<String?>(json['publicosAddress']),
      displayName: serializer.fromJson<String>(json['displayName']),
      isOrgAccount: serializer.fromJson<bool>(json['isOrgAccount']),
      sessions: serializer.fromJson<String?>(json['sessions']),
      records: serializer.fromJson<String?>(json['records']),
      registeredInboxIDs:
          serializer.fromJson<String?>(json['registeredInboxIDs']),
      orgMembers: serializer.fromJson<String?>(json['orgMembers']),
      orgMemberCount: serializer.fromJson<int?>(json['orgMemberCount']),
      isBlocked: serializer.fromJson<bool>(json['isBlocked']),
      isSupport: serializer.fromJson<bool>(json['isSupport']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      founderAddress: serializer.fromJson<String?>(json['founderAddress']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      sessionAddress: serializer.fromJson<String>(json['sessionAddress']),
      xmtpConversationTopic:
          serializer.fromJson<String?>(json['xmtpConversationTopic']),
      isCitizen: serializer.fromJson<bool?>(json['isCitizen']),
      isPublicOrg: serializer.fromJson<bool?>(json['isPublicOrg']),
      verifiedNftAvatar:
          serializer.fromJson<String?>(json['verifiedNftAvatar']),
      verifiedNftBanner:
          serializer.fromJson<String?>(json['verifiedNftBanner']),
      bookmarked: serializer.fromJson<bool>(json['bookmarked']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'publicosDisplayName': serializer.toJson<String?>(publicosDisplayName),
      'publicosAddress': serializer.toJson<String?>(publicosAddress),
      'displayName': serializer.toJson<String>(displayName),
      'isOrgAccount': serializer.toJson<bool>(isOrgAccount),
      'sessions': serializer.toJson<String?>(sessions),
      'records': serializer.toJson<String?>(records),
      'registeredInboxIDs': serializer.toJson<String?>(registeredInboxIDs),
      'orgMembers': serializer.toJson<String?>(orgMembers),
      'orgMemberCount': serializer.toJson<int?>(orgMemberCount),
      'isBlocked': serializer.toJson<bool>(isBlocked),
      'isSupport': serializer.toJson<bool>(isSupport),
      'createdBy': serializer.toJson<String?>(createdBy),
      'founderAddress': serializer.toJson<String?>(founderAddress),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'sessionAddress': serializer.toJson<String>(sessionAddress),
      'xmtpConversationTopic':
          serializer.toJson<String?>(xmtpConversationTopic),
      'isCitizen': serializer.toJson<bool?>(isCitizen),
      'isPublicOrg': serializer.toJson<bool?>(isPublicOrg),
      'verifiedNftAvatar': serializer.toJson<String?>(verifiedNftAvatar),
      'verifiedNftBanner': serializer.toJson<String?>(verifiedNftBanner),
      'bookmarked': serializer.toJson<bool>(bookmarked),
    };
  }

  Contact copyWith(
          {int? id,
          Value<String?> publicosDisplayName = const Value.absent(),
          Value<String?> publicosAddress = const Value.absent(),
          String? displayName,
          bool? isOrgAccount,
          Value<String?> sessions = const Value.absent(),
          Value<String?> records = const Value.absent(),
          Value<String?> registeredInboxIDs = const Value.absent(),
          Value<String?> orgMembers = const Value.absent(),
          Value<int?> orgMemberCount = const Value.absent(),
          bool? isBlocked,
          bool? isSupport,
          Value<String?> createdBy = const Value.absent(),
          Value<String?> founderAddress = const Value.absent(),
          Value<String?> createdAt = const Value.absent(),
          int? updatedAt,
          String? sessionAddress,
          Value<String?> xmtpConversationTopic = const Value.absent(),
          Value<bool?> isCitizen = const Value.absent(),
          Value<bool?> isPublicOrg = const Value.absent(),
          Value<String?> verifiedNftAvatar = const Value.absent(),
          Value<String?> verifiedNftBanner = const Value.absent(),
          bool? bookmarked}) =>
      Contact(
        id: id ?? this.id,
        publicosDisplayName: publicosDisplayName.present
            ? publicosDisplayName.value
            : this.publicosDisplayName,
        publicosAddress: publicosAddress.present
            ? publicosAddress.value
            : this.publicosAddress,
        displayName: displayName ?? this.displayName,
        isOrgAccount: isOrgAccount ?? this.isOrgAccount,
        sessions: sessions.present ? sessions.value : this.sessions,
        records: records.present ? records.value : this.records,
        registeredInboxIDs: registeredInboxIDs.present
            ? registeredInboxIDs.value
            : this.registeredInboxIDs,
        orgMembers: orgMembers.present ? orgMembers.value : this.orgMembers,
        orgMemberCount:
            orgMemberCount.present ? orgMemberCount.value : this.orgMemberCount,
        isBlocked: isBlocked ?? this.isBlocked,
        isSupport: isSupport ?? this.isSupport,
        createdBy: createdBy.present ? createdBy.value : this.createdBy,
        founderAddress:
            founderAddress.present ? founderAddress.value : this.founderAddress,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        sessionAddress: sessionAddress ?? this.sessionAddress,
        xmtpConversationTopic: xmtpConversationTopic.present
            ? xmtpConversationTopic.value
            : this.xmtpConversationTopic,
        isCitizen: isCitizen.present ? isCitizen.value : this.isCitizen,
        isPublicOrg: isPublicOrg.present ? isPublicOrg.value : this.isPublicOrg,
        verifiedNftAvatar: verifiedNftAvatar.present
            ? verifiedNftAvatar.value
            : this.verifiedNftAvatar,
        verifiedNftBanner: verifiedNftBanner.present
            ? verifiedNftBanner.value
            : this.verifiedNftBanner,
        bookmarked: bookmarked ?? this.bookmarked,
      );
  Contact copyWithCompanion(ContactsCompanion data) {
    return Contact(
      id: data.id.present ? data.id.value : this.id,
      publicosDisplayName: data.publicosDisplayName.present
          ? data.publicosDisplayName.value
          : this.publicosDisplayName,
      publicosAddress: data.publicosAddress.present
          ? data.publicosAddress.value
          : this.publicosAddress,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      isOrgAccount: data.isOrgAccount.present
          ? data.isOrgAccount.value
          : this.isOrgAccount,
      sessions: data.sessions.present ? data.sessions.value : this.sessions,
      records: data.records.present ? data.records.value : this.records,
      registeredInboxIDs: data.registeredInboxIDs.present
          ? data.registeredInboxIDs.value
          : this.registeredInboxIDs,
      orgMembers:
          data.orgMembers.present ? data.orgMembers.value : this.orgMembers,
      orgMemberCount: data.orgMemberCount.present
          ? data.orgMemberCount.value
          : this.orgMemberCount,
      isBlocked: data.isBlocked.present ? data.isBlocked.value : this.isBlocked,
      isSupport: data.isSupport.present ? data.isSupport.value : this.isSupport,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      founderAddress: data.founderAddress.present
          ? data.founderAddress.value
          : this.founderAddress,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      sessionAddress: data.sessionAddress.present
          ? data.sessionAddress.value
          : this.sessionAddress,
      xmtpConversationTopic: data.xmtpConversationTopic.present
          ? data.xmtpConversationTopic.value
          : this.xmtpConversationTopic,
      isCitizen: data.isCitizen.present ? data.isCitizen.value : this.isCitizen,
      isPublicOrg:
          data.isPublicOrg.present ? data.isPublicOrg.value : this.isPublicOrg,
      verifiedNftAvatar: data.verifiedNftAvatar.present
          ? data.verifiedNftAvatar.value
          : this.verifiedNftAvatar,
      verifiedNftBanner: data.verifiedNftBanner.present
          ? data.verifiedNftBanner.value
          : this.verifiedNftBanner,
      bookmarked:
          data.bookmarked.present ? data.bookmarked.value : this.bookmarked,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Contact(')
          ..write('id: $id, ')
          ..write('publicosDisplayName: $publicosDisplayName, ')
          ..write('publicosAddress: $publicosAddress, ')
          ..write('displayName: $displayName, ')
          ..write('isOrgAccount: $isOrgAccount, ')
          ..write('sessions: $sessions, ')
          ..write('records: $records, ')
          ..write('registeredInboxIDs: $registeredInboxIDs, ')
          ..write('orgMembers: $orgMembers, ')
          ..write('orgMemberCount: $orgMemberCount, ')
          ..write('isBlocked: $isBlocked, ')
          ..write('isSupport: $isSupport, ')
          ..write('createdBy: $createdBy, ')
          ..write('founderAddress: $founderAddress, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('xmtpConversationTopic: $xmtpConversationTopic, ')
          ..write('isCitizen: $isCitizen, ')
          ..write('isPublicOrg: $isPublicOrg, ')
          ..write('verifiedNftAvatar: $verifiedNftAvatar, ')
          ..write('verifiedNftBanner: $verifiedNftBanner, ')
          ..write('bookmarked: $bookmarked')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        publicosDisplayName,
        publicosAddress,
        displayName,
        isOrgAccount,
        sessions,
        records,
        registeredInboxIDs,
        orgMembers,
        orgMemberCount,
        isBlocked,
        isSupport,
        createdBy,
        founderAddress,
        createdAt,
        updatedAt,
        sessionAddress,
        xmtpConversationTopic,
        isCitizen,
        isPublicOrg,
        verifiedNftAvatar,
        verifiedNftBanner,
        bookmarked
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Contact &&
          other.id == this.id &&
          other.publicosDisplayName == this.publicosDisplayName &&
          other.publicosAddress == this.publicosAddress &&
          other.displayName == this.displayName &&
          other.isOrgAccount == this.isOrgAccount &&
          other.sessions == this.sessions &&
          other.records == this.records &&
          other.registeredInboxIDs == this.registeredInboxIDs &&
          other.orgMembers == this.orgMembers &&
          other.orgMemberCount == this.orgMemberCount &&
          other.isBlocked == this.isBlocked &&
          other.isSupport == this.isSupport &&
          other.createdBy == this.createdBy &&
          other.founderAddress == this.founderAddress &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.sessionAddress == this.sessionAddress &&
          other.xmtpConversationTopic == this.xmtpConversationTopic &&
          other.isCitizen == this.isCitizen &&
          other.isPublicOrg == this.isPublicOrg &&
          other.verifiedNftAvatar == this.verifiedNftAvatar &&
          other.verifiedNftBanner == this.verifiedNftBanner &&
          other.bookmarked == this.bookmarked);
}

class ContactsCompanion extends UpdateCompanion<Contact> {
  final Value<int> id;
  final Value<String?> publicosDisplayName;
  final Value<String?> publicosAddress;
  final Value<String> displayName;
  final Value<bool> isOrgAccount;
  final Value<String?> sessions;
  final Value<String?> records;
  final Value<String?> registeredInboxIDs;
  final Value<String?> orgMembers;
  final Value<int?> orgMemberCount;
  final Value<bool> isBlocked;
  final Value<bool> isSupport;
  final Value<String?> createdBy;
  final Value<String?> founderAddress;
  final Value<String?> createdAt;
  final Value<int> updatedAt;
  final Value<String> sessionAddress;
  final Value<String?> xmtpConversationTopic;
  final Value<bool?> isCitizen;
  final Value<bool?> isPublicOrg;
  final Value<String?> verifiedNftAvatar;
  final Value<String?> verifiedNftBanner;
  final Value<bool> bookmarked;
  const ContactsCompanion({
    this.id = const Value.absent(),
    this.publicosDisplayName = const Value.absent(),
    this.publicosAddress = const Value.absent(),
    this.displayName = const Value.absent(),
    this.isOrgAccount = const Value.absent(),
    this.sessions = const Value.absent(),
    this.records = const Value.absent(),
    this.registeredInboxIDs = const Value.absent(),
    this.orgMembers = const Value.absent(),
    this.orgMemberCount = const Value.absent(),
    this.isBlocked = const Value.absent(),
    this.isSupport = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.founderAddress = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.sessionAddress = const Value.absent(),
    this.xmtpConversationTopic = const Value.absent(),
    this.isCitizen = const Value.absent(),
    this.isPublicOrg = const Value.absent(),
    this.verifiedNftAvatar = const Value.absent(),
    this.verifiedNftBanner = const Value.absent(),
    this.bookmarked = const Value.absent(),
  });
  ContactsCompanion.insert({
    this.id = const Value.absent(),
    this.publicosDisplayName = const Value.absent(),
    this.publicosAddress = const Value.absent(),
    required String displayName,
    this.isOrgAccount = const Value.absent(),
    this.sessions = const Value.absent(),
    this.records = const Value.absent(),
    this.registeredInboxIDs = const Value.absent(),
    this.orgMembers = const Value.absent(),
    this.orgMemberCount = const Value.absent(),
    this.isBlocked = const Value.absent(),
    this.isSupport = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.founderAddress = const Value.absent(),
    this.createdAt = const Value.absent(),
    required int updatedAt,
    required String sessionAddress,
    this.xmtpConversationTopic = const Value.absent(),
    this.isCitizen = const Value.absent(),
    this.isPublicOrg = const Value.absent(),
    this.verifiedNftAvatar = const Value.absent(),
    this.verifiedNftBanner = const Value.absent(),
    this.bookmarked = const Value.absent(),
  })  : displayName = Value(displayName),
        updatedAt = Value(updatedAt),
        sessionAddress = Value(sessionAddress);
  static Insertable<Contact> custom({
    Expression<int>? id,
    Expression<String>? publicosDisplayName,
    Expression<String>? publicosAddress,
    Expression<String>? displayName,
    Expression<bool>? isOrgAccount,
    Expression<String>? sessions,
    Expression<String>? records,
    Expression<String>? registeredInboxIDs,
    Expression<String>? orgMembers,
    Expression<int>? orgMemberCount,
    Expression<bool>? isBlocked,
    Expression<bool>? isSupport,
    Expression<String>? createdBy,
    Expression<String>? founderAddress,
    Expression<String>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? sessionAddress,
    Expression<String>? xmtpConversationTopic,
    Expression<bool>? isCitizen,
    Expression<bool>? isPublicOrg,
    Expression<String>? verifiedNftAvatar,
    Expression<String>? verifiedNftBanner,
    Expression<bool>? bookmarked,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (publicosDisplayName != null)
        'publicos_display_name': publicosDisplayName,
      if (publicosAddress != null) 'publicos_address': publicosAddress,
      if (displayName != null) 'display_name': displayName,
      if (isOrgAccount != null) 'is_org_account': isOrgAccount,
      if (sessions != null) 'sessions': sessions,
      if (records != null) 'records': records,
      if (registeredInboxIDs != null)
        'registered_inbox_i_ds': registeredInboxIDs,
      if (orgMembers != null) 'org_members': orgMembers,
      if (orgMemberCount != null) 'org_member_count': orgMemberCount,
      if (isBlocked != null) 'is_blocked': isBlocked,
      if (isSupport != null) 'is_support': isSupport,
      if (createdBy != null) 'created_by': createdBy,
      if (founderAddress != null) 'founder_address': founderAddress,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (sessionAddress != null) 'session_address': sessionAddress,
      if (xmtpConversationTopic != null)
        'xmtp_conversation_topic': xmtpConversationTopic,
      if (isCitizen != null) 'is_citizen': isCitizen,
      if (isPublicOrg != null) 'is_public_org': isPublicOrg,
      if (verifiedNftAvatar != null) 'verified_nft_avatar': verifiedNftAvatar,
      if (verifiedNftBanner != null) 'verified_nft_banner': verifiedNftBanner,
      if (bookmarked != null) 'bookmarked': bookmarked,
    });
  }

  ContactsCompanion copyWith(
      {Value<int>? id,
      Value<String?>? publicosDisplayName,
      Value<String?>? publicosAddress,
      Value<String>? displayName,
      Value<bool>? isOrgAccount,
      Value<String?>? sessions,
      Value<String?>? records,
      Value<String?>? registeredInboxIDs,
      Value<String?>? orgMembers,
      Value<int?>? orgMemberCount,
      Value<bool>? isBlocked,
      Value<bool>? isSupport,
      Value<String?>? createdBy,
      Value<String?>? founderAddress,
      Value<String?>? createdAt,
      Value<int>? updatedAt,
      Value<String>? sessionAddress,
      Value<String?>? xmtpConversationTopic,
      Value<bool?>? isCitizen,
      Value<bool?>? isPublicOrg,
      Value<String?>? verifiedNftAvatar,
      Value<String?>? verifiedNftBanner,
      Value<bool>? bookmarked}) {
    return ContactsCompanion(
      id: id ?? this.id,
      publicosDisplayName: publicosDisplayName ?? this.publicosDisplayName,
      publicosAddress: publicosAddress ?? this.publicosAddress,
      displayName: displayName ?? this.displayName,
      isOrgAccount: isOrgAccount ?? this.isOrgAccount,
      sessions: sessions ?? this.sessions,
      records: records ?? this.records,
      registeredInboxIDs: registeredInboxIDs ?? this.registeredInboxIDs,
      orgMembers: orgMembers ?? this.orgMembers,
      orgMemberCount: orgMemberCount ?? this.orgMemberCount,
      isBlocked: isBlocked ?? this.isBlocked,
      isSupport: isSupport ?? this.isSupport,
      createdBy: createdBy ?? this.createdBy,
      founderAddress: founderAddress ?? this.founderAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sessionAddress: sessionAddress ?? this.sessionAddress,
      xmtpConversationTopic:
          xmtpConversationTopic ?? this.xmtpConversationTopic,
      isCitizen: isCitizen ?? this.isCitizen,
      isPublicOrg: isPublicOrg ?? this.isPublicOrg,
      verifiedNftAvatar: verifiedNftAvatar ?? this.verifiedNftAvatar,
      verifiedNftBanner: verifiedNftBanner ?? this.verifiedNftBanner,
      bookmarked: bookmarked ?? this.bookmarked,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (publicosDisplayName.present) {
      map['publicos_display_name'] =
          Variable<String>(publicosDisplayName.value);
    }
    if (publicosAddress.present) {
      map['publicos_address'] = Variable<String>(publicosAddress.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (isOrgAccount.present) {
      map['is_org_account'] = Variable<bool>(isOrgAccount.value);
    }
    if (sessions.present) {
      map['sessions'] = Variable<String>(sessions.value);
    }
    if (records.present) {
      map['records'] = Variable<String>(records.value);
    }
    if (registeredInboxIDs.present) {
      map['registered_inbox_i_ds'] = Variable<String>(registeredInboxIDs.value);
    }
    if (orgMembers.present) {
      map['org_members'] = Variable<String>(orgMembers.value);
    }
    if (orgMemberCount.present) {
      map['org_member_count'] = Variable<int>(orgMemberCount.value);
    }
    if (isBlocked.present) {
      map['is_blocked'] = Variable<bool>(isBlocked.value);
    }
    if (isSupport.present) {
      map['is_support'] = Variable<bool>(isSupport.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (founderAddress.present) {
      map['founder_address'] = Variable<String>(founderAddress.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (sessionAddress.present) {
      map['session_address'] = Variable<String>(sessionAddress.value);
    }
    if (xmtpConversationTopic.present) {
      map['xmtp_conversation_topic'] =
          Variable<String>(xmtpConversationTopic.value);
    }
    if (isCitizen.present) {
      map['is_citizen'] = Variable<bool>(isCitizen.value);
    }
    if (isPublicOrg.present) {
      map['is_public_org'] = Variable<bool>(isPublicOrg.value);
    }
    if (verifiedNftAvatar.present) {
      map['verified_nft_avatar'] = Variable<String>(verifiedNftAvatar.value);
    }
    if (verifiedNftBanner.present) {
      map['verified_nft_banner'] = Variable<String>(verifiedNftBanner.value);
    }
    if (bookmarked.present) {
      map['bookmarked'] = Variable<bool>(bookmarked.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactsCompanion(')
          ..write('id: $id, ')
          ..write('publicosDisplayName: $publicosDisplayName, ')
          ..write('publicosAddress: $publicosAddress, ')
          ..write('displayName: $displayName, ')
          ..write('isOrgAccount: $isOrgAccount, ')
          ..write('sessions: $sessions, ')
          ..write('records: $records, ')
          ..write('registeredInboxIDs: $registeredInboxIDs, ')
          ..write('orgMembers: $orgMembers, ')
          ..write('orgMemberCount: $orgMemberCount, ')
          ..write('isBlocked: $isBlocked, ')
          ..write('isSupport: $isSupport, ')
          ..write('createdBy: $createdBy, ')
          ..write('founderAddress: $founderAddress, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('xmtpConversationTopic: $xmtpConversationTopic, ')
          ..write('isCitizen: $isCitizen, ')
          ..write('isPublicOrg: $isPublicOrg, ')
          ..write('verifiedNftAvatar: $verifiedNftAvatar, ')
          ..write('verifiedNftBanner: $verifiedNftBanner, ')
          ..write('bookmarked: $bookmarked')
          ..write(')'))
        .toString();
  }
}

class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, Conversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
      'topic', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _peerInboxIdMeta =
      const VerificationMeta('peerInboxId');
  @override
  late final GeneratedColumn<String> peerInboxId = GeneratedColumn<String>(
      'peer_inbox_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _groupNameMeta =
      const VerificationMeta('groupName');
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
      'group_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _groupImageUrlMeta =
      const VerificationMeta('groupImageUrl');
  @override
  late final GeneratedColumn<String> groupImageUrl = GeneratedColumn<String>(
      'group_image_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _groupDescriptionMeta =
      const VerificationMeta('groupDescription');
  @override
  late final GeneratedColumn<String> groupDescription = GeneratedColumn<String>(
      'group_description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pinnedFrameUrlMeta =
      const VerificationMeta('pinnedFrameUrl');
  @override
  late final GeneratedColumn<String> pinnedFrameUrl = GeneratedColumn<String>(
      'pinned_frame_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _membersJsonMeta =
      const VerificationMeta('membersJson');
  @override
  late final GeneratedColumn<String> membersJson = GeneratedColumn<String>(
      'members_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sessionAddressMeta =
      const VerificationMeta('sessionAddress');
  @override
  late final GeneratedColumn<String> sessionAddress = GeneratedColumn<String>(
      'session_address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerInboxIdMeta =
      const VerificationMeta('ownerInboxId');
  @override
  late final GeneratedColumn<String> ownerInboxId = GeneratedColumn<String>(
      'owner_inbox_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        topic,
        type,
        peerInboxId,
        groupName,
        groupImageUrl,
        groupDescription,
        pinnedFrameUrl,
        membersJson,
        createdAt,
        sessionAddress,
        ownerInboxId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(Insertable<Conversation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('topic')) {
      context.handle(
          _topicMeta, topic.isAcceptableOrUnknown(data['topic']!, _topicMeta));
    } else if (isInserting) {
      context.missing(_topicMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('peer_inbox_id')) {
      context.handle(
          _peerInboxIdMeta,
          peerInboxId.isAcceptableOrUnknown(
              data['peer_inbox_id']!, _peerInboxIdMeta));
    }
    if (data.containsKey('group_name')) {
      context.handle(_groupNameMeta,
          groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta));
    }
    if (data.containsKey('group_image_url')) {
      context.handle(
          _groupImageUrlMeta,
          groupImageUrl.isAcceptableOrUnknown(
              data['group_image_url']!, _groupImageUrlMeta));
    }
    if (data.containsKey('group_description')) {
      context.handle(
          _groupDescriptionMeta,
          groupDescription.isAcceptableOrUnknown(
              data['group_description']!, _groupDescriptionMeta));
    }
    if (data.containsKey('pinned_frame_url')) {
      context.handle(
          _pinnedFrameUrlMeta,
          pinnedFrameUrl.isAcceptableOrUnknown(
              data['pinned_frame_url']!, _pinnedFrameUrlMeta));
    }
    if (data.containsKey('members_json')) {
      context.handle(
          _membersJsonMeta,
          membersJson.isAcceptableOrUnknown(
              data['members_json']!, _membersJsonMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('session_address')) {
      context.handle(
          _sessionAddressMeta,
          sessionAddress.isAcceptableOrUnknown(
              data['session_address']!, _sessionAddressMeta));
    } else if (isInserting) {
      context.missing(_sessionAddressMeta);
    }
    if (data.containsKey('owner_inbox_id')) {
      context.handle(
          _ownerInboxIdMeta,
          ownerInboxId.isAcceptableOrUnknown(
              data['owner_inbox_id']!, _ownerInboxIdMeta));
    } else if (isInserting) {
      context.missing(_ownerInboxIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {topic, ownerInboxId};
  @override
  Conversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Conversation(
      topic: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}topic'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      peerInboxId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}peer_inbox_id']),
      groupName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_name']),
      groupImageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_image_url']),
      groupDescription: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}group_description']),
      pinnedFrameUrl: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}pinned_frame_url']),
      membersJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}members_json']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at']),
      sessionAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}session_address'])!,
      ownerInboxId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_inbox_id'])!,
    );
  }

  @override
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }
}

class Conversation extends DataClass implements Insertable<Conversation> {
  final String topic;
  final String type;
  final String? peerInboxId;
  final String? groupName;
  final String? groupImageUrl;
  final String? groupDescription;
  final String? pinnedFrameUrl;
  final String? membersJson;
  final int? createdAt;
  final String sessionAddress;
  final String ownerInboxId;
  const Conversation(
      {required this.topic,
      required this.type,
      this.peerInboxId,
      this.groupName,
      this.groupImageUrl,
      this.groupDescription,
      this.pinnedFrameUrl,
      this.membersJson,
      this.createdAt,
      required this.sessionAddress,
      required this.ownerInboxId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['topic'] = Variable<String>(topic);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || peerInboxId != null) {
      map['peer_inbox_id'] = Variable<String>(peerInboxId);
    }
    if (!nullToAbsent || groupName != null) {
      map['group_name'] = Variable<String>(groupName);
    }
    if (!nullToAbsent || groupImageUrl != null) {
      map['group_image_url'] = Variable<String>(groupImageUrl);
    }
    if (!nullToAbsent || groupDescription != null) {
      map['group_description'] = Variable<String>(groupDescription);
    }
    if (!nullToAbsent || pinnedFrameUrl != null) {
      map['pinned_frame_url'] = Variable<String>(pinnedFrameUrl);
    }
    if (!nullToAbsent || membersJson != null) {
      map['members_json'] = Variable<String>(membersJson);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    map['session_address'] = Variable<String>(sessionAddress);
    map['owner_inbox_id'] = Variable<String>(ownerInboxId);
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      topic: Value(topic),
      type: Value(type),
      peerInboxId: peerInboxId == null && nullToAbsent
          ? const Value.absent()
          : Value(peerInboxId),
      groupName: groupName == null && nullToAbsent
          ? const Value.absent()
          : Value(groupName),
      groupImageUrl: groupImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(groupImageUrl),
      groupDescription: groupDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(groupDescription),
      pinnedFrameUrl: pinnedFrameUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(pinnedFrameUrl),
      membersJson: membersJson == null && nullToAbsent
          ? const Value.absent()
          : Value(membersJson),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      sessionAddress: Value(sessionAddress),
      ownerInboxId: Value(ownerInboxId),
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Conversation(
      topic: serializer.fromJson<String>(json['topic']),
      type: serializer.fromJson<String>(json['type']),
      peerInboxId: serializer.fromJson<String?>(json['peerInboxId']),
      groupName: serializer.fromJson<String?>(json['groupName']),
      groupImageUrl: serializer.fromJson<String?>(json['groupImageUrl']),
      groupDescription: serializer.fromJson<String?>(json['groupDescription']),
      pinnedFrameUrl: serializer.fromJson<String?>(json['pinnedFrameUrl']),
      membersJson: serializer.fromJson<String?>(json['membersJson']),
      createdAt: serializer.fromJson<int?>(json['createdAt']),
      sessionAddress: serializer.fromJson<String>(json['sessionAddress']),
      ownerInboxId: serializer.fromJson<String>(json['ownerInboxId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'topic': serializer.toJson<String>(topic),
      'type': serializer.toJson<String>(type),
      'peerInboxId': serializer.toJson<String?>(peerInboxId),
      'groupName': serializer.toJson<String?>(groupName),
      'groupImageUrl': serializer.toJson<String?>(groupImageUrl),
      'groupDescription': serializer.toJson<String?>(groupDescription),
      'pinnedFrameUrl': serializer.toJson<String?>(pinnedFrameUrl),
      'membersJson': serializer.toJson<String?>(membersJson),
      'createdAt': serializer.toJson<int?>(createdAt),
      'sessionAddress': serializer.toJson<String>(sessionAddress),
      'ownerInboxId': serializer.toJson<String>(ownerInboxId),
    };
  }

  Conversation copyWith(
          {String? topic,
          String? type,
          Value<String?> peerInboxId = const Value.absent(),
          Value<String?> groupName = const Value.absent(),
          Value<String?> groupImageUrl = const Value.absent(),
          Value<String?> groupDescription = const Value.absent(),
          Value<String?> pinnedFrameUrl = const Value.absent(),
          Value<String?> membersJson = const Value.absent(),
          Value<int?> createdAt = const Value.absent(),
          String? sessionAddress,
          String? ownerInboxId}) =>
      Conversation(
        topic: topic ?? this.topic,
        type: type ?? this.type,
        peerInboxId: peerInboxId.present ? peerInboxId.value : this.peerInboxId,
        groupName: groupName.present ? groupName.value : this.groupName,
        groupImageUrl:
            groupImageUrl.present ? groupImageUrl.value : this.groupImageUrl,
        groupDescription: groupDescription.present
            ? groupDescription.value
            : this.groupDescription,
        pinnedFrameUrl:
            pinnedFrameUrl.present ? pinnedFrameUrl.value : this.pinnedFrameUrl,
        membersJson: membersJson.present ? membersJson.value : this.membersJson,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        sessionAddress: sessionAddress ?? this.sessionAddress,
        ownerInboxId: ownerInboxId ?? this.ownerInboxId,
      );
  Conversation copyWithCompanion(ConversationsCompanion data) {
    return Conversation(
      topic: data.topic.present ? data.topic.value : this.topic,
      type: data.type.present ? data.type.value : this.type,
      peerInboxId:
          data.peerInboxId.present ? data.peerInboxId.value : this.peerInboxId,
      groupName: data.groupName.present ? data.groupName.value : this.groupName,
      groupImageUrl: data.groupImageUrl.present
          ? data.groupImageUrl.value
          : this.groupImageUrl,
      groupDescription: data.groupDescription.present
          ? data.groupDescription.value
          : this.groupDescription,
      pinnedFrameUrl: data.pinnedFrameUrl.present
          ? data.pinnedFrameUrl.value
          : this.pinnedFrameUrl,
      membersJson:
          data.membersJson.present ? data.membersJson.value : this.membersJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      sessionAddress: data.sessionAddress.present
          ? data.sessionAddress.value
          : this.sessionAddress,
      ownerInboxId: data.ownerInboxId.present
          ? data.ownerInboxId.value
          : this.ownerInboxId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Conversation(')
          ..write('topic: $topic, ')
          ..write('type: $type, ')
          ..write('peerInboxId: $peerInboxId, ')
          ..write('groupName: $groupName, ')
          ..write('groupImageUrl: $groupImageUrl, ')
          ..write('groupDescription: $groupDescription, ')
          ..write('pinnedFrameUrl: $pinnedFrameUrl, ')
          ..write('membersJson: $membersJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('ownerInboxId: $ownerInboxId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      topic,
      type,
      peerInboxId,
      groupName,
      groupImageUrl,
      groupDescription,
      pinnedFrameUrl,
      membersJson,
      createdAt,
      sessionAddress,
      ownerInboxId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Conversation &&
          other.topic == this.topic &&
          other.type == this.type &&
          other.peerInboxId == this.peerInboxId &&
          other.groupName == this.groupName &&
          other.groupImageUrl == this.groupImageUrl &&
          other.groupDescription == this.groupDescription &&
          other.pinnedFrameUrl == this.pinnedFrameUrl &&
          other.membersJson == this.membersJson &&
          other.createdAt == this.createdAt &&
          other.sessionAddress == this.sessionAddress &&
          other.ownerInboxId == this.ownerInboxId);
}

class ConversationsCompanion extends UpdateCompanion<Conversation> {
  final Value<String> topic;
  final Value<String> type;
  final Value<String?> peerInboxId;
  final Value<String?> groupName;
  final Value<String?> groupImageUrl;
  final Value<String?> groupDescription;
  final Value<String?> pinnedFrameUrl;
  final Value<String?> membersJson;
  final Value<int?> createdAt;
  final Value<String> sessionAddress;
  final Value<String> ownerInboxId;
  final Value<int> rowid;
  const ConversationsCompanion({
    this.topic = const Value.absent(),
    this.type = const Value.absent(),
    this.peerInboxId = const Value.absent(),
    this.groupName = const Value.absent(),
    this.groupImageUrl = const Value.absent(),
    this.groupDescription = const Value.absent(),
    this.pinnedFrameUrl = const Value.absent(),
    this.membersJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.sessionAddress = const Value.absent(),
    this.ownerInboxId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationsCompanion.insert({
    required String topic,
    required String type,
    this.peerInboxId = const Value.absent(),
    this.groupName = const Value.absent(),
    this.groupImageUrl = const Value.absent(),
    this.groupDescription = const Value.absent(),
    this.pinnedFrameUrl = const Value.absent(),
    this.membersJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    required String sessionAddress,
    required String ownerInboxId,
    this.rowid = const Value.absent(),
  })  : topic = Value(topic),
        type = Value(type),
        sessionAddress = Value(sessionAddress),
        ownerInboxId = Value(ownerInboxId);
  static Insertable<Conversation> custom({
    Expression<String>? topic,
    Expression<String>? type,
    Expression<String>? peerInboxId,
    Expression<String>? groupName,
    Expression<String>? groupImageUrl,
    Expression<String>? groupDescription,
    Expression<String>? pinnedFrameUrl,
    Expression<String>? membersJson,
    Expression<int>? createdAt,
    Expression<String>? sessionAddress,
    Expression<String>? ownerInboxId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (topic != null) 'topic': topic,
      if (type != null) 'type': type,
      if (peerInboxId != null) 'peer_inbox_id': peerInboxId,
      if (groupName != null) 'group_name': groupName,
      if (groupImageUrl != null) 'group_image_url': groupImageUrl,
      if (groupDescription != null) 'group_description': groupDescription,
      if (pinnedFrameUrl != null) 'pinned_frame_url': pinnedFrameUrl,
      if (membersJson != null) 'members_json': membersJson,
      if (createdAt != null) 'created_at': createdAt,
      if (sessionAddress != null) 'session_address': sessionAddress,
      if (ownerInboxId != null) 'owner_inbox_id': ownerInboxId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationsCompanion copyWith(
      {Value<String>? topic,
      Value<String>? type,
      Value<String?>? peerInboxId,
      Value<String?>? groupName,
      Value<String?>? groupImageUrl,
      Value<String?>? groupDescription,
      Value<String?>? pinnedFrameUrl,
      Value<String?>? membersJson,
      Value<int?>? createdAt,
      Value<String>? sessionAddress,
      Value<String>? ownerInboxId,
      Value<int>? rowid}) {
    return ConversationsCompanion(
      topic: topic ?? this.topic,
      type: type ?? this.type,
      peerInboxId: peerInboxId ?? this.peerInboxId,
      groupName: groupName ?? this.groupName,
      groupImageUrl: groupImageUrl ?? this.groupImageUrl,
      groupDescription: groupDescription ?? this.groupDescription,
      pinnedFrameUrl: pinnedFrameUrl ?? this.pinnedFrameUrl,
      membersJson: membersJson ?? this.membersJson,
      createdAt: createdAt ?? this.createdAt,
      sessionAddress: sessionAddress ?? this.sessionAddress,
      ownerInboxId: ownerInboxId ?? this.ownerInboxId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (peerInboxId.present) {
      map['peer_inbox_id'] = Variable<String>(peerInboxId.value);
    }
    if (groupName.present) {
      map['group_name'] = Variable<String>(groupName.value);
    }
    if (groupImageUrl.present) {
      map['group_image_url'] = Variable<String>(groupImageUrl.value);
    }
    if (groupDescription.present) {
      map['group_description'] = Variable<String>(groupDescription.value);
    }
    if (pinnedFrameUrl.present) {
      map['pinned_frame_url'] = Variable<String>(pinnedFrameUrl.value);
    }
    if (membersJson.present) {
      map['members_json'] = Variable<String>(membersJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (sessionAddress.present) {
      map['session_address'] = Variable<String>(sessionAddress.value);
    }
    if (ownerInboxId.present) {
      map['owner_inbox_id'] = Variable<String>(ownerInboxId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsCompanion(')
          ..write('topic: $topic, ')
          ..write('type: $type, ')
          ..write('peerInboxId: $peerInboxId, ')
          ..write('groupName: $groupName, ')
          ..write('groupImageUrl: $groupImageUrl, ')
          ..write('groupDescription: $groupDescription, ')
          ..write('pinnedFrameUrl: $pinnedFrameUrl, ')
          ..write('membersJson: $membersJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('ownerInboxId: $ownerInboxId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recordMeta = const VerificationMeta('record');
  @override
  late final GeneratedColumn<String> record = GeneratedColumn<String>(
      'record', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionAddressMeta =
      const VerificationMeta('sessionAddress');
  @override
  late final GeneratedColumn<String> sessionAddress = GeneratedColumn<String>(
      'session_address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, key, record, sessionAddress, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<Setting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('record')) {
      context.handle(_recordMeta,
          record.isAcceptableOrUnknown(data['record']!, _recordMeta));
    } else if (isInserting) {
      context.missing(_recordMeta);
    }
    if (data.containsKey('session_address')) {
      context.handle(
          _sessionAddressMeta,
          sessionAddress.isAcceptableOrUnknown(
              data['session_address']!, _sessionAddressMeta));
    } else if (isInserting) {
      context.missing(_sessionAddressMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {key, sessionAddress},
      ];
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      record: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}record'])!,
      sessionAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}session_address'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final int id;
  final String key;
  final String record;
  final String sessionAddress;
  final int updatedAt;
  const Setting(
      {required this.id,
      required this.key,
      required this.record,
      required this.sessionAddress,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    map['record'] = Variable<String>(record);
    map['session_address'] = Variable<String>(sessionAddress);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      key: Value(key),
      record: Value(record),
      sessionAddress: Value(sessionAddress),
      updatedAt: Value(updatedAt),
    );
  }

  factory Setting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      record: serializer.fromJson<String>(json['record']),
      sessionAddress: serializer.fromJson<String>(json['sessionAddress']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'record': serializer.toJson<String>(record),
      'sessionAddress': serializer.toJson<String>(sessionAddress),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Setting copyWith(
          {int? id,
          String? key,
          String? record,
          String? sessionAddress,
          int? updatedAt}) =>
      Setting(
        id: id ?? this.id,
        key: key ?? this.key,
        record: record ?? this.record,
        sessionAddress: sessionAddress ?? this.sessionAddress,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      record: data.record.present ? data.record.value : this.record,
      sessionAddress: data.sessionAddress.present
          ? data.sessionAddress.value
          : this.sessionAddress,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('record: $record, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, key, record, sessionAddress, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.id == this.id &&
          other.key == this.key &&
          other.record == this.record &&
          other.sessionAddress == this.sessionAddress &&
          other.updatedAt == this.updatedAt);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> record;
  final Value<String> sessionAddress;
  final Value<int> updatedAt;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.record = const Value.absent(),
    this.sessionAddress = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String record,
    required String sessionAddress,
    required int updatedAt,
  })  : key = Value(key),
        record = Value(record),
        sessionAddress = Value(sessionAddress),
        updatedAt = Value(updatedAt);
  static Insertable<Setting> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? record,
    Expression<String>? sessionAddress,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (record != null) 'record': record,
      if (sessionAddress != null) 'session_address': sessionAddress,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SettingsCompanion copyWith(
      {Value<int>? id,
      Value<String>? key,
      Value<String>? record,
      Value<String>? sessionAddress,
      Value<int>? updatedAt}) {
    return SettingsCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      record: record ?? this.record,
      sessionAddress: sessionAddress ?? this.sessionAddress,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (record.present) {
      map['record'] = Variable<String>(record.value);
    }
    if (sessionAddress.present) {
      map['session_address'] = Variable<String>(sessionAddress.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('record: $record, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $FeedServersTable extends FeedServers
    with TableInfo<$FeedServersTable, FeedServer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FeedServersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _feedServerAddressMeta =
      const VerificationMeta('feedServerAddress');
  @override
  late final GeneratedColumn<String> feedServerAddress =
      GeneratedColumn<String>('feed_server_address', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isDefaultMeta =
      const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
      'is_default', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_default" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sessionAddressMeta =
      const VerificationMeta('sessionAddress');
  @override
  late final GeneratedColumn<String> sessionAddress = GeneratedColumn<String>(
      'session_address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        feedServerAddress,
        name,
        isDefault,
        sessionAddress,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'feed_servers';
  @override
  VerificationContext validateIntegrity(Insertable<FeedServer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('feed_server_address')) {
      context.handle(
          _feedServerAddressMeta,
          feedServerAddress.isAcceptableOrUnknown(
              data['feed_server_address']!, _feedServerAddressMeta));
    } else if (isInserting) {
      context.missing(_feedServerAddressMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('is_default')) {
      context.handle(_isDefaultMeta,
          isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta));
    }
    if (data.containsKey('session_address')) {
      context.handle(
          _sessionAddressMeta,
          sessionAddress.isAcceptableOrUnknown(
              data['session_address']!, _sessionAddressMeta));
    } else if (isInserting) {
      context.missing(_sessionAddressMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {feedServerAddress, sessionAddress},
      ];
  @override
  FeedServer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FeedServer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      feedServerAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}feed_server_address'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      isDefault: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_default'])!,
      sessionAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}session_address'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $FeedServersTable createAlias(String alias) {
    return $FeedServersTable(attachedDatabase, alias);
  }
}

class FeedServer extends DataClass implements Insertable<FeedServer> {
  final int id;
  final String feedServerAddress;
  final String? name;
  final bool isDefault;
  final String sessionAddress;
  final int createdAt;
  final int updatedAt;
  const FeedServer(
      {required this.id,
      required this.feedServerAddress,
      this.name,
      required this.isDefault,
      required this.sessionAddress,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['feed_server_address'] = Variable<String>(feedServerAddress);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['is_default'] = Variable<bool>(isDefault);
    map['session_address'] = Variable<String>(sessionAddress);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  FeedServersCompanion toCompanion(bool nullToAbsent) {
    return FeedServersCompanion(
      id: Value(id),
      feedServerAddress: Value(feedServerAddress),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      isDefault: Value(isDefault),
      sessionAddress: Value(sessionAddress),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FeedServer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FeedServer(
      id: serializer.fromJson<int>(json['id']),
      feedServerAddress: serializer.fromJson<String>(json['feedServerAddress']),
      name: serializer.fromJson<String?>(json['name']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      sessionAddress: serializer.fromJson<String>(json['sessionAddress']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'feedServerAddress': serializer.toJson<String>(feedServerAddress),
      'name': serializer.toJson<String?>(name),
      'isDefault': serializer.toJson<bool>(isDefault),
      'sessionAddress': serializer.toJson<String>(sessionAddress),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  FeedServer copyWith(
          {int? id,
          String? feedServerAddress,
          Value<String?> name = const Value.absent(),
          bool? isDefault,
          String? sessionAddress,
          int? createdAt,
          int? updatedAt}) =>
      FeedServer(
        id: id ?? this.id,
        feedServerAddress: feedServerAddress ?? this.feedServerAddress,
        name: name.present ? name.value : this.name,
        isDefault: isDefault ?? this.isDefault,
        sessionAddress: sessionAddress ?? this.sessionAddress,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  FeedServer copyWithCompanion(FeedServersCompanion data) {
    return FeedServer(
      id: data.id.present ? data.id.value : this.id,
      feedServerAddress: data.feedServerAddress.present
          ? data.feedServerAddress.value
          : this.feedServerAddress,
      name: data.name.present ? data.name.value : this.name,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      sessionAddress: data.sessionAddress.present
          ? data.sessionAddress.value
          : this.sessionAddress,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FeedServer(')
          ..write('id: $id, ')
          ..write('feedServerAddress: $feedServerAddress, ')
          ..write('name: $name, ')
          ..write('isDefault: $isDefault, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, feedServerAddress, name, isDefault,
      sessionAddress, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FeedServer &&
          other.id == this.id &&
          other.feedServerAddress == this.feedServerAddress &&
          other.name == this.name &&
          other.isDefault == this.isDefault &&
          other.sessionAddress == this.sessionAddress &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FeedServersCompanion extends UpdateCompanion<FeedServer> {
  final Value<int> id;
  final Value<String> feedServerAddress;
  final Value<String?> name;
  final Value<bool> isDefault;
  final Value<String> sessionAddress;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const FeedServersCompanion({
    this.id = const Value.absent(),
    this.feedServerAddress = const Value.absent(),
    this.name = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.sessionAddress = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  FeedServersCompanion.insert({
    this.id = const Value.absent(),
    required String feedServerAddress,
    this.name = const Value.absent(),
    this.isDefault = const Value.absent(),
    required String sessionAddress,
    required int createdAt,
    required int updatedAt,
  })  : feedServerAddress = Value(feedServerAddress),
        sessionAddress = Value(sessionAddress),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<FeedServer> custom({
    Expression<int>? id,
    Expression<String>? feedServerAddress,
    Expression<String>? name,
    Expression<bool>? isDefault,
    Expression<String>? sessionAddress,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (feedServerAddress != null) 'feed_server_address': feedServerAddress,
      if (name != null) 'name': name,
      if (isDefault != null) 'is_default': isDefault,
      if (sessionAddress != null) 'session_address': sessionAddress,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  FeedServersCompanion copyWith(
      {Value<int>? id,
      Value<String>? feedServerAddress,
      Value<String?>? name,
      Value<bool>? isDefault,
      Value<String>? sessionAddress,
      Value<int>? createdAt,
      Value<int>? updatedAt}) {
    return FeedServersCompanion(
      id: id ?? this.id,
      feedServerAddress: feedServerAddress ?? this.feedServerAddress,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      sessionAddress: sessionAddress ?? this.sessionAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (feedServerAddress.present) {
      map['feed_server_address'] = Variable<String>(feedServerAddress.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (sessionAddress.present) {
      map['session_address'] = Variable<String>(sessionAddress.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FeedServersCompanion(')
          ..write('id: $id, ')
          ..write('feedServerAddress: $feedServerAddress, ')
          ..write('name: $name, ')
          ..write('isDefault: $isDefault, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $RpcServersTable extends RpcServers
    with TableInfo<$RpcServersTable, RpcServer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RpcServersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _rpcUrlMeta = const VerificationMeta('rpcUrl');
  @override
  late final GeneratedColumn<String> rpcUrl = GeneratedColumn<String>(
      'rpc_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isDefaultMeta =
      const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
      'is_default', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_default" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sessionAddressMeta =
      const VerificationMeta('sessionAddress');
  @override
  late final GeneratedColumn<String> sessionAddress = GeneratedColumn<String>(
      'session_address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, rpcUrl, name, isDefault, sessionAddress, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rpc_servers';
  @override
  VerificationContext validateIntegrity(Insertable<RpcServer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('rpc_url')) {
      context.handle(_rpcUrlMeta,
          rpcUrl.isAcceptableOrUnknown(data['rpc_url']!, _rpcUrlMeta));
    } else if (isInserting) {
      context.missing(_rpcUrlMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('is_default')) {
      context.handle(_isDefaultMeta,
          isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta));
    }
    if (data.containsKey('session_address')) {
      context.handle(
          _sessionAddressMeta,
          sessionAddress.isAcceptableOrUnknown(
              data['session_address']!, _sessionAddressMeta));
    } else if (isInserting) {
      context.missing(_sessionAddressMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {rpcUrl, sessionAddress},
      ];
  @override
  RpcServer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RpcServer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      rpcUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rpc_url'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      isDefault: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_default'])!,
      sessionAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}session_address'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $RpcServersTable createAlias(String alias) {
    return $RpcServersTable(attachedDatabase, alias);
  }
}

class RpcServer extends DataClass implements Insertable<RpcServer> {
  final int id;
  final String rpcUrl;
  final String? name;
  final bool isDefault;
  final String sessionAddress;
  final int createdAt;
  final int updatedAt;
  const RpcServer(
      {required this.id,
      required this.rpcUrl,
      this.name,
      required this.isDefault,
      required this.sessionAddress,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['rpc_url'] = Variable<String>(rpcUrl);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['is_default'] = Variable<bool>(isDefault);
    map['session_address'] = Variable<String>(sessionAddress);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  RpcServersCompanion toCompanion(bool nullToAbsent) {
    return RpcServersCompanion(
      id: Value(id),
      rpcUrl: Value(rpcUrl),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      isDefault: Value(isDefault),
      sessionAddress: Value(sessionAddress),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory RpcServer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RpcServer(
      id: serializer.fromJson<int>(json['id']),
      rpcUrl: serializer.fromJson<String>(json['rpcUrl']),
      name: serializer.fromJson<String?>(json['name']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      sessionAddress: serializer.fromJson<String>(json['sessionAddress']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'rpcUrl': serializer.toJson<String>(rpcUrl),
      'name': serializer.toJson<String?>(name),
      'isDefault': serializer.toJson<bool>(isDefault),
      'sessionAddress': serializer.toJson<String>(sessionAddress),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  RpcServer copyWith(
          {int? id,
          String? rpcUrl,
          Value<String?> name = const Value.absent(),
          bool? isDefault,
          String? sessionAddress,
          int? createdAt,
          int? updatedAt}) =>
      RpcServer(
        id: id ?? this.id,
        rpcUrl: rpcUrl ?? this.rpcUrl,
        name: name.present ? name.value : this.name,
        isDefault: isDefault ?? this.isDefault,
        sessionAddress: sessionAddress ?? this.sessionAddress,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  RpcServer copyWithCompanion(RpcServersCompanion data) {
    return RpcServer(
      id: data.id.present ? data.id.value : this.id,
      rpcUrl: data.rpcUrl.present ? data.rpcUrl.value : this.rpcUrl,
      name: data.name.present ? data.name.value : this.name,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      sessionAddress: data.sessionAddress.present
          ? data.sessionAddress.value
          : this.sessionAddress,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RpcServer(')
          ..write('id: $id, ')
          ..write('rpcUrl: $rpcUrl, ')
          ..write('name: $name, ')
          ..write('isDefault: $isDefault, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, rpcUrl, name, isDefault, sessionAddress, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RpcServer &&
          other.id == this.id &&
          other.rpcUrl == this.rpcUrl &&
          other.name == this.name &&
          other.isDefault == this.isDefault &&
          other.sessionAddress == this.sessionAddress &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RpcServersCompanion extends UpdateCompanion<RpcServer> {
  final Value<int> id;
  final Value<String> rpcUrl;
  final Value<String?> name;
  final Value<bool> isDefault;
  final Value<String> sessionAddress;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const RpcServersCompanion({
    this.id = const Value.absent(),
    this.rpcUrl = const Value.absent(),
    this.name = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.sessionAddress = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  RpcServersCompanion.insert({
    this.id = const Value.absent(),
    required String rpcUrl,
    this.name = const Value.absent(),
    this.isDefault = const Value.absent(),
    required String sessionAddress,
    required int createdAt,
    required int updatedAt,
  })  : rpcUrl = Value(rpcUrl),
        sessionAddress = Value(sessionAddress),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<RpcServer> custom({
    Expression<int>? id,
    Expression<String>? rpcUrl,
    Expression<String>? name,
    Expression<bool>? isDefault,
    Expression<String>? sessionAddress,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rpcUrl != null) 'rpc_url': rpcUrl,
      if (name != null) 'name': name,
      if (isDefault != null) 'is_default': isDefault,
      if (sessionAddress != null) 'session_address': sessionAddress,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  RpcServersCompanion copyWith(
      {Value<int>? id,
      Value<String>? rpcUrl,
      Value<String?>? name,
      Value<bool>? isDefault,
      Value<String>? sessionAddress,
      Value<int>? createdAt,
      Value<int>? updatedAt}) {
    return RpcServersCompanion(
      id: id ?? this.id,
      rpcUrl: rpcUrl ?? this.rpcUrl,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      sessionAddress: sessionAddress ?? this.sessionAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (rpcUrl.present) {
      map['rpc_url'] = Variable<String>(rpcUrl.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (sessionAddress.present) {
      map['session_address'] = Variable<String>(sessionAddress.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RpcServersCompanion(')
          ..write('id: $id, ')
          ..write('rpcUrl: $rpcUrl, ')
          ..write('name: $name, ')
          ..write('isDefault: $isDefault, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $FeedListsTable extends FeedLists
    with TableInfo<$FeedListsTable, FeedListData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FeedListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sessionAddressMeta =
      const VerificationMeta('sessionAddress');
  @override
  late final GeneratedColumn<String> sessionAddress = GeneratedColumn<String>(
      'session_address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isSingleMeta =
      const VerificationMeta('isSingle');
  @override
  late final GeneratedColumn<bool> isSingle = GeneratedColumn<bool>(
      'is_single', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_single" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, icon, sessionAddress, createdAt, updatedAt, isSingle];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'feed_lists';
  @override
  VerificationContext validateIntegrity(Insertable<FeedListData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('session_address')) {
      context.handle(
          _sessionAddressMeta,
          sessionAddress.isAcceptableOrUnknown(
              data['session_address']!, _sessionAddressMeta));
    } else if (isInserting) {
      context.missing(_sessionAddressMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_single')) {
      context.handle(_isSingleMeta,
          isSingle.isAcceptableOrUnknown(data['is_single']!, _isSingleMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FeedListData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FeedListData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon']),
      sessionAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}session_address'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      isSingle: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_single'])!,
    );
  }

  @override
  $FeedListsTable createAlias(String alias) {
    return $FeedListsTable(attachedDatabase, alias);
  }
}

class FeedListData extends DataClass implements Insertable<FeedListData> {
  final int id;
  final String name;
  final String? icon;
  final String sessionAddress;
  final int createdAt;
  final int updatedAt;
  final bool isSingle;
  const FeedListData(
      {required this.id,
      required this.name,
      this.icon,
      required this.sessionAddress,
      required this.createdAt,
      required this.updatedAt,
      required this.isSingle});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['session_address'] = Variable<String>(sessionAddress);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['is_single'] = Variable<bool>(isSingle);
    return map;
  }

  FeedListsCompanion toCompanion(bool nullToAbsent) {
    return FeedListsCompanion(
      id: Value(id),
      name: Value(name),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      sessionAddress: Value(sessionAddress),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isSingle: Value(isSingle),
    );
  }

  factory FeedListData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FeedListData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String?>(json['icon']),
      sessionAddress: serializer.fromJson<String>(json['sessionAddress']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      isSingle: serializer.fromJson<bool>(json['isSingle']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String?>(icon),
      'sessionAddress': serializer.toJson<String>(sessionAddress),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'isSingle': serializer.toJson<bool>(isSingle),
    };
  }

  FeedListData copyWith(
          {int? id,
          String? name,
          Value<String?> icon = const Value.absent(),
          String? sessionAddress,
          int? createdAt,
          int? updatedAt,
          bool? isSingle}) =>
      FeedListData(
        id: id ?? this.id,
        name: name ?? this.name,
        icon: icon.present ? icon.value : this.icon,
        sessionAddress: sessionAddress ?? this.sessionAddress,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isSingle: isSingle ?? this.isSingle,
      );
  FeedListData copyWithCompanion(FeedListsCompanion data) {
    return FeedListData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      sessionAddress: data.sessionAddress.present
          ? data.sessionAddress.value
          : this.sessionAddress,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isSingle: data.isSingle.present ? data.isSingle.value : this.isSingle,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FeedListData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSingle: $isSingle')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, icon, sessionAddress, createdAt, updatedAt, isSingle);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FeedListData &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.sessionAddress == this.sessionAddress &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isSingle == this.isSingle);
}

class FeedListsCompanion extends UpdateCompanion<FeedListData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> icon;
  final Value<String> sessionAddress;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<bool> isSingle;
  const FeedListsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.sessionAddress = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSingle = const Value.absent(),
  });
  FeedListsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.icon = const Value.absent(),
    required String sessionAddress,
    required int createdAt,
    required int updatedAt,
    this.isSingle = const Value.absent(),
  })  : name = Value(name),
        sessionAddress = Value(sessionAddress),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<FeedListData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<String>? sessionAddress,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<bool>? isSingle,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (sessionAddress != null) 'session_address': sessionAddress,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isSingle != null) 'is_single': isSingle,
    });
  }

  FeedListsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? icon,
      Value<String>? sessionAddress,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<bool>? isSingle}) {
    return FeedListsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      sessionAddress: sessionAddress ?? this.sessionAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSingle: isSingle ?? this.isSingle,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (sessionAddress.present) {
      map['session_address'] = Variable<String>(sessionAddress.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (isSingle.present) {
      map['is_single'] = Variable<bool>(isSingle.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FeedListsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSingle: $isSingle')
          ..write(')'))
        .toString();
  }
}

class $ListFeedsTable extends ListFeeds
    with TableInfo<$ListFeedsTable, ListFeed> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListFeedsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<int> listId = GeneratedColumn<int>(
      'list_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints:
          'NOT NULL REFERENCES feed_lists(id) ON DELETE CASCADE');
  static const VerificationMeta _feedUrlMeta =
      const VerificationMeta('feedUrl');
  @override
  late final GeneratedColumn<String> feedUrl = GeneratedColumn<String>(
      'feed_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _feedTitleMeta =
      const VerificationMeta('feedTitle');
  @override
  late final GeneratedColumn<String> feedTitle = GeneratedColumn<String>(
      'feed_title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _feedDescriptionMeta =
      const VerificationMeta('feedDescription');
  @override
  late final GeneratedColumn<String> feedDescription = GeneratedColumn<String>(
      'feed_description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _feedFoundAtAccountAddressMeta =
      const VerificationMeta('feedFoundAtAccountAddress');
  @override
  late final GeneratedColumn<String> feedFoundAtAccountAddress =
      GeneratedColumn<String>(
          'feed_found_at_account_address', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _feedRecordKeyMeta =
      const VerificationMeta('feedRecordKey');
  @override
  late final GeneratedColumn<String> feedRecordKey = GeneratedColumn<String>(
      'feed_record_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
      'added_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        listId,
        feedUrl,
        feedTitle,
        feedDescription,
        feedFoundAtAccountAddress,
        feedRecordKey,
        addedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'list_feeds';
  @override
  VerificationContext validateIntegrity(Insertable<ListFeed> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('list_id')) {
      context.handle(_listIdMeta,
          listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta));
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('feed_url')) {
      context.handle(_feedUrlMeta,
          feedUrl.isAcceptableOrUnknown(data['feed_url']!, _feedUrlMeta));
    } else if (isInserting) {
      context.missing(_feedUrlMeta);
    }
    if (data.containsKey('feed_title')) {
      context.handle(_feedTitleMeta,
          feedTitle.isAcceptableOrUnknown(data['feed_title']!, _feedTitleMeta));
    }
    if (data.containsKey('feed_description')) {
      context.handle(
          _feedDescriptionMeta,
          feedDescription.isAcceptableOrUnknown(
              data['feed_description']!, _feedDescriptionMeta));
    }
    if (data.containsKey('feed_found_at_account_address')) {
      context.handle(
          _feedFoundAtAccountAddressMeta,
          feedFoundAtAccountAddress.isAcceptableOrUnknown(
              data['feed_found_at_account_address']!,
              _feedFoundAtAccountAddressMeta));
    }
    if (data.containsKey('feed_record_key')) {
      context.handle(
          _feedRecordKeyMeta,
          feedRecordKey.isAcceptableOrUnknown(
              data['feed_record_key']!, _feedRecordKeyMeta));
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ListFeed map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListFeed(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      listId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}list_id'])!,
      feedUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}feed_url'])!,
      feedTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}feed_title']),
      feedDescription: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}feed_description']),
      feedFoundAtAccountAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}feed_found_at_account_address']),
      feedRecordKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}feed_record_key']),
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}added_at'])!,
    );
  }

  @override
  $ListFeedsTable createAlias(String alias) {
    return $ListFeedsTable(attachedDatabase, alias);
  }
}

class ListFeed extends DataClass implements Insertable<ListFeed> {
  final int id;
  final int listId;
  final String feedUrl;
  final String? feedTitle;
  final String? feedDescription;
  final String? feedFoundAtAccountAddress;

  /// The owner's `record.key` for this channel, when the row is a CHANNEL
  /// FOLLOW rather than a raw URL snapshot. Null = raw URL: fetch [feedUrl] as
  /// stored. Non-null = re-resolve the URL from the owner's records by this
  /// key, so the follow survives the author re-pointing or renaming the
  /// channel.
  ///
  /// Read by `PublicOSFollows.resolveListFeeds` (the only re-resolving reader;
  /// raw `getFeedsInList` callers still see the stored URL). Note it is NOT
  /// carried onto the rendered `Post`: the direct half of `resolveListItems`
  /// and `ListRowFeedOrigin` drop it (wiki publicos_client/feeds § where a post
  /// came from).
  final String? feedRecordKey;
  final int addedAt;
  const ListFeed(
      {required this.id,
      required this.listId,
      required this.feedUrl,
      this.feedTitle,
      this.feedDescription,
      this.feedFoundAtAccountAddress,
      this.feedRecordKey,
      required this.addedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['list_id'] = Variable<int>(listId);
    map['feed_url'] = Variable<String>(feedUrl);
    if (!nullToAbsent || feedTitle != null) {
      map['feed_title'] = Variable<String>(feedTitle);
    }
    if (!nullToAbsent || feedDescription != null) {
      map['feed_description'] = Variable<String>(feedDescription);
    }
    if (!nullToAbsent || feedFoundAtAccountAddress != null) {
      map['feed_found_at_account_address'] =
          Variable<String>(feedFoundAtAccountAddress);
    }
    if (!nullToAbsent || feedRecordKey != null) {
      map['feed_record_key'] = Variable<String>(feedRecordKey);
    }
    map['added_at'] = Variable<int>(addedAt);
    return map;
  }

  ListFeedsCompanion toCompanion(bool nullToAbsent) {
    return ListFeedsCompanion(
      id: Value(id),
      listId: Value(listId),
      feedUrl: Value(feedUrl),
      feedTitle: feedTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(feedTitle),
      feedDescription: feedDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(feedDescription),
      feedFoundAtAccountAddress:
          feedFoundAtAccountAddress == null && nullToAbsent
              ? const Value.absent()
              : Value(feedFoundAtAccountAddress),
      feedRecordKey: feedRecordKey == null && nullToAbsent
          ? const Value.absent()
          : Value(feedRecordKey),
      addedAt: Value(addedAt),
    );
  }

  factory ListFeed.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListFeed(
      id: serializer.fromJson<int>(json['id']),
      listId: serializer.fromJson<int>(json['listId']),
      feedUrl: serializer.fromJson<String>(json['feedUrl']),
      feedTitle: serializer.fromJson<String?>(json['feedTitle']),
      feedDescription: serializer.fromJson<String?>(json['feedDescription']),
      feedFoundAtAccountAddress:
          serializer.fromJson<String?>(json['feedFoundAtAccountAddress']),
      feedRecordKey: serializer.fromJson<String?>(json['feedRecordKey']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'listId': serializer.toJson<int>(listId),
      'feedUrl': serializer.toJson<String>(feedUrl),
      'feedTitle': serializer.toJson<String?>(feedTitle),
      'feedDescription': serializer.toJson<String?>(feedDescription),
      'feedFoundAtAccountAddress':
          serializer.toJson<String?>(feedFoundAtAccountAddress),
      'feedRecordKey': serializer.toJson<String?>(feedRecordKey),
      'addedAt': serializer.toJson<int>(addedAt),
    };
  }

  ListFeed copyWith(
          {int? id,
          int? listId,
          String? feedUrl,
          Value<String?> feedTitle = const Value.absent(),
          Value<String?> feedDescription = const Value.absent(),
          Value<String?> feedFoundAtAccountAddress = const Value.absent(),
          Value<String?> feedRecordKey = const Value.absent(),
          int? addedAt}) =>
      ListFeed(
        id: id ?? this.id,
        listId: listId ?? this.listId,
        feedUrl: feedUrl ?? this.feedUrl,
        feedTitle: feedTitle.present ? feedTitle.value : this.feedTitle,
        feedDescription: feedDescription.present
            ? feedDescription.value
            : this.feedDescription,
        feedFoundAtAccountAddress: feedFoundAtAccountAddress.present
            ? feedFoundAtAccountAddress.value
            : this.feedFoundAtAccountAddress,
        feedRecordKey:
            feedRecordKey.present ? feedRecordKey.value : this.feedRecordKey,
        addedAt: addedAt ?? this.addedAt,
      );
  ListFeed copyWithCompanion(ListFeedsCompanion data) {
    return ListFeed(
      id: data.id.present ? data.id.value : this.id,
      listId: data.listId.present ? data.listId.value : this.listId,
      feedUrl: data.feedUrl.present ? data.feedUrl.value : this.feedUrl,
      feedTitle: data.feedTitle.present ? data.feedTitle.value : this.feedTitle,
      feedDescription: data.feedDescription.present
          ? data.feedDescription.value
          : this.feedDescription,
      feedFoundAtAccountAddress: data.feedFoundAtAccountAddress.present
          ? data.feedFoundAtAccountAddress.value
          : this.feedFoundAtAccountAddress,
      feedRecordKey: data.feedRecordKey.present
          ? data.feedRecordKey.value
          : this.feedRecordKey,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListFeed(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('feedUrl: $feedUrl, ')
          ..write('feedTitle: $feedTitle, ')
          ..write('feedDescription: $feedDescription, ')
          ..write('feedFoundAtAccountAddress: $feedFoundAtAccountAddress, ')
          ..write('feedRecordKey: $feedRecordKey, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, listId, feedUrl, feedTitle,
      feedDescription, feedFoundAtAccountAddress, feedRecordKey, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListFeed &&
          other.id == this.id &&
          other.listId == this.listId &&
          other.feedUrl == this.feedUrl &&
          other.feedTitle == this.feedTitle &&
          other.feedDescription == this.feedDescription &&
          other.feedFoundAtAccountAddress == this.feedFoundAtAccountAddress &&
          other.feedRecordKey == this.feedRecordKey &&
          other.addedAt == this.addedAt);
}

class ListFeedsCompanion extends UpdateCompanion<ListFeed> {
  final Value<int> id;
  final Value<int> listId;
  final Value<String> feedUrl;
  final Value<String?> feedTitle;
  final Value<String?> feedDescription;
  final Value<String?> feedFoundAtAccountAddress;
  final Value<String?> feedRecordKey;
  final Value<int> addedAt;
  const ListFeedsCompanion({
    this.id = const Value.absent(),
    this.listId = const Value.absent(),
    this.feedUrl = const Value.absent(),
    this.feedTitle = const Value.absent(),
    this.feedDescription = const Value.absent(),
    this.feedFoundAtAccountAddress = const Value.absent(),
    this.feedRecordKey = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  ListFeedsCompanion.insert({
    this.id = const Value.absent(),
    required int listId,
    required String feedUrl,
    this.feedTitle = const Value.absent(),
    this.feedDescription = const Value.absent(),
    this.feedFoundAtAccountAddress = const Value.absent(),
    this.feedRecordKey = const Value.absent(),
    required int addedAt,
  })  : listId = Value(listId),
        feedUrl = Value(feedUrl),
        addedAt = Value(addedAt);
  static Insertable<ListFeed> custom({
    Expression<int>? id,
    Expression<int>? listId,
    Expression<String>? feedUrl,
    Expression<String>? feedTitle,
    Expression<String>? feedDescription,
    Expression<String>? feedFoundAtAccountAddress,
    Expression<String>? feedRecordKey,
    Expression<int>? addedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (listId != null) 'list_id': listId,
      if (feedUrl != null) 'feed_url': feedUrl,
      if (feedTitle != null) 'feed_title': feedTitle,
      if (feedDescription != null) 'feed_description': feedDescription,
      if (feedFoundAtAccountAddress != null)
        'feed_found_at_account_address': feedFoundAtAccountAddress,
      if (feedRecordKey != null) 'feed_record_key': feedRecordKey,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  ListFeedsCompanion copyWith(
      {Value<int>? id,
      Value<int>? listId,
      Value<String>? feedUrl,
      Value<String?>? feedTitle,
      Value<String?>? feedDescription,
      Value<String?>? feedFoundAtAccountAddress,
      Value<String?>? feedRecordKey,
      Value<int>? addedAt}) {
    return ListFeedsCompanion(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      feedUrl: feedUrl ?? this.feedUrl,
      feedTitle: feedTitle ?? this.feedTitle,
      feedDescription: feedDescription ?? this.feedDescription,
      feedFoundAtAccountAddress:
          feedFoundAtAccountAddress ?? this.feedFoundAtAccountAddress,
      feedRecordKey: feedRecordKey ?? this.feedRecordKey,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<int>(listId.value);
    }
    if (feedUrl.present) {
      map['feed_url'] = Variable<String>(feedUrl.value);
    }
    if (feedTitle.present) {
      map['feed_title'] = Variable<String>(feedTitle.value);
    }
    if (feedDescription.present) {
      map['feed_description'] = Variable<String>(feedDescription.value);
    }
    if (feedFoundAtAccountAddress.present) {
      map['feed_found_at_account_address'] =
          Variable<String>(feedFoundAtAccountAddress.value);
    }
    if (feedRecordKey.present) {
      map['feed_record_key'] = Variable<String>(feedRecordKey.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListFeedsCompanion(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('feedUrl: $feedUrl, ')
          ..write('feedTitle: $feedTitle, ')
          ..write('feedDescription: $feedDescription, ')
          ..write('feedFoundAtAccountAddress: $feedFoundAtAccountAddress, ')
          ..write('feedRecordKey: $feedRecordKey, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

class $FeedCacheTable extends FeedCache
    with TableInfo<$FeedCacheTable, FeedCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FeedCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _feedUrlMeta =
      const VerificationMeta('feedUrl');
  @override
  late final GeneratedColumn<String> feedUrl = GeneratedColumn<String>(
      'feed_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionAddressMeta =
      const VerificationMeta('sessionAddress');
  @override
  late final GeneratedColumn<String> sessionAddress = GeneratedColumn<String>(
      'session_address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentTypeMeta =
      const VerificationMeta('contentType');
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
      'content_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
      'etag', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumn<String> lastModified = GeneratedColumn<String>(
      'last_modified', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fetchedAtMeta =
      const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
      'fetched_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lockedMeta = const VerificationMeta('locked');
  @override
  late final GeneratedColumn<bool> locked = GeneratedColumn<bool>(
      'locked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("locked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _interactionsMeta =
      const VerificationMeta('interactions');
  @override
  late final GeneratedColumn<String> interactions = GeneratedColumn<String>(
      'interactions', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        feedUrl,
        sessionAddress,
        body,
        contentType,
        etag,
        lastModified,
        fetchedAt,
        locked,
        lastError,
        interactions
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'feed_cache';
  @override
  VerificationContext validateIntegrity(Insertable<FeedCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('feed_url')) {
      context.handle(_feedUrlMeta,
          feedUrl.isAcceptableOrUnknown(data['feed_url']!, _feedUrlMeta));
    } else if (isInserting) {
      context.missing(_feedUrlMeta);
    }
    if (data.containsKey('session_address')) {
      context.handle(
          _sessionAddressMeta,
          sessionAddress.isAcceptableOrUnknown(
              data['session_address']!, _sessionAddressMeta));
    } else if (isInserting) {
      context.missing(_sessionAddressMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('content_type')) {
      context.handle(
          _contentTypeMeta,
          contentType.isAcceptableOrUnknown(
              data['content_type']!, _contentTypeMeta));
    }
    if (data.containsKey('etag')) {
      context.handle(
          _etagMeta, etag.isAcceptableOrUnknown(data['etag']!, _etagMeta));
    }
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    }
    if (data.containsKey('fetched_at')) {
      context.handle(_fetchedAtMeta,
          fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta));
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('locked')) {
      context.handle(_lockedMeta,
          locked.isAcceptableOrUnknown(data['locked']!, _lockedMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('interactions')) {
      context.handle(
          _interactionsMeta,
          interactions.isAcceptableOrUnknown(
              data['interactions']!, _interactionsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {feedUrl, sessionAddress},
      ];
  @override
  FeedCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FeedCacheData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      feedUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}feed_url'])!,
      sessionAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}session_address'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      contentType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_type']),
      etag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}etag']),
      lastModified: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_modified']),
      fetchedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fetched_at'])!,
      locked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}locked'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      interactions: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}interactions']),
    );
  }

  @override
  $FeedCacheTable createAlias(String alias) {
    return $FeedCacheTable(attachedDatabase, alias);
  }
}

class FeedCacheData extends DataClass implements Insertable<FeedCacheData> {
  final int id;
  final String feedUrl;

  /// The house convention for per-user rows. `publicos.sqlite` is ONE file
  /// shared by every account on the device, so every per-user table carries
  /// this: `Settings{key, sessionAddress}`, `FeedLists.sessionAddress`,
  /// `BookmarkedPosts{postUid, feedUrl, sessionAddress}`. Reads are always
  /// `WHERE sessionAddress = ? AND feedUrl = ?`, so no account can reach
  /// another's row — a `304` only ever validates the copy *you* hold.
  final String sessionAddress;

  /// The raw response body, exactly as received. Re-parsed on read.
  final String body;
  final String? contentType;

  /// HTTP validators, echoed back on the next fetch as `If-None-Match` /
  /// `If-Modified-Since`. Null when the server sent none (plenty don't) — in
  /// which case we simply re-download, exactly as we do today.
  final String? etag;
  final String? lastModified;

  /// Drives eviction: rows older than 7 days are swept (nothing else prunes
  /// this table, and raw bodies run 50-500KB each).
  final int fetchedAt;

  /// The private-feed verdict, persisted. Without this the "some feeds in this
  /// list are private" banner needs a live 403 to know, so it can't survive a
  /// cold start.
  final bool locked;

  /// Last failure for this feed, so a dead feed can render as *dead* rather
  /// than as empty.
  final String? lastError;

  /// The last interactions answer for this document, raw JSON (v33,
  /// 2026-11-02). A PublicOS Feed document carries no counts by design (they
  /// vary per reader and per minute, the document does not), so without this
  /// the cached paint showed every post count-less until phase 2 landed.
  /// Written with every answer, on a 200 with the new body and on a 304 beside
  /// the kept one; read back into the cached posts. Per session like the row,
  /// so a signed answer's viewer facts stay with the reader they belong to.
  final String? interactions;
  const FeedCacheData(
      {required this.id,
      required this.feedUrl,
      required this.sessionAddress,
      required this.body,
      this.contentType,
      this.etag,
      this.lastModified,
      required this.fetchedAt,
      required this.locked,
      this.lastError,
      this.interactions});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['feed_url'] = Variable<String>(feedUrl);
    map['session_address'] = Variable<String>(sessionAddress);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || contentType != null) {
      map['content_type'] = Variable<String>(contentType);
    }
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    if (!nullToAbsent || lastModified != null) {
      map['last_modified'] = Variable<String>(lastModified);
    }
    map['fetched_at'] = Variable<int>(fetchedAt);
    map['locked'] = Variable<bool>(locked);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || interactions != null) {
      map['interactions'] = Variable<String>(interactions);
    }
    return map;
  }

  FeedCacheCompanion toCompanion(bool nullToAbsent) {
    return FeedCacheCompanion(
      id: Value(id),
      feedUrl: Value(feedUrl),
      sessionAddress: Value(sessionAddress),
      body: Value(body),
      contentType: contentType == null && nullToAbsent
          ? const Value.absent()
          : Value(contentType),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      lastModified: lastModified == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModified),
      fetchedAt: Value(fetchedAt),
      locked: Value(locked),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      interactions: interactions == null && nullToAbsent
          ? const Value.absent()
          : Value(interactions),
    );
  }

  factory FeedCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FeedCacheData(
      id: serializer.fromJson<int>(json['id']),
      feedUrl: serializer.fromJson<String>(json['feedUrl']),
      sessionAddress: serializer.fromJson<String>(json['sessionAddress']),
      body: serializer.fromJson<String>(json['body']),
      contentType: serializer.fromJson<String?>(json['contentType']),
      etag: serializer.fromJson<String?>(json['etag']),
      lastModified: serializer.fromJson<String?>(json['lastModified']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
      locked: serializer.fromJson<bool>(json['locked']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      interactions: serializer.fromJson<String?>(json['interactions']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'feedUrl': serializer.toJson<String>(feedUrl),
      'sessionAddress': serializer.toJson<String>(sessionAddress),
      'body': serializer.toJson<String>(body),
      'contentType': serializer.toJson<String?>(contentType),
      'etag': serializer.toJson<String?>(etag),
      'lastModified': serializer.toJson<String?>(lastModified),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
      'locked': serializer.toJson<bool>(locked),
      'lastError': serializer.toJson<String?>(lastError),
      'interactions': serializer.toJson<String?>(interactions),
    };
  }

  FeedCacheData copyWith(
          {int? id,
          String? feedUrl,
          String? sessionAddress,
          String? body,
          Value<String?> contentType = const Value.absent(),
          Value<String?> etag = const Value.absent(),
          Value<String?> lastModified = const Value.absent(),
          int? fetchedAt,
          bool? locked,
          Value<String?> lastError = const Value.absent(),
          Value<String?> interactions = const Value.absent()}) =>
      FeedCacheData(
        id: id ?? this.id,
        feedUrl: feedUrl ?? this.feedUrl,
        sessionAddress: sessionAddress ?? this.sessionAddress,
        body: body ?? this.body,
        contentType: contentType.present ? contentType.value : this.contentType,
        etag: etag.present ? etag.value : this.etag,
        lastModified:
            lastModified.present ? lastModified.value : this.lastModified,
        fetchedAt: fetchedAt ?? this.fetchedAt,
        locked: locked ?? this.locked,
        lastError: lastError.present ? lastError.value : this.lastError,
        interactions:
            interactions.present ? interactions.value : this.interactions,
      );
  FeedCacheData copyWithCompanion(FeedCacheCompanion data) {
    return FeedCacheData(
      id: data.id.present ? data.id.value : this.id,
      feedUrl: data.feedUrl.present ? data.feedUrl.value : this.feedUrl,
      sessionAddress: data.sessionAddress.present
          ? data.sessionAddress.value
          : this.sessionAddress,
      body: data.body.present ? data.body.value : this.body,
      contentType:
          data.contentType.present ? data.contentType.value : this.contentType,
      etag: data.etag.present ? data.etag.value : this.etag,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      locked: data.locked.present ? data.locked.value : this.locked,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      interactions: data.interactions.present
          ? data.interactions.value
          : this.interactions,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FeedCacheData(')
          ..write('id: $id, ')
          ..write('feedUrl: $feedUrl, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('body: $body, ')
          ..write('contentType: $contentType, ')
          ..write('etag: $etag, ')
          ..write('lastModified: $lastModified, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('locked: $locked, ')
          ..write('lastError: $lastError, ')
          ..write('interactions: $interactions')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      feedUrl,
      sessionAddress,
      body,
      contentType,
      etag,
      lastModified,
      fetchedAt,
      locked,
      lastError,
      interactions);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FeedCacheData &&
          other.id == this.id &&
          other.feedUrl == this.feedUrl &&
          other.sessionAddress == this.sessionAddress &&
          other.body == this.body &&
          other.contentType == this.contentType &&
          other.etag == this.etag &&
          other.lastModified == this.lastModified &&
          other.fetchedAt == this.fetchedAt &&
          other.locked == this.locked &&
          other.lastError == this.lastError &&
          other.interactions == this.interactions);
}

class FeedCacheCompanion extends UpdateCompanion<FeedCacheData> {
  final Value<int> id;
  final Value<String> feedUrl;
  final Value<String> sessionAddress;
  final Value<String> body;
  final Value<String?> contentType;
  final Value<String?> etag;
  final Value<String?> lastModified;
  final Value<int> fetchedAt;
  final Value<bool> locked;
  final Value<String?> lastError;
  final Value<String?> interactions;
  const FeedCacheCompanion({
    this.id = const Value.absent(),
    this.feedUrl = const Value.absent(),
    this.sessionAddress = const Value.absent(),
    this.body = const Value.absent(),
    this.contentType = const Value.absent(),
    this.etag = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.locked = const Value.absent(),
    this.lastError = const Value.absent(),
    this.interactions = const Value.absent(),
  });
  FeedCacheCompanion.insert({
    this.id = const Value.absent(),
    required String feedUrl,
    required String sessionAddress,
    required String body,
    this.contentType = const Value.absent(),
    this.etag = const Value.absent(),
    this.lastModified = const Value.absent(),
    required int fetchedAt,
    this.locked = const Value.absent(),
    this.lastError = const Value.absent(),
    this.interactions = const Value.absent(),
  })  : feedUrl = Value(feedUrl),
        sessionAddress = Value(sessionAddress),
        body = Value(body),
        fetchedAt = Value(fetchedAt);
  static Insertable<FeedCacheData> custom({
    Expression<int>? id,
    Expression<String>? feedUrl,
    Expression<String>? sessionAddress,
    Expression<String>? body,
    Expression<String>? contentType,
    Expression<String>? etag,
    Expression<String>? lastModified,
    Expression<int>? fetchedAt,
    Expression<bool>? locked,
    Expression<String>? lastError,
    Expression<String>? interactions,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (feedUrl != null) 'feed_url': feedUrl,
      if (sessionAddress != null) 'session_address': sessionAddress,
      if (body != null) 'body': body,
      if (contentType != null) 'content_type': contentType,
      if (etag != null) 'etag': etag,
      if (lastModified != null) 'last_modified': lastModified,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (locked != null) 'locked': locked,
      if (lastError != null) 'last_error': lastError,
      if (interactions != null) 'interactions': interactions,
    });
  }

  FeedCacheCompanion copyWith(
      {Value<int>? id,
      Value<String>? feedUrl,
      Value<String>? sessionAddress,
      Value<String>? body,
      Value<String?>? contentType,
      Value<String?>? etag,
      Value<String?>? lastModified,
      Value<int>? fetchedAt,
      Value<bool>? locked,
      Value<String?>? lastError,
      Value<String?>? interactions}) {
    return FeedCacheCompanion(
      id: id ?? this.id,
      feedUrl: feedUrl ?? this.feedUrl,
      sessionAddress: sessionAddress ?? this.sessionAddress,
      body: body ?? this.body,
      contentType: contentType ?? this.contentType,
      etag: etag ?? this.etag,
      lastModified: lastModified ?? this.lastModified,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      locked: locked ?? this.locked,
      lastError: lastError ?? this.lastError,
      interactions: interactions ?? this.interactions,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (feedUrl.present) {
      map['feed_url'] = Variable<String>(feedUrl.value);
    }
    if (sessionAddress.present) {
      map['session_address'] = Variable<String>(sessionAddress.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<String>(lastModified.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (locked.present) {
      map['locked'] = Variable<bool>(locked.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (interactions.present) {
      map['interactions'] = Variable<String>(interactions.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FeedCacheCompanion(')
          ..write('id: $id, ')
          ..write('feedUrl: $feedUrl, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('body: $body, ')
          ..write('contentType: $contentType, ')
          ..write('etag: $etag, ')
          ..write('lastModified: $lastModified, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('locked: $locked, ')
          ..write('lastError: $lastError, ')
          ..write('interactions: $interactions')
          ..write(')'))
        .toString();
  }
}

class $AttachmentCacheTable extends AttachmentCache
    with TableInfo<$AttachmentCacheTable, AttachmentCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _contentDigestMeta =
      const VerificationMeta('contentDigest');
  @override
  late final GeneratedColumn<String> contentDigest = GeneratedColumn<String>(
      'content_digest', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _filenameMeta =
      const VerificationMeta('filename');
  @override
  late final GeneratedColumn<String> filename = GeneratedColumn<String>(
      'filename', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mimeTypeMeta =
      const VerificationMeta('mimeType');
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
      'mime_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<Uint8List> data = GeneratedColumn<Uint8List>(
      'data', aliasedName, false,
      type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
      'size', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastAccessedMeta =
      const VerificationMeta('lastAccessed');
  @override
  late final GeneratedColumn<int> lastAccessed = GeneratedColumn<int>(
      'last_accessed', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [contentDigest, filename, mimeType, data, size, cachedAt, lastAccessed];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachment_cache';
  @override
  VerificationContext validateIntegrity(
      Insertable<AttachmentCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('content_digest')) {
      context.handle(
          _contentDigestMeta,
          contentDigest.isAcceptableOrUnknown(
              data['content_digest']!, _contentDigestMeta));
    } else if (isInserting) {
      context.missing(_contentDigestMeta);
    }
    if (data.containsKey('filename')) {
      context.handle(_filenameMeta,
          filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta));
    } else if (isInserting) {
      context.missing(_filenameMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(_mimeTypeMeta,
          mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta));
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
          _sizeMeta, size.isAcceptableOrUnknown(data['size']!, _sizeMeta));
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('last_accessed')) {
      context.handle(
          _lastAccessedMeta,
          lastAccessed.isAcceptableOrUnknown(
              data['last_accessed']!, _lastAccessedMeta));
    } else if (isInserting) {
      context.missing(_lastAccessedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {contentDigest};
  @override
  AttachmentCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttachmentCacheData(
      contentDigest: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_digest'])!,
      filename: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}filename'])!,
      mimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mime_type'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}data'])!,
      size: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cached_at'])!,
      lastAccessed: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_accessed'])!,
    );
  }

  @override
  $AttachmentCacheTable createAlias(String alias) {
    return $AttachmentCacheTable(attachedDatabase, alias);
  }
}

class AttachmentCacheData extends DataClass
    implements Insertable<AttachmentCacheData> {
  final String contentDigest;
  final String filename;
  final String mimeType;
  final Uint8List data;
  final int size;
  final int cachedAt;
  final int lastAccessed;
  const AttachmentCacheData(
      {required this.contentDigest,
      required this.filename,
      required this.mimeType,
      required this.data,
      required this.size,
      required this.cachedAt,
      required this.lastAccessed});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['content_digest'] = Variable<String>(contentDigest);
    map['filename'] = Variable<String>(filename);
    map['mime_type'] = Variable<String>(mimeType);
    map['data'] = Variable<Uint8List>(data);
    map['size'] = Variable<int>(size);
    map['cached_at'] = Variable<int>(cachedAt);
    map['last_accessed'] = Variable<int>(lastAccessed);
    return map;
  }

  AttachmentCacheCompanion toCompanion(bool nullToAbsent) {
    return AttachmentCacheCompanion(
      contentDigest: Value(contentDigest),
      filename: Value(filename),
      mimeType: Value(mimeType),
      data: Value(data),
      size: Value(size),
      cachedAt: Value(cachedAt),
      lastAccessed: Value(lastAccessed),
    );
  }

  factory AttachmentCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttachmentCacheData(
      contentDigest: serializer.fromJson<String>(json['contentDigest']),
      filename: serializer.fromJson<String>(json['filename']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      data: serializer.fromJson<Uint8List>(json['data']),
      size: serializer.fromJson<int>(json['size']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
      lastAccessed: serializer.fromJson<int>(json['lastAccessed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contentDigest': serializer.toJson<String>(contentDigest),
      'filename': serializer.toJson<String>(filename),
      'mimeType': serializer.toJson<String>(mimeType),
      'data': serializer.toJson<Uint8List>(data),
      'size': serializer.toJson<int>(size),
      'cachedAt': serializer.toJson<int>(cachedAt),
      'lastAccessed': serializer.toJson<int>(lastAccessed),
    };
  }

  AttachmentCacheData copyWith(
          {String? contentDigest,
          String? filename,
          String? mimeType,
          Uint8List? data,
          int? size,
          int? cachedAt,
          int? lastAccessed}) =>
      AttachmentCacheData(
        contentDigest: contentDigest ?? this.contentDigest,
        filename: filename ?? this.filename,
        mimeType: mimeType ?? this.mimeType,
        data: data ?? this.data,
        size: size ?? this.size,
        cachedAt: cachedAt ?? this.cachedAt,
        lastAccessed: lastAccessed ?? this.lastAccessed,
      );
  AttachmentCacheData copyWithCompanion(AttachmentCacheCompanion data) {
    return AttachmentCacheData(
      contentDigest: data.contentDigest.present
          ? data.contentDigest.value
          : this.contentDigest,
      filename: data.filename.present ? data.filename.value : this.filename,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      data: data.data.present ? data.data.value : this.data,
      size: data.size.present ? data.size.value : this.size,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      lastAccessed: data.lastAccessed.present
          ? data.lastAccessed.value
          : this.lastAccessed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentCacheData(')
          ..write('contentDigest: $contentDigest, ')
          ..write('filename: $filename, ')
          ..write('mimeType: $mimeType, ')
          ..write('data: $data, ')
          ..write('size: $size, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('lastAccessed: $lastAccessed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(contentDigest, filename, mimeType,
      $driftBlobEquality.hash(data), size, cachedAt, lastAccessed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttachmentCacheData &&
          other.contentDigest == this.contentDigest &&
          other.filename == this.filename &&
          other.mimeType == this.mimeType &&
          $driftBlobEquality.equals(other.data, this.data) &&
          other.size == this.size &&
          other.cachedAt == this.cachedAt &&
          other.lastAccessed == this.lastAccessed);
}

class AttachmentCacheCompanion extends UpdateCompanion<AttachmentCacheData> {
  final Value<String> contentDigest;
  final Value<String> filename;
  final Value<String> mimeType;
  final Value<Uint8List> data;
  final Value<int> size;
  final Value<int> cachedAt;
  final Value<int> lastAccessed;
  final Value<int> rowid;
  const AttachmentCacheCompanion({
    this.contentDigest = const Value.absent(),
    this.filename = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.data = const Value.absent(),
    this.size = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.lastAccessed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentCacheCompanion.insert({
    required String contentDigest,
    required String filename,
    required String mimeType,
    required Uint8List data,
    required int size,
    required int cachedAt,
    required int lastAccessed,
    this.rowid = const Value.absent(),
  })  : contentDigest = Value(contentDigest),
        filename = Value(filename),
        mimeType = Value(mimeType),
        data = Value(data),
        size = Value(size),
        cachedAt = Value(cachedAt),
        lastAccessed = Value(lastAccessed);
  static Insertable<AttachmentCacheData> custom({
    Expression<String>? contentDigest,
    Expression<String>? filename,
    Expression<String>? mimeType,
    Expression<Uint8List>? data,
    Expression<int>? size,
    Expression<int>? cachedAt,
    Expression<int>? lastAccessed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (contentDigest != null) 'content_digest': contentDigest,
      if (filename != null) 'filename': filename,
      if (mimeType != null) 'mime_type': mimeType,
      if (data != null) 'data': data,
      if (size != null) 'size': size,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (lastAccessed != null) 'last_accessed': lastAccessed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentCacheCompanion copyWith(
      {Value<String>? contentDigest,
      Value<String>? filename,
      Value<String>? mimeType,
      Value<Uint8List>? data,
      Value<int>? size,
      Value<int>? cachedAt,
      Value<int>? lastAccessed,
      Value<int>? rowid}) {
    return AttachmentCacheCompanion(
      contentDigest: contentDigest ?? this.contentDigest,
      filename: filename ?? this.filename,
      mimeType: mimeType ?? this.mimeType,
      data: data ?? this.data,
      size: size ?? this.size,
      cachedAt: cachedAt ?? this.cachedAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (contentDigest.present) {
      map['content_digest'] = Variable<String>(contentDigest.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (data.present) {
      map['data'] = Variable<Uint8List>(data.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (lastAccessed.present) {
      map['last_accessed'] = Variable<int>(lastAccessed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentCacheCompanion(')
          ..write('contentDigest: $contentDigest, ')
          ..write('filename: $filename, ')
          ..write('mimeType: $mimeType, ')
          ..write('data: $data, ')
          ..write('size: $size, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('lastAccessed: $lastAccessed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookmarkedAppsTable extends BookmarkedApps
    with TableInfo<$BookmarkedAppsTable, BookmarkedApp> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarkedAppsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _appNameMeta =
      const VerificationMeta('appName');
  @override
  late final GeneratedColumn<String> appName = GeneratedColumn<String>(
      'app_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerAddressMeta =
      const VerificationMeta('ownerAddress');
  @override
  late final GeneratedColumn<String> ownerAddress = GeneratedColumn<String>(
      'owner_address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconUrlMeta =
      const VerificationMeta('iconUrl');
  @override
  late final GeneratedColumn<String> iconUrl = GeneratedColumn<String>(
      'icon_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _warningsMeta =
      const VerificationMeta('warnings');
  @override
  late final GeneratedColumn<String> warnings = GeneratedColumn<String>(
      'warnings', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryOneMeta =
      const VerificationMeta('categoryOne');
  @override
  late final GeneratedColumn<String> categoryOne = GeneratedColumn<String>(
      'category_one', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryTwoMeta =
      const VerificationMeta('categoryTwo');
  @override
  late final GeneratedColumn<String> categoryTwo = GeneratedColumn<String>(
      'category_two', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _appstoreLinkMeta =
      const VerificationMeta('appstoreLink');
  @override
  late final GeneratedColumn<String> appstoreLink = GeneratedColumn<String>(
      'appstore_link', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _playstoreLinkMeta =
      const VerificationMeta('playstoreLink');
  @override
  late final GeneratedColumn<String> playstoreLink = GeneratedColumn<String>(
      'playstore_link', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _apkDownloadMeta =
      const VerificationMeta('apkDownload');
  @override
  late final GeneratedColumn<String> apkDownload = GeneratedColumn<String>(
      'apk_download', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ipaDownloadMeta =
      const VerificationMeta('ipaDownload');
  @override
  late final GeneratedColumn<String> ipaDownload = GeneratedColumn<String>(
      'ipa_download', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sessionAddressMeta =
      const VerificationMeta('sessionAddress');
  @override
  late final GeneratedColumn<String> sessionAddress = GeneratedColumn<String>(
      'session_address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bookmarkedAtMeta =
      const VerificationMeta('bookmarkedAt');
  @override
  late final GeneratedColumn<int> bookmarkedAt = GeneratedColumn<int>(
      'bookmarked_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nextUpdateMeta =
      const VerificationMeta('nextUpdate');
  @override
  late final GeneratedColumn<int> nextUpdate = GeneratedColumn<int>(
      'next_update', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        appName,
        ownerAddress,
        displayName,
        iconUrl,
        description,
        warnings,
        categoryOne,
        categoryTwo,
        url,
        appstoreLink,
        playstoreLink,
        apkDownload,
        ipaDownload,
        sessionAddress,
        bookmarkedAt,
        nextUpdate
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarked_apps';
  @override
  VerificationContext validateIntegrity(Insertable<BookmarkedApp> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('app_name')) {
      context.handle(_appNameMeta,
          appName.isAcceptableOrUnknown(data['app_name']!, _appNameMeta));
    } else if (isInserting) {
      context.missing(_appNameMeta);
    }
    if (data.containsKey('owner_address')) {
      context.handle(
          _ownerAddressMeta,
          ownerAddress.isAcceptableOrUnknown(
              data['owner_address']!, _ownerAddressMeta));
    } else if (isInserting) {
      context.missing(_ownerAddressMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('icon_url')) {
      context.handle(_iconUrlMeta,
          iconUrl.isAcceptableOrUnknown(data['icon_url']!, _iconUrlMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('warnings')) {
      context.handle(_warningsMeta,
          warnings.isAcceptableOrUnknown(data['warnings']!, _warningsMeta));
    }
    if (data.containsKey('category_one')) {
      context.handle(
          _categoryOneMeta,
          categoryOne.isAcceptableOrUnknown(
              data['category_one']!, _categoryOneMeta));
    }
    if (data.containsKey('category_two')) {
      context.handle(
          _categoryTwoMeta,
          categoryTwo.isAcceptableOrUnknown(
              data['category_two']!, _categoryTwoMeta));
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    }
    if (data.containsKey('appstore_link')) {
      context.handle(
          _appstoreLinkMeta,
          appstoreLink.isAcceptableOrUnknown(
              data['appstore_link']!, _appstoreLinkMeta));
    }
    if (data.containsKey('playstore_link')) {
      context.handle(
          _playstoreLinkMeta,
          playstoreLink.isAcceptableOrUnknown(
              data['playstore_link']!, _playstoreLinkMeta));
    }
    if (data.containsKey('apk_download')) {
      context.handle(
          _apkDownloadMeta,
          apkDownload.isAcceptableOrUnknown(
              data['apk_download']!, _apkDownloadMeta));
    }
    if (data.containsKey('ipa_download')) {
      context.handle(
          _ipaDownloadMeta,
          ipaDownload.isAcceptableOrUnknown(
              data['ipa_download']!, _ipaDownloadMeta));
    }
    if (data.containsKey('session_address')) {
      context.handle(
          _sessionAddressMeta,
          sessionAddress.isAcceptableOrUnknown(
              data['session_address']!, _sessionAddressMeta));
    } else if (isInserting) {
      context.missing(_sessionAddressMeta);
    }
    if (data.containsKey('bookmarked_at')) {
      context.handle(
          _bookmarkedAtMeta,
          bookmarkedAt.isAcceptableOrUnknown(
              data['bookmarked_at']!, _bookmarkedAtMeta));
    } else if (isInserting) {
      context.missing(_bookmarkedAtMeta);
    }
    if (data.containsKey('next_update')) {
      context.handle(
          _nextUpdateMeta,
          nextUpdate.isAcceptableOrUnknown(
              data['next_update']!, _nextUpdateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {appName, ownerAddress, sessionAddress},
      ];
  @override
  BookmarkedApp map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookmarkedApp(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      appName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}app_name'])!,
      ownerAddress: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_address'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      iconUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_url']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      warnings: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}warnings']),
      categoryOne: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_one']),
      categoryTwo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_two']),
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url']),
      appstoreLink: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}appstore_link']),
      playstoreLink: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}playstore_link']),
      apkDownload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}apk_download']),
      ipaDownload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ipa_download']),
      sessionAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}session_address'])!,
      bookmarkedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bookmarked_at'])!,
      nextUpdate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}next_update']),
    );
  }

  @override
  $BookmarkedAppsTable createAlias(String alias) {
    return $BookmarkedAppsTable(attachedDatabase, alias);
  }
}

class BookmarkedApp extends DataClass implements Insertable<BookmarkedApp> {
  final int id;
  final String appName;
  final String ownerAddress;
  final String displayName;
  final String? iconUrl;
  final String? description;
  final String? warnings;
  final String? categoryOne;
  final String? categoryTwo;
  final String? url;
  final String? appstoreLink;
  final String? playstoreLink;
  final String? apkDownload;
  final String? ipaDownload;
  final String sessionAddress;
  final int bookmarkedAt;
  final int? nextUpdate;
  const BookmarkedApp(
      {required this.id,
      required this.appName,
      required this.ownerAddress,
      required this.displayName,
      this.iconUrl,
      this.description,
      this.warnings,
      this.categoryOne,
      this.categoryTwo,
      this.url,
      this.appstoreLink,
      this.playstoreLink,
      this.apkDownload,
      this.ipaDownload,
      required this.sessionAddress,
      required this.bookmarkedAt,
      this.nextUpdate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['app_name'] = Variable<String>(appName);
    map['owner_address'] = Variable<String>(ownerAddress);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || iconUrl != null) {
      map['icon_url'] = Variable<String>(iconUrl);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || warnings != null) {
      map['warnings'] = Variable<String>(warnings);
    }
    if (!nullToAbsent || categoryOne != null) {
      map['category_one'] = Variable<String>(categoryOne);
    }
    if (!nullToAbsent || categoryTwo != null) {
      map['category_two'] = Variable<String>(categoryTwo);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || appstoreLink != null) {
      map['appstore_link'] = Variable<String>(appstoreLink);
    }
    if (!nullToAbsent || playstoreLink != null) {
      map['playstore_link'] = Variable<String>(playstoreLink);
    }
    if (!nullToAbsent || apkDownload != null) {
      map['apk_download'] = Variable<String>(apkDownload);
    }
    if (!nullToAbsent || ipaDownload != null) {
      map['ipa_download'] = Variable<String>(ipaDownload);
    }
    map['session_address'] = Variable<String>(sessionAddress);
    map['bookmarked_at'] = Variable<int>(bookmarkedAt);
    if (!nullToAbsent || nextUpdate != null) {
      map['next_update'] = Variable<int>(nextUpdate);
    }
    return map;
  }

  BookmarkedAppsCompanion toCompanion(bool nullToAbsent) {
    return BookmarkedAppsCompanion(
      id: Value(id),
      appName: Value(appName),
      ownerAddress: Value(ownerAddress),
      displayName: Value(displayName),
      iconUrl: iconUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(iconUrl),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      warnings: warnings == null && nullToAbsent
          ? const Value.absent()
          : Value(warnings),
      categoryOne: categoryOne == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryOne),
      categoryTwo: categoryTwo == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryTwo),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      appstoreLink: appstoreLink == null && nullToAbsent
          ? const Value.absent()
          : Value(appstoreLink),
      playstoreLink: playstoreLink == null && nullToAbsent
          ? const Value.absent()
          : Value(playstoreLink),
      apkDownload: apkDownload == null && nullToAbsent
          ? const Value.absent()
          : Value(apkDownload),
      ipaDownload: ipaDownload == null && nullToAbsent
          ? const Value.absent()
          : Value(ipaDownload),
      sessionAddress: Value(sessionAddress),
      bookmarkedAt: Value(bookmarkedAt),
      nextUpdate: nextUpdate == null && nullToAbsent
          ? const Value.absent()
          : Value(nextUpdate),
    );
  }

  factory BookmarkedApp.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookmarkedApp(
      id: serializer.fromJson<int>(json['id']),
      appName: serializer.fromJson<String>(json['appName']),
      ownerAddress: serializer.fromJson<String>(json['ownerAddress']),
      displayName: serializer.fromJson<String>(json['displayName']),
      iconUrl: serializer.fromJson<String?>(json['iconUrl']),
      description: serializer.fromJson<String?>(json['description']),
      warnings: serializer.fromJson<String?>(json['warnings']),
      categoryOne: serializer.fromJson<String?>(json['categoryOne']),
      categoryTwo: serializer.fromJson<String?>(json['categoryTwo']),
      url: serializer.fromJson<String?>(json['url']),
      appstoreLink: serializer.fromJson<String?>(json['appstoreLink']),
      playstoreLink: serializer.fromJson<String?>(json['playstoreLink']),
      apkDownload: serializer.fromJson<String?>(json['apkDownload']),
      ipaDownload: serializer.fromJson<String?>(json['ipaDownload']),
      sessionAddress: serializer.fromJson<String>(json['sessionAddress']),
      bookmarkedAt: serializer.fromJson<int>(json['bookmarkedAt']),
      nextUpdate: serializer.fromJson<int?>(json['nextUpdate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'appName': serializer.toJson<String>(appName),
      'ownerAddress': serializer.toJson<String>(ownerAddress),
      'displayName': serializer.toJson<String>(displayName),
      'iconUrl': serializer.toJson<String?>(iconUrl),
      'description': serializer.toJson<String?>(description),
      'warnings': serializer.toJson<String?>(warnings),
      'categoryOne': serializer.toJson<String?>(categoryOne),
      'categoryTwo': serializer.toJson<String?>(categoryTwo),
      'url': serializer.toJson<String?>(url),
      'appstoreLink': serializer.toJson<String?>(appstoreLink),
      'playstoreLink': serializer.toJson<String?>(playstoreLink),
      'apkDownload': serializer.toJson<String?>(apkDownload),
      'ipaDownload': serializer.toJson<String?>(ipaDownload),
      'sessionAddress': serializer.toJson<String>(sessionAddress),
      'bookmarkedAt': serializer.toJson<int>(bookmarkedAt),
      'nextUpdate': serializer.toJson<int?>(nextUpdate),
    };
  }

  BookmarkedApp copyWith(
          {int? id,
          String? appName,
          String? ownerAddress,
          String? displayName,
          Value<String?> iconUrl = const Value.absent(),
          Value<String?> description = const Value.absent(),
          Value<String?> warnings = const Value.absent(),
          Value<String?> categoryOne = const Value.absent(),
          Value<String?> categoryTwo = const Value.absent(),
          Value<String?> url = const Value.absent(),
          Value<String?> appstoreLink = const Value.absent(),
          Value<String?> playstoreLink = const Value.absent(),
          Value<String?> apkDownload = const Value.absent(),
          Value<String?> ipaDownload = const Value.absent(),
          String? sessionAddress,
          int? bookmarkedAt,
          Value<int?> nextUpdate = const Value.absent()}) =>
      BookmarkedApp(
        id: id ?? this.id,
        appName: appName ?? this.appName,
        ownerAddress: ownerAddress ?? this.ownerAddress,
        displayName: displayName ?? this.displayName,
        iconUrl: iconUrl.present ? iconUrl.value : this.iconUrl,
        description: description.present ? description.value : this.description,
        warnings: warnings.present ? warnings.value : this.warnings,
        categoryOne: categoryOne.present ? categoryOne.value : this.categoryOne,
        categoryTwo: categoryTwo.present ? categoryTwo.value : this.categoryTwo,
        url: url.present ? url.value : this.url,
        appstoreLink:
            appstoreLink.present ? appstoreLink.value : this.appstoreLink,
        playstoreLink:
            playstoreLink.present ? playstoreLink.value : this.playstoreLink,
        apkDownload: apkDownload.present ? apkDownload.value : this.apkDownload,
        ipaDownload: ipaDownload.present ? ipaDownload.value : this.ipaDownload,
        sessionAddress: sessionAddress ?? this.sessionAddress,
        bookmarkedAt: bookmarkedAt ?? this.bookmarkedAt,
        nextUpdate: nextUpdate.present ? nextUpdate.value : this.nextUpdate,
      );
  BookmarkedApp copyWithCompanion(BookmarkedAppsCompanion data) {
    return BookmarkedApp(
      id: data.id.present ? data.id.value : this.id,
      appName: data.appName.present ? data.appName.value : this.appName,
      ownerAddress: data.ownerAddress.present
          ? data.ownerAddress.value
          : this.ownerAddress,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      iconUrl: data.iconUrl.present ? data.iconUrl.value : this.iconUrl,
      description:
          data.description.present ? data.description.value : this.description,
      warnings: data.warnings.present ? data.warnings.value : this.warnings,
      categoryOne:
          data.categoryOne.present ? data.categoryOne.value : this.categoryOne,
      categoryTwo:
          data.categoryTwo.present ? data.categoryTwo.value : this.categoryTwo,
      url: data.url.present ? data.url.value : this.url,
      appstoreLink: data.appstoreLink.present
          ? data.appstoreLink.value
          : this.appstoreLink,
      playstoreLink: data.playstoreLink.present
          ? data.playstoreLink.value
          : this.playstoreLink,
      apkDownload:
          data.apkDownload.present ? data.apkDownload.value : this.apkDownload,
      ipaDownload:
          data.ipaDownload.present ? data.ipaDownload.value : this.ipaDownload,
      sessionAddress: data.sessionAddress.present
          ? data.sessionAddress.value
          : this.sessionAddress,
      bookmarkedAt: data.bookmarkedAt.present
          ? data.bookmarkedAt.value
          : this.bookmarkedAt,
      nextUpdate:
          data.nextUpdate.present ? data.nextUpdate.value : this.nextUpdate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookmarkedApp(')
          ..write('id: $id, ')
          ..write('appName: $appName, ')
          ..write('ownerAddress: $ownerAddress, ')
          ..write('displayName: $displayName, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('description: $description, ')
          ..write('warnings: $warnings, ')
          ..write('categoryOne: $categoryOne, ')
          ..write('categoryTwo: $categoryTwo, ')
          ..write('url: $url, ')
          ..write('appstoreLink: $appstoreLink, ')
          ..write('playstoreLink: $playstoreLink, ')
          ..write('apkDownload: $apkDownload, ')
          ..write('ipaDownload: $ipaDownload, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('bookmarkedAt: $bookmarkedAt, ')
          ..write('nextUpdate: $nextUpdate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      appName,
      ownerAddress,
      displayName,
      iconUrl,
      description,
      warnings,
      categoryOne,
      categoryTwo,
      url,
      appstoreLink,
      playstoreLink,
      apkDownload,
      ipaDownload,
      sessionAddress,
      bookmarkedAt,
      nextUpdate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookmarkedApp &&
          other.id == this.id &&
          other.appName == this.appName &&
          other.ownerAddress == this.ownerAddress &&
          other.displayName == this.displayName &&
          other.iconUrl == this.iconUrl &&
          other.description == this.description &&
          other.warnings == this.warnings &&
          other.categoryOne == this.categoryOne &&
          other.categoryTwo == this.categoryTwo &&
          other.url == this.url &&
          other.appstoreLink == this.appstoreLink &&
          other.playstoreLink == this.playstoreLink &&
          other.apkDownload == this.apkDownload &&
          other.ipaDownload == this.ipaDownload &&
          other.sessionAddress == this.sessionAddress &&
          other.bookmarkedAt == this.bookmarkedAt &&
          other.nextUpdate == this.nextUpdate);
}

class BookmarkedAppsCompanion extends UpdateCompanion<BookmarkedApp> {
  final Value<int> id;
  final Value<String> appName;
  final Value<String> ownerAddress;
  final Value<String> displayName;
  final Value<String?> iconUrl;
  final Value<String?> description;
  final Value<String?> warnings;
  final Value<String?> categoryOne;
  final Value<String?> categoryTwo;
  final Value<String?> url;
  final Value<String?> appstoreLink;
  final Value<String?> playstoreLink;
  final Value<String?> apkDownload;
  final Value<String?> ipaDownload;
  final Value<String> sessionAddress;
  final Value<int> bookmarkedAt;
  final Value<int?> nextUpdate;
  const BookmarkedAppsCompanion({
    this.id = const Value.absent(),
    this.appName = const Value.absent(),
    this.ownerAddress = const Value.absent(),
    this.displayName = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.description = const Value.absent(),
    this.warnings = const Value.absent(),
    this.categoryOne = const Value.absent(),
    this.categoryTwo = const Value.absent(),
    this.url = const Value.absent(),
    this.appstoreLink = const Value.absent(),
    this.playstoreLink = const Value.absent(),
    this.apkDownload = const Value.absent(),
    this.ipaDownload = const Value.absent(),
    this.sessionAddress = const Value.absent(),
    this.bookmarkedAt = const Value.absent(),
    this.nextUpdate = const Value.absent(),
  });
  BookmarkedAppsCompanion.insert({
    this.id = const Value.absent(),
    required String appName,
    required String ownerAddress,
    required String displayName,
    this.iconUrl = const Value.absent(),
    this.description = const Value.absent(),
    this.warnings = const Value.absent(),
    this.categoryOne = const Value.absent(),
    this.categoryTwo = const Value.absent(),
    this.url = const Value.absent(),
    this.appstoreLink = const Value.absent(),
    this.playstoreLink = const Value.absent(),
    this.apkDownload = const Value.absent(),
    this.ipaDownload = const Value.absent(),
    required String sessionAddress,
    required int bookmarkedAt,
    this.nextUpdate = const Value.absent(),
  })  : appName = Value(appName),
        ownerAddress = Value(ownerAddress),
        displayName = Value(displayName),
        sessionAddress = Value(sessionAddress),
        bookmarkedAt = Value(bookmarkedAt);
  static Insertable<BookmarkedApp> custom({
    Expression<int>? id,
    Expression<String>? appName,
    Expression<String>? ownerAddress,
    Expression<String>? displayName,
    Expression<String>? iconUrl,
    Expression<String>? description,
    Expression<String>? warnings,
    Expression<String>? categoryOne,
    Expression<String>? categoryTwo,
    Expression<String>? url,
    Expression<String>? appstoreLink,
    Expression<String>? playstoreLink,
    Expression<String>? apkDownload,
    Expression<String>? ipaDownload,
    Expression<String>? sessionAddress,
    Expression<int>? bookmarkedAt,
    Expression<int>? nextUpdate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (appName != null) 'app_name': appName,
      if (ownerAddress != null) 'owner_address': ownerAddress,
      if (displayName != null) 'display_name': displayName,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (description != null) 'description': description,
      if (warnings != null) 'warnings': warnings,
      if (categoryOne != null) 'category_one': categoryOne,
      if (categoryTwo != null) 'category_two': categoryTwo,
      if (url != null) 'url': url,
      if (appstoreLink != null) 'appstore_link': appstoreLink,
      if (playstoreLink != null) 'playstore_link': playstoreLink,
      if (apkDownload != null) 'apk_download': apkDownload,
      if (ipaDownload != null) 'ipa_download': ipaDownload,
      if (sessionAddress != null) 'session_address': sessionAddress,
      if (bookmarkedAt != null) 'bookmarked_at': bookmarkedAt,
      if (nextUpdate != null) 'next_update': nextUpdate,
    });
  }

  BookmarkedAppsCompanion copyWith(
      {Value<int>? id,
      Value<String>? appName,
      Value<String>? ownerAddress,
      Value<String>? displayName,
      Value<String?>? iconUrl,
      Value<String?>? description,
      Value<String?>? warnings,
      Value<String?>? categoryOne,
      Value<String?>? categoryTwo,
      Value<String?>? url,
      Value<String?>? appstoreLink,
      Value<String?>? playstoreLink,
      Value<String?>? apkDownload,
      Value<String?>? ipaDownload,
      Value<String>? sessionAddress,
      Value<int>? bookmarkedAt,
      Value<int?>? nextUpdate}) {
    return BookmarkedAppsCompanion(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      ownerAddress: ownerAddress ?? this.ownerAddress,
      displayName: displayName ?? this.displayName,
      iconUrl: iconUrl ?? this.iconUrl,
      description: description ?? this.description,
      warnings: warnings ?? this.warnings,
      categoryOne: categoryOne ?? this.categoryOne,
      categoryTwo: categoryTwo ?? this.categoryTwo,
      url: url ?? this.url,
      appstoreLink: appstoreLink ?? this.appstoreLink,
      playstoreLink: playstoreLink ?? this.playstoreLink,
      apkDownload: apkDownload ?? this.apkDownload,
      ipaDownload: ipaDownload ?? this.ipaDownload,
      sessionAddress: sessionAddress ?? this.sessionAddress,
      bookmarkedAt: bookmarkedAt ?? this.bookmarkedAt,
      nextUpdate: nextUpdate ?? this.nextUpdate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (appName.present) {
      map['app_name'] = Variable<String>(appName.value);
    }
    if (ownerAddress.present) {
      map['owner_address'] = Variable<String>(ownerAddress.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (iconUrl.present) {
      map['icon_url'] = Variable<String>(iconUrl.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (warnings.present) {
      map['warnings'] = Variable<String>(warnings.value);
    }
    if (categoryOne.present) {
      map['category_one'] = Variable<String>(categoryOne.value);
    }
    if (categoryTwo.present) {
      map['category_two'] = Variable<String>(categoryTwo.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (appstoreLink.present) {
      map['appstore_link'] = Variable<String>(appstoreLink.value);
    }
    if (playstoreLink.present) {
      map['playstore_link'] = Variable<String>(playstoreLink.value);
    }
    if (apkDownload.present) {
      map['apk_download'] = Variable<String>(apkDownload.value);
    }
    if (ipaDownload.present) {
      map['ipa_download'] = Variable<String>(ipaDownload.value);
    }
    if (sessionAddress.present) {
      map['session_address'] = Variable<String>(sessionAddress.value);
    }
    if (bookmarkedAt.present) {
      map['bookmarked_at'] = Variable<int>(bookmarkedAt.value);
    }
    if (nextUpdate.present) {
      map['next_update'] = Variable<int>(nextUpdate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarkedAppsCompanion(')
          ..write('id: $id, ')
          ..write('appName: $appName, ')
          ..write('ownerAddress: $ownerAddress, ')
          ..write('displayName: $displayName, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('description: $description, ')
          ..write('warnings: $warnings, ')
          ..write('categoryOne: $categoryOne, ')
          ..write('categoryTwo: $categoryTwo, ')
          ..write('url: $url, ')
          ..write('appstoreLink: $appstoreLink, ')
          ..write('playstoreLink: $playstoreLink, ')
          ..write('apkDownload: $apkDownload, ')
          ..write('ipaDownload: $ipaDownload, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('bookmarkedAt: $bookmarkedAt, ')
          ..write('nextUpdate: $nextUpdate')
          ..write(')'))
        .toString();
  }
}

class $BookmarkedPostsTable extends BookmarkedPosts
    with TableInfo<$BookmarkedPostsTable, BookmarkedPost> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarkedPostsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _postUidMeta =
      const VerificationMeta('postUid');
  @override
  late final GeneratedColumn<String> postUid = GeneratedColumn<String>(
      'post_uid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _feedUrlMeta =
      const VerificationMeta('feedUrl');
  @override
  late final GeneratedColumn<String> feedUrl = GeneratedColumn<String>(
      'feed_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _postJsonMeta =
      const VerificationMeta('postJson');
  @override
  late final GeneratedColumn<String> postJson = GeneratedColumn<String>(
      'post_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionAddressMeta =
      const VerificationMeta('sessionAddress');
  @override
  late final GeneratedColumn<String> sessionAddress = GeneratedColumn<String>(
      'session_address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bookmarkedAtMeta =
      const VerificationMeta('bookmarkedAt');
  @override
  late final GeneratedColumn<int> bookmarkedAt = GeneratedColumn<int>(
      'bookmarked_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _unavailableMeta =
      const VerificationMeta('unavailable');
  @override
  late final GeneratedColumn<bool> unavailable = GeneratedColumn<bool>(
      'unavailable', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("unavailable" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
      'etag', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        postUid,
        title,
        feedUrl,
        postJson,
        sessionAddress,
        bookmarkedAt,
        updatedAt,
        unavailable,
        etag
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarked_posts';
  @override
  VerificationContext validateIntegrity(Insertable<BookmarkedPost> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('post_uid')) {
      context.handle(_postUidMeta,
          postUid.isAcceptableOrUnknown(data['post_uid']!, _postUidMeta));
    } else if (isInserting) {
      context.missing(_postUidMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('feed_url')) {
      context.handle(_feedUrlMeta,
          feedUrl.isAcceptableOrUnknown(data['feed_url']!, _feedUrlMeta));
    }
    if (data.containsKey('post_json')) {
      context.handle(_postJsonMeta,
          postJson.isAcceptableOrUnknown(data['post_json']!, _postJsonMeta));
    } else if (isInserting) {
      context.missing(_postJsonMeta);
    }
    if (data.containsKey('session_address')) {
      context.handle(
          _sessionAddressMeta,
          sessionAddress.isAcceptableOrUnknown(
              data['session_address']!, _sessionAddressMeta));
    } else if (isInserting) {
      context.missing(_sessionAddressMeta);
    }
    if (data.containsKey('bookmarked_at')) {
      context.handle(
          _bookmarkedAtMeta,
          bookmarkedAt.isAcceptableOrUnknown(
              data['bookmarked_at']!, _bookmarkedAtMeta));
    } else if (isInserting) {
      context.missing(_bookmarkedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('unavailable')) {
      context.handle(
          _unavailableMeta,
          unavailable.isAcceptableOrUnknown(
              data['unavailable']!, _unavailableMeta));
    }
    if (data.containsKey('etag')) {
      context.handle(
          _etagMeta, etag.isAcceptableOrUnknown(data['etag']!, _etagMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {postUid, feedUrl, sessionAddress},
      ];
  @override
  BookmarkedPost map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookmarkedPost(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      postUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}post_uid'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      feedUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}feed_url']),
      postJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}post_json'])!,
      sessionAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}session_address'])!,
      bookmarkedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bookmarked_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      unavailable: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}unavailable'])!,
      etag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}etag']),
    );
  }

  @override
  $BookmarkedPostsTable createAlias(String alias) {
    return $BookmarkedPostsTable(attachedDatabase, alias);
  }
}

class BookmarkedPost extends DataClass implements Insertable<BookmarkedPost> {
  final int id;
  final String postUid;
  final String title;
  final String? feedUrl;
  final String postJson;
  final String sessionAddress;
  final int bookmarkedAt;

  /// Last successful server sync of [postJson] (ms epoch). Seeded to the
  /// bookmark time on insert; bumped by every refresh write-back (v28).
  /// Drives the Bookmarks view's staleness sweep.
  final int updatedAt;

  /// The server answered "gone" (`POST_NOT_FOUND` and kin) on the last
  /// refresh — the local blob may be the only copy left, so it is kept
  /// verbatim and surfaced with the cloud-off badge; retries back off to
  /// the slower cadence (v28).
  final bool unavailable;

  /// The single-post read's `ETag` validator (v28). Echoed back as
  /// `If-None-Match` on the next refresh so an unchanged post revalidates
  /// with a 304 instead of a full body — same contract as [FeedCache].
  /// Null until the first successful refresh (the bookmark write itself has
  /// no response to take a validator from).
  final String? etag;
  const BookmarkedPost(
      {required this.id,
      required this.postUid,
      required this.title,
      this.feedUrl,
      required this.postJson,
      required this.sessionAddress,
      required this.bookmarkedAt,
      required this.updatedAt,
      required this.unavailable,
      this.etag});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['post_uid'] = Variable<String>(postUid);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || feedUrl != null) {
      map['feed_url'] = Variable<String>(feedUrl);
    }
    map['post_json'] = Variable<String>(postJson);
    map['session_address'] = Variable<String>(sessionAddress);
    map['bookmarked_at'] = Variable<int>(bookmarkedAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['unavailable'] = Variable<bool>(unavailable);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    return map;
  }

  BookmarkedPostsCompanion toCompanion(bool nullToAbsent) {
    return BookmarkedPostsCompanion(
      id: Value(id),
      postUid: Value(postUid),
      title: Value(title),
      feedUrl: feedUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(feedUrl),
      postJson: Value(postJson),
      sessionAddress: Value(sessionAddress),
      bookmarkedAt: Value(bookmarkedAt),
      updatedAt: Value(updatedAt),
      unavailable: Value(unavailable),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
    );
  }

  factory BookmarkedPost.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookmarkedPost(
      id: serializer.fromJson<int>(json['id']),
      postUid: serializer.fromJson<String>(json['postUid']),
      title: serializer.fromJson<String>(json['title']),
      feedUrl: serializer.fromJson<String?>(json['feedUrl']),
      postJson: serializer.fromJson<String>(json['postJson']),
      sessionAddress: serializer.fromJson<String>(json['sessionAddress']),
      bookmarkedAt: serializer.fromJson<int>(json['bookmarkedAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      unavailable: serializer.fromJson<bool>(json['unavailable']),
      etag: serializer.fromJson<String?>(json['etag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'postUid': serializer.toJson<String>(postUid),
      'title': serializer.toJson<String>(title),
      'feedUrl': serializer.toJson<String?>(feedUrl),
      'postJson': serializer.toJson<String>(postJson),
      'sessionAddress': serializer.toJson<String>(sessionAddress),
      'bookmarkedAt': serializer.toJson<int>(bookmarkedAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'unavailable': serializer.toJson<bool>(unavailable),
      'etag': serializer.toJson<String?>(etag),
    };
  }

  BookmarkedPost copyWith(
          {int? id,
          String? postUid,
          String? title,
          Value<String?> feedUrl = const Value.absent(),
          String? postJson,
          String? sessionAddress,
          int? bookmarkedAt,
          int? updatedAt,
          bool? unavailable,
          Value<String?> etag = const Value.absent()}) =>
      BookmarkedPost(
        id: id ?? this.id,
        postUid: postUid ?? this.postUid,
        title: title ?? this.title,
        feedUrl: feedUrl.present ? feedUrl.value : this.feedUrl,
        postJson: postJson ?? this.postJson,
        sessionAddress: sessionAddress ?? this.sessionAddress,
        bookmarkedAt: bookmarkedAt ?? this.bookmarkedAt,
        updatedAt: updatedAt ?? this.updatedAt,
        unavailable: unavailable ?? this.unavailable,
        etag: etag.present ? etag.value : this.etag,
      );
  BookmarkedPost copyWithCompanion(BookmarkedPostsCompanion data) {
    return BookmarkedPost(
      id: data.id.present ? data.id.value : this.id,
      postUid: data.postUid.present ? data.postUid.value : this.postUid,
      title: data.title.present ? data.title.value : this.title,
      feedUrl: data.feedUrl.present ? data.feedUrl.value : this.feedUrl,
      postJson: data.postJson.present ? data.postJson.value : this.postJson,
      sessionAddress: data.sessionAddress.present
          ? data.sessionAddress.value
          : this.sessionAddress,
      bookmarkedAt: data.bookmarkedAt.present
          ? data.bookmarkedAt.value
          : this.bookmarkedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      unavailable:
          data.unavailable.present ? data.unavailable.value : this.unavailable,
      etag: data.etag.present ? data.etag.value : this.etag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookmarkedPost(')
          ..write('id: $id, ')
          ..write('postUid: $postUid, ')
          ..write('title: $title, ')
          ..write('feedUrl: $feedUrl, ')
          ..write('postJson: $postJson, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('bookmarkedAt: $bookmarkedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('unavailable: $unavailable, ')
          ..write('etag: $etag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, postUid, title, feedUrl, postJson,
      sessionAddress, bookmarkedAt, updatedAt, unavailable, etag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookmarkedPost &&
          other.id == this.id &&
          other.postUid == this.postUid &&
          other.title == this.title &&
          other.feedUrl == this.feedUrl &&
          other.postJson == this.postJson &&
          other.sessionAddress == this.sessionAddress &&
          other.bookmarkedAt == this.bookmarkedAt &&
          other.updatedAt == this.updatedAt &&
          other.unavailable == this.unavailable &&
          other.etag == this.etag);
}

class BookmarkedPostsCompanion extends UpdateCompanion<BookmarkedPost> {
  final Value<int> id;
  final Value<String> postUid;
  final Value<String> title;
  final Value<String?> feedUrl;
  final Value<String> postJson;
  final Value<String> sessionAddress;
  final Value<int> bookmarkedAt;
  final Value<int> updatedAt;
  final Value<bool> unavailable;
  final Value<String?> etag;
  const BookmarkedPostsCompanion({
    this.id = const Value.absent(),
    this.postUid = const Value.absent(),
    this.title = const Value.absent(),
    this.feedUrl = const Value.absent(),
    this.postJson = const Value.absent(),
    this.sessionAddress = const Value.absent(),
    this.bookmarkedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.unavailable = const Value.absent(),
    this.etag = const Value.absent(),
  });
  BookmarkedPostsCompanion.insert({
    this.id = const Value.absent(),
    required String postUid,
    required String title,
    this.feedUrl = const Value.absent(),
    required String postJson,
    required String sessionAddress,
    required int bookmarkedAt,
    required int updatedAt,
    this.unavailable = const Value.absent(),
    this.etag = const Value.absent(),
  })  : postUid = Value(postUid),
        title = Value(title),
        postJson = Value(postJson),
        sessionAddress = Value(sessionAddress),
        bookmarkedAt = Value(bookmarkedAt),
        updatedAt = Value(updatedAt);
  static Insertable<BookmarkedPost> custom({
    Expression<int>? id,
    Expression<String>? postUid,
    Expression<String>? title,
    Expression<String>? feedUrl,
    Expression<String>? postJson,
    Expression<String>? sessionAddress,
    Expression<int>? bookmarkedAt,
    Expression<int>? updatedAt,
    Expression<bool>? unavailable,
    Expression<String>? etag,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (postUid != null) 'post_uid': postUid,
      if (title != null) 'title': title,
      if (feedUrl != null) 'feed_url': feedUrl,
      if (postJson != null) 'post_json': postJson,
      if (sessionAddress != null) 'session_address': sessionAddress,
      if (bookmarkedAt != null) 'bookmarked_at': bookmarkedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (unavailable != null) 'unavailable': unavailable,
      if (etag != null) 'etag': etag,
    });
  }

  BookmarkedPostsCompanion copyWith(
      {Value<int>? id,
      Value<String>? postUid,
      Value<String>? title,
      Value<String?>? feedUrl,
      Value<String>? postJson,
      Value<String>? sessionAddress,
      Value<int>? bookmarkedAt,
      Value<int>? updatedAt,
      Value<bool>? unavailable,
      Value<String?>? etag}) {
    return BookmarkedPostsCompanion(
      id: id ?? this.id,
      postUid: postUid ?? this.postUid,
      title: title ?? this.title,
      feedUrl: feedUrl ?? this.feedUrl,
      postJson: postJson ?? this.postJson,
      sessionAddress: sessionAddress ?? this.sessionAddress,
      bookmarkedAt: bookmarkedAt ?? this.bookmarkedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unavailable: unavailable ?? this.unavailable,
      etag: etag ?? this.etag,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (postUid.present) {
      map['post_uid'] = Variable<String>(postUid.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (feedUrl.present) {
      map['feed_url'] = Variable<String>(feedUrl.value);
    }
    if (postJson.present) {
      map['post_json'] = Variable<String>(postJson.value);
    }
    if (sessionAddress.present) {
      map['session_address'] = Variable<String>(sessionAddress.value);
    }
    if (bookmarkedAt.present) {
      map['bookmarked_at'] = Variable<int>(bookmarkedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (unavailable.present) {
      map['unavailable'] = Variable<bool>(unavailable.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarkedPostsCompanion(')
          ..write('id: $id, ')
          ..write('postUid: $postUid, ')
          ..write('title: $title, ')
          ..write('feedUrl: $feedUrl, ')
          ..write('postJson: $postJson, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('bookmarkedAt: $bookmarkedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('unavailable: $unavailable, ')
          ..write('etag: $etag')
          ..write(')'))
        .toString();
  }
}

class $ActivityEventsTable extends ActivityEvents
    with TableInfo<$ActivityEventsTable, ActivityEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _eventTypeMeta =
      const VerificationMeta('eventType');
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
      'event_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _actorMeta = const VerificationMeta('actor');
  @override
  late final GeneratedColumn<String> actor = GeneratedColumn<String>(
      'actor', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<String> target = GeneratedColumn<String>(
      'target', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _blockNumberMeta =
      const VerificationMeta('blockNumber');
  @override
  late final GeneratedColumn<int> blockNumber = GeneratedColumn<int>(
      'block_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _logIndexMeta =
      const VerificationMeta('logIndex');
  @override
  late final GeneratedColumn<int> logIndex = GeneratedColumn<int>(
      'log_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _txHashMeta = const VerificationMeta('txHash');
  @override
  late final GeneratedColumn<String> txHash = GeneratedColumn<String>(
      'tx_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_read" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sessionAddressMeta =
      const VerificationMeta('sessionAddress');
  @override
  late final GeneratedColumn<String> sessionAddress = GeneratedColumn<String>(
      'session_address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        eventType,
        actor,
        target,
        blockNumber,
        logIndex,
        txHash,
        timestamp,
        data,
        isRead,
        sessionAddress
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_events';
  @override
  VerificationContext validateIntegrity(Insertable<ActivityEventRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('event_type')) {
      context.handle(_eventTypeMeta,
          eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta));
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('actor')) {
      context.handle(
          _actorMeta, actor.isAcceptableOrUnknown(data['actor']!, _actorMeta));
    } else if (isInserting) {
      context.missing(_actorMeta);
    }
    if (data.containsKey('target')) {
      context.handle(_targetMeta,
          target.isAcceptableOrUnknown(data['target']!, _targetMeta));
    }
    if (data.containsKey('block_number')) {
      context.handle(
          _blockNumberMeta,
          blockNumber.isAcceptableOrUnknown(
              data['block_number']!, _blockNumberMeta));
    } else if (isInserting) {
      context.missing(_blockNumberMeta);
    }
    if (data.containsKey('log_index')) {
      context.handle(_logIndexMeta,
          logIndex.isAcceptableOrUnknown(data['log_index']!, _logIndexMeta));
    } else if (isInserting) {
      context.missing(_logIndexMeta);
    }
    if (data.containsKey('tx_hash')) {
      context.handle(_txHashMeta,
          txHash.isAcceptableOrUnknown(data['tx_hash']!, _txHashMeta));
    } else if (isInserting) {
      context.missing(_txHashMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    if (data.containsKey('session_address')) {
      context.handle(
          _sessionAddressMeta,
          sessionAddress.isAcceptableOrUnknown(
              data['session_address']!, _sessionAddressMeta));
    } else if (isInserting) {
      context.missing(_sessionAddressMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {txHash, logIndex, sessionAddress},
      ];
  @override
  ActivityEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityEventRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      eventType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_type'])!,
      actor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}actor'])!,
      target: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target']),
      blockNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}block_number'])!,
      logIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}log_index'])!,
      txHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tx_hash'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
      sessionAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}session_address'])!,
    );
  }

  @override
  $ActivityEventsTable createAlias(String alias) {
    return $ActivityEventsTable(attachedDatabase, alias);
  }
}

class ActivityEventRow extends DataClass
    implements Insertable<ActivityEventRow> {
  final int id;
  final String eventType;
  final String actor;
  final String? target;
  final int blockNumber;
  final int logIndex;
  final String txHash;
  final int timestamp;
  final String data;
  final bool isRead;
  final String sessionAddress;
  const ActivityEventRow(
      {required this.id,
      required this.eventType,
      required this.actor,
      this.target,
      required this.blockNumber,
      required this.logIndex,
      required this.txHash,
      required this.timestamp,
      required this.data,
      required this.isRead,
      required this.sessionAddress});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['event_type'] = Variable<String>(eventType);
    map['actor'] = Variable<String>(actor);
    if (!nullToAbsent || target != null) {
      map['target'] = Variable<String>(target);
    }
    map['block_number'] = Variable<int>(blockNumber);
    map['log_index'] = Variable<int>(logIndex);
    map['tx_hash'] = Variable<String>(txHash);
    map['timestamp'] = Variable<int>(timestamp);
    map['data'] = Variable<String>(data);
    map['is_read'] = Variable<bool>(isRead);
    map['session_address'] = Variable<String>(sessionAddress);
    return map;
  }

  ActivityEventsCompanion toCompanion(bool nullToAbsent) {
    return ActivityEventsCompanion(
      id: Value(id),
      eventType: Value(eventType),
      actor: Value(actor),
      target:
          target == null && nullToAbsent ? const Value.absent() : Value(target),
      blockNumber: Value(blockNumber),
      logIndex: Value(logIndex),
      txHash: Value(txHash),
      timestamp: Value(timestamp),
      data: Value(data),
      isRead: Value(isRead),
      sessionAddress: Value(sessionAddress),
    );
  }

  factory ActivityEventRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityEventRow(
      id: serializer.fromJson<int>(json['id']),
      eventType: serializer.fromJson<String>(json['eventType']),
      actor: serializer.fromJson<String>(json['actor']),
      target: serializer.fromJson<String?>(json['target']),
      blockNumber: serializer.fromJson<int>(json['blockNumber']),
      logIndex: serializer.fromJson<int>(json['logIndex']),
      txHash: serializer.fromJson<String>(json['txHash']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      data: serializer.fromJson<String>(json['data']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      sessionAddress: serializer.fromJson<String>(json['sessionAddress']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'eventType': serializer.toJson<String>(eventType),
      'actor': serializer.toJson<String>(actor),
      'target': serializer.toJson<String?>(target),
      'blockNumber': serializer.toJson<int>(blockNumber),
      'logIndex': serializer.toJson<int>(logIndex),
      'txHash': serializer.toJson<String>(txHash),
      'timestamp': serializer.toJson<int>(timestamp),
      'data': serializer.toJson<String>(data),
      'isRead': serializer.toJson<bool>(isRead),
      'sessionAddress': serializer.toJson<String>(sessionAddress),
    };
  }

  ActivityEventRow copyWith(
          {int? id,
          String? eventType,
          String? actor,
          Value<String?> target = const Value.absent(),
          int? blockNumber,
          int? logIndex,
          String? txHash,
          int? timestamp,
          String? data,
          bool? isRead,
          String? sessionAddress}) =>
      ActivityEventRow(
        id: id ?? this.id,
        eventType: eventType ?? this.eventType,
        actor: actor ?? this.actor,
        target: target.present ? target.value : this.target,
        blockNumber: blockNumber ?? this.blockNumber,
        logIndex: logIndex ?? this.logIndex,
        txHash: txHash ?? this.txHash,
        timestamp: timestamp ?? this.timestamp,
        data: data ?? this.data,
        isRead: isRead ?? this.isRead,
        sessionAddress: sessionAddress ?? this.sessionAddress,
      );
  ActivityEventRow copyWithCompanion(ActivityEventsCompanion data) {
    return ActivityEventRow(
      id: data.id.present ? data.id.value : this.id,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      actor: data.actor.present ? data.actor.value : this.actor,
      target: data.target.present ? data.target.value : this.target,
      blockNumber:
          data.blockNumber.present ? data.blockNumber.value : this.blockNumber,
      logIndex: data.logIndex.present ? data.logIndex.value : this.logIndex,
      txHash: data.txHash.present ? data.txHash.value : this.txHash,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      data: data.data.present ? data.data.value : this.data,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      sessionAddress: data.sessionAddress.present
          ? data.sessionAddress.value
          : this.sessionAddress,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityEventRow(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('actor: $actor, ')
          ..write('target: $target, ')
          ..write('blockNumber: $blockNumber, ')
          ..write('logIndex: $logIndex, ')
          ..write('txHash: $txHash, ')
          ..write('timestamp: $timestamp, ')
          ..write('data: $data, ')
          ..write('isRead: $isRead, ')
          ..write('sessionAddress: $sessionAddress')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, eventType, actor, target, blockNumber,
      logIndex, txHash, timestamp, data, isRead, sessionAddress);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityEventRow &&
          other.id == this.id &&
          other.eventType == this.eventType &&
          other.actor == this.actor &&
          other.target == this.target &&
          other.blockNumber == this.blockNumber &&
          other.logIndex == this.logIndex &&
          other.txHash == this.txHash &&
          other.timestamp == this.timestamp &&
          other.data == this.data &&
          other.isRead == this.isRead &&
          other.sessionAddress == this.sessionAddress);
}

class ActivityEventsCompanion extends UpdateCompanion<ActivityEventRow> {
  final Value<int> id;
  final Value<String> eventType;
  final Value<String> actor;
  final Value<String?> target;
  final Value<int> blockNumber;
  final Value<int> logIndex;
  final Value<String> txHash;
  final Value<int> timestamp;
  final Value<String> data;
  final Value<bool> isRead;
  final Value<String> sessionAddress;
  const ActivityEventsCompanion({
    this.id = const Value.absent(),
    this.eventType = const Value.absent(),
    this.actor = const Value.absent(),
    this.target = const Value.absent(),
    this.blockNumber = const Value.absent(),
    this.logIndex = const Value.absent(),
    this.txHash = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.data = const Value.absent(),
    this.isRead = const Value.absent(),
    this.sessionAddress = const Value.absent(),
  });
  ActivityEventsCompanion.insert({
    this.id = const Value.absent(),
    required String eventType,
    required String actor,
    this.target = const Value.absent(),
    required int blockNumber,
    required int logIndex,
    required String txHash,
    required int timestamp,
    this.data = const Value.absent(),
    this.isRead = const Value.absent(),
    required String sessionAddress,
  })  : eventType = Value(eventType),
        actor = Value(actor),
        blockNumber = Value(blockNumber),
        logIndex = Value(logIndex),
        txHash = Value(txHash),
        timestamp = Value(timestamp),
        sessionAddress = Value(sessionAddress);
  static Insertable<ActivityEventRow> custom({
    Expression<int>? id,
    Expression<String>? eventType,
    Expression<String>? actor,
    Expression<String>? target,
    Expression<int>? blockNumber,
    Expression<int>? logIndex,
    Expression<String>? txHash,
    Expression<int>? timestamp,
    Expression<String>? data,
    Expression<bool>? isRead,
    Expression<String>? sessionAddress,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventType != null) 'event_type': eventType,
      if (actor != null) 'actor': actor,
      if (target != null) 'target': target,
      if (blockNumber != null) 'block_number': blockNumber,
      if (logIndex != null) 'log_index': logIndex,
      if (txHash != null) 'tx_hash': txHash,
      if (timestamp != null) 'timestamp': timestamp,
      if (data != null) 'data': data,
      if (isRead != null) 'is_read': isRead,
      if (sessionAddress != null) 'session_address': sessionAddress,
    });
  }

  ActivityEventsCompanion copyWith(
      {Value<int>? id,
      Value<String>? eventType,
      Value<String>? actor,
      Value<String?>? target,
      Value<int>? blockNumber,
      Value<int>? logIndex,
      Value<String>? txHash,
      Value<int>? timestamp,
      Value<String>? data,
      Value<bool>? isRead,
      Value<String>? sessionAddress}) {
    return ActivityEventsCompanion(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      actor: actor ?? this.actor,
      target: target ?? this.target,
      blockNumber: blockNumber ?? this.blockNumber,
      logIndex: logIndex ?? this.logIndex,
      txHash: txHash ?? this.txHash,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      sessionAddress: sessionAddress ?? this.sessionAddress,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (actor.present) {
      map['actor'] = Variable<String>(actor.value);
    }
    if (target.present) {
      map['target'] = Variable<String>(target.value);
    }
    if (blockNumber.present) {
      map['block_number'] = Variable<int>(blockNumber.value);
    }
    if (logIndex.present) {
      map['log_index'] = Variable<int>(logIndex.value);
    }
    if (txHash.present) {
      map['tx_hash'] = Variable<String>(txHash.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (sessionAddress.present) {
      map['session_address'] = Variable<String>(sessionAddress.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityEventsCompanion(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('actor: $actor, ')
          ..write('target: $target, ')
          ..write('blockNumber: $blockNumber, ')
          ..write('logIndex: $logIndex, ')
          ..write('txHash: $txHash, ')
          ..write('timestamp: $timestamp, ')
          ..write('data: $data, ')
          ..write('isRead: $isRead, ')
          ..write('sessionAddress: $sessionAddress')
          ..write(')'))
        .toString();
  }
}

class $SavedStickersTable extends SavedStickers
    with TableInfo<$SavedStickersTable, SavedStickerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedStickersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _digestMeta = const VerificationMeta('digest');
  @override
  late final GeneratedColumn<String> digest = GeneratedColumn<String>(
      'digest', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _filenameMeta =
      const VerificationMeta('filename');
  @override
  late final GeneratedColumn<String> filename = GeneratedColumn<String>(
      'filename', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mimeTypeMeta =
      const VerificationMeta('mimeType');
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
      'mime_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<Uint8List> data = GeneratedColumn<Uint8List>(
      'data', aliasedName, false,
      type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
      'size', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sessionAddressMeta =
      const VerificationMeta('sessionAddress');
  @override
  late final GeneratedColumn<String> sessionAddress = GeneratedColumn<String>(
      'session_address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _savedAtMeta =
      const VerificationMeta('savedAt');
  @override
  late final GeneratedColumn<int> savedAt = GeneratedColumn<int>(
      'saved_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, digest, filename, mimeType, data, size, sessionAddress, savedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_stickers';
  @override
  VerificationContext validateIntegrity(Insertable<SavedStickerRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('digest')) {
      context.handle(_digestMeta,
          digest.isAcceptableOrUnknown(data['digest']!, _digestMeta));
    } else if (isInserting) {
      context.missing(_digestMeta);
    }
    if (data.containsKey('filename')) {
      context.handle(_filenameMeta,
          filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta));
    } else if (isInserting) {
      context.missing(_filenameMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(_mimeTypeMeta,
          mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta));
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
          _sizeMeta, size.isAcceptableOrUnknown(data['size']!, _sizeMeta));
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('session_address')) {
      context.handle(
          _sessionAddressMeta,
          sessionAddress.isAcceptableOrUnknown(
              data['session_address']!, _sessionAddressMeta));
    } else if (isInserting) {
      context.missing(_sessionAddressMeta);
    }
    if (data.containsKey('saved_at')) {
      context.handle(_savedAtMeta,
          savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta));
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {digest, sessionAddress},
      ];
  @override
  SavedStickerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedStickerRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      digest: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}digest'])!,
      filename: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}filename'])!,
      mimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mime_type'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}data'])!,
      size: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size'])!,
      sessionAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}session_address'])!,
      savedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}saved_at'])!,
    );
  }

  @override
  $SavedStickersTable createAlias(String alias) {
    return $SavedStickersTable(attachedDatabase, alias);
  }
}

class SavedStickerRow extends DataClass implements Insertable<SavedStickerRow> {
  final int id;
  final String digest;
  final String filename;
  final String mimeType;
  final Uint8List data;
  final int size;
  final String sessionAddress;
  final int savedAt;
  const SavedStickerRow(
      {required this.id,
      required this.digest,
      required this.filename,
      required this.mimeType,
      required this.data,
      required this.size,
      required this.sessionAddress,
      required this.savedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['digest'] = Variable<String>(digest);
    map['filename'] = Variable<String>(filename);
    map['mime_type'] = Variable<String>(mimeType);
    map['data'] = Variable<Uint8List>(data);
    map['size'] = Variable<int>(size);
    map['session_address'] = Variable<String>(sessionAddress);
    map['saved_at'] = Variable<int>(savedAt);
    return map;
  }

  SavedStickersCompanion toCompanion(bool nullToAbsent) {
    return SavedStickersCompanion(
      id: Value(id),
      digest: Value(digest),
      filename: Value(filename),
      mimeType: Value(mimeType),
      data: Value(data),
      size: Value(size),
      sessionAddress: Value(sessionAddress),
      savedAt: Value(savedAt),
    );
  }

  factory SavedStickerRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedStickerRow(
      id: serializer.fromJson<int>(json['id']),
      digest: serializer.fromJson<String>(json['digest']),
      filename: serializer.fromJson<String>(json['filename']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      data: serializer.fromJson<Uint8List>(json['data']),
      size: serializer.fromJson<int>(json['size']),
      sessionAddress: serializer.fromJson<String>(json['sessionAddress']),
      savedAt: serializer.fromJson<int>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'digest': serializer.toJson<String>(digest),
      'filename': serializer.toJson<String>(filename),
      'mimeType': serializer.toJson<String>(mimeType),
      'data': serializer.toJson<Uint8List>(data),
      'size': serializer.toJson<int>(size),
      'sessionAddress': serializer.toJson<String>(sessionAddress),
      'savedAt': serializer.toJson<int>(savedAt),
    };
  }

  SavedStickerRow copyWith(
          {int? id,
          String? digest,
          String? filename,
          String? mimeType,
          Uint8List? data,
          int? size,
          String? sessionAddress,
          int? savedAt}) =>
      SavedStickerRow(
        id: id ?? this.id,
        digest: digest ?? this.digest,
        filename: filename ?? this.filename,
        mimeType: mimeType ?? this.mimeType,
        data: data ?? this.data,
        size: size ?? this.size,
        sessionAddress: sessionAddress ?? this.sessionAddress,
        savedAt: savedAt ?? this.savedAt,
      );
  SavedStickerRow copyWithCompanion(SavedStickersCompanion data) {
    return SavedStickerRow(
      id: data.id.present ? data.id.value : this.id,
      digest: data.digest.present ? data.digest.value : this.digest,
      filename: data.filename.present ? data.filename.value : this.filename,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      data: data.data.present ? data.data.value : this.data,
      size: data.size.present ? data.size.value : this.size,
      sessionAddress: data.sessionAddress.present
          ? data.sessionAddress.value
          : this.sessionAddress,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedStickerRow(')
          ..write('id: $id, ')
          ..write('digest: $digest, ')
          ..write('filename: $filename, ')
          ..write('mimeType: $mimeType, ')
          ..write('data: $data, ')
          ..write('size: $size, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, digest, filename, mimeType,
      $driftBlobEquality.hash(data), size, sessionAddress, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedStickerRow &&
          other.id == this.id &&
          other.digest == this.digest &&
          other.filename == this.filename &&
          other.mimeType == this.mimeType &&
          $driftBlobEquality.equals(other.data, this.data) &&
          other.size == this.size &&
          other.sessionAddress == this.sessionAddress &&
          other.savedAt == this.savedAt);
}

class SavedStickersCompanion extends UpdateCompanion<SavedStickerRow> {
  final Value<int> id;
  final Value<String> digest;
  final Value<String> filename;
  final Value<String> mimeType;
  final Value<Uint8List> data;
  final Value<int> size;
  final Value<String> sessionAddress;
  final Value<int> savedAt;
  const SavedStickersCompanion({
    this.id = const Value.absent(),
    this.digest = const Value.absent(),
    this.filename = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.data = const Value.absent(),
    this.size = const Value.absent(),
    this.sessionAddress = const Value.absent(),
    this.savedAt = const Value.absent(),
  });
  SavedStickersCompanion.insert({
    this.id = const Value.absent(),
    required String digest,
    required String filename,
    required String mimeType,
    required Uint8List data,
    required int size,
    required String sessionAddress,
    required int savedAt,
  })  : digest = Value(digest),
        filename = Value(filename),
        mimeType = Value(mimeType),
        data = Value(data),
        size = Value(size),
        sessionAddress = Value(sessionAddress),
        savedAt = Value(savedAt);
  static Insertable<SavedStickerRow> custom({
    Expression<int>? id,
    Expression<String>? digest,
    Expression<String>? filename,
    Expression<String>? mimeType,
    Expression<Uint8List>? data,
    Expression<int>? size,
    Expression<String>? sessionAddress,
    Expression<int>? savedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (digest != null) 'digest': digest,
      if (filename != null) 'filename': filename,
      if (mimeType != null) 'mime_type': mimeType,
      if (data != null) 'data': data,
      if (size != null) 'size': size,
      if (sessionAddress != null) 'session_address': sessionAddress,
      if (savedAt != null) 'saved_at': savedAt,
    });
  }

  SavedStickersCompanion copyWith(
      {Value<int>? id,
      Value<String>? digest,
      Value<String>? filename,
      Value<String>? mimeType,
      Value<Uint8List>? data,
      Value<int>? size,
      Value<String>? sessionAddress,
      Value<int>? savedAt}) {
    return SavedStickersCompanion(
      id: id ?? this.id,
      digest: digest ?? this.digest,
      filename: filename ?? this.filename,
      mimeType: mimeType ?? this.mimeType,
      data: data ?? this.data,
      size: size ?? this.size,
      sessionAddress: sessionAddress ?? this.sessionAddress,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (digest.present) {
      map['digest'] = Variable<String>(digest.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (data.present) {
      map['data'] = Variable<Uint8List>(data.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (sessionAddress.present) {
      map['session_address'] = Variable<String>(sessionAddress.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<int>(savedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedStickersCompanion(')
          ..write('id: $id, ')
          ..write('digest: $digest, ')
          ..write('filename: $filename, ')
          ..write('mimeType: $mimeType, ')
          ..write('data: $data, ')
          ..write('size: $size, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }
}

class $ConnectedSitesTable extends ConnectedSites
    with TableInfo<$ConnectedSitesTable, ConnectedSite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConnectedSitesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
      'origin', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionAddressMeta =
      const VerificationMeta('sessionAddress');
  @override
  late final GeneratedColumn<String> sessionAddress = GeneratedColumn<String>(
      'session_address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _grantedEoaMeta =
      const VerificationMeta('grantedEoa');
  @override
  late final GeneratedColumn<String> grantedEoa = GeneratedColumn<String>(
      'granted_eoa', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _keyLabelMeta =
      const VerificationMeta('keyLabel');
  @override
  late final GeneratedColumn<String> keyLabel = GeneratedColumn<String>(
      'key_label', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _grantedAtMeta =
      const VerificationMeta('grantedAt');
  @override
  late final GeneratedColumn<int> grantedAt = GeneratedColumn<int>(
      'granted_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastUsedAtMeta =
      const VerificationMeta('lastUsedAt');
  @override
  late final GeneratedColumn<int> lastUsedAt = GeneratedColumn<int>(
      'last_used_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _activeKeyMeta =
      const VerificationMeta('activeKey');
  @override
  late final GeneratedColumn<bool> activeKey = GeneratedColumn<bool>(
      'active_key', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active_key" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        origin,
        sessionAddress,
        grantedEoa,
        keyLabel,
        grantedAt,
        lastUsedAt,
        activeKey
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'connected_sites';
  @override
  VerificationContext validateIntegrity(Insertable<ConnectedSite> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('origin')) {
      context.handle(_originMeta,
          origin.isAcceptableOrUnknown(data['origin']!, _originMeta));
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('session_address')) {
      context.handle(
          _sessionAddressMeta,
          sessionAddress.isAcceptableOrUnknown(
              data['session_address']!, _sessionAddressMeta));
    } else if (isInserting) {
      context.missing(_sessionAddressMeta);
    }
    if (data.containsKey('granted_eoa')) {
      context.handle(
          _grantedEoaMeta,
          grantedEoa.isAcceptableOrUnknown(
              data['granted_eoa']!, _grantedEoaMeta));
    } else if (isInserting) {
      context.missing(_grantedEoaMeta);
    }
    if (data.containsKey('key_label')) {
      context.handle(_keyLabelMeta,
          keyLabel.isAcceptableOrUnknown(data['key_label']!, _keyLabelMeta));
    }
    if (data.containsKey('granted_at')) {
      context.handle(_grantedAtMeta,
          grantedAt.isAcceptableOrUnknown(data['granted_at']!, _grantedAtMeta));
    } else if (isInserting) {
      context.missing(_grantedAtMeta);
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
          _lastUsedAtMeta,
          lastUsedAt.isAcceptableOrUnknown(
              data['last_used_at']!, _lastUsedAtMeta));
    } else if (isInserting) {
      context.missing(_lastUsedAtMeta);
    }
    if (data.containsKey('active_key')) {
      context.handle(_activeKeyMeta,
          activeKey.isAcceptableOrUnknown(data['active_key']!, _activeKeyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {origin, sessionAddress, grantedEoa},
      ];
  @override
  ConnectedSite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConnectedSite(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      origin: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}origin'])!,
      sessionAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}session_address'])!,
      grantedEoa: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}granted_eoa'])!,
      keyLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key_label']),
      grantedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}granted_at'])!,
      lastUsedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_used_at'])!,
      activeKey: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active_key'])!,
    );
  }

  @override
  $ConnectedSitesTable createAlias(String alias) {
    return $ConnectedSitesTable(attachedDatabase, alias);
  }
}

class ConnectedSite extends DataClass implements Insertable<ConnectedSite> {
  final int id;
  final String origin;
  final String sessionAddress;
  final String grantedEoa;
  final String? keyLabel;
  final int grantedAt;
  final int lastUsedAt;
  final bool activeKey;
  const ConnectedSite(
      {required this.id,
      required this.origin,
      required this.sessionAddress,
      required this.grantedEoa,
      this.keyLabel,
      required this.grantedAt,
      required this.lastUsedAt,
      required this.activeKey});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['origin'] = Variable<String>(origin);
    map['session_address'] = Variable<String>(sessionAddress);
    map['granted_eoa'] = Variable<String>(grantedEoa);
    if (!nullToAbsent || keyLabel != null) {
      map['key_label'] = Variable<String>(keyLabel);
    }
    map['granted_at'] = Variable<int>(grantedAt);
    map['last_used_at'] = Variable<int>(lastUsedAt);
    map['active_key'] = Variable<bool>(activeKey);
    return map;
  }

  ConnectedSitesCompanion toCompanion(bool nullToAbsent) {
    return ConnectedSitesCompanion(
      id: Value(id),
      origin: Value(origin),
      sessionAddress: Value(sessionAddress),
      grantedEoa: Value(grantedEoa),
      keyLabel: keyLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(keyLabel),
      grantedAt: Value(grantedAt),
      lastUsedAt: Value(lastUsedAt),
      activeKey: Value(activeKey),
    );
  }

  factory ConnectedSite.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConnectedSite(
      id: serializer.fromJson<int>(json['id']),
      origin: serializer.fromJson<String>(json['origin']),
      sessionAddress: serializer.fromJson<String>(json['sessionAddress']),
      grantedEoa: serializer.fromJson<String>(json['grantedEoa']),
      keyLabel: serializer.fromJson<String?>(json['keyLabel']),
      grantedAt: serializer.fromJson<int>(json['grantedAt']),
      lastUsedAt: serializer.fromJson<int>(json['lastUsedAt']),
      activeKey: serializer.fromJson<bool>(json['activeKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'origin': serializer.toJson<String>(origin),
      'sessionAddress': serializer.toJson<String>(sessionAddress),
      'grantedEoa': serializer.toJson<String>(grantedEoa),
      'keyLabel': serializer.toJson<String?>(keyLabel),
      'grantedAt': serializer.toJson<int>(grantedAt),
      'lastUsedAt': serializer.toJson<int>(lastUsedAt),
      'activeKey': serializer.toJson<bool>(activeKey),
    };
  }

  ConnectedSite copyWith(
          {int? id,
          String? origin,
          String? sessionAddress,
          String? grantedEoa,
          Value<String?> keyLabel = const Value.absent(),
          int? grantedAt,
          int? lastUsedAt,
          bool? activeKey}) =>
      ConnectedSite(
        id: id ?? this.id,
        origin: origin ?? this.origin,
        sessionAddress: sessionAddress ?? this.sessionAddress,
        grantedEoa: grantedEoa ?? this.grantedEoa,
        keyLabel: keyLabel.present ? keyLabel.value : this.keyLabel,
        grantedAt: grantedAt ?? this.grantedAt,
        lastUsedAt: lastUsedAt ?? this.lastUsedAt,
        activeKey: activeKey ?? this.activeKey,
      );
  ConnectedSite copyWithCompanion(ConnectedSitesCompanion data) {
    return ConnectedSite(
      id: data.id.present ? data.id.value : this.id,
      origin: data.origin.present ? data.origin.value : this.origin,
      sessionAddress: data.sessionAddress.present
          ? data.sessionAddress.value
          : this.sessionAddress,
      grantedEoa:
          data.grantedEoa.present ? data.grantedEoa.value : this.grantedEoa,
      keyLabel: data.keyLabel.present ? data.keyLabel.value : this.keyLabel,
      grantedAt: data.grantedAt.present ? data.grantedAt.value : this.grantedAt,
      lastUsedAt:
          data.lastUsedAt.present ? data.lastUsedAt.value : this.lastUsedAt,
      activeKey: data.activeKey.present ? data.activeKey.value : this.activeKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConnectedSite(')
          ..write('id: $id, ')
          ..write('origin: $origin, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('grantedEoa: $grantedEoa, ')
          ..write('keyLabel: $keyLabel, ')
          ..write('grantedAt: $grantedAt, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('activeKey: $activeKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, origin, sessionAddress, grantedEoa,
      keyLabel, grantedAt, lastUsedAt, activeKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConnectedSite &&
          other.id == this.id &&
          other.origin == this.origin &&
          other.sessionAddress == this.sessionAddress &&
          other.grantedEoa == this.grantedEoa &&
          other.keyLabel == this.keyLabel &&
          other.grantedAt == this.grantedAt &&
          other.lastUsedAt == this.lastUsedAt &&
          other.activeKey == this.activeKey);
}

class ConnectedSitesCompanion extends UpdateCompanion<ConnectedSite> {
  final Value<int> id;
  final Value<String> origin;
  final Value<String> sessionAddress;
  final Value<String> grantedEoa;
  final Value<String?> keyLabel;
  final Value<int> grantedAt;
  final Value<int> lastUsedAt;
  final Value<bool> activeKey;
  const ConnectedSitesCompanion({
    this.id = const Value.absent(),
    this.origin = const Value.absent(),
    this.sessionAddress = const Value.absent(),
    this.grantedEoa = const Value.absent(),
    this.keyLabel = const Value.absent(),
    this.grantedAt = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.activeKey = const Value.absent(),
  });
  ConnectedSitesCompanion.insert({
    this.id = const Value.absent(),
    required String origin,
    required String sessionAddress,
    required String grantedEoa,
    this.keyLabel = const Value.absent(),
    required int grantedAt,
    required int lastUsedAt,
    this.activeKey = const Value.absent(),
  })  : origin = Value(origin),
        sessionAddress = Value(sessionAddress),
        grantedEoa = Value(grantedEoa),
        grantedAt = Value(grantedAt),
        lastUsedAt = Value(lastUsedAt);
  static Insertable<ConnectedSite> custom({
    Expression<int>? id,
    Expression<String>? origin,
    Expression<String>? sessionAddress,
    Expression<String>? grantedEoa,
    Expression<String>? keyLabel,
    Expression<int>? grantedAt,
    Expression<int>? lastUsedAt,
    Expression<bool>? activeKey,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (origin != null) 'origin': origin,
      if (sessionAddress != null) 'session_address': sessionAddress,
      if (grantedEoa != null) 'granted_eoa': grantedEoa,
      if (keyLabel != null) 'key_label': keyLabel,
      if (grantedAt != null) 'granted_at': grantedAt,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (activeKey != null) 'active_key': activeKey,
    });
  }

  ConnectedSitesCompanion copyWith(
      {Value<int>? id,
      Value<String>? origin,
      Value<String>? sessionAddress,
      Value<String>? grantedEoa,
      Value<String?>? keyLabel,
      Value<int>? grantedAt,
      Value<int>? lastUsedAt,
      Value<bool>? activeKey}) {
    return ConnectedSitesCompanion(
      id: id ?? this.id,
      origin: origin ?? this.origin,
      sessionAddress: sessionAddress ?? this.sessionAddress,
      grantedEoa: grantedEoa ?? this.grantedEoa,
      keyLabel: keyLabel ?? this.keyLabel,
      grantedAt: grantedAt ?? this.grantedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      activeKey: activeKey ?? this.activeKey,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (sessionAddress.present) {
      map['session_address'] = Variable<String>(sessionAddress.value);
    }
    if (grantedEoa.present) {
      map['granted_eoa'] = Variable<String>(grantedEoa.value);
    }
    if (keyLabel.present) {
      map['key_label'] = Variable<String>(keyLabel.value);
    }
    if (grantedAt.present) {
      map['granted_at'] = Variable<int>(grantedAt.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<int>(lastUsedAt.value);
    }
    if (activeKey.present) {
      map['active_key'] = Variable<bool>(activeKey.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConnectedSitesCompanion(')
          ..write('id: $id, ')
          ..write('origin: $origin, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('grantedEoa: $grantedEoa, ')
          ..write('keyLabel: $keyLabel, ')
          ..write('grantedAt: $grantedAt, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('activeKey: $activeKey')
          ..write(')'))
        .toString();
  }
}

class $FollowedAccountsTable extends FollowedAccounts
    with TableInfo<$FollowedAccountsTable, FollowedAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FollowedAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _sessionAddressMeta =
      const VerificationMeta('sessionAddress');
  @override
  late final GeneratedColumn<String> sessionAddress = GeneratedColumn<String>(
      'session_address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountAddressMeta =
      const VerificationMeta('accountAddress');
  @override
  late final GeneratedColumn<String> accountAddress = GeneratedColumn<String>(
      'account_address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<int> listId = GeneratedColumn<int>(
      'list_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints:
          'NOT NULL REFERENCES feed_lists(id) ON DELETE CASCADE');
  static const VerificationMeta _followedAtMeta =
      const VerificationMeta('followedAt');
  @override
  late final GeneratedColumn<int> followedAt = GeneratedColumn<int>(
      'followed_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, sessionAddress, accountAddress, listId, followedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'followed_accounts';
  @override
  VerificationContext validateIntegrity(Insertable<FollowedAccount> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_address')) {
      context.handle(
          _sessionAddressMeta,
          sessionAddress.isAcceptableOrUnknown(
              data['session_address']!, _sessionAddressMeta));
    } else if (isInserting) {
      context.missing(_sessionAddressMeta);
    }
    if (data.containsKey('account_address')) {
      context.handle(
          _accountAddressMeta,
          accountAddress.isAcceptableOrUnknown(
              data['account_address']!, _accountAddressMeta));
    } else if (isInserting) {
      context.missing(_accountAddressMeta);
    }
    if (data.containsKey('list_id')) {
      context.handle(_listIdMeta,
          listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta));
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('followed_at')) {
      context.handle(
          _followedAtMeta,
          followedAt.isAcceptableOrUnknown(
              data['followed_at']!, _followedAtMeta));
    } else if (isInserting) {
      context.missing(_followedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {sessionAddress, accountAddress, listId},
      ];
  @override
  FollowedAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FollowedAccount(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sessionAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}session_address'])!,
      accountAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}account_address'])!,
      listId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}list_id'])!,
      followedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}followed_at'])!,
    );
  }

  @override
  $FollowedAccountsTable createAlias(String alias) {
    return $FollowedAccountsTable(attachedDatabase, alias);
  }
}

class FollowedAccount extends DataClass implements Insertable<FollowedAccount> {
  final int id;
  final String sessionAddress;
  final String accountAddress;
  final int listId;
  final int followedAt;
  const FollowedAccount(
      {required this.id,
      required this.sessionAddress,
      required this.accountAddress,
      required this.listId,
      required this.followedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_address'] = Variable<String>(sessionAddress);
    map['account_address'] = Variable<String>(accountAddress);
    map['list_id'] = Variable<int>(listId);
    map['followed_at'] = Variable<int>(followedAt);
    return map;
  }

  FollowedAccountsCompanion toCompanion(bool nullToAbsent) {
    return FollowedAccountsCompanion(
      id: Value(id),
      sessionAddress: Value(sessionAddress),
      accountAddress: Value(accountAddress),
      listId: Value(listId),
      followedAt: Value(followedAt),
    );
  }

  factory FollowedAccount.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FollowedAccount(
      id: serializer.fromJson<int>(json['id']),
      sessionAddress: serializer.fromJson<String>(json['sessionAddress']),
      accountAddress: serializer.fromJson<String>(json['accountAddress']),
      listId: serializer.fromJson<int>(json['listId']),
      followedAt: serializer.fromJson<int>(json['followedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionAddress': serializer.toJson<String>(sessionAddress),
      'accountAddress': serializer.toJson<String>(accountAddress),
      'listId': serializer.toJson<int>(listId),
      'followedAt': serializer.toJson<int>(followedAt),
    };
  }

  FollowedAccount copyWith(
          {int? id,
          String? sessionAddress,
          String? accountAddress,
          int? listId,
          int? followedAt}) =>
      FollowedAccount(
        id: id ?? this.id,
        sessionAddress: sessionAddress ?? this.sessionAddress,
        accountAddress: accountAddress ?? this.accountAddress,
        listId: listId ?? this.listId,
        followedAt: followedAt ?? this.followedAt,
      );
  FollowedAccount copyWithCompanion(FollowedAccountsCompanion data) {
    return FollowedAccount(
      id: data.id.present ? data.id.value : this.id,
      sessionAddress: data.sessionAddress.present
          ? data.sessionAddress.value
          : this.sessionAddress,
      accountAddress: data.accountAddress.present
          ? data.accountAddress.value
          : this.accountAddress,
      listId: data.listId.present ? data.listId.value : this.listId,
      followedAt:
          data.followedAt.present ? data.followedAt.value : this.followedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FollowedAccount(')
          ..write('id: $id, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('accountAddress: $accountAddress, ')
          ..write('listId: $listId, ')
          ..write('followedAt: $followedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionAddress, accountAddress, listId, followedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FollowedAccount &&
          other.id == this.id &&
          other.sessionAddress == this.sessionAddress &&
          other.accountAddress == this.accountAddress &&
          other.listId == this.listId &&
          other.followedAt == this.followedAt);
}

class FollowedAccountsCompanion extends UpdateCompanion<FollowedAccount> {
  final Value<int> id;
  final Value<String> sessionAddress;
  final Value<String> accountAddress;
  final Value<int> listId;
  final Value<int> followedAt;
  const FollowedAccountsCompanion({
    this.id = const Value.absent(),
    this.sessionAddress = const Value.absent(),
    this.accountAddress = const Value.absent(),
    this.listId = const Value.absent(),
    this.followedAt = const Value.absent(),
  });
  FollowedAccountsCompanion.insert({
    this.id = const Value.absent(),
    required String sessionAddress,
    required String accountAddress,
    required int listId,
    required int followedAt,
  })  : sessionAddress = Value(sessionAddress),
        accountAddress = Value(accountAddress),
        listId = Value(listId),
        followedAt = Value(followedAt);
  static Insertable<FollowedAccount> custom({
    Expression<int>? id,
    Expression<String>? sessionAddress,
    Expression<String>? accountAddress,
    Expression<int>? listId,
    Expression<int>? followedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionAddress != null) 'session_address': sessionAddress,
      if (accountAddress != null) 'account_address': accountAddress,
      if (listId != null) 'list_id': listId,
      if (followedAt != null) 'followed_at': followedAt,
    });
  }

  FollowedAccountsCompanion copyWith(
      {Value<int>? id,
      Value<String>? sessionAddress,
      Value<String>? accountAddress,
      Value<int>? listId,
      Value<int>? followedAt}) {
    return FollowedAccountsCompanion(
      id: id ?? this.id,
      sessionAddress: sessionAddress ?? this.sessionAddress,
      accountAddress: accountAddress ?? this.accountAddress,
      listId: listId ?? this.listId,
      followedAt: followedAt ?? this.followedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionAddress.present) {
      map['session_address'] = Variable<String>(sessionAddress.value);
    }
    if (accountAddress.present) {
      map['account_address'] = Variable<String>(accountAddress.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<int>(listId.value);
    }
    if (followedAt.present) {
      map['followed_at'] = Variable<int>(followedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FollowedAccountsCompanion(')
          ..write('id: $id, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('accountAddress: $accountAddress, ')
          ..write('listId: $listId, ')
          ..write('followedAt: $followedAt')
          ..write(')'))
        .toString();
  }
}

class $MutedChannelsTable extends MutedChannels
    with TableInfo<$MutedChannelsTable, MutedChannel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MutedChannelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _sessionAddressMeta =
      const VerificationMeta('sessionAddress');
  @override
  late final GeneratedColumn<String> sessionAddress = GeneratedColumn<String>(
      'session_address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountAddressMeta =
      const VerificationMeta('accountAddress');
  @override
  late final GeneratedColumn<String> accountAddress = GeneratedColumn<String>(
      'account_address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<int> listId = GeneratedColumn<int>(
      'list_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints:
          'NOT NULL REFERENCES feed_lists(id) ON DELETE CASCADE');
  static const VerificationMeta _recordKeyMeta =
      const VerificationMeta('recordKey');
  @override
  late final GeneratedColumn<String> recordKey = GeneratedColumn<String>(
      'record_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mutedAtMeta =
      const VerificationMeta('mutedAt');
  @override
  late final GeneratedColumn<int> mutedAt = GeneratedColumn<int>(
      'muted_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, sessionAddress, accountAddress, listId, recordKey, mutedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'muted_channels';
  @override
  VerificationContext validateIntegrity(Insertable<MutedChannel> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_address')) {
      context.handle(
          _sessionAddressMeta,
          sessionAddress.isAcceptableOrUnknown(
              data['session_address']!, _sessionAddressMeta));
    } else if (isInserting) {
      context.missing(_sessionAddressMeta);
    }
    if (data.containsKey('account_address')) {
      context.handle(
          _accountAddressMeta,
          accountAddress.isAcceptableOrUnknown(
              data['account_address']!, _accountAddressMeta));
    } else if (isInserting) {
      context.missing(_accountAddressMeta);
    }
    if (data.containsKey('list_id')) {
      context.handle(_listIdMeta,
          listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta));
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('record_key')) {
      context.handle(_recordKeyMeta,
          recordKey.isAcceptableOrUnknown(data['record_key']!, _recordKeyMeta));
    } else if (isInserting) {
      context.missing(_recordKeyMeta);
    }
    if (data.containsKey('muted_at')) {
      context.handle(_mutedAtMeta,
          mutedAt.isAcceptableOrUnknown(data['muted_at']!, _mutedAtMeta));
    } else if (isInserting) {
      context.missing(_mutedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {sessionAddress, accountAddress, listId, recordKey},
      ];
  @override
  MutedChannel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MutedChannel(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sessionAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}session_address'])!,
      accountAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}account_address'])!,
      listId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}list_id'])!,
      recordKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}record_key'])!,
      mutedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}muted_at'])!,
    );
  }

  @override
  $MutedChannelsTable createAlias(String alias) {
    return $MutedChannelsTable(attachedDatabase, alias);
  }
}

class MutedChannel extends DataClass implements Insertable<MutedChannel> {
  final int id;
  final String sessionAddress;
  final String accountAddress;
  final int listId;
  final String recordKey;
  final int mutedAt;
  const MutedChannel(
      {required this.id,
      required this.sessionAddress,
      required this.accountAddress,
      required this.listId,
      required this.recordKey,
      required this.mutedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_address'] = Variable<String>(sessionAddress);
    map['account_address'] = Variable<String>(accountAddress);
    map['list_id'] = Variable<int>(listId);
    map['record_key'] = Variable<String>(recordKey);
    map['muted_at'] = Variable<int>(mutedAt);
    return map;
  }

  MutedChannelsCompanion toCompanion(bool nullToAbsent) {
    return MutedChannelsCompanion(
      id: Value(id),
      sessionAddress: Value(sessionAddress),
      accountAddress: Value(accountAddress),
      listId: Value(listId),
      recordKey: Value(recordKey),
      mutedAt: Value(mutedAt),
    );
  }

  factory MutedChannel.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MutedChannel(
      id: serializer.fromJson<int>(json['id']),
      sessionAddress: serializer.fromJson<String>(json['sessionAddress']),
      accountAddress: serializer.fromJson<String>(json['accountAddress']),
      listId: serializer.fromJson<int>(json['listId']),
      recordKey: serializer.fromJson<String>(json['recordKey']),
      mutedAt: serializer.fromJson<int>(json['mutedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionAddress': serializer.toJson<String>(sessionAddress),
      'accountAddress': serializer.toJson<String>(accountAddress),
      'listId': serializer.toJson<int>(listId),
      'recordKey': serializer.toJson<String>(recordKey),
      'mutedAt': serializer.toJson<int>(mutedAt),
    };
  }

  MutedChannel copyWith(
          {int? id,
          String? sessionAddress,
          String? accountAddress,
          int? listId,
          String? recordKey,
          int? mutedAt}) =>
      MutedChannel(
        id: id ?? this.id,
        sessionAddress: sessionAddress ?? this.sessionAddress,
        accountAddress: accountAddress ?? this.accountAddress,
        listId: listId ?? this.listId,
        recordKey: recordKey ?? this.recordKey,
        mutedAt: mutedAt ?? this.mutedAt,
      );
  MutedChannel copyWithCompanion(MutedChannelsCompanion data) {
    return MutedChannel(
      id: data.id.present ? data.id.value : this.id,
      sessionAddress: data.sessionAddress.present
          ? data.sessionAddress.value
          : this.sessionAddress,
      accountAddress: data.accountAddress.present
          ? data.accountAddress.value
          : this.accountAddress,
      listId: data.listId.present ? data.listId.value : this.listId,
      recordKey: data.recordKey.present ? data.recordKey.value : this.recordKey,
      mutedAt: data.mutedAt.present ? data.mutedAt.value : this.mutedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MutedChannel(')
          ..write('id: $id, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('accountAddress: $accountAddress, ')
          ..write('listId: $listId, ')
          ..write('recordKey: $recordKey, ')
          ..write('mutedAt: $mutedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, sessionAddress, accountAddress, listId, recordKey, mutedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MutedChannel &&
          other.id == this.id &&
          other.sessionAddress == this.sessionAddress &&
          other.accountAddress == this.accountAddress &&
          other.listId == this.listId &&
          other.recordKey == this.recordKey &&
          other.mutedAt == this.mutedAt);
}

class MutedChannelsCompanion extends UpdateCompanion<MutedChannel> {
  final Value<int> id;
  final Value<String> sessionAddress;
  final Value<String> accountAddress;
  final Value<int> listId;
  final Value<String> recordKey;
  final Value<int> mutedAt;
  const MutedChannelsCompanion({
    this.id = const Value.absent(),
    this.sessionAddress = const Value.absent(),
    this.accountAddress = const Value.absent(),
    this.listId = const Value.absent(),
    this.recordKey = const Value.absent(),
    this.mutedAt = const Value.absent(),
  });
  MutedChannelsCompanion.insert({
    this.id = const Value.absent(),
    required String sessionAddress,
    required String accountAddress,
    required int listId,
    required String recordKey,
    required int mutedAt,
  })  : sessionAddress = Value(sessionAddress),
        accountAddress = Value(accountAddress),
        listId = Value(listId),
        recordKey = Value(recordKey),
        mutedAt = Value(mutedAt);
  static Insertable<MutedChannel> custom({
    Expression<int>? id,
    Expression<String>? sessionAddress,
    Expression<String>? accountAddress,
    Expression<int>? listId,
    Expression<String>? recordKey,
    Expression<int>? mutedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionAddress != null) 'session_address': sessionAddress,
      if (accountAddress != null) 'account_address': accountAddress,
      if (listId != null) 'list_id': listId,
      if (recordKey != null) 'record_key': recordKey,
      if (mutedAt != null) 'muted_at': mutedAt,
    });
  }

  MutedChannelsCompanion copyWith(
      {Value<int>? id,
      Value<String>? sessionAddress,
      Value<String>? accountAddress,
      Value<int>? listId,
      Value<String>? recordKey,
      Value<int>? mutedAt}) {
    return MutedChannelsCompanion(
      id: id ?? this.id,
      sessionAddress: sessionAddress ?? this.sessionAddress,
      accountAddress: accountAddress ?? this.accountAddress,
      listId: listId ?? this.listId,
      recordKey: recordKey ?? this.recordKey,
      mutedAt: mutedAt ?? this.mutedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionAddress.present) {
      map['session_address'] = Variable<String>(sessionAddress.value);
    }
    if (accountAddress.present) {
      map['account_address'] = Variable<String>(accountAddress.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<int>(listId.value);
    }
    if (recordKey.present) {
      map['record_key'] = Variable<String>(recordKey.value);
    }
    if (mutedAt.present) {
      map['muted_at'] = Variable<int>(mutedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MutedChannelsCompanion(')
          ..write('id: $id, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('accountAddress: $accountAddress, ')
          ..write('listId: $listId, ')
          ..write('recordKey: $recordKey, ')
          ..write('mutedAt: $mutedAt')
          ..write(')'))
        .toString();
  }
}

class $ChannelSigninPrefsTable extends ChannelSigninPrefs
    with TableInfo<$ChannelSigninPrefsTable, ChannelSigninPref> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelSigninPrefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _feedUrlMeta =
      const VerificationMeta('feedUrl');
  @override
  late final GeneratedColumn<String> feedUrl = GeneratedColumn<String>(
      'feed_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionAddressMeta =
      const VerificationMeta('sessionAddress');
  @override
  late final GeneratedColumn<String> sessionAddress = GeneratedColumn<String>(
      'session_address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _decisionMeta =
      const VerificationMeta('decision');
  @override
  late final GeneratedColumn<String> decision = GeneratedColumn<String>(
      'decision', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
      'mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('optional'));
  static const VerificationMeta _discoveredAtMeta =
      const VerificationMeta('discoveredAt');
  @override
  late final GeneratedColumn<int> discoveredAt = GeneratedColumn<int>(
      'discovered_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [feedUrl, sessionAddress, decision, mode, discoveredAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channel_signin_prefs';
  @override
  VerificationContext validateIntegrity(Insertable<ChannelSigninPref> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('feed_url')) {
      context.handle(_feedUrlMeta,
          feedUrl.isAcceptableOrUnknown(data['feed_url']!, _feedUrlMeta));
    } else if (isInserting) {
      context.missing(_feedUrlMeta);
    }
    if (data.containsKey('session_address')) {
      context.handle(
          _sessionAddressMeta,
          sessionAddress.isAcceptableOrUnknown(
              data['session_address']!, _sessionAddressMeta));
    } else if (isInserting) {
      context.missing(_sessionAddressMeta);
    }
    if (data.containsKey('decision')) {
      context.handle(_decisionMeta,
          decision.isAcceptableOrUnknown(data['decision']!, _decisionMeta));
    }
    if (data.containsKey('mode')) {
      context.handle(
          _modeMeta, mode.isAcceptableOrUnknown(data['mode']!, _modeMeta));
    }
    if (data.containsKey('discovered_at')) {
      context.handle(
          _discoveredAtMeta,
          discoveredAt.isAcceptableOrUnknown(
              data['discovered_at']!, _discoveredAtMeta));
    } else if (isInserting) {
      context.missing(_discoveredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {feedUrl, sessionAddress};
  @override
  ChannelSigninPref map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChannelSigninPref(
      feedUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}feed_url'])!,
      sessionAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}session_address'])!,
      decision: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}decision']),
      mode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mode'])!,
      discoveredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}discovered_at'])!,
    );
  }

  @override
  $ChannelSigninPrefsTable createAlias(String alias) {
    return $ChannelSigninPrefsTable(attachedDatabase, alias);
  }
}

class ChannelSigninPref extends DataClass
    implements Insertable<ChannelSigninPref> {
  /// The CHANNEL BASE URL — `<server>/api/<owner>/channels/<slug>` — never a
  /// feed / post / comments URL (every reader normalises with
  /// `channelBaseOf` first). Column name kept across the v31 migration.
  final String feedUrl;

  /// House convention for per-user rows — see [FeedCache.sessionAddress].
  final String sessionAddress;

  /// The user's answer: null = not answered · `accepted` · `denied`. Written
  /// ONLY by the user's three actions (Allow / Deny / Forget) — a fetch never
  /// touches it. Replaced `enabled: bool` in v31 (true → accepted, false →
  /// null: the old bool could not tell "never asked" from "declined").
  final String? decision;

  /// The signalled mode as last seen: `optional` (public channel, sign-in is
  /// a choice) or `required` (gated — the dialog's copy).
  final String mode;
  final int discoveredAt;
  const ChannelSigninPref(
      {required this.feedUrl,
      required this.sessionAddress,
      this.decision,
      required this.mode,
      required this.discoveredAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['feed_url'] = Variable<String>(feedUrl);
    map['session_address'] = Variable<String>(sessionAddress);
    if (!nullToAbsent || decision != null) {
      map['decision'] = Variable<String>(decision);
    }
    map['mode'] = Variable<String>(mode);
    map['discovered_at'] = Variable<int>(discoveredAt);
    return map;
  }

  ChannelSigninPrefsCompanion toCompanion(bool nullToAbsent) {
    return ChannelSigninPrefsCompanion(
      feedUrl: Value(feedUrl),
      sessionAddress: Value(sessionAddress),
      decision: decision == null && nullToAbsent
          ? const Value.absent()
          : Value(decision),
      mode: Value(mode),
      discoveredAt: Value(discoveredAt),
    );
  }

  factory ChannelSigninPref.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChannelSigninPref(
      feedUrl: serializer.fromJson<String>(json['feedUrl']),
      sessionAddress: serializer.fromJson<String>(json['sessionAddress']),
      decision: serializer.fromJson<String?>(json['decision']),
      mode: serializer.fromJson<String>(json['mode']),
      discoveredAt: serializer.fromJson<int>(json['discoveredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'feedUrl': serializer.toJson<String>(feedUrl),
      'sessionAddress': serializer.toJson<String>(sessionAddress),
      'decision': serializer.toJson<String?>(decision),
      'mode': serializer.toJson<String>(mode),
      'discoveredAt': serializer.toJson<int>(discoveredAt),
    };
  }

  ChannelSigninPref copyWith(
          {String? feedUrl,
          String? sessionAddress,
          Value<String?> decision = const Value.absent(),
          String? mode,
          int? discoveredAt}) =>
      ChannelSigninPref(
        feedUrl: feedUrl ?? this.feedUrl,
        sessionAddress: sessionAddress ?? this.sessionAddress,
        decision: decision.present ? decision.value : this.decision,
        mode: mode ?? this.mode,
        discoveredAt: discoveredAt ?? this.discoveredAt,
      );
  ChannelSigninPref copyWithCompanion(ChannelSigninPrefsCompanion data) {
    return ChannelSigninPref(
      feedUrl: data.feedUrl.present ? data.feedUrl.value : this.feedUrl,
      sessionAddress: data.sessionAddress.present
          ? data.sessionAddress.value
          : this.sessionAddress,
      decision: data.decision.present ? data.decision.value : this.decision,
      mode: data.mode.present ? data.mode.value : this.mode,
      discoveredAt: data.discoveredAt.present
          ? data.discoveredAt.value
          : this.discoveredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChannelSigninPref(')
          ..write('feedUrl: $feedUrl, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('decision: $decision, ')
          ..write('mode: $mode, ')
          ..write('discoveredAt: $discoveredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(feedUrl, sessionAddress, decision, mode, discoveredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChannelSigninPref &&
          other.feedUrl == this.feedUrl &&
          other.sessionAddress == this.sessionAddress &&
          other.decision == this.decision &&
          other.mode == this.mode &&
          other.discoveredAt == this.discoveredAt);
}

class ChannelSigninPrefsCompanion extends UpdateCompanion<ChannelSigninPref> {
  final Value<String> feedUrl;
  final Value<String> sessionAddress;
  final Value<String?> decision;
  final Value<String> mode;
  final Value<int> discoveredAt;
  final Value<int> rowid;
  const ChannelSigninPrefsCompanion({
    this.feedUrl = const Value.absent(),
    this.sessionAddress = const Value.absent(),
    this.decision = const Value.absent(),
    this.mode = const Value.absent(),
    this.discoveredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChannelSigninPrefsCompanion.insert({
    required String feedUrl,
    required String sessionAddress,
    this.decision = const Value.absent(),
    this.mode = const Value.absent(),
    required int discoveredAt,
    this.rowid = const Value.absent(),
  })  : feedUrl = Value(feedUrl),
        sessionAddress = Value(sessionAddress),
        discoveredAt = Value(discoveredAt);
  static Insertable<ChannelSigninPref> custom({
    Expression<String>? feedUrl,
    Expression<String>? sessionAddress,
    Expression<String>? decision,
    Expression<String>? mode,
    Expression<int>? discoveredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (feedUrl != null) 'feed_url': feedUrl,
      if (sessionAddress != null) 'session_address': sessionAddress,
      if (decision != null) 'decision': decision,
      if (mode != null) 'mode': mode,
      if (discoveredAt != null) 'discovered_at': discoveredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChannelSigninPrefsCompanion copyWith(
      {Value<String>? feedUrl,
      Value<String>? sessionAddress,
      Value<String?>? decision,
      Value<String>? mode,
      Value<int>? discoveredAt,
      Value<int>? rowid}) {
    return ChannelSigninPrefsCompanion(
      feedUrl: feedUrl ?? this.feedUrl,
      sessionAddress: sessionAddress ?? this.sessionAddress,
      decision: decision ?? this.decision,
      mode: mode ?? this.mode,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (feedUrl.present) {
      map['feed_url'] = Variable<String>(feedUrl.value);
    }
    if (sessionAddress.present) {
      map['session_address'] = Variable<String>(sessionAddress.value);
    }
    if (decision.present) {
      map['decision'] = Variable<String>(decision.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (discoveredAt.present) {
      map['discovered_at'] = Variable<int>(discoveredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChannelSigninPrefsCompanion(')
          ..write('feedUrl: $feedUrl, ')
          ..write('sessionAddress: $sessionAddress, ')
          ..write('decision: $decision, ')
          ..write('mode: $mode, ')
          ..write('discoveredAt: $discoveredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $ContactsTable contacts = $ContactsTable(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $FeedServersTable feedServers = $FeedServersTable(this);
  late final $RpcServersTable rpcServers = $RpcServersTable(this);
  late final $FeedListsTable feedLists = $FeedListsTable(this);
  late final $ListFeedsTable listFeeds = $ListFeedsTable(this);
  late final $FeedCacheTable feedCache = $FeedCacheTable(this);
  late final $AttachmentCacheTable attachmentCache =
      $AttachmentCacheTable(this);
  late final $BookmarkedAppsTable bookmarkedApps = $BookmarkedAppsTable(this);
  late final $BookmarkedPostsTable bookmarkedPosts =
      $BookmarkedPostsTable(this);
  late final $ActivityEventsTable activityEvents = $ActivityEventsTable(this);
  late final $SavedStickersTable savedStickers = $SavedStickersTable(this);
  late final $ConnectedSitesTable connectedSites = $ConnectedSitesTable(this);
  late final $FollowedAccountsTable followedAccounts =
      $FollowedAccountsTable(this);
  late final $MutedChannelsTable mutedChannels = $MutedChannelsTable(this);
  late final $ChannelSigninPrefsTable channelSigninPrefs =
      $ChannelSigninPrefsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        messages,
        contacts,
        conversations,
        settings,
        feedServers,
        rpcServers,
        feedLists,
        listFeeds,
        feedCache,
        attachmentCache,
        bookmarkedApps,
        bookmarkedPosts,
        activityEvents,
        savedStickers,
        connectedSites,
        followedAccounts,
        mutedChannels,
        channelSigninPrefs
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('feed_lists',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('list_feeds', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('feed_lists',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('followed_accounts', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('feed_lists',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('muted_channels', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$MessagesTableCreateCompanionBuilder = MessagesCompanion Function({
  Value<int> id,
  Value<String?> idXmtp,
  required String xmtpMessageData,
  required int timestamp,
  required String conversationTopic,
  Value<String?> senderInboxId,
  required String sessionAddress,
  required String ownerInboxId,
  Value<String?> typeId,
  Value<bool> isPending,
  Value<bool> sendFailed,
  Value<bool> isRead,
});
typedef $$MessagesTableUpdateCompanionBuilder = MessagesCompanion Function({
  Value<int> id,
  Value<String?> idXmtp,
  Value<String> xmtpMessageData,
  Value<int> timestamp,
  Value<String> conversationTopic,
  Value<String?> senderInboxId,
  Value<String> sessionAddress,
  Value<String> ownerInboxId,
  Value<String?> typeId,
  Value<bool> isPending,
  Value<bool> sendFailed,
  Value<bool> isRead,
});

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get idXmtp => $composableBuilder(
      column: $table.idXmtp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get xmtpMessageData => $composableBuilder(
      column: $table.xmtpMessageData,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get conversationTopic => $composableBuilder(
      column: $table.conversationTopic,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get senderInboxId => $composableBuilder(
      column: $table.senderInboxId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerInboxId => $composableBuilder(
      column: $table.ownerInboxId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get typeId => $composableBuilder(
      column: $table.typeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPending => $composableBuilder(
      column: $table.isPending, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get sendFailed => $composableBuilder(
      column: $table.sendFailed, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnFilters(column));
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get idXmtp => $composableBuilder(
      column: $table.idXmtp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get xmtpMessageData => $composableBuilder(
      column: $table.xmtpMessageData,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get conversationTopic => $composableBuilder(
      column: $table.conversationTopic,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get senderInboxId => $composableBuilder(
      column: $table.senderInboxId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerInboxId => $composableBuilder(
      column: $table.ownerInboxId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get typeId => $composableBuilder(
      column: $table.typeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPending => $composableBuilder(
      column: $table.isPending, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get sendFailed => $composableBuilder(
      column: $table.sendFailed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnOrderings(column));
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get idXmtp =>
      $composableBuilder(column: $table.idXmtp, builder: (column) => column);

  GeneratedColumn<String> get xmtpMessageData => $composableBuilder(
      column: $table.xmtpMessageData, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get conversationTopic => $composableBuilder(
      column: $table.conversationTopic, builder: (column) => column);

  GeneratedColumn<String> get senderInboxId => $composableBuilder(
      column: $table.senderInboxId, builder: (column) => column);

  GeneratedColumn<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress, builder: (column) => column);

  GeneratedColumn<String> get ownerInboxId => $composableBuilder(
      column: $table.ownerInboxId, builder: (column) => column);

  GeneratedColumn<String> get typeId =>
      $composableBuilder(column: $table.typeId, builder: (column) => column);

  GeneratedColumn<bool> get isPending =>
      $composableBuilder(column: $table.isPending, builder: (column) => column);

  GeneratedColumn<bool> get sendFailed => $composableBuilder(
      column: $table.sendFailed, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);
}

class $$MessagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MessagesTable,
    Message,
    $$MessagesTableFilterComposer,
    $$MessagesTableOrderingComposer,
    $$MessagesTableAnnotationComposer,
    $$MessagesTableCreateCompanionBuilder,
    $$MessagesTableUpdateCompanionBuilder,
    (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
    Message,
    PrefetchHooks Function()> {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> idXmtp = const Value.absent(),
            Value<String> xmtpMessageData = const Value.absent(),
            Value<int> timestamp = const Value.absent(),
            Value<String> conversationTopic = const Value.absent(),
            Value<String?> senderInboxId = const Value.absent(),
            Value<String> sessionAddress = const Value.absent(),
            Value<String> ownerInboxId = const Value.absent(),
            Value<String?> typeId = const Value.absent(),
            Value<bool> isPending = const Value.absent(),
            Value<bool> sendFailed = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
          }) =>
              MessagesCompanion(
            id: id,
            idXmtp: idXmtp,
            xmtpMessageData: xmtpMessageData,
            timestamp: timestamp,
            conversationTopic: conversationTopic,
            senderInboxId: senderInboxId,
            sessionAddress: sessionAddress,
            ownerInboxId: ownerInboxId,
            typeId: typeId,
            isPending: isPending,
            sendFailed: sendFailed,
            isRead: isRead,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> idXmtp = const Value.absent(),
            required String xmtpMessageData,
            required int timestamp,
            required String conversationTopic,
            Value<String?> senderInboxId = const Value.absent(),
            required String sessionAddress,
            required String ownerInboxId,
            Value<String?> typeId = const Value.absent(),
            Value<bool> isPending = const Value.absent(),
            Value<bool> sendFailed = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
          }) =>
              MessagesCompanion.insert(
            id: id,
            idXmtp: idXmtp,
            xmtpMessageData: xmtpMessageData,
            timestamp: timestamp,
            conversationTopic: conversationTopic,
            senderInboxId: senderInboxId,
            sessionAddress: sessionAddress,
            ownerInboxId: ownerInboxId,
            typeId: typeId,
            isPending: isPending,
            sendFailed: sendFailed,
            isRead: isRead,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MessagesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MessagesTable,
    Message,
    $$MessagesTableFilterComposer,
    $$MessagesTableOrderingComposer,
    $$MessagesTableAnnotationComposer,
    $$MessagesTableCreateCompanionBuilder,
    $$MessagesTableUpdateCompanionBuilder,
    (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
    Message,
    PrefetchHooks Function()>;
typedef $$ContactsTableCreateCompanionBuilder = ContactsCompanion Function({
  Value<int> id,
  Value<String?> publicosDisplayName,
  Value<String?> publicosAddress,
  required String displayName,
  Value<bool> isOrgAccount,
  Value<String?> sessions,
  Value<String?> records,
  Value<String?> registeredInboxIDs,
  Value<String?> orgMembers,
  Value<int?> orgMemberCount,
  Value<bool> isBlocked,
  Value<bool> isSupport,
  Value<String?> createdBy,
  Value<String?> founderAddress,
  Value<String?> createdAt,
  required int updatedAt,
  required String sessionAddress,
  Value<String?> xmtpConversationTopic,
  Value<bool?> isCitizen,
  Value<bool?> isPublicOrg,
  Value<String?> verifiedNftAvatar,
  Value<String?> verifiedNftBanner,
  Value<bool> bookmarked,
});
typedef $$ContactsTableUpdateCompanionBuilder = ContactsCompanion Function({
  Value<int> id,
  Value<String?> publicosDisplayName,
  Value<String?> publicosAddress,
  Value<String> displayName,
  Value<bool> isOrgAccount,
  Value<String?> sessions,
  Value<String?> records,
  Value<String?> registeredInboxIDs,
  Value<String?> orgMembers,
  Value<int?> orgMemberCount,
  Value<bool> isBlocked,
  Value<bool> isSupport,
  Value<String?> createdBy,
  Value<String?> founderAddress,
  Value<String?> createdAt,
  Value<int> updatedAt,
  Value<String> sessionAddress,
  Value<String?> xmtpConversationTopic,
  Value<bool?> isCitizen,
  Value<bool?> isPublicOrg,
  Value<String?> verifiedNftAvatar,
  Value<String?> verifiedNftBanner,
  Value<bool> bookmarked,
});

class $$ContactsTableFilterComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get publicosDisplayName => $composableBuilder(
      column: $table.publicosDisplayName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get publicosAddress => $composableBuilder(
      column: $table.publicosAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isOrgAccount => $composableBuilder(
      column: $table.isOrgAccount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessions => $composableBuilder(
      column: $table.sessions, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get records => $composableBuilder(
      column: $table.records, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get registeredInboxIDs => $composableBuilder(
      column: $table.registeredInboxIDs,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orgMembers => $composableBuilder(
      column: $table.orgMembers, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orgMemberCount => $composableBuilder(
      column: $table.orgMemberCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isBlocked => $composableBuilder(
      column: $table.isBlocked, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSupport => $composableBuilder(
      column: $table.isSupport, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get founderAddress => $composableBuilder(
      column: $table.founderAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get xmtpConversationTopic => $composableBuilder(
      column: $table.xmtpConversationTopic,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCitizen => $composableBuilder(
      column: $table.isCitizen, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPublicOrg => $composableBuilder(
      column: $table.isPublicOrg, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get verifiedNftAvatar => $composableBuilder(
      column: $table.verifiedNftAvatar,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get verifiedNftBanner => $composableBuilder(
      column: $table.verifiedNftBanner,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get bookmarked => $composableBuilder(
      column: $table.bookmarked, builder: (column) => ColumnFilters(column));
}

class $$ContactsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get publicosDisplayName => $composableBuilder(
      column: $table.publicosDisplayName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get publicosAddress => $composableBuilder(
      column: $table.publicosAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isOrgAccount => $composableBuilder(
      column: $table.isOrgAccount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessions => $composableBuilder(
      column: $table.sessions, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get records => $composableBuilder(
      column: $table.records, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get registeredInboxIDs => $composableBuilder(
      column: $table.registeredInboxIDs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orgMembers => $composableBuilder(
      column: $table.orgMembers, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orgMemberCount => $composableBuilder(
      column: $table.orgMemberCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isBlocked => $composableBuilder(
      column: $table.isBlocked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSupport => $composableBuilder(
      column: $table.isSupport, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get founderAddress => $composableBuilder(
      column: $table.founderAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get xmtpConversationTopic => $composableBuilder(
      column: $table.xmtpConversationTopic,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCitizen => $composableBuilder(
      column: $table.isCitizen, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPublicOrg => $composableBuilder(
      column: $table.isPublicOrg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get verifiedNftAvatar => $composableBuilder(
      column: $table.verifiedNftAvatar,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get verifiedNftBanner => $composableBuilder(
      column: $table.verifiedNftBanner,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get bookmarked => $composableBuilder(
      column: $table.bookmarked, builder: (column) => ColumnOrderings(column));
}

class $$ContactsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get publicosDisplayName => $composableBuilder(
      column: $table.publicosDisplayName, builder: (column) => column);

  GeneratedColumn<String> get publicosAddress => $composableBuilder(
      column: $table.publicosAddress, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<bool> get isOrgAccount => $composableBuilder(
      column: $table.isOrgAccount, builder: (column) => column);

  GeneratedColumn<String> get sessions =>
      $composableBuilder(column: $table.sessions, builder: (column) => column);

  GeneratedColumn<String> get records =>
      $composableBuilder(column: $table.records, builder: (column) => column);

  GeneratedColumn<String> get registeredInboxIDs => $composableBuilder(
      column: $table.registeredInboxIDs, builder: (column) => column);

  GeneratedColumn<String> get orgMembers => $composableBuilder(
      column: $table.orgMembers, builder: (column) => column);

  GeneratedColumn<int> get orgMemberCount => $composableBuilder(
      column: $table.orgMemberCount, builder: (column) => column);

  GeneratedColumn<bool> get isBlocked =>
      $composableBuilder(column: $table.isBlocked, builder: (column) => column);

  GeneratedColumn<bool> get isSupport =>
      $composableBuilder(column: $table.isSupport, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get founderAddress => $composableBuilder(
      column: $table.founderAddress, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress, builder: (column) => column);

  GeneratedColumn<String> get xmtpConversationTopic => $composableBuilder(
      column: $table.xmtpConversationTopic, builder: (column) => column);

  GeneratedColumn<bool> get isCitizen =>
      $composableBuilder(column: $table.isCitizen, builder: (column) => column);

  GeneratedColumn<bool> get isPublicOrg => $composableBuilder(
      column: $table.isPublicOrg, builder: (column) => column);

  GeneratedColumn<String> get verifiedNftAvatar => $composableBuilder(
      column: $table.verifiedNftAvatar, builder: (column) => column);

  GeneratedColumn<String> get verifiedNftBanner => $composableBuilder(
      column: $table.verifiedNftBanner, builder: (column) => column);

  GeneratedColumn<bool> get bookmarked => $composableBuilder(
      column: $table.bookmarked, builder: (column) => column);
}

class $$ContactsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ContactsTable,
    Contact,
    $$ContactsTableFilterComposer,
    $$ContactsTableOrderingComposer,
    $$ContactsTableAnnotationComposer,
    $$ContactsTableCreateCompanionBuilder,
    $$ContactsTableUpdateCompanionBuilder,
    (Contact, BaseReferences<_$AppDatabase, $ContactsTable, Contact>),
    Contact,
    PrefetchHooks Function()> {
  $$ContactsTableTableManager(_$AppDatabase db, $ContactsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> publicosDisplayName = const Value.absent(),
            Value<String?> publicosAddress = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<bool> isOrgAccount = const Value.absent(),
            Value<String?> sessions = const Value.absent(),
            Value<String?> records = const Value.absent(),
            Value<String?> registeredInboxIDs = const Value.absent(),
            Value<String?> orgMembers = const Value.absent(),
            Value<int?> orgMemberCount = const Value.absent(),
            Value<bool> isBlocked = const Value.absent(),
            Value<bool> isSupport = const Value.absent(),
            Value<String?> createdBy = const Value.absent(),
            Value<String?> founderAddress = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<String> sessionAddress = const Value.absent(),
            Value<String?> xmtpConversationTopic = const Value.absent(),
            Value<bool?> isCitizen = const Value.absent(),
            Value<bool?> isPublicOrg = const Value.absent(),
            Value<String?> verifiedNftAvatar = const Value.absent(),
            Value<String?> verifiedNftBanner = const Value.absent(),
            Value<bool> bookmarked = const Value.absent(),
          }) =>
              ContactsCompanion(
            id: id,
            publicosDisplayName: publicosDisplayName,
            publicosAddress: publicosAddress,
            displayName: displayName,
            isOrgAccount: isOrgAccount,
            sessions: sessions,
            records: records,
            registeredInboxIDs: registeredInboxIDs,
            orgMembers: orgMembers,
            orgMemberCount: orgMemberCount,
            isBlocked: isBlocked,
            isSupport: isSupport,
            createdBy: createdBy,
            founderAddress: founderAddress,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sessionAddress: sessionAddress,
            xmtpConversationTopic: xmtpConversationTopic,
            isCitizen: isCitizen,
            isPublicOrg: isPublicOrg,
            verifiedNftAvatar: verifiedNftAvatar,
            verifiedNftBanner: verifiedNftBanner,
            bookmarked: bookmarked,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> publicosDisplayName = const Value.absent(),
            Value<String?> publicosAddress = const Value.absent(),
            required String displayName,
            Value<bool> isOrgAccount = const Value.absent(),
            Value<String?> sessions = const Value.absent(),
            Value<String?> records = const Value.absent(),
            Value<String?> registeredInboxIDs = const Value.absent(),
            Value<String?> orgMembers = const Value.absent(),
            Value<int?> orgMemberCount = const Value.absent(),
            Value<bool> isBlocked = const Value.absent(),
            Value<bool> isSupport = const Value.absent(),
            Value<String?> createdBy = const Value.absent(),
            Value<String?> founderAddress = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
            required int updatedAt,
            required String sessionAddress,
            Value<String?> xmtpConversationTopic = const Value.absent(),
            Value<bool?> isCitizen = const Value.absent(),
            Value<bool?> isPublicOrg = const Value.absent(),
            Value<String?> verifiedNftAvatar = const Value.absent(),
            Value<String?> verifiedNftBanner = const Value.absent(),
            Value<bool> bookmarked = const Value.absent(),
          }) =>
              ContactsCompanion.insert(
            id: id,
            publicosDisplayName: publicosDisplayName,
            publicosAddress: publicosAddress,
            displayName: displayName,
            isOrgAccount: isOrgAccount,
            sessions: sessions,
            records: records,
            registeredInboxIDs: registeredInboxIDs,
            orgMembers: orgMembers,
            orgMemberCount: orgMemberCount,
            isBlocked: isBlocked,
            isSupport: isSupport,
            createdBy: createdBy,
            founderAddress: founderAddress,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sessionAddress: sessionAddress,
            xmtpConversationTopic: xmtpConversationTopic,
            isCitizen: isCitizen,
            isPublicOrg: isPublicOrg,
            verifiedNftAvatar: verifiedNftAvatar,
            verifiedNftBanner: verifiedNftBanner,
            bookmarked: bookmarked,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ContactsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ContactsTable,
    Contact,
    $$ContactsTableFilterComposer,
    $$ContactsTableOrderingComposer,
    $$ContactsTableAnnotationComposer,
    $$ContactsTableCreateCompanionBuilder,
    $$ContactsTableUpdateCompanionBuilder,
    (Contact, BaseReferences<_$AppDatabase, $ContactsTable, Contact>),
    Contact,
    PrefetchHooks Function()>;
typedef $$ConversationsTableCreateCompanionBuilder = ConversationsCompanion
    Function({
  required String topic,
  required String type,
  Value<String?> peerInboxId,
  Value<String?> groupName,
  Value<String?> groupImageUrl,
  Value<String?> groupDescription,
  Value<String?> pinnedFrameUrl,
  Value<String?> membersJson,
  Value<int?> createdAt,
  required String sessionAddress,
  required String ownerInboxId,
  Value<int> rowid,
});
typedef $$ConversationsTableUpdateCompanionBuilder = ConversationsCompanion
    Function({
  Value<String> topic,
  Value<String> type,
  Value<String?> peerInboxId,
  Value<String?> groupName,
  Value<String?> groupImageUrl,
  Value<String?> groupDescription,
  Value<String?> pinnedFrameUrl,
  Value<String?> membersJson,
  Value<int?> createdAt,
  Value<String> sessionAddress,
  Value<String> ownerInboxId,
  Value<int> rowid,
});

class $$ConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get topic => $composableBuilder(
      column: $table.topic, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get peerInboxId => $composableBuilder(
      column: $table.peerInboxId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupName => $composableBuilder(
      column: $table.groupName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupImageUrl => $composableBuilder(
      column: $table.groupImageUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupDescription => $composableBuilder(
      column: $table.groupDescription,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pinnedFrameUrl => $composableBuilder(
      column: $table.pinnedFrameUrl,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get membersJson => $composableBuilder(
      column: $table.membersJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerInboxId => $composableBuilder(
      column: $table.ownerInboxId, builder: (column) => ColumnFilters(column));
}

class $$ConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get topic => $composableBuilder(
      column: $table.topic, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get peerInboxId => $composableBuilder(
      column: $table.peerInboxId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupName => $composableBuilder(
      column: $table.groupName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupImageUrl => $composableBuilder(
      column: $table.groupImageUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupDescription => $composableBuilder(
      column: $table.groupDescription,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pinnedFrameUrl => $composableBuilder(
      column: $table.pinnedFrameUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get membersJson => $composableBuilder(
      column: $table.membersJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerInboxId => $composableBuilder(
      column: $table.ownerInboxId,
      builder: (column) => ColumnOrderings(column));
}

class $$ConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get peerInboxId => $composableBuilder(
      column: $table.peerInboxId, builder: (column) => column);

  GeneratedColumn<String> get groupName =>
      $composableBuilder(column: $table.groupName, builder: (column) => column);

  GeneratedColumn<String> get groupImageUrl => $composableBuilder(
      column: $table.groupImageUrl, builder: (column) => column);

  GeneratedColumn<String> get groupDescription => $composableBuilder(
      column: $table.groupDescription, builder: (column) => column);

  GeneratedColumn<String> get pinnedFrameUrl => $composableBuilder(
      column: $table.pinnedFrameUrl, builder: (column) => column);

  GeneratedColumn<String> get membersJson => $composableBuilder(
      column: $table.membersJson, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress, builder: (column) => column);

  GeneratedColumn<String> get ownerInboxId => $composableBuilder(
      column: $table.ownerInboxId, builder: (column) => column);
}

class $$ConversationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ConversationsTable,
    Conversation,
    $$ConversationsTableFilterComposer,
    $$ConversationsTableOrderingComposer,
    $$ConversationsTableAnnotationComposer,
    $$ConversationsTableCreateCompanionBuilder,
    $$ConversationsTableUpdateCompanionBuilder,
    (
      Conversation,
      BaseReferences<_$AppDatabase, $ConversationsTable, Conversation>
    ),
    Conversation,
    PrefetchHooks Function()> {
  $$ConversationsTableTableManager(_$AppDatabase db, $ConversationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> topic = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> peerInboxId = const Value.absent(),
            Value<String?> groupName = const Value.absent(),
            Value<String?> groupImageUrl = const Value.absent(),
            Value<String?> groupDescription = const Value.absent(),
            Value<String?> pinnedFrameUrl = const Value.absent(),
            Value<String?> membersJson = const Value.absent(),
            Value<int?> createdAt = const Value.absent(),
            Value<String> sessionAddress = const Value.absent(),
            Value<String> ownerInboxId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConversationsCompanion(
            topic: topic,
            type: type,
            peerInboxId: peerInboxId,
            groupName: groupName,
            groupImageUrl: groupImageUrl,
            groupDescription: groupDescription,
            pinnedFrameUrl: pinnedFrameUrl,
            membersJson: membersJson,
            createdAt: createdAt,
            sessionAddress: sessionAddress,
            ownerInboxId: ownerInboxId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String topic,
            required String type,
            Value<String?> peerInboxId = const Value.absent(),
            Value<String?> groupName = const Value.absent(),
            Value<String?> groupImageUrl = const Value.absent(),
            Value<String?> groupDescription = const Value.absent(),
            Value<String?> pinnedFrameUrl = const Value.absent(),
            Value<String?> membersJson = const Value.absent(),
            Value<int?> createdAt = const Value.absent(),
            required String sessionAddress,
            required String ownerInboxId,
            Value<int> rowid = const Value.absent(),
          }) =>
              ConversationsCompanion.insert(
            topic: topic,
            type: type,
            peerInboxId: peerInboxId,
            groupName: groupName,
            groupImageUrl: groupImageUrl,
            groupDescription: groupDescription,
            pinnedFrameUrl: pinnedFrameUrl,
            membersJson: membersJson,
            createdAt: createdAt,
            sessionAddress: sessionAddress,
            ownerInboxId: ownerInboxId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ConversationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ConversationsTable,
    Conversation,
    $$ConversationsTableFilterComposer,
    $$ConversationsTableOrderingComposer,
    $$ConversationsTableAnnotationComposer,
    $$ConversationsTableCreateCompanionBuilder,
    $$ConversationsTableUpdateCompanionBuilder,
    (
      Conversation,
      BaseReferences<_$AppDatabase, $ConversationsTable, Conversation>
    ),
    Conversation,
    PrefetchHooks Function()>;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  required String key,
  required String record,
  required String sessionAddress,
  required int updatedAt,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  Value<String> key,
  Value<String> record,
  Value<String> sessionAddress,
  Value<int> updatedAt,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get record => $composableBuilder(
      column: $table.record, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get record => $composableBuilder(
      column: $table.record, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get record =>
      $composableBuilder(column: $table.record, builder: (column) => column);

  GeneratedColumn<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()> {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> key = const Value.absent(),
            Value<String> record = const Value.absent(),
            Value<String> sessionAddress = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
          }) =>
              SettingsCompanion(
            id: id,
            key: key,
            record: record,
            sessionAddress: sessionAddress,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String key,
            required String record,
            required String sessionAddress,
            required int updatedAt,
          }) =>
              SettingsCompanion.insert(
            id: id,
            key: key,
            record: record,
            sessionAddress: sessionAddress,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()>;
typedef $$FeedServersTableCreateCompanionBuilder = FeedServersCompanion
    Function({
  Value<int> id,
  required String feedServerAddress,
  Value<String?> name,
  Value<bool> isDefault,
  required String sessionAddress,
  required int createdAt,
  required int updatedAt,
});
typedef $$FeedServersTableUpdateCompanionBuilder = FeedServersCompanion
    Function({
  Value<int> id,
  Value<String> feedServerAddress,
  Value<String?> name,
  Value<bool> isDefault,
  Value<String> sessionAddress,
  Value<int> createdAt,
  Value<int> updatedAt,
});

class $$FeedServersTableFilterComposer
    extends Composer<_$AppDatabase, $FeedServersTable> {
  $$FeedServersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get feedServerAddress => $composableBuilder(
      column: $table.feedServerAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$FeedServersTableOrderingComposer
    extends Composer<_$AppDatabase, $FeedServersTable> {
  $$FeedServersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get feedServerAddress => $composableBuilder(
      column: $table.feedServerAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$FeedServersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FeedServersTable> {
  $$FeedServersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get feedServerAddress => $composableBuilder(
      column: $table.feedServerAddress, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FeedServersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FeedServersTable,
    FeedServer,
    $$FeedServersTableFilterComposer,
    $$FeedServersTableOrderingComposer,
    $$FeedServersTableAnnotationComposer,
    $$FeedServersTableCreateCompanionBuilder,
    $$FeedServersTableUpdateCompanionBuilder,
    (FeedServer, BaseReferences<_$AppDatabase, $FeedServersTable, FeedServer>),
    FeedServer,
    PrefetchHooks Function()> {
  $$FeedServersTableTableManager(_$AppDatabase db, $FeedServersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FeedServersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FeedServersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FeedServersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> feedServerAddress = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<String> sessionAddress = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
          }) =>
              FeedServersCompanion(
            id: id,
            feedServerAddress: feedServerAddress,
            name: name,
            isDefault: isDefault,
            sessionAddress: sessionAddress,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String feedServerAddress,
            Value<String?> name = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            required String sessionAddress,
            required int createdAt,
            required int updatedAt,
          }) =>
              FeedServersCompanion.insert(
            id: id,
            feedServerAddress: feedServerAddress,
            name: name,
            isDefault: isDefault,
            sessionAddress: sessionAddress,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FeedServersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FeedServersTable,
    FeedServer,
    $$FeedServersTableFilterComposer,
    $$FeedServersTableOrderingComposer,
    $$FeedServersTableAnnotationComposer,
    $$FeedServersTableCreateCompanionBuilder,
    $$FeedServersTableUpdateCompanionBuilder,
    (FeedServer, BaseReferences<_$AppDatabase, $FeedServersTable, FeedServer>),
    FeedServer,
    PrefetchHooks Function()>;
typedef $$RpcServersTableCreateCompanionBuilder = RpcServersCompanion Function({
  Value<int> id,
  required String rpcUrl,
  Value<String?> name,
  Value<bool> isDefault,
  required String sessionAddress,
  required int createdAt,
  required int updatedAt,
});
typedef $$RpcServersTableUpdateCompanionBuilder = RpcServersCompanion Function({
  Value<int> id,
  Value<String> rpcUrl,
  Value<String?> name,
  Value<bool> isDefault,
  Value<String> sessionAddress,
  Value<int> createdAt,
  Value<int> updatedAt,
});

class $$RpcServersTableFilterComposer
    extends Composer<_$AppDatabase, $RpcServersTable> {
  $$RpcServersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rpcUrl => $composableBuilder(
      column: $table.rpcUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$RpcServersTableOrderingComposer
    extends Composer<_$AppDatabase, $RpcServersTable> {
  $$RpcServersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rpcUrl => $composableBuilder(
      column: $table.rpcUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$RpcServersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RpcServersTable> {
  $$RpcServersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rpcUrl =>
      $composableBuilder(column: $table.rpcUrl, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RpcServersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RpcServersTable,
    RpcServer,
    $$RpcServersTableFilterComposer,
    $$RpcServersTableOrderingComposer,
    $$RpcServersTableAnnotationComposer,
    $$RpcServersTableCreateCompanionBuilder,
    $$RpcServersTableUpdateCompanionBuilder,
    (RpcServer, BaseReferences<_$AppDatabase, $RpcServersTable, RpcServer>),
    RpcServer,
    PrefetchHooks Function()> {
  $$RpcServersTableTableManager(_$AppDatabase db, $RpcServersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RpcServersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RpcServersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RpcServersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> rpcUrl = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<String> sessionAddress = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
          }) =>
              RpcServersCompanion(
            id: id,
            rpcUrl: rpcUrl,
            name: name,
            isDefault: isDefault,
            sessionAddress: sessionAddress,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String rpcUrl,
            Value<String?> name = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            required String sessionAddress,
            required int createdAt,
            required int updatedAt,
          }) =>
              RpcServersCompanion.insert(
            id: id,
            rpcUrl: rpcUrl,
            name: name,
            isDefault: isDefault,
            sessionAddress: sessionAddress,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RpcServersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RpcServersTable,
    RpcServer,
    $$RpcServersTableFilterComposer,
    $$RpcServersTableOrderingComposer,
    $$RpcServersTableAnnotationComposer,
    $$RpcServersTableCreateCompanionBuilder,
    $$RpcServersTableUpdateCompanionBuilder,
    (RpcServer, BaseReferences<_$AppDatabase, $RpcServersTable, RpcServer>),
    RpcServer,
    PrefetchHooks Function()>;
typedef $$FeedListsTableCreateCompanionBuilder = FeedListsCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> icon,
  required String sessionAddress,
  required int createdAt,
  required int updatedAt,
  Value<bool> isSingle,
});
typedef $$FeedListsTableUpdateCompanionBuilder = FeedListsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> icon,
  Value<String> sessionAddress,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<bool> isSingle,
});

final class $$FeedListsTableReferences
    extends BaseReferences<_$AppDatabase, $FeedListsTable, FeedListData> {
  $$FeedListsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ListFeedsTable, List<ListFeed>>
      _listFeedsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.listFeeds,
              aliasName:
                  $_aliasNameGenerator(db.feedLists.id, db.listFeeds.listId));

  $$ListFeedsTableProcessedTableManager get listFeedsRefs {
    final manager = $$ListFeedsTableTableManager($_db, $_db.listFeeds)
        .filter((f) => f.listId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_listFeedsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$FollowedAccountsTable, List<FollowedAccount>>
      _followedAccountsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.followedAccounts,
              aliasName: $_aliasNameGenerator(
                  db.feedLists.id, db.followedAccounts.listId));

  $$FollowedAccountsTableProcessedTableManager get followedAccountsRefs {
    final manager =
        $$FollowedAccountsTableTableManager($_db, $_db.followedAccounts)
            .filter((f) => f.listId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_followedAccountsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$MutedChannelsTable, List<MutedChannel>>
      _mutedChannelsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.mutedChannels,
              aliasName: $_aliasNameGenerator(
                  db.feedLists.id, db.mutedChannels.listId));

  $$MutedChannelsTableProcessedTableManager get mutedChannelsRefs {
    final manager = $$MutedChannelsTableTableManager($_db, $_db.mutedChannels)
        .filter((f) => f.listId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_mutedChannelsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$FeedListsTableFilterComposer
    extends Composer<_$AppDatabase, $FeedListsTable> {
  $$FeedListsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSingle => $composableBuilder(
      column: $table.isSingle, builder: (column) => ColumnFilters(column));

  Expression<bool> listFeedsRefs(
      Expression<bool> Function($$ListFeedsTableFilterComposer f) f) {
    final $$ListFeedsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.listFeeds,
        getReferencedColumn: (t) => t.listId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ListFeedsTableFilterComposer(
              $db: $db,
              $table: $db.listFeeds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> followedAccountsRefs(
      Expression<bool> Function($$FollowedAccountsTableFilterComposer f) f) {
    final $$FollowedAccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.followedAccounts,
        getReferencedColumn: (t) => t.listId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FollowedAccountsTableFilterComposer(
              $db: $db,
              $table: $db.followedAccounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> mutedChannelsRefs(
      Expression<bool> Function($$MutedChannelsTableFilterComposer f) f) {
    final $$MutedChannelsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.mutedChannels,
        getReferencedColumn: (t) => t.listId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MutedChannelsTableFilterComposer(
              $db: $db,
              $table: $db.mutedChannels,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$FeedListsTableOrderingComposer
    extends Composer<_$AppDatabase, $FeedListsTable> {
  $$FeedListsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSingle => $composableBuilder(
      column: $table.isSingle, builder: (column) => ColumnOrderings(column));
}

class $$FeedListsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FeedListsTable> {
  $$FeedListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSingle =>
      $composableBuilder(column: $table.isSingle, builder: (column) => column);

  Expression<T> listFeedsRefs<T extends Object>(
      Expression<T> Function($$ListFeedsTableAnnotationComposer a) f) {
    final $$ListFeedsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.listFeeds,
        getReferencedColumn: (t) => t.listId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ListFeedsTableAnnotationComposer(
              $db: $db,
              $table: $db.listFeeds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> followedAccountsRefs<T extends Object>(
      Expression<T> Function($$FollowedAccountsTableAnnotationComposer a) f) {
    final $$FollowedAccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.followedAccounts,
        getReferencedColumn: (t) => t.listId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FollowedAccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.followedAccounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> mutedChannelsRefs<T extends Object>(
      Expression<T> Function($$MutedChannelsTableAnnotationComposer a) f) {
    final $$MutedChannelsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.mutedChannels,
        getReferencedColumn: (t) => t.listId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MutedChannelsTableAnnotationComposer(
              $db: $db,
              $table: $db.mutedChannels,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$FeedListsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FeedListsTable,
    FeedListData,
    $$FeedListsTableFilterComposer,
    $$FeedListsTableOrderingComposer,
    $$FeedListsTableAnnotationComposer,
    $$FeedListsTableCreateCompanionBuilder,
    $$FeedListsTableUpdateCompanionBuilder,
    (FeedListData, $$FeedListsTableReferences),
    FeedListData,
    PrefetchHooks Function(
        {bool listFeedsRefs,
        bool followedAccountsRefs,
        bool mutedChannelsRefs})> {
  $$FeedListsTableTableManager(_$AppDatabase db, $FeedListsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FeedListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FeedListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FeedListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<String> sessionAddress = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<bool> isSingle = const Value.absent(),
          }) =>
              FeedListsCompanion(
            id: id,
            name: name,
            icon: icon,
            sessionAddress: sessionAddress,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isSingle: isSingle,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> icon = const Value.absent(),
            required String sessionAddress,
            required int createdAt,
            required int updatedAt,
            Value<bool> isSingle = const Value.absent(),
          }) =>
              FeedListsCompanion.insert(
            id: id,
            name: name,
            icon: icon,
            sessionAddress: sessionAddress,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isSingle: isSingle,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$FeedListsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {listFeedsRefs = false,
              followedAccountsRefs = false,
              mutedChannelsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (listFeedsRefs) db.listFeeds,
                if (followedAccountsRefs) db.followedAccounts,
                if (mutedChannelsRefs) db.mutedChannels
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (listFeedsRefs)
                    await $_getPrefetchedData<FeedListData, $FeedListsTable,
                            ListFeed>(
                        currentTable: table,
                        referencedTable:
                            $$FeedListsTableReferences._listFeedsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FeedListsTableReferences(db, table, p0)
                                .listFeedsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.listId == item.id),
                        typedResults: items),
                  if (followedAccountsRefs)
                    await $_getPrefetchedData<FeedListData, $FeedListsTable,
                            FollowedAccount>(
                        currentTable: table,
                        referencedTable: $$FeedListsTableReferences
                            ._followedAccountsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FeedListsTableReferences(db, table, p0)
                                .followedAccountsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.listId == item.id),
                        typedResults: items),
                  if (mutedChannelsRefs)
                    await $_getPrefetchedData<FeedListData, $FeedListsTable,
                            MutedChannel>(
                        currentTable: table,
                        referencedTable: $$FeedListsTableReferences
                            ._mutedChannelsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FeedListsTableReferences(db, table, p0)
                                .mutedChannelsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.listId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$FeedListsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FeedListsTable,
    FeedListData,
    $$FeedListsTableFilterComposer,
    $$FeedListsTableOrderingComposer,
    $$FeedListsTableAnnotationComposer,
    $$FeedListsTableCreateCompanionBuilder,
    $$FeedListsTableUpdateCompanionBuilder,
    (FeedListData, $$FeedListsTableReferences),
    FeedListData,
    PrefetchHooks Function(
        {bool listFeedsRefs,
        bool followedAccountsRefs,
        bool mutedChannelsRefs})>;
typedef $$ListFeedsTableCreateCompanionBuilder = ListFeedsCompanion Function({
  Value<int> id,
  required int listId,
  required String feedUrl,
  Value<String?> feedTitle,
  Value<String?> feedDescription,
  Value<String?> feedFoundAtAccountAddress,
  Value<String?> feedRecordKey,
  required int addedAt,
});
typedef $$ListFeedsTableUpdateCompanionBuilder = ListFeedsCompanion Function({
  Value<int> id,
  Value<int> listId,
  Value<String> feedUrl,
  Value<String?> feedTitle,
  Value<String?> feedDescription,
  Value<String?> feedFoundAtAccountAddress,
  Value<String?> feedRecordKey,
  Value<int> addedAt,
});

final class $$ListFeedsTableReferences
    extends BaseReferences<_$AppDatabase, $ListFeedsTable, ListFeed> {
  $$ListFeedsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FeedListsTable _listIdTable(_$AppDatabase db) => db.feedLists
      .createAlias($_aliasNameGenerator(db.listFeeds.listId, db.feedLists.id));

  $$FeedListsTableProcessedTableManager get listId {
    final $_column = $_itemColumn<int>('list_id')!;

    final manager = $$FeedListsTableTableManager($_db, $_db.feedLists)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ListFeedsTableFilterComposer
    extends Composer<_$AppDatabase, $ListFeedsTable> {
  $$ListFeedsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get feedUrl => $composableBuilder(
      column: $table.feedUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get feedTitle => $composableBuilder(
      column: $table.feedTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get feedDescription => $composableBuilder(
      column: $table.feedDescription,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get feedFoundAtAccountAddress => $composableBuilder(
      column: $table.feedFoundAtAccountAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get feedRecordKey => $composableBuilder(
      column: $table.feedRecordKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));

  $$FeedListsTableFilterComposer get listId {
    final $$FeedListsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.listId,
        referencedTable: $db.feedLists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FeedListsTableFilterComposer(
              $db: $db,
              $table: $db.feedLists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ListFeedsTableOrderingComposer
    extends Composer<_$AppDatabase, $ListFeedsTable> {
  $$ListFeedsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get feedUrl => $composableBuilder(
      column: $table.feedUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get feedTitle => $composableBuilder(
      column: $table.feedTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get feedDescription => $composableBuilder(
      column: $table.feedDescription,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get feedFoundAtAccountAddress => $composableBuilder(
      column: $table.feedFoundAtAccountAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get feedRecordKey => $composableBuilder(
      column: $table.feedRecordKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));

  $$FeedListsTableOrderingComposer get listId {
    final $$FeedListsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.listId,
        referencedTable: $db.feedLists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FeedListsTableOrderingComposer(
              $db: $db,
              $table: $db.feedLists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ListFeedsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ListFeedsTable> {
  $$ListFeedsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get feedUrl =>
      $composableBuilder(column: $table.feedUrl, builder: (column) => column);

  GeneratedColumn<String> get feedTitle =>
      $composableBuilder(column: $table.feedTitle, builder: (column) => column);

  GeneratedColumn<String> get feedDescription => $composableBuilder(
      column: $table.feedDescription, builder: (column) => column);

  GeneratedColumn<String> get feedFoundAtAccountAddress => $composableBuilder(
      column: $table.feedFoundAtAccountAddress, builder: (column) => column);

  GeneratedColumn<String> get feedRecordKey => $composableBuilder(
      column: $table.feedRecordKey, builder: (column) => column);

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$FeedListsTableAnnotationComposer get listId {
    final $$FeedListsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.listId,
        referencedTable: $db.feedLists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FeedListsTableAnnotationComposer(
              $db: $db,
              $table: $db.feedLists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ListFeedsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ListFeedsTable,
    ListFeed,
    $$ListFeedsTableFilterComposer,
    $$ListFeedsTableOrderingComposer,
    $$ListFeedsTableAnnotationComposer,
    $$ListFeedsTableCreateCompanionBuilder,
    $$ListFeedsTableUpdateCompanionBuilder,
    (ListFeed, $$ListFeedsTableReferences),
    ListFeed,
    PrefetchHooks Function({bool listId})> {
  $$ListFeedsTableTableManager(_$AppDatabase db, $ListFeedsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListFeedsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListFeedsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListFeedsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> listId = const Value.absent(),
            Value<String> feedUrl = const Value.absent(),
            Value<String?> feedTitle = const Value.absent(),
            Value<String?> feedDescription = const Value.absent(),
            Value<String?> feedFoundAtAccountAddress = const Value.absent(),
            Value<String?> feedRecordKey = const Value.absent(),
            Value<int> addedAt = const Value.absent(),
          }) =>
              ListFeedsCompanion(
            id: id,
            listId: listId,
            feedUrl: feedUrl,
            feedTitle: feedTitle,
            feedDescription: feedDescription,
            feedFoundAtAccountAddress: feedFoundAtAccountAddress,
            feedRecordKey: feedRecordKey,
            addedAt: addedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int listId,
            required String feedUrl,
            Value<String?> feedTitle = const Value.absent(),
            Value<String?> feedDescription = const Value.absent(),
            Value<String?> feedFoundAtAccountAddress = const Value.absent(),
            Value<String?> feedRecordKey = const Value.absent(),
            required int addedAt,
          }) =>
              ListFeedsCompanion.insert(
            id: id,
            listId: listId,
            feedUrl: feedUrl,
            feedTitle: feedTitle,
            feedDescription: feedDescription,
            feedFoundAtAccountAddress: feedFoundAtAccountAddress,
            feedRecordKey: feedRecordKey,
            addedAt: addedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ListFeedsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({listId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (listId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.listId,
                    referencedTable:
                        $$ListFeedsTableReferences._listIdTable(db),
                    referencedColumn:
                        $$ListFeedsTableReferences._listIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ListFeedsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ListFeedsTable,
    ListFeed,
    $$ListFeedsTableFilterComposer,
    $$ListFeedsTableOrderingComposer,
    $$ListFeedsTableAnnotationComposer,
    $$ListFeedsTableCreateCompanionBuilder,
    $$ListFeedsTableUpdateCompanionBuilder,
    (ListFeed, $$ListFeedsTableReferences),
    ListFeed,
    PrefetchHooks Function({bool listId})>;
typedef $$FeedCacheTableCreateCompanionBuilder = FeedCacheCompanion Function({
  Value<int> id,
  required String feedUrl,
  required String sessionAddress,
  required String body,
  Value<String?> contentType,
  Value<String?> etag,
  Value<String?> lastModified,
  required int fetchedAt,
  Value<bool> locked,
  Value<String?> lastError,
  Value<String?> interactions,
});
typedef $$FeedCacheTableUpdateCompanionBuilder = FeedCacheCompanion Function({
  Value<int> id,
  Value<String> feedUrl,
  Value<String> sessionAddress,
  Value<String> body,
  Value<String?> contentType,
  Value<String?> etag,
  Value<String?> lastModified,
  Value<int> fetchedAt,
  Value<bool> locked,
  Value<String?> lastError,
  Value<String?> interactions,
});

class $$FeedCacheTableFilterComposer
    extends Composer<_$AppDatabase, $FeedCacheTable> {
  $$FeedCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get feedUrl => $composableBuilder(
      column: $table.feedUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentType => $composableBuilder(
      column: $table.contentType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get etag => $composableBuilder(
      column: $table.etag, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get locked => $composableBuilder(
      column: $table.locked, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get interactions => $composableBuilder(
      column: $table.interactions, builder: (column) => ColumnFilters(column));
}

class $$FeedCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $FeedCacheTable> {
  $$FeedCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get feedUrl => $composableBuilder(
      column: $table.feedUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentType => $composableBuilder(
      column: $table.contentType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get etag => $composableBuilder(
      column: $table.etag, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastModified => $composableBuilder(
      column: $table.lastModified,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get locked => $composableBuilder(
      column: $table.locked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get interactions => $composableBuilder(
      column: $table.interactions,
      builder: (column) => ColumnOrderings(column));
}

class $$FeedCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $FeedCacheTable> {
  $$FeedCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get feedUrl =>
      $composableBuilder(column: $table.feedUrl, builder: (column) => column);

  GeneratedColumn<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get contentType => $composableBuilder(
      column: $table.contentType, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<String> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => column);

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<bool> get locked =>
      $composableBuilder(column: $table.locked, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get interactions => $composableBuilder(
      column: $table.interactions, builder: (column) => column);
}

class $$FeedCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FeedCacheTable,
    FeedCacheData,
    $$FeedCacheTableFilterComposer,
    $$FeedCacheTableOrderingComposer,
    $$FeedCacheTableAnnotationComposer,
    $$FeedCacheTableCreateCompanionBuilder,
    $$FeedCacheTableUpdateCompanionBuilder,
    (
      FeedCacheData,
      BaseReferences<_$AppDatabase, $FeedCacheTable, FeedCacheData>
    ),
    FeedCacheData,
    PrefetchHooks Function()> {
  $$FeedCacheTableTableManager(_$AppDatabase db, $FeedCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FeedCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FeedCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FeedCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> feedUrl = const Value.absent(),
            Value<String> sessionAddress = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<String?> contentType = const Value.absent(),
            Value<String?> etag = const Value.absent(),
            Value<String?> lastModified = const Value.absent(),
            Value<int> fetchedAt = const Value.absent(),
            Value<bool> locked = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<String?> interactions = const Value.absent(),
          }) =>
              FeedCacheCompanion(
            id: id,
            feedUrl: feedUrl,
            sessionAddress: sessionAddress,
            body: body,
            contentType: contentType,
            etag: etag,
            lastModified: lastModified,
            fetchedAt: fetchedAt,
            locked: locked,
            lastError: lastError,
            interactions: interactions,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String feedUrl,
            required String sessionAddress,
            required String body,
            Value<String?> contentType = const Value.absent(),
            Value<String?> etag = const Value.absent(),
            Value<String?> lastModified = const Value.absent(),
            required int fetchedAt,
            Value<bool> locked = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<String?> interactions = const Value.absent(),
          }) =>
              FeedCacheCompanion.insert(
            id: id,
            feedUrl: feedUrl,
            sessionAddress: sessionAddress,
            body: body,
            contentType: contentType,
            etag: etag,
            lastModified: lastModified,
            fetchedAt: fetchedAt,
            locked: locked,
            lastError: lastError,
            interactions: interactions,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FeedCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FeedCacheTable,
    FeedCacheData,
    $$FeedCacheTableFilterComposer,
    $$FeedCacheTableOrderingComposer,
    $$FeedCacheTableAnnotationComposer,
    $$FeedCacheTableCreateCompanionBuilder,
    $$FeedCacheTableUpdateCompanionBuilder,
    (
      FeedCacheData,
      BaseReferences<_$AppDatabase, $FeedCacheTable, FeedCacheData>
    ),
    FeedCacheData,
    PrefetchHooks Function()>;
typedef $$AttachmentCacheTableCreateCompanionBuilder = AttachmentCacheCompanion
    Function({
  required String contentDigest,
  required String filename,
  required String mimeType,
  required Uint8List data,
  required int size,
  required int cachedAt,
  required int lastAccessed,
  Value<int> rowid,
});
typedef $$AttachmentCacheTableUpdateCompanionBuilder = AttachmentCacheCompanion
    Function({
  Value<String> contentDigest,
  Value<String> filename,
  Value<String> mimeType,
  Value<Uint8List> data,
  Value<int> size,
  Value<int> cachedAt,
  Value<int> lastAccessed,
  Value<int> rowid,
});

class $$AttachmentCacheTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentCacheTable> {
  $$AttachmentCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get contentDigest => $composableBuilder(
      column: $table.contentDigest, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filename => $composableBuilder(
      column: $table.filename, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get size => $composableBuilder(
      column: $table.size, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastAccessed => $composableBuilder(
      column: $table.lastAccessed, builder: (column) => ColumnFilters(column));
}

class $$AttachmentCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentCacheTable> {
  $$AttachmentCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get contentDigest => $composableBuilder(
      column: $table.contentDigest,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filename => $composableBuilder(
      column: $table.filename, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get size => $composableBuilder(
      column: $table.size, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastAccessed => $composableBuilder(
      column: $table.lastAccessed,
      builder: (column) => ColumnOrderings(column));
}

class $$AttachmentCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentCacheTable> {
  $$AttachmentCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get contentDigest => $composableBuilder(
      column: $table.contentDigest, builder: (column) => column);

  GeneratedColumn<String> get filename =>
      $composableBuilder(column: $table.filename, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<Uint8List> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<int> get lastAccessed => $composableBuilder(
      column: $table.lastAccessed, builder: (column) => column);
}

class $$AttachmentCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AttachmentCacheTable,
    AttachmentCacheData,
    $$AttachmentCacheTableFilterComposer,
    $$AttachmentCacheTableOrderingComposer,
    $$AttachmentCacheTableAnnotationComposer,
    $$AttachmentCacheTableCreateCompanionBuilder,
    $$AttachmentCacheTableUpdateCompanionBuilder,
    (
      AttachmentCacheData,
      BaseReferences<_$AppDatabase, $AttachmentCacheTable, AttachmentCacheData>
    ),
    AttachmentCacheData,
    PrefetchHooks Function()> {
  $$AttachmentCacheTableTableManager(
      _$AppDatabase db, $AttachmentCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> contentDigest = const Value.absent(),
            Value<String> filename = const Value.absent(),
            Value<String> mimeType = const Value.absent(),
            Value<Uint8List> data = const Value.absent(),
            Value<int> size = const Value.absent(),
            Value<int> cachedAt = const Value.absent(),
            Value<int> lastAccessed = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttachmentCacheCompanion(
            contentDigest: contentDigest,
            filename: filename,
            mimeType: mimeType,
            data: data,
            size: size,
            cachedAt: cachedAt,
            lastAccessed: lastAccessed,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String contentDigest,
            required String filename,
            required String mimeType,
            required Uint8List data,
            required int size,
            required int cachedAt,
            required int lastAccessed,
            Value<int> rowid = const Value.absent(),
          }) =>
              AttachmentCacheCompanion.insert(
            contentDigest: contentDigest,
            filename: filename,
            mimeType: mimeType,
            data: data,
            size: size,
            cachedAt: cachedAt,
            lastAccessed: lastAccessed,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AttachmentCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AttachmentCacheTable,
    AttachmentCacheData,
    $$AttachmentCacheTableFilterComposer,
    $$AttachmentCacheTableOrderingComposer,
    $$AttachmentCacheTableAnnotationComposer,
    $$AttachmentCacheTableCreateCompanionBuilder,
    $$AttachmentCacheTableUpdateCompanionBuilder,
    (
      AttachmentCacheData,
      BaseReferences<_$AppDatabase, $AttachmentCacheTable, AttachmentCacheData>
    ),
    AttachmentCacheData,
    PrefetchHooks Function()>;
typedef $$BookmarkedAppsTableCreateCompanionBuilder = BookmarkedAppsCompanion
    Function({
  Value<int> id,
  required String appName,
  required String ownerAddress,
  required String displayName,
  Value<String?> iconUrl,
  Value<String?> description,
  Value<String?> warnings,
  Value<String?> categoryOne,
  Value<String?> categoryTwo,
  Value<String?> url,
  Value<String?> appstoreLink,
  Value<String?> playstoreLink,
  Value<String?> apkDownload,
  Value<String?> ipaDownload,
  required String sessionAddress,
  required int bookmarkedAt,
  Value<int?> nextUpdate,
});
typedef $$BookmarkedAppsTableUpdateCompanionBuilder = BookmarkedAppsCompanion
    Function({
  Value<int> id,
  Value<String> appName,
  Value<String> ownerAddress,
  Value<String> displayName,
  Value<String?> iconUrl,
  Value<String?> description,
  Value<String?> warnings,
  Value<String?> categoryOne,
  Value<String?> categoryTwo,
  Value<String?> url,
  Value<String?> appstoreLink,
  Value<String?> playstoreLink,
  Value<String?> apkDownload,
  Value<String?> ipaDownload,
  Value<String> sessionAddress,
  Value<int> bookmarkedAt,
  Value<int?> nextUpdate,
});

class $$BookmarkedAppsTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarkedAppsTable> {
  $$BookmarkedAppsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get appName => $composableBuilder(
      column: $table.appName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerAddress => $composableBuilder(
      column: $table.ownerAddress, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconUrl => $composableBuilder(
      column: $table.iconUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get warnings => $composableBuilder(
      column: $table.warnings, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryOne => $composableBuilder(
      column: $table.categoryOne, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryTwo => $composableBuilder(
      column: $table.categoryTwo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get appstoreLink => $composableBuilder(
      column: $table.appstoreLink, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get playstoreLink => $composableBuilder(
      column: $table.playstoreLink, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get apkDownload => $composableBuilder(
      column: $table.apkDownload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ipaDownload => $composableBuilder(
      column: $table.ipaDownload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bookmarkedAt => $composableBuilder(
      column: $table.bookmarkedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get nextUpdate => $composableBuilder(
      column: $table.nextUpdate, builder: (column) => ColumnFilters(column));
}

class $$BookmarkedAppsTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarkedAppsTable> {
  $$BookmarkedAppsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get appName => $composableBuilder(
      column: $table.appName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerAddress => $composableBuilder(
      column: $table.ownerAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconUrl => $composableBuilder(
      column: $table.iconUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get warnings => $composableBuilder(
      column: $table.warnings, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryOne => $composableBuilder(
      column: $table.categoryOne, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryTwo => $composableBuilder(
      column: $table.categoryTwo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get appstoreLink => $composableBuilder(
      column: $table.appstoreLink,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get playstoreLink => $composableBuilder(
      column: $table.playstoreLink,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get apkDownload => $composableBuilder(
      column: $table.apkDownload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ipaDownload => $composableBuilder(
      column: $table.ipaDownload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bookmarkedAt => $composableBuilder(
      column: $table.bookmarkedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get nextUpdate => $composableBuilder(
      column: $table.nextUpdate, builder: (column) => ColumnOrderings(column));
}

class $$BookmarkedAppsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarkedAppsTable> {
  $$BookmarkedAppsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get appName =>
      $composableBuilder(column: $table.appName, builder: (column) => column);

  GeneratedColumn<String> get ownerAddress => $composableBuilder(
      column: $table.ownerAddress, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get iconUrl =>
      $composableBuilder(column: $table.iconUrl, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get warnings =>
      $composableBuilder(column: $table.warnings, builder: (column) => column);

  GeneratedColumn<String> get categoryOne => $composableBuilder(
      column: $table.categoryOne, builder: (column) => column);

  GeneratedColumn<String> get categoryTwo => $composableBuilder(
      column: $table.categoryTwo, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get appstoreLink => $composableBuilder(
      column: $table.appstoreLink, builder: (column) => column);

  GeneratedColumn<String> get playstoreLink => $composableBuilder(
      column: $table.playstoreLink, builder: (column) => column);

  GeneratedColumn<String> get apkDownload => $composableBuilder(
      column: $table.apkDownload, builder: (column) => column);

  GeneratedColumn<String> get ipaDownload => $composableBuilder(
      column: $table.ipaDownload, builder: (column) => column);

  GeneratedColumn<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress, builder: (column) => column);

  GeneratedColumn<int> get bookmarkedAt => $composableBuilder(
      column: $table.bookmarkedAt, builder: (column) => column);

  GeneratedColumn<int> get nextUpdate => $composableBuilder(
      column: $table.nextUpdate, builder: (column) => column);
}

class $$BookmarkedAppsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BookmarkedAppsTable,
    BookmarkedApp,
    $$BookmarkedAppsTableFilterComposer,
    $$BookmarkedAppsTableOrderingComposer,
    $$BookmarkedAppsTableAnnotationComposer,
    $$BookmarkedAppsTableCreateCompanionBuilder,
    $$BookmarkedAppsTableUpdateCompanionBuilder,
    (
      BookmarkedApp,
      BaseReferences<_$AppDatabase, $BookmarkedAppsTable, BookmarkedApp>
    ),
    BookmarkedApp,
    PrefetchHooks Function()> {
  $$BookmarkedAppsTableTableManager(
      _$AppDatabase db, $BookmarkedAppsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarkedAppsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarkedAppsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarkedAppsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> appName = const Value.absent(),
            Value<String> ownerAddress = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String?> iconUrl = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> warnings = const Value.absent(),
            Value<String?> categoryOne = const Value.absent(),
            Value<String?> categoryTwo = const Value.absent(),
            Value<String?> url = const Value.absent(),
            Value<String?> appstoreLink = const Value.absent(),
            Value<String?> playstoreLink = const Value.absent(),
            Value<String?> apkDownload = const Value.absent(),
            Value<String?> ipaDownload = const Value.absent(),
            Value<String> sessionAddress = const Value.absent(),
            Value<int> bookmarkedAt = const Value.absent(),
            Value<int?> nextUpdate = const Value.absent(),
          }) =>
              BookmarkedAppsCompanion(
            id: id,
            appName: appName,
            ownerAddress: ownerAddress,
            displayName: displayName,
            iconUrl: iconUrl,
            description: description,
            warnings: warnings,
            categoryOne: categoryOne,
            categoryTwo: categoryTwo,
            url: url,
            appstoreLink: appstoreLink,
            playstoreLink: playstoreLink,
            apkDownload: apkDownload,
            ipaDownload: ipaDownload,
            sessionAddress: sessionAddress,
            bookmarkedAt: bookmarkedAt,
            nextUpdate: nextUpdate,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String appName,
            required String ownerAddress,
            required String displayName,
            Value<String?> iconUrl = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> warnings = const Value.absent(),
            Value<String?> categoryOne = const Value.absent(),
            Value<String?> categoryTwo = const Value.absent(),
            Value<String?> url = const Value.absent(),
            Value<String?> appstoreLink = const Value.absent(),
            Value<String?> playstoreLink = const Value.absent(),
            Value<String?> apkDownload = const Value.absent(),
            Value<String?> ipaDownload = const Value.absent(),
            required String sessionAddress,
            required int bookmarkedAt,
            Value<int?> nextUpdate = const Value.absent(),
          }) =>
              BookmarkedAppsCompanion.insert(
            id: id,
            appName: appName,
            ownerAddress: ownerAddress,
            displayName: displayName,
            iconUrl: iconUrl,
            description: description,
            warnings: warnings,
            categoryOne: categoryOne,
            categoryTwo: categoryTwo,
            url: url,
            appstoreLink: appstoreLink,
            playstoreLink: playstoreLink,
            apkDownload: apkDownload,
            ipaDownload: ipaDownload,
            sessionAddress: sessionAddress,
            bookmarkedAt: bookmarkedAt,
            nextUpdate: nextUpdate,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BookmarkedAppsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BookmarkedAppsTable,
    BookmarkedApp,
    $$BookmarkedAppsTableFilterComposer,
    $$BookmarkedAppsTableOrderingComposer,
    $$BookmarkedAppsTableAnnotationComposer,
    $$BookmarkedAppsTableCreateCompanionBuilder,
    $$BookmarkedAppsTableUpdateCompanionBuilder,
    (
      BookmarkedApp,
      BaseReferences<_$AppDatabase, $BookmarkedAppsTable, BookmarkedApp>
    ),
    BookmarkedApp,
    PrefetchHooks Function()>;
typedef $$BookmarkedPostsTableCreateCompanionBuilder = BookmarkedPostsCompanion
    Function({
  Value<int> id,
  required String postUid,
  required String title,
  Value<String?> feedUrl,
  required String postJson,
  required String sessionAddress,
  required int bookmarkedAt,
  required int updatedAt,
  Value<bool> unavailable,
  Value<String?> etag,
});
typedef $$BookmarkedPostsTableUpdateCompanionBuilder = BookmarkedPostsCompanion
    Function({
  Value<int> id,
  Value<String> postUid,
  Value<String> title,
  Value<String?> feedUrl,
  Value<String> postJson,
  Value<String> sessionAddress,
  Value<int> bookmarkedAt,
  Value<int> updatedAt,
  Value<bool> unavailable,
  Value<String?> etag,
});

class $$BookmarkedPostsTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarkedPostsTable> {
  $$BookmarkedPostsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get postUid => $composableBuilder(
      column: $table.postUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get feedUrl => $composableBuilder(
      column: $table.feedUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get postJson => $composableBuilder(
      column: $table.postJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bookmarkedAt => $composableBuilder(
      column: $table.bookmarkedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get unavailable => $composableBuilder(
      column: $table.unavailable, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get etag => $composableBuilder(
      column: $table.etag, builder: (column) => ColumnFilters(column));
}

class $$BookmarkedPostsTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarkedPostsTable> {
  $$BookmarkedPostsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get postUid => $composableBuilder(
      column: $table.postUid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get feedUrl => $composableBuilder(
      column: $table.feedUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get postJson => $composableBuilder(
      column: $table.postJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bookmarkedAt => $composableBuilder(
      column: $table.bookmarkedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get unavailable => $composableBuilder(
      column: $table.unavailable, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get etag => $composableBuilder(
      column: $table.etag, builder: (column) => ColumnOrderings(column));
}

class $$BookmarkedPostsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarkedPostsTable> {
  $$BookmarkedPostsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get postUid =>
      $composableBuilder(column: $table.postUid, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get feedUrl =>
      $composableBuilder(column: $table.feedUrl, builder: (column) => column);

  GeneratedColumn<String> get postJson =>
      $composableBuilder(column: $table.postJson, builder: (column) => column);

  GeneratedColumn<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress, builder: (column) => column);

  GeneratedColumn<int> get bookmarkedAt => $composableBuilder(
      column: $table.bookmarkedAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get unavailable => $composableBuilder(
      column: $table.unavailable, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);
}

class $$BookmarkedPostsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BookmarkedPostsTable,
    BookmarkedPost,
    $$BookmarkedPostsTableFilterComposer,
    $$BookmarkedPostsTableOrderingComposer,
    $$BookmarkedPostsTableAnnotationComposer,
    $$BookmarkedPostsTableCreateCompanionBuilder,
    $$BookmarkedPostsTableUpdateCompanionBuilder,
    (
      BookmarkedPost,
      BaseReferences<_$AppDatabase, $BookmarkedPostsTable, BookmarkedPost>
    ),
    BookmarkedPost,
    PrefetchHooks Function()> {
  $$BookmarkedPostsTableTableManager(
      _$AppDatabase db, $BookmarkedPostsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarkedPostsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarkedPostsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarkedPostsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> postUid = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> feedUrl = const Value.absent(),
            Value<String> postJson = const Value.absent(),
            Value<String> sessionAddress = const Value.absent(),
            Value<int> bookmarkedAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<bool> unavailable = const Value.absent(),
            Value<String?> etag = const Value.absent(),
          }) =>
              BookmarkedPostsCompanion(
            id: id,
            postUid: postUid,
            title: title,
            feedUrl: feedUrl,
            postJson: postJson,
            sessionAddress: sessionAddress,
            bookmarkedAt: bookmarkedAt,
            updatedAt: updatedAt,
            unavailable: unavailable,
            etag: etag,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String postUid,
            required String title,
            Value<String?> feedUrl = const Value.absent(),
            required String postJson,
            required String sessionAddress,
            required int bookmarkedAt,
            required int updatedAt,
            Value<bool> unavailable = const Value.absent(),
            Value<String?> etag = const Value.absent(),
          }) =>
              BookmarkedPostsCompanion.insert(
            id: id,
            postUid: postUid,
            title: title,
            feedUrl: feedUrl,
            postJson: postJson,
            sessionAddress: sessionAddress,
            bookmarkedAt: bookmarkedAt,
            updatedAt: updatedAt,
            unavailable: unavailable,
            etag: etag,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BookmarkedPostsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BookmarkedPostsTable,
    BookmarkedPost,
    $$BookmarkedPostsTableFilterComposer,
    $$BookmarkedPostsTableOrderingComposer,
    $$BookmarkedPostsTableAnnotationComposer,
    $$BookmarkedPostsTableCreateCompanionBuilder,
    $$BookmarkedPostsTableUpdateCompanionBuilder,
    (
      BookmarkedPost,
      BaseReferences<_$AppDatabase, $BookmarkedPostsTable, BookmarkedPost>
    ),
    BookmarkedPost,
    PrefetchHooks Function()>;
typedef $$ActivityEventsTableCreateCompanionBuilder = ActivityEventsCompanion
    Function({
  Value<int> id,
  required String eventType,
  required String actor,
  Value<String?> target,
  required int blockNumber,
  required int logIndex,
  required String txHash,
  required int timestamp,
  Value<String> data,
  Value<bool> isRead,
  required String sessionAddress,
});
typedef $$ActivityEventsTableUpdateCompanionBuilder = ActivityEventsCompanion
    Function({
  Value<int> id,
  Value<String> eventType,
  Value<String> actor,
  Value<String?> target,
  Value<int> blockNumber,
  Value<int> logIndex,
  Value<String> txHash,
  Value<int> timestamp,
  Value<String> data,
  Value<bool> isRead,
  Value<String> sessionAddress,
});

class $$ActivityEventsTableFilterComposer
    extends Composer<_$AppDatabase, $ActivityEventsTable> {
  $$ActivityEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get actor => $composableBuilder(
      column: $table.actor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get target => $composableBuilder(
      column: $table.target, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get blockNumber => $composableBuilder(
      column: $table.blockNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get logIndex => $composableBuilder(
      column: $table.logIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get txHash => $composableBuilder(
      column: $table.txHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnFilters(column));
}

class $$ActivityEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivityEventsTable> {
  $$ActivityEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get actor => $composableBuilder(
      column: $table.actor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get target => $composableBuilder(
      column: $table.target, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get blockNumber => $composableBuilder(
      column: $table.blockNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get logIndex => $composableBuilder(
      column: $table.logIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get txHash => $composableBuilder(
      column: $table.txHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnOrderings(column));
}

class $$ActivityEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivityEventsTable> {
  $$ActivityEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get actor =>
      $composableBuilder(column: $table.actor, builder: (column) => column);

  GeneratedColumn<String> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<int> get blockNumber => $composableBuilder(
      column: $table.blockNumber, builder: (column) => column);

  GeneratedColumn<int> get logIndex =>
      $composableBuilder(column: $table.logIndex, builder: (column) => column);

  GeneratedColumn<String> get txHash =>
      $composableBuilder(column: $table.txHash, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress, builder: (column) => column);
}

class $$ActivityEventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ActivityEventsTable,
    ActivityEventRow,
    $$ActivityEventsTableFilterComposer,
    $$ActivityEventsTableOrderingComposer,
    $$ActivityEventsTableAnnotationComposer,
    $$ActivityEventsTableCreateCompanionBuilder,
    $$ActivityEventsTableUpdateCompanionBuilder,
    (
      ActivityEventRow,
      BaseReferences<_$AppDatabase, $ActivityEventsTable, ActivityEventRow>
    ),
    ActivityEventRow,
    PrefetchHooks Function()> {
  $$ActivityEventsTableTableManager(
      _$AppDatabase db, $ActivityEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivityEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivityEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivityEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> eventType = const Value.absent(),
            Value<String> actor = const Value.absent(),
            Value<String?> target = const Value.absent(),
            Value<int> blockNumber = const Value.absent(),
            Value<int> logIndex = const Value.absent(),
            Value<String> txHash = const Value.absent(),
            Value<int> timestamp = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            Value<String> sessionAddress = const Value.absent(),
          }) =>
              ActivityEventsCompanion(
            id: id,
            eventType: eventType,
            actor: actor,
            target: target,
            blockNumber: blockNumber,
            logIndex: logIndex,
            txHash: txHash,
            timestamp: timestamp,
            data: data,
            isRead: isRead,
            sessionAddress: sessionAddress,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String eventType,
            required String actor,
            Value<String?> target = const Value.absent(),
            required int blockNumber,
            required int logIndex,
            required String txHash,
            required int timestamp,
            Value<String> data = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            required String sessionAddress,
          }) =>
              ActivityEventsCompanion.insert(
            id: id,
            eventType: eventType,
            actor: actor,
            target: target,
            blockNumber: blockNumber,
            logIndex: logIndex,
            txHash: txHash,
            timestamp: timestamp,
            data: data,
            isRead: isRead,
            sessionAddress: sessionAddress,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ActivityEventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ActivityEventsTable,
    ActivityEventRow,
    $$ActivityEventsTableFilterComposer,
    $$ActivityEventsTableOrderingComposer,
    $$ActivityEventsTableAnnotationComposer,
    $$ActivityEventsTableCreateCompanionBuilder,
    $$ActivityEventsTableUpdateCompanionBuilder,
    (
      ActivityEventRow,
      BaseReferences<_$AppDatabase, $ActivityEventsTable, ActivityEventRow>
    ),
    ActivityEventRow,
    PrefetchHooks Function()>;
typedef $$SavedStickersTableCreateCompanionBuilder = SavedStickersCompanion
    Function({
  Value<int> id,
  required String digest,
  required String filename,
  required String mimeType,
  required Uint8List data,
  required int size,
  required String sessionAddress,
  required int savedAt,
});
typedef $$SavedStickersTableUpdateCompanionBuilder = SavedStickersCompanion
    Function({
  Value<int> id,
  Value<String> digest,
  Value<String> filename,
  Value<String> mimeType,
  Value<Uint8List> data,
  Value<int> size,
  Value<String> sessionAddress,
  Value<int> savedAt,
});

class $$SavedStickersTableFilterComposer
    extends Composer<_$AppDatabase, $SavedStickersTable> {
  $$SavedStickersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get digest => $composableBuilder(
      column: $table.digest, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filename => $composableBuilder(
      column: $table.filename, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get size => $composableBuilder(
      column: $table.size, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get savedAt => $composableBuilder(
      column: $table.savedAt, builder: (column) => ColumnFilters(column));
}

class $$SavedStickersTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedStickersTable> {
  $$SavedStickersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get digest => $composableBuilder(
      column: $table.digest, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filename => $composableBuilder(
      column: $table.filename, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get size => $composableBuilder(
      column: $table.size, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get savedAt => $composableBuilder(
      column: $table.savedAt, builder: (column) => ColumnOrderings(column));
}

class $$SavedStickersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedStickersTable> {
  $$SavedStickersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get digest =>
      $composableBuilder(column: $table.digest, builder: (column) => column);

  GeneratedColumn<String> get filename =>
      $composableBuilder(column: $table.filename, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<Uint8List> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress, builder: (column) => column);

  GeneratedColumn<int> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$SavedStickersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SavedStickersTable,
    SavedStickerRow,
    $$SavedStickersTableFilterComposer,
    $$SavedStickersTableOrderingComposer,
    $$SavedStickersTableAnnotationComposer,
    $$SavedStickersTableCreateCompanionBuilder,
    $$SavedStickersTableUpdateCompanionBuilder,
    (
      SavedStickerRow,
      BaseReferences<_$AppDatabase, $SavedStickersTable, SavedStickerRow>
    ),
    SavedStickerRow,
    PrefetchHooks Function()> {
  $$SavedStickersTableTableManager(_$AppDatabase db, $SavedStickersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedStickersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedStickersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedStickersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> digest = const Value.absent(),
            Value<String> filename = const Value.absent(),
            Value<String> mimeType = const Value.absent(),
            Value<Uint8List> data = const Value.absent(),
            Value<int> size = const Value.absent(),
            Value<String> sessionAddress = const Value.absent(),
            Value<int> savedAt = const Value.absent(),
          }) =>
              SavedStickersCompanion(
            id: id,
            digest: digest,
            filename: filename,
            mimeType: mimeType,
            data: data,
            size: size,
            sessionAddress: sessionAddress,
            savedAt: savedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String digest,
            required String filename,
            required String mimeType,
            required Uint8List data,
            required int size,
            required String sessionAddress,
            required int savedAt,
          }) =>
              SavedStickersCompanion.insert(
            id: id,
            digest: digest,
            filename: filename,
            mimeType: mimeType,
            data: data,
            size: size,
            sessionAddress: sessionAddress,
            savedAt: savedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SavedStickersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SavedStickersTable,
    SavedStickerRow,
    $$SavedStickersTableFilterComposer,
    $$SavedStickersTableOrderingComposer,
    $$SavedStickersTableAnnotationComposer,
    $$SavedStickersTableCreateCompanionBuilder,
    $$SavedStickersTableUpdateCompanionBuilder,
    (
      SavedStickerRow,
      BaseReferences<_$AppDatabase, $SavedStickersTable, SavedStickerRow>
    ),
    SavedStickerRow,
    PrefetchHooks Function()>;
typedef $$ConnectedSitesTableCreateCompanionBuilder = ConnectedSitesCompanion
    Function({
  Value<int> id,
  required String origin,
  required String sessionAddress,
  required String grantedEoa,
  Value<String?> keyLabel,
  required int grantedAt,
  required int lastUsedAt,
  Value<bool> activeKey,
});
typedef $$ConnectedSitesTableUpdateCompanionBuilder = ConnectedSitesCompanion
    Function({
  Value<int> id,
  Value<String> origin,
  Value<String> sessionAddress,
  Value<String> grantedEoa,
  Value<String?> keyLabel,
  Value<int> grantedAt,
  Value<int> lastUsedAt,
  Value<bool> activeKey,
});

class $$ConnectedSitesTableFilterComposer
    extends Composer<_$AppDatabase, $ConnectedSitesTable> {
  $$ConnectedSitesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get origin => $composableBuilder(
      column: $table.origin, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get grantedEoa => $composableBuilder(
      column: $table.grantedEoa, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get keyLabel => $composableBuilder(
      column: $table.keyLabel, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get grantedAt => $composableBuilder(
      column: $table.grantedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get activeKey => $composableBuilder(
      column: $table.activeKey, builder: (column) => ColumnFilters(column));
}

class $$ConnectedSitesTableOrderingComposer
    extends Composer<_$AppDatabase, $ConnectedSitesTable> {
  $$ConnectedSitesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get origin => $composableBuilder(
      column: $table.origin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get grantedEoa => $composableBuilder(
      column: $table.grantedEoa, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get keyLabel => $composableBuilder(
      column: $table.keyLabel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get grantedAt => $composableBuilder(
      column: $table.grantedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get activeKey => $composableBuilder(
      column: $table.activeKey, builder: (column) => ColumnOrderings(column));
}

class $$ConnectedSitesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConnectedSitesTable> {
  $$ConnectedSitesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress, builder: (column) => column);

  GeneratedColumn<String> get grantedEoa => $composableBuilder(
      column: $table.grantedEoa, builder: (column) => column);

  GeneratedColumn<String> get keyLabel =>
      $composableBuilder(column: $table.keyLabel, builder: (column) => column);

  GeneratedColumn<int> get grantedAt =>
      $composableBuilder(column: $table.grantedAt, builder: (column) => column);

  GeneratedColumn<int> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => column);

  GeneratedColumn<bool> get activeKey =>
      $composableBuilder(column: $table.activeKey, builder: (column) => column);
}

class $$ConnectedSitesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ConnectedSitesTable,
    ConnectedSite,
    $$ConnectedSitesTableFilterComposer,
    $$ConnectedSitesTableOrderingComposer,
    $$ConnectedSitesTableAnnotationComposer,
    $$ConnectedSitesTableCreateCompanionBuilder,
    $$ConnectedSitesTableUpdateCompanionBuilder,
    (
      ConnectedSite,
      BaseReferences<_$AppDatabase, $ConnectedSitesTable, ConnectedSite>
    ),
    ConnectedSite,
    PrefetchHooks Function()> {
  $$ConnectedSitesTableTableManager(
      _$AppDatabase db, $ConnectedSitesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConnectedSitesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConnectedSitesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConnectedSitesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> origin = const Value.absent(),
            Value<String> sessionAddress = const Value.absent(),
            Value<String> grantedEoa = const Value.absent(),
            Value<String?> keyLabel = const Value.absent(),
            Value<int> grantedAt = const Value.absent(),
            Value<int> lastUsedAt = const Value.absent(),
            Value<bool> activeKey = const Value.absent(),
          }) =>
              ConnectedSitesCompanion(
            id: id,
            origin: origin,
            sessionAddress: sessionAddress,
            grantedEoa: grantedEoa,
            keyLabel: keyLabel,
            grantedAt: grantedAt,
            lastUsedAt: lastUsedAt,
            activeKey: activeKey,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String origin,
            required String sessionAddress,
            required String grantedEoa,
            Value<String?> keyLabel = const Value.absent(),
            required int grantedAt,
            required int lastUsedAt,
            Value<bool> activeKey = const Value.absent(),
          }) =>
              ConnectedSitesCompanion.insert(
            id: id,
            origin: origin,
            sessionAddress: sessionAddress,
            grantedEoa: grantedEoa,
            keyLabel: keyLabel,
            grantedAt: grantedAt,
            lastUsedAt: lastUsedAt,
            activeKey: activeKey,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ConnectedSitesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ConnectedSitesTable,
    ConnectedSite,
    $$ConnectedSitesTableFilterComposer,
    $$ConnectedSitesTableOrderingComposer,
    $$ConnectedSitesTableAnnotationComposer,
    $$ConnectedSitesTableCreateCompanionBuilder,
    $$ConnectedSitesTableUpdateCompanionBuilder,
    (
      ConnectedSite,
      BaseReferences<_$AppDatabase, $ConnectedSitesTable, ConnectedSite>
    ),
    ConnectedSite,
    PrefetchHooks Function()>;
typedef $$FollowedAccountsTableCreateCompanionBuilder
    = FollowedAccountsCompanion Function({
  Value<int> id,
  required String sessionAddress,
  required String accountAddress,
  required int listId,
  required int followedAt,
});
typedef $$FollowedAccountsTableUpdateCompanionBuilder
    = FollowedAccountsCompanion Function({
  Value<int> id,
  Value<String> sessionAddress,
  Value<String> accountAddress,
  Value<int> listId,
  Value<int> followedAt,
});

final class $$FollowedAccountsTableReferences extends BaseReferences<
    _$AppDatabase, $FollowedAccountsTable, FollowedAccount> {
  $$FollowedAccountsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $FeedListsTable _listIdTable(_$AppDatabase db) =>
      db.feedLists.createAlias(
          $_aliasNameGenerator(db.followedAccounts.listId, db.feedLists.id));

  $$FeedListsTableProcessedTableManager get listId {
    final $_column = $_itemColumn<int>('list_id')!;

    final manager = $$FeedListsTableTableManager($_db, $_db.feedLists)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$FollowedAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $FollowedAccountsTable> {
  $$FollowedAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountAddress => $composableBuilder(
      column: $table.accountAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get followedAt => $composableBuilder(
      column: $table.followedAt, builder: (column) => ColumnFilters(column));

  $$FeedListsTableFilterComposer get listId {
    final $$FeedListsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.listId,
        referencedTable: $db.feedLists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FeedListsTableFilterComposer(
              $db: $db,
              $table: $db.feedLists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FollowedAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $FollowedAccountsTable> {
  $$FollowedAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountAddress => $composableBuilder(
      column: $table.accountAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get followedAt => $composableBuilder(
      column: $table.followedAt, builder: (column) => ColumnOrderings(column));

  $$FeedListsTableOrderingComposer get listId {
    final $$FeedListsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.listId,
        referencedTable: $db.feedLists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FeedListsTableOrderingComposer(
              $db: $db,
              $table: $db.feedLists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FollowedAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FollowedAccountsTable> {
  $$FollowedAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress, builder: (column) => column);

  GeneratedColumn<String> get accountAddress => $composableBuilder(
      column: $table.accountAddress, builder: (column) => column);

  GeneratedColumn<int> get followedAt => $composableBuilder(
      column: $table.followedAt, builder: (column) => column);

  $$FeedListsTableAnnotationComposer get listId {
    final $$FeedListsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.listId,
        referencedTable: $db.feedLists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FeedListsTableAnnotationComposer(
              $db: $db,
              $table: $db.feedLists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FollowedAccountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FollowedAccountsTable,
    FollowedAccount,
    $$FollowedAccountsTableFilterComposer,
    $$FollowedAccountsTableOrderingComposer,
    $$FollowedAccountsTableAnnotationComposer,
    $$FollowedAccountsTableCreateCompanionBuilder,
    $$FollowedAccountsTableUpdateCompanionBuilder,
    (FollowedAccount, $$FollowedAccountsTableReferences),
    FollowedAccount,
    PrefetchHooks Function({bool listId})> {
  $$FollowedAccountsTableTableManager(
      _$AppDatabase db, $FollowedAccountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FollowedAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FollowedAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FollowedAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> sessionAddress = const Value.absent(),
            Value<String> accountAddress = const Value.absent(),
            Value<int> listId = const Value.absent(),
            Value<int> followedAt = const Value.absent(),
          }) =>
              FollowedAccountsCompanion(
            id: id,
            sessionAddress: sessionAddress,
            accountAddress: accountAddress,
            listId: listId,
            followedAt: followedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String sessionAddress,
            required String accountAddress,
            required int listId,
            required int followedAt,
          }) =>
              FollowedAccountsCompanion.insert(
            id: id,
            sessionAddress: sessionAddress,
            accountAddress: accountAddress,
            listId: listId,
            followedAt: followedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$FollowedAccountsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({listId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (listId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.listId,
                    referencedTable:
                        $$FollowedAccountsTableReferences._listIdTable(db),
                    referencedColumn:
                        $$FollowedAccountsTableReferences._listIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$FollowedAccountsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FollowedAccountsTable,
    FollowedAccount,
    $$FollowedAccountsTableFilterComposer,
    $$FollowedAccountsTableOrderingComposer,
    $$FollowedAccountsTableAnnotationComposer,
    $$FollowedAccountsTableCreateCompanionBuilder,
    $$FollowedAccountsTableUpdateCompanionBuilder,
    (FollowedAccount, $$FollowedAccountsTableReferences),
    FollowedAccount,
    PrefetchHooks Function({bool listId})>;
typedef $$MutedChannelsTableCreateCompanionBuilder = MutedChannelsCompanion
    Function({
  Value<int> id,
  required String sessionAddress,
  required String accountAddress,
  required int listId,
  required String recordKey,
  required int mutedAt,
});
typedef $$MutedChannelsTableUpdateCompanionBuilder = MutedChannelsCompanion
    Function({
  Value<int> id,
  Value<String> sessionAddress,
  Value<String> accountAddress,
  Value<int> listId,
  Value<String> recordKey,
  Value<int> mutedAt,
});

final class $$MutedChannelsTableReferences
    extends BaseReferences<_$AppDatabase, $MutedChannelsTable, MutedChannel> {
  $$MutedChannelsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $FeedListsTable _listIdTable(_$AppDatabase db) =>
      db.feedLists.createAlias(
          $_aliasNameGenerator(db.mutedChannels.listId, db.feedLists.id));

  $$FeedListsTableProcessedTableManager get listId {
    final $_column = $_itemColumn<int>('list_id')!;

    final manager = $$FeedListsTableTableManager($_db, $_db.feedLists)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$MutedChannelsTableFilterComposer
    extends Composer<_$AppDatabase, $MutedChannelsTable> {
  $$MutedChannelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountAddress => $composableBuilder(
      column: $table.accountAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recordKey => $composableBuilder(
      column: $table.recordKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get mutedAt => $composableBuilder(
      column: $table.mutedAt, builder: (column) => ColumnFilters(column));

  $$FeedListsTableFilterComposer get listId {
    final $$FeedListsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.listId,
        referencedTable: $db.feedLists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FeedListsTableFilterComposer(
              $db: $db,
              $table: $db.feedLists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MutedChannelsTableOrderingComposer
    extends Composer<_$AppDatabase, $MutedChannelsTable> {
  $$MutedChannelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountAddress => $composableBuilder(
      column: $table.accountAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recordKey => $composableBuilder(
      column: $table.recordKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mutedAt => $composableBuilder(
      column: $table.mutedAt, builder: (column) => ColumnOrderings(column));

  $$FeedListsTableOrderingComposer get listId {
    final $$FeedListsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.listId,
        referencedTable: $db.feedLists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FeedListsTableOrderingComposer(
              $db: $db,
              $table: $db.feedLists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MutedChannelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MutedChannelsTable> {
  $$MutedChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress, builder: (column) => column);

  GeneratedColumn<String> get accountAddress => $composableBuilder(
      column: $table.accountAddress, builder: (column) => column);

  GeneratedColumn<String> get recordKey =>
      $composableBuilder(column: $table.recordKey, builder: (column) => column);

  GeneratedColumn<int> get mutedAt =>
      $composableBuilder(column: $table.mutedAt, builder: (column) => column);

  $$FeedListsTableAnnotationComposer get listId {
    final $$FeedListsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.listId,
        referencedTable: $db.feedLists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FeedListsTableAnnotationComposer(
              $db: $db,
              $table: $db.feedLists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MutedChannelsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MutedChannelsTable,
    MutedChannel,
    $$MutedChannelsTableFilterComposer,
    $$MutedChannelsTableOrderingComposer,
    $$MutedChannelsTableAnnotationComposer,
    $$MutedChannelsTableCreateCompanionBuilder,
    $$MutedChannelsTableUpdateCompanionBuilder,
    (MutedChannel, $$MutedChannelsTableReferences),
    MutedChannel,
    PrefetchHooks Function({bool listId})> {
  $$MutedChannelsTableTableManager(_$AppDatabase db, $MutedChannelsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MutedChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MutedChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MutedChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> sessionAddress = const Value.absent(),
            Value<String> accountAddress = const Value.absent(),
            Value<int> listId = const Value.absent(),
            Value<String> recordKey = const Value.absent(),
            Value<int> mutedAt = const Value.absent(),
          }) =>
              MutedChannelsCompanion(
            id: id,
            sessionAddress: sessionAddress,
            accountAddress: accountAddress,
            listId: listId,
            recordKey: recordKey,
            mutedAt: mutedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String sessionAddress,
            required String accountAddress,
            required int listId,
            required String recordKey,
            required int mutedAt,
          }) =>
              MutedChannelsCompanion.insert(
            id: id,
            sessionAddress: sessionAddress,
            accountAddress: accountAddress,
            listId: listId,
            recordKey: recordKey,
            mutedAt: mutedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$MutedChannelsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({listId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (listId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.listId,
                    referencedTable:
                        $$MutedChannelsTableReferences._listIdTable(db),
                    referencedColumn:
                        $$MutedChannelsTableReferences._listIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$MutedChannelsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MutedChannelsTable,
    MutedChannel,
    $$MutedChannelsTableFilterComposer,
    $$MutedChannelsTableOrderingComposer,
    $$MutedChannelsTableAnnotationComposer,
    $$MutedChannelsTableCreateCompanionBuilder,
    $$MutedChannelsTableUpdateCompanionBuilder,
    (MutedChannel, $$MutedChannelsTableReferences),
    MutedChannel,
    PrefetchHooks Function({bool listId})>;
typedef $$ChannelSigninPrefsTableCreateCompanionBuilder
    = ChannelSigninPrefsCompanion Function({
  required String feedUrl,
  required String sessionAddress,
  Value<String?> decision,
  Value<String> mode,
  required int discoveredAt,
  Value<int> rowid,
});
typedef $$ChannelSigninPrefsTableUpdateCompanionBuilder
    = ChannelSigninPrefsCompanion Function({
  Value<String> feedUrl,
  Value<String> sessionAddress,
  Value<String?> decision,
  Value<String> mode,
  Value<int> discoveredAt,
  Value<int> rowid,
});

class $$ChannelSigninPrefsTableFilterComposer
    extends Composer<_$AppDatabase, $ChannelSigninPrefsTable> {
  $$ChannelSigninPrefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get feedUrl => $composableBuilder(
      column: $table.feedUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get decision => $composableBuilder(
      column: $table.decision, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get discoveredAt => $composableBuilder(
      column: $table.discoveredAt, builder: (column) => ColumnFilters(column));
}

class $$ChannelSigninPrefsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChannelSigninPrefsTable> {
  $$ChannelSigninPrefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get feedUrl => $composableBuilder(
      column: $table.feedUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get decision => $composableBuilder(
      column: $table.decision, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get discoveredAt => $composableBuilder(
      column: $table.discoveredAt,
      builder: (column) => ColumnOrderings(column));
}

class $$ChannelSigninPrefsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChannelSigninPrefsTable> {
  $$ChannelSigninPrefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get feedUrl =>
      $composableBuilder(column: $table.feedUrl, builder: (column) => column);

  GeneratedColumn<String> get sessionAddress => $composableBuilder(
      column: $table.sessionAddress, builder: (column) => column);

  GeneratedColumn<String> get decision =>
      $composableBuilder(column: $table.decision, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<int> get discoveredAt => $composableBuilder(
      column: $table.discoveredAt, builder: (column) => column);
}

class $$ChannelSigninPrefsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChannelSigninPrefsTable,
    ChannelSigninPref,
    $$ChannelSigninPrefsTableFilterComposer,
    $$ChannelSigninPrefsTableOrderingComposer,
    $$ChannelSigninPrefsTableAnnotationComposer,
    $$ChannelSigninPrefsTableCreateCompanionBuilder,
    $$ChannelSigninPrefsTableUpdateCompanionBuilder,
    (
      ChannelSigninPref,
      BaseReferences<_$AppDatabase, $ChannelSigninPrefsTable, ChannelSigninPref>
    ),
    ChannelSigninPref,
    PrefetchHooks Function()> {
  $$ChannelSigninPrefsTableTableManager(
      _$AppDatabase db, $ChannelSigninPrefsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChannelSigninPrefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChannelSigninPrefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChannelSigninPrefsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> feedUrl = const Value.absent(),
            Value<String> sessionAddress = const Value.absent(),
            Value<String?> decision = const Value.absent(),
            Value<String> mode = const Value.absent(),
            Value<int> discoveredAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChannelSigninPrefsCompanion(
            feedUrl: feedUrl,
            sessionAddress: sessionAddress,
            decision: decision,
            mode: mode,
            discoveredAt: discoveredAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String feedUrl,
            required String sessionAddress,
            Value<String?> decision = const Value.absent(),
            Value<String> mode = const Value.absent(),
            required int discoveredAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ChannelSigninPrefsCompanion.insert(
            feedUrl: feedUrl,
            sessionAddress: sessionAddress,
            decision: decision,
            mode: mode,
            discoveredAt: discoveredAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChannelSigninPrefsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChannelSigninPrefsTable,
    ChannelSigninPref,
    $$ChannelSigninPrefsTableFilterComposer,
    $$ChannelSigninPrefsTableOrderingComposer,
    $$ChannelSigninPrefsTableAnnotationComposer,
    $$ChannelSigninPrefsTableCreateCompanionBuilder,
    $$ChannelSigninPrefsTableUpdateCompanionBuilder,
    (
      ChannelSigninPref,
      BaseReferences<_$AppDatabase, $ChannelSigninPrefsTable, ChannelSigninPref>
    ),
    ChannelSigninPref,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db, _db.contacts);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db, _db.conversations);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$FeedServersTableTableManager get feedServers =>
      $$FeedServersTableTableManager(_db, _db.feedServers);
  $$RpcServersTableTableManager get rpcServers =>
      $$RpcServersTableTableManager(_db, _db.rpcServers);
  $$FeedListsTableTableManager get feedLists =>
      $$FeedListsTableTableManager(_db, _db.feedLists);
  $$ListFeedsTableTableManager get listFeeds =>
      $$ListFeedsTableTableManager(_db, _db.listFeeds);
  $$FeedCacheTableTableManager get feedCache =>
      $$FeedCacheTableTableManager(_db, _db.feedCache);
  $$AttachmentCacheTableTableManager get attachmentCache =>
      $$AttachmentCacheTableTableManager(_db, _db.attachmentCache);
  $$BookmarkedAppsTableTableManager get bookmarkedApps =>
      $$BookmarkedAppsTableTableManager(_db, _db.bookmarkedApps);
  $$BookmarkedPostsTableTableManager get bookmarkedPosts =>
      $$BookmarkedPostsTableTableManager(_db, _db.bookmarkedPosts);
  $$ActivityEventsTableTableManager get activityEvents =>
      $$ActivityEventsTableTableManager(_db, _db.activityEvents);
  $$SavedStickersTableTableManager get savedStickers =>
      $$SavedStickersTableTableManager(_db, _db.savedStickers);
  $$ConnectedSitesTableTableManager get connectedSites =>
      $$ConnectedSitesTableTableManager(_db, _db.connectedSites);
  $$FollowedAccountsTableTableManager get followedAccounts =>
      $$FollowedAccountsTableTableManager(_db, _db.followedAccounts);
  $$MutedChannelsTableTableManager get mutedChannels =>
      $$MutedChannelsTableTableManager(_db, _db.mutedChannels);
  $$ChannelSigninPrefsTableTableManager get channelSigninPrefs =>
      $$ChannelSigninPrefsTableTableManager(_db, _db.channelSigninPrefs);
}
