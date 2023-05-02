import 'dart:io';
import 'dart:async';
import 'dart:core';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class Relays extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 0, max: 64)();
  TextColumn get url => text().withLength(min: 0, max: 256)();
}

class Npubs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get pubkey => text().unique().withLength(min: 0, max: 64)();
  TextColumn get label => text().withLength(min: 0, max: 64)();
}

class ContactNpubs extends Table {
  IntColumn get contact => integer().references(DbContacts, #id)();
  IntColumn get npub => integer().references(Npubs, #id)();
}

class DbContacts extends Table {
  /// Can have multiple users, only one active at a time. A user
  /// can have multiple npubs
  /// isLocal:
  ///   When false, then this is in the contacts list and not a local user
  ///   When true, then this is one of the user "accounts"
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 0, max: 64)();
  BoolColumn get isLocal => boolean()(); // Whether this is associated with a User
}

class Events extends Table {
  /// All events table
  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get id => text().unique().withLength(min: 0, max: 64)();
  TextColumn get pubkey => text().withLength(min: 64, max: 64)();
  TextColumn get receiver => text().withLength(min: 64, max: 64)(); // still have to do tags!
  TextColumn get fromRelay => text().withLength(min: 0, max: 64)();
  TextColumn get content => text().withLength(min: 0, max: 1024)();
  // TODO: Consider not storing the plaintext.
  TextColumn get plaintext => text().withLength(min: 0, max: 1024)();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get kind => integer()();
  BoolColumn get decryptError => boolean()();
  // TODO: TAGS
}
