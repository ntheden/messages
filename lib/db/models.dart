import 'dart:io';
import 'dart:async';
import 'dart:core';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';


class DbRelays extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get url => text().unique().withLength(min: 0, max: 1024)();
  TextColumn get notes => text()();
  BoolColumn get write => boolean()();
  BoolColumn get read => boolean()();
}

class DbRelayGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
}

class GroupRelays extends Table {
  IntColumn get group => integer().references(DbRelays, #id)();
  IntColumn get relay => integer().references(DbRelayGroups, #id)();
}

class ContactRelays extends Table {
  IntColumn get contact => integer().references(DbContacts, #id)();
  IntColumn get relay => integer().references(DbRelays, #id)();
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
  TextColumn? get surname => text().withLength(min: 0, max: 64)();
  TextColumn get username => text()();
  BoolColumn get isLocal => boolean()(); // Whether this is associated with a User
  BoolColumn get active => boolean()(); // Whether this is the active user
  // There can be more in Contact.npubs (see db/db.dart), but we will
  // use a primary npub here to maintain uniqueness of DbContact entries
  TextColumn get npub => text().unique().withLength(min: 64, max: 64)();
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
  IntColumn get pubkeyRef => integer().references(Npubs, #id)();
  IntColumn get receiverRef => integer().references(Npubs, #id)();
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
