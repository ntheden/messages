import 'dart:io';
import 'dart:async';
import 'dart:core';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';
part 'db.g.dart';


class Contact {
  final DbContact contact;
  final List<Npub> npubs;

  Contact(this.contact, this.npubs);

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


class User {
  final Contact contact;

  User(this.contact);
}


@DriftDatabase(tables: [DbContacts, Npubs, Events, ContactNpubs])
class AppDatabase extends _$AppDatabase {
    AppDatabase() : super(_openConnection());

    @override
    int get schemaVersion => 1;

}   

LazyDatabase _openConnection() {
    return LazyDatabase(() async {
        final dbFolder = await getApplicationDocumentsDirectory();
        final file = File(join(dbFolder.path, 'nostrim.sqlite'));
        return NativeDatabase(file);
    });
}

final AppDatabase database = AppDatabase();
