import 'dart:io';
import 'dart:async';
import 'dart:core';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'crud.dart';
import 'models.dart';
part 'db.g.dart';


// This class might be going away
class Context {
  final DbContext context;
  final List<Relay> defaultRelays;
  final Contact user; 

  Context(this.context, this.defaultRelays, this.user);

  @override
  String toString() {
    return (StringBuffer('Context(')
          ..write('user: $user, ')
          ..write('defaultRelays: ${defaultRelays}, ')
          ..write(')'))
        .toString();
  }
}


class Contact {
  final DbContact contact;
  final List<Npub> npubs;

  Contact(this.contact, this.npubs);

  bool get isLocal => contact.isLocal;
  bool get active => contact.active;
  String get name => contact.name;
  String get pubkey => npubs[0].pubkey;
  String get privkey => npubs[0].privkey;
  int get id => contact.id;

  @override
  String toString() {
    return (StringBuffer('Contact(')
          ..write('id: ${contact.id}, ')
          ..write('name: ${contact.name}, ')
          ..write('npubs: ${npubs}, ')
          ..write(')'))
        .toString();
  }
}


class Event {
  final DbEvent event;
  final Npub npub;
  final List<Etag> etags;
  final List<Npub> ptags;

  Event(this.event, this.npub, this.etags, this.ptags);

  @override
  String toString() {
    return (StringBuffer('Event(')
          ..write('id: ${event.id}, ')
          ..write('plaintext: ${event.plaintext}, ')
          ..write('npub: ${npub}, ')
          ..write('etags: ${etags}, ')
          ..write('ptags: ${ptags}, ')
          ..write(')'))
        .toString();
  }
}


@DriftDatabase(
    tables: [
      DbContacts,
      DbContexts,
      DefaultRelays,
      DbEvents,
      Npubs,
      ContactNpubs,
      Etags,
      EventPtags,
      EventEtags,
      Relays,
    ])
class AppDatabase extends _$AppDatabase {
    AppDatabase() : super(_openConnection());

    @override
    int get schemaVersion => 1;

}   

LazyDatabase _openConnection() {
    return LazyDatabase(() async {
        final dbFolder = await getApplicationDocumentsDirectory();
        final file = File(join(dbFolder.path, 'messages.sqlite'));
        return NativeDatabase(file);
    });
}

final AppDatabase database = AppDatabase();
