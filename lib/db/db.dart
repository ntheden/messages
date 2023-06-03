import 'dart:typed_data';
import 'dart:io';
import 'dart:core';
import 'package:dart_bech32/dart_bech32.dart';
import 'package:drift/drift.dart';
import 'package:nostr/nostr.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multiavatar/multiavatar.dart';

import 'connection/connection.dart' as impl;
import 'models.dart';
part 'db.g.dart';

class MessageEntry {
  final Npub npub; // public key in nostr event
  final DbEvent dbEvent;
  final EncryptedDirectMessage nostrEvent;
  Contact from;
  Contact to;

  MessageEntry(this.npub, this.dbEvent, this.nostrEvent, this.from, this.to);

  int get fromId => dbEvent.fromContact;
  int get toId => dbEvent.toContact;
  int get timestamp => nostrEvent.createdAt;
  int get id => dbEvent.id;
  String get content => dbEvent.plaintext;

  @override
  String toString() {
    return (StringBuffer('MessageEntry(')
          ..write('fromId: $fromId, ')
          ..write('toId: $toId, ')
          ..write('timestamp: $timestamp, ')
          ..write(')'))
        .toString();
  }
}

class Relay {
  final DbRelay relay;
  final List<RelayGroup> groups;
  String get url => relay.url;
  String get notes => relay.notes;
  bool get read => relay.read;
  bool get write => relay.write;

  const Relay(this.relay, this.groups);
}

class RelayGroup {
  final String name;
  final List<Relay> relays;

  const RelayGroup(this.name, this.relays);
}

class Contact {
  final DbContact contact;
  final List<Npub> npubs;
  final List<Relay> relays;

  Contact(this.contact, this.npubs, this.relays);

  bool get isLocal => contact.isLocal;
  bool get active => contact.active;
  String get name => contact.name;
  String get surname => contact.surname;
  String get username => contact.username;
  String get pubkey => npubs[0].pubkey; // FIXME
  String get privkey => npubs[0].privkey;
  String get npub => hexToBech32('npub', pubkey);
  String get nsec => hexToBech32('nsec', privkey);
  String get address => contact.address;
  String get city => contact.city;
  String get phone => contact.phone;
  String get email => contact.email;
  String get notes => contact.notes;
  //String get picture_url => contact.picture_url;
  //String get picture_pathname => contact.picture_pathname;
  int get id => contact.id;
  SvgPicture get avatar => SvgPicture.string(multiavatar(npub));

  @override
  String toString() {
    return (StringBuffer('Contact(')
          ..write('id: ${contact.id}, ')
          ..write('name: ${contact.name}, ')
          ..write('npubs: ${npubs.length}, ')
          ..write(')'))
        .toString();
  }

  String hexToBech32(String prefix, String hexKey) {
    List<int> data = [];
    for (int i = 0; i < hexKey.length; i += 2) {
      data.add(int.parse(hexKey.substring(i, i + 2), radix: 16));
    }

    final decoded = Decoded(prefix: prefix, words: bech32.toWords(Uint8List.fromList(data)));
    return bech32.encode(decoded);
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

@DriftDatabase(tables: [
  DbContacts,
  DbEvents,
  Npubs,
  ContactNpubs,
  Etags,
  EventPtags,
  EventEtags,
  DbRelays,
  DbRelayGroups,
])

class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.connect());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
  return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
    );
  }
}

final AppDatabase database = AppDatabase();
