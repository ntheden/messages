// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class $DbContactsTable extends DbContacts
    with TableInfo<$DbContactsTable, DbContact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbContactsTable(this.attachedDatabase, [this._alias]);
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
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 0, maxTextLength: 64),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _isLocalMeta =
      const VerificationMeta('isLocal');
  @override
  late final GeneratedColumn<bool> isLocal =
      GeneratedColumn<bool>('is_local', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: true,
          defaultConstraints: GeneratedColumn.constraintsDependsOnDialect({
            SqlDialect.sqlite: 'CHECK ("is_local" IN (0, 1))',
            SqlDialect.mysql: '',
            SqlDialect.postgres: '',
          }));
  @override
  List<GeneratedColumn> get $columns => [id, name, isLocal];
  @override
  String get aliasedName => _alias ?? 'db_contacts';
  @override
  String get actualTableName => 'db_contacts';
  @override
  VerificationContext validateIntegrity(Insertable<DbContact> instance,
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
    if (data.containsKey('is_local')) {
      context.handle(_isLocalMeta,
          isLocal.isAcceptableOrUnknown(data['is_local']!, _isLocalMeta));
    } else if (isInserting) {
      context.missing(_isLocalMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbContact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbContact(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      isLocal: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_local'])!,
    );
  }

  @override
  $DbContactsTable createAlias(String alias) {
    return $DbContactsTable(attachedDatabase, alias);
  }
}

class DbContact extends DataClass implements Insertable<DbContact> {
  /// Can have multiple users, only one active at a time. A user
  /// can have multiple npubs
  /// isLocal:
  ///   When false, then this is in the contacts list and not a local user
  ///   When true, then this is one of the user "accounts"
  final int id;
  final String name;
  final bool isLocal;
  const DbContact(
      {required this.id, required this.name, required this.isLocal});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['is_local'] = Variable<bool>(isLocal);
    return map;
  }

  DbContactsCompanion toCompanion(bool nullToAbsent) {
    return DbContactsCompanion(
      id: Value(id),
      name: Value(name),
      isLocal: Value(isLocal),
    );
  }

  factory DbContact.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbContact(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isLocal: serializer.fromJson<bool>(json['isLocal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'isLocal': serializer.toJson<bool>(isLocal),
    };
  }

  DbContact copyWith({int? id, String? name, bool? isLocal}) => DbContact(
        id: id ?? this.id,
        name: name ?? this.name,
        isLocal: isLocal ?? this.isLocal,
      );
  @override
  String toString() {
    return (StringBuffer('DbContact(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isLocal: $isLocal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, isLocal);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbContact &&
          other.id == this.id &&
          other.name == this.name &&
          other.isLocal == this.isLocal);
}

class DbContactsCompanion extends UpdateCompanion<DbContact> {
  final Value<int> id;
  final Value<String> name;
  final Value<bool> isLocal;
  const DbContactsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isLocal = const Value.absent(),
  });
  DbContactsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required bool isLocal,
  })  : name = Value(name),
        isLocal = Value(isLocal);
  static Insertable<DbContact> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<bool>? isLocal,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isLocal != null) 'is_local': isLocal,
    });
  }

  DbContactsCompanion copyWith(
      {Value<int>? id, Value<String>? name, Value<bool>? isLocal}) {
    return DbContactsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isLocal: isLocal ?? this.isLocal,
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
    if (isLocal.present) {
      map['is_local'] = Variable<bool>(isLocal.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbContactsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isLocal: $isLocal')
          ..write(')'))
        .toString();
  }
}

class $NpubsTable extends Npubs with TableInfo<$NpubsTable, Npub> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NpubsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _pubkeyMeta = const VerificationMeta('pubkey');
  @override
  late final GeneratedColumn<String> pubkey = GeneratedColumn<String>(
      'pubkey', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 0, maxTextLength: 64),
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 0, maxTextLength: 64),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, pubkey, label];
  @override
  String get aliasedName => _alias ?? 'npubs';
  @override
  String get actualTableName => 'npubs';
  @override
  VerificationContext validateIntegrity(Insertable<Npub> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pubkey')) {
      context.handle(_pubkeyMeta,
          pubkey.isAcceptableOrUnknown(data['pubkey']!, _pubkeyMeta));
    } else if (isInserting) {
      context.missing(_pubkeyMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Npub map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Npub(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      pubkey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pubkey'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
    );
  }

  @override
  $NpubsTable createAlias(String alias) {
    return $NpubsTable(attachedDatabase, alias);
  }
}

