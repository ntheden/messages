import 'dart:io';
import 'dart:async';
import 'dart:core';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';


class DbContexts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get currentUser => integer().references(DbContacts, #id)();
}

class DefaultRelays extends Table {
  IntColumn get context => integer().references(DbContexts, #id)();
  IntColumn get relay => integer().references(Relays, #id)();
}

class Relays extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get url => text().withLength(min: 0, max: 256)();
  TextColumn? get name => text().withLength(min: 0, max: 64)();
}

class Npubs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get pubkey => text().unique().withLength(min: 64, max: 64)();
  TextColumn? get label => text().withLength(min: 0, max: 64)();
  TextColumn? get privkey => text().withLength(min: 0, max: 64)();
}

class ContactNpubs extends Table {
  IntColumn get contact => integer().references(DbContacts, #id)();
  IntColumn get npub => integer().references(Npubs, #id)();
}

class Etags extends Table {
  IntColumn get id => integer().autoIncrement()();
  // event id may or may not be in db
  TextColumn get eventId => text().withLength(min: 0, max: 64)();
  // marker is one of "reply", "root", "mention"
  TextColumn? get marker => text().withLength(min: 0, max: 20)();
  IntColumn get relayRef => integer()();
}

class EventEtags extends Table {
  IntColumn get event => integer().references(DbEvents, #id)();
  IntColumn get etag => integer().references(Etags, #id)();
}

class EventPtags extends Table {
  IntColumn get event => integer().references(DbEvents, #id)();
  IntColumn get ptag => integer().references(Npubs, #id)();
}

class DbContacts extends Table {
  /// isLocal:
  ///   When false, then this is in the contacts list and not a local user
  ///   When true, then this is one of the user "accounts"
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 0, max: 64)();
  BoolColumn get isLocal => boolean()(); // Whether this is associated with a User
}

class DbEvents extends Table {
  /// All events table
  IntColumn get id => integer().autoIncrement()();
  TextColumn get eventId => text().unique().withLength(min: 0, max: 64)();
  IntColumn get pubkeyRef => integer()();
  IntColumn get receiverRef => integer()();
  TextColumn get fromRelay => text().withLength(min: 0, max: 64)();
  TextColumn get content => text().withLength(min: 0, max: 1024)();
  // TODO: Consider not storing the plaintext.
  TextColumn get plaintext => text().withLength(min: 0, max: 1024)();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get kind => integer()();
  BoolColumn get decryptError => boolean()();
  // TODO: TAGS
}
