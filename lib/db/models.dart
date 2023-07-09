import 'dart:io';
import 'dart:async';
import 'dart:core';
import 'package:drift/drift.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';


class DbRelays extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get url => text().unique().withLength(min: 0, max: 1024)();
  TextColumn get notes => text()();
  BoolColumn get write => boolean()();
  BoolColumn get read => boolean()();
}

class DbContacts extends Table {
  /// isLocal:
  ///   When false, then this is in the contacts list and not a local user
  ///   When true, then this is one of the user "accounts"
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 0, max: 64)();
  TextColumn? get surname => text().withLength(min: 0, max: 64)();
  TextColumn get username => text()();
  BoolColumn get isLocal => boolean()(); // Whether this is associated with a User
  BoolColumn get active => boolean()(); // Whether this is the active user
  // use npub here to maintain uniqueness of DbContact entries
  TextColumn get npub => text().unique().withLength(min: 64, max: 64)();
  TextColumn get pubkey => text().unique().withLength(min: 64, max: 64)();
  TextColumn? get privkey => text().withLength(min: 0, max: 64)();
  TextColumn get address => text()();
  TextColumn get city => text()();
  TextColumn get phone => text()();
  TextColumn get email => text()();
  TextColumn get email2 => text()();
  TextColumn get notes => text()();
  TextColumn get picture_url => text()();
  TextColumn get picture_pathname => text()();
  DateTimeColumn get createdAt => dateTime()();
}

class DbEvents extends Table {
  /// All events table
  IntColumn get id => integer().autoIncrement()();
  TextColumn get eventId => text().unique().withLength(min: 0, max: 64)();
  IntColumn get toContact => integer().references(DbContacts, #id)();
  IntColumn get fromContact => integer().references(DbContacts, #id)();
  TextColumn get content => text().withLength(min: 0, max: 1024)();
  // TODO: Consider not storing the plaintext.
  TextColumn get plaintext => text().withLength(min: 0, max: 1024)();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get kind => integer()();
  BoolColumn get decryptError => boolean()();
  // TODO: TAGS
}