class Npub extends DataClass implements Insertable<Npub> {
  final int id;
  final String pubkey;
  final String label;
  const Npub({required this.id, required this.pubkey, required this.label});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pubkey'] = Variable<String>(pubkey);
    map['label'] = Variable<String>(label);
    return map;
  }

  NpubsCompanion toCompanion(bool nullToAbsent) {
    return NpubsCompanion(
      id: Value(id),
      pubkey: Value(pubkey),
      label: Value(label),
    );
  }

  factory Npub.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Npub(
      id: serializer.fromJson<int>(json['id']),
      pubkey: serializer.fromJson<String>(json['pubkey']),
      label: serializer.fromJson<String>(json['label']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'pubkey': serializer.toJson<String>(pubkey),
      'label': serializer.toJson<String>(label),
    };
  }

  Npub copyWith({int? id, String? pubkey, String? label}) => Npub(
        id: id ?? this.id,
        pubkey: pubkey ?? this.pubkey,
        label: label ?? this.label,
      );
  @override
  String toString() {
    return (StringBuffer('Npub(')
          ..write('id: $id, ')
          ..write('pubkey: $pubkey, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, pubkey, label);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Npub &&
          other.id == this.id &&
          other.pubkey == this.pubkey &&
          other.label == this.label);
}

class NpubsCompanion extends UpdateCompanion<Npub> {
  final Value<int> id;
  final Value<String> pubkey;
  final Value<String> label;
  const NpubsCompanion({
    this.id = const Value.absent(),
    this.pubkey = const Value.absent(),
    this.label = const Value.absent(),
  });
  NpubsCompanion.insert({
    this.id = const Value.absent(),
    required String pubkey,
    required String label,
  })  : pubkey = Value(pubkey),
        label = Value(label);
  static Insertable<Npub> custom({
    Expression<int>? id,
    Expression<String>? pubkey,
    Expression<String>? label,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pubkey != null) 'pubkey': pubkey,
      if (label != null) 'label': label,
    });
  }

  NpubsCompanion copyWith(
      {Value<int>? id, Value<String>? pubkey, Value<String>? label}) {
    return NpubsCompanion(
      id: id ?? this.id,
      pubkey: pubkey ?? this.pubkey,
      label: label ?? this.label,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (pubkey.present) {
      map['pubkey'] = Variable<String>(pubkey.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NpubsCompanion(')
          ..write('id: $id, ')
          ..write('pubkey: $pubkey, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }
}

class $EventsTable extends Events with TableInfo<$EventsTable, Event> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
      'row_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 0, maxTextLength: 64),
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _pubkeyMeta = const VerificationMeta('pubkey');
  @override
  late final GeneratedColumn<String> pubkey = GeneratedColumn<String>(
      'pubkey', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 64, maxTextLength: 64),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _receiverMeta =
      const VerificationMeta('receiver');
  @override
  late final GeneratedColumn<String> receiver = GeneratedColumn<String>(
      'receiver', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 64, maxTextLength: 64),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _fromRelayMeta =
      const VerificationMeta('fromRelay');
  @override
  late final GeneratedColumn<String> fromRelay = GeneratedColumn<String>(
      'from_relay', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 0, maxTextLength: 64),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(
          minTextLength: 0, maxTextLength: 1024),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _plaintextMeta =
      const VerificationMeta('plaintext');
  @override
  late final GeneratedColumn<String> plaintext = GeneratedColumn<String>(
      'plaintext', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(
          minTextLength: 0, maxTextLength: 1024),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<int> kind = GeneratedColumn<int>(
      'kind', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _decryptErrorMeta =
      const VerificationMeta('decryptError');
  @override
  late final GeneratedColumn<bool> decryptError =
      GeneratedColumn<bool>('decrypt_error', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: true,
          defaultConstraints: GeneratedColumn.constraintsDependsOnDialect({
            SqlDialect.sqlite: 'CHECK ("decrypt_error" IN (0, 1))',
            SqlDialect.mysql: '',
            SqlDialect.postgres: '',
          }));
  @override
  List<GeneratedColumn> get $columns => [
        rowId,
        id,
        pubkey,
        receiver,
        fromRelay,
        content,
        plaintext,
        createdAt,
        kind,
        decryptError
      ];
  @override
  String get aliasedName => _alias ?? 'events';
  @override
  String get actualTableName => 'events';
  @override
  VerificationContext validateIntegrity(Insertable<Event> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
          _rowIdMeta, rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pubkey')) {
      context.handle(_pubkeyMeta,
          pubkey.isAcceptableOrUnknown(data['pubkey']!, _pubkeyMeta));
    } else if (isInserting) {
      context.missing(_pubkeyMeta);
    }
    if (data.containsKey('receiver')) {
      context.handle(_receiverMeta,
          receiver.isAcceptableOrUnknown(data['receiver']!, _receiverMeta));
    } else if (isInserting) {
      context.missing(_receiverMeta);
    }
    if (data.containsKey('from_relay')) {
      context.handle(_fromRelayMeta,
          fromRelay.isAcceptableOrUnknown(data['from_relay']!, _fromRelayMeta));
    } else if (isInserting) {
      context.missing(_fromRelayMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('plaintext')) {
      context.handle(_plaintextMeta,
          plaintext.isAcceptableOrUnknown(data['plaintext']!, _plaintextMeta));
    } else if (isInserting) {
      context.missing(_plaintextMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('decrypt_error')) {
      context.handle(
          _decryptErrorMeta,
          decryptError.isAcceptableOrUnknown(
              data['decrypt_error']!, _decryptErrorMeta));
    } else if (isInserting) {
      context.missing(_decryptErrorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  Event map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Event(
      rowId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}row_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      pubkey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pubkey'])!,
      receiver: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}receiver'])!,
      fromRelay: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}from_relay'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      plaintext: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plaintext'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kind'])!,
      decryptError: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}decrypt_error'])!,
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class Event extends DataClass implements Insertable<Event> {
  /// All events table
  final int rowId;
  final String id;
  final String pubkey;
  final String receiver;
  final String fromRelay;
  final String content;
  final String plaintext;
  final DateTime createdAt;
  final int kind;
  final bool decryptError;
  const Event(
      {required this.rowId,
      required this.id,
      required this.pubkey,
      required this.receiver,
      required this.fromRelay,
      required this.content,
      required this.plaintext,
      required this.createdAt,
      required this.kind,
      required this.decryptError});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['id'] = Variable<String>(id);
    map['pubkey'] = Variable<String>(pubkey);
    map['receiver'] = Variable<String>(receiver);
    map['from_relay'] = Variable<String>(fromRelay);
    map['content'] = Variable<String>(content);
    map['plaintext'] = Variable<String>(plaintext);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['kind'] = Variable<int>(kind);
    map['decrypt_error'] = Variable<bool>(decryptError);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      rowId: Value(rowId),
      id: Value(id),
      pubkey: Value(pubkey),
      receiver: Value(receiver),
      fromRelay: Value(fromRelay),
      content: Value(content),
      plaintext: Value(plaintext),
      createdAt: Value(createdAt),
      kind: Value(kind),
      decryptError: Value(decryptError),
    );
  }

  factory Event.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Event(
      rowId: serializer.fromJson<int>(json['rowId']),
      id: serializer.fromJson<String>(json['id']),
      pubkey: serializer.fromJson<String>(json['pubkey']),
      receiver: serializer.fromJson<String>(json['receiver']),
      fromRelay: serializer.fromJson<String>(json['fromRelay']),
      content: serializer.fromJson<String>(json['content']),
      plaintext: serializer.fromJson<String>(json['plaintext']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      kind: serializer.fromJson<int>(json['kind']),
      decryptError: serializer.fromJson<bool>(json['decryptError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'id': serializer.toJson<String>(id),
      'pubkey': serializer.toJson<String>(pubkey),
      'receiver': serializer.toJson<String>(receiver),
      'fromRelay': serializer.toJson<String>(fromRelay),
      'content': serializer.toJson<String>(content),
      'plaintext': serializer.toJson<String>(plaintext),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'kind': serializer.toJson<int>(kind),
      'decryptError': serializer.toJson<bool>(decryptError),
    };
  }

  Event copyWith(
          {int? rowId,
          String? id,
          String? pubkey,
          String? receiver,
          String? fromRelay,
          String? content,
          String? plaintext,
          DateTime? createdAt,
          int? kind,
          bool? decryptError}) =>
      Event(
        rowId: rowId ?? this.rowId,
        id: id ?? this.id,
        pubkey: pubkey ?? this.pubkey,
        receiver: receiver ?? this.receiver,
        fromRelay: fromRelay ?? this.fromRelay,
        content: content ?? this.content,
        plaintext: plaintext ?? this.plaintext,
        createdAt: createdAt ?? this.createdAt,
        kind: kind ?? this.kind,
        decryptError: decryptError ?? this.decryptError,
      );
  @override
  String toString() {
    return (StringBuffer('Event(')
          ..write('rowId: $rowId, ')
          ..write('id: $id, ')
          ..write('pubkey: $pubkey, ')
          ..write('receiver: $receiver, ')
          ..write('fromRelay: $fromRelay, ')
          ..write('content: $content, ')
          ..write('plaintext: $plaintext, ')
          ..write('createdAt: $createdAt, ')
          ..write('kind: $kind, ')
          ..write('decryptError: $decryptError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(rowId, id, pubkey, receiver, fromRelay,
      content, plaintext, createdAt, kind, decryptError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Event &&
          other.rowId == this.rowId &&
          other.id == this.id &&
          other.pubkey == this.pubkey &&
          other.receiver == this.receiver &&
          other.fromRelay == this.fromRelay &&
          other.content == this.content &&
          other.plaintext == this.plaintext &&
          other.createdAt == this.createdAt &&
          other.kind == this.kind &&
          other.decryptError == this.decryptError);
}

class EventsCompanion extends UpdateCompanion<Event> {
  final Value<int> rowId;
  final Value<String> id;
  final Value<String> pubkey;
  final Value<String> receiver;
  final Value<String> fromRelay;
  final Value<String> content;
  final Value<String> plaintext;
  final Value<DateTime> createdAt;
  final Value<int> kind;
  final Value<bool> decryptError;
  const EventsCompanion({
    this.rowId = const Value.absent(),
    this.id = const Value.absent(),
    this.pubkey = const Value.absent(),
    this.receiver = const Value.absent(),
    this.fromRelay = const Value.absent(),
    this.content = const Value.absent(),
    this.plaintext = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.kind = const Value.absent(),
    this.decryptError = const Value.absent(),
  });
  EventsCompanion.insert({
    this.rowId = const Value.absent(),
    required String id,
    required String pubkey,
    required String receiver,
    required String fromRelay,
    required String content,
    required String plaintext,
    required DateTime createdAt,
    required int kind,
    required bool decryptError,
  })  : id = Value(id),
        pubkey = Value(pubkey),
        receiver = Value(receiver),
        fromRelay = Value(fromRelay),
        content = Value(content),
        plaintext = Value(plaintext),
        createdAt = Value(createdAt),
        kind = Value(kind),
        decryptError = Value(decryptError);
  static Insertable<Event> custom({
    Expression<int>? rowId,
    Expression<String>? id,
    Expression<String>? pubkey,
    Expression<String>? receiver,
    Expression<String>? fromRelay,
    Expression<String>? content,
    Expression<String>? plaintext,
    Expression<DateTime>? createdAt,
    Expression<int>? kind,
    Expression<bool>? decryptError,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (id != null) 'id': id,
      if (pubkey != null) 'pubkey': pubkey,
      if (receiver != null) 'receiver': receiver,
      if (fromRelay != null) 'from_relay': fromRelay,
      if (content != null) 'content': content,
      if (plaintext != null) 'plaintext': plaintext,
      if (createdAt != null) 'created_at': createdAt,
      if (kind != null) 'kind': kind,
      if (decryptError != null) 'decrypt_error': decryptError,
    });
  }

  EventsCompanion copyWith(
      {Value<int>? rowId,
      Value<String>? id,
      Value<String>? pubkey,
      Value<String>? receiver,
      Value<String>? fromRelay,
      Value<String>? content,
      Value<String>? plaintext,
      Value<DateTime>? createdAt,
      Value<int>? kind,
      Value<bool>? decryptError}) {
    return EventsCompanion(
      rowId: rowId ?? this.rowId,
      id: id ?? this.id,
      pubkey: pubkey ?? this.pubkey,
      receiver: receiver ?? this.receiver,
      fromRelay: fromRelay ?? this.fromRelay,
      content: content ?? this.content,
      plaintext: plaintext ?? this.plaintext,
      createdAt: createdAt ?? this.createdAt,
      kind: kind ?? this.kind,
      decryptError: decryptError ?? this.decryptError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pubkey.present) {
      map['pubkey'] = Variable<String>(pubkey.value);
    }
    if (receiver.present) {
      map['receiver'] = Variable<String>(receiver.value);
    }
    if (fromRelay.present) {
      map['from_relay'] = Variable<String>(fromRelay.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (plaintext.present) {
      map['plaintext'] = Variable<String>(plaintext.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(kind.value);
    }
    if (decryptError.present) {
      map['decrypt_error'] = Variable<bool>(decryptError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('rowId: $rowId, ')
          ..write('id: $id, ')
          ..write('pubkey: $pubkey, ')
          ..write('receiver: $receiver, ')
          ..write('fromRelay: $fromRelay, ')
          ..write('content: $content, ')
          ..write('plaintext: $plaintext, ')
          ..write('createdAt: $createdAt, ')
          ..write('kind: $kind, ')
          ..write('decryptError: $decryptError')
          ..write(')'))
        .toString();
  }
}

class $ContactNpubsTable extends ContactNpubs
    with TableInfo<$ContactNpubsTable, ContactNpub> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactNpubsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _contactMeta =
      const VerificationMeta('contact');
  @override
  late final GeneratedColumn<int> contact = GeneratedColumn<int>(
      'contact', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES db_contacts (id)'));
  static const VerificationMeta _npubMeta = const VerificationMeta('npub');
  @override
  late final GeneratedColumn<int> npub = GeneratedColumn<int>(
      'npub', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES npubs (id)'));
  @override
  List<GeneratedColumn> get $columns => [contact, npub];
  @override
  String get aliasedName => _alias ?? 'contact_npubs';
  @override
  String get actualTableName => 'contact_npubs';
  @override
  VerificationContext validateIntegrity(Insertable<ContactNpub> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('contact')) {
      context.handle(_contactMeta,
          contact.isAcceptableOrUnknown(data['contact']!, _contactMeta));
    } else if (isInserting) {
      context.missing(_contactMeta);
    }
    if (data.containsKey('npub')) {
      context.handle(
          _npubMeta, npub.isAcceptableOrUnknown(data['npub']!, _npubMeta));
    } else if (isInserting) {
      context.missing(_npubMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  ContactNpub map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContactNpub(
      contact: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}contact'])!,
      npub: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}npub'])!,
    );
  }

  @override
  $ContactNpubsTable createAlias(String alias) {
    return $ContactNpubsTable(attachedDatabase, alias);
  }
}

class ContactNpub extends DataClass implements Insertable<ContactNpub> {
  final int contact;
  final int npub;
  const ContactNpub({required this.contact, required this.npub});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['contact'] = Variable<int>(contact);
    map['npub'] = Variable<int>(npub);
    return map;
  }

  ContactNpubsCompanion toCompanion(bool nullToAbsent) {
    return ContactNpubsCompanion(
      contact: Value(contact),
      npub: Value(npub),
    );
  }

  factory ContactNpub.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContactNpub(
      contact: serializer.fromJson<int>(json['contact']),
      npub: serializer.fromJson<int>(json['npub']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contact': serializer.toJson<int>(contact),
      'npub': serializer.toJson<int>(npub),
    };
  }

  ContactNpub copyWith({int? contact, int? npub}) => ContactNpub(
        contact: contact ?? this.contact,
        npub: npub ?? this.npub,
      );
  @override
  String toString() {
    return (StringBuffer('ContactNpub(')
          ..write('contact: $contact, ')
          ..write('npub: $npub')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(contact, npub);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContactNpub &&
          other.contact == this.contact &&
          other.npub == this.npub);
}

class ContactNpubsCompanion extends UpdateCompanion<ContactNpub> {
  final Value<int> contact;
  final Value<int> npub;
  final Value<int> rowid;
  const ContactNpubsCompanion({
    this.contact = const Value.absent(),
    this.npub = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactNpubsCompanion.insert({
    required int contact,
    required int npub,
    this.rowid = const Value.absent(),
  })  : contact = Value(contact),
        npub = Value(npub);
  static Insertable<ContactNpub> custom({
    Expression<int>? contact,
    Expression<int>? npub,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (contact != null) 'contact': contact,
      if (npub != null) 'npub': npub,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactNpubsCompanion copyWith(
      {Value<int>? contact, Value<int>? npub, Value<int>? rowid}) {
    return ContactNpubsCompanion(
      contact: contact ?? this.contact,
      npub: npub ?? this.npub,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (contact.present) {
      map['contact'] = Variable<int>(contact.value);
    }
    if (npub.present) {
      map['npub'] = Variable<int>(npub.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactNpubsCompanion(')
          ..write('contact: $contact, ')
          ..write('npub: $npub, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $DbContactsTable dbContacts = $DbContactsTable(this);
  late final $NpubsTable npubs = $NpubsTable(this);
  late final $EventsTable events = $EventsTable(this);
  late final $ContactNpubsTable contactNpubs = $ContactNpubsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [dbContacts, npubs, events, contactNpubs];
}
