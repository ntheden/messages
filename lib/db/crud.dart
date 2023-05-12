import 'package:drift/drift.dart';
import 'package:nostr/nostr.dart' as nostr;
import 'package:rxdart/rxdart.dart';

import 'db.dart';
import '../config/settings.dart';
import '../util/logging.dart';


// why doesn't this work???
Stream<List<DbContact>> watchUser() async* {
  Stream<List<DbContact>> entries = await (database.select(database.dbContacts)
        ..where((c) => c.active.equals(true)))
      .watch();
}

Future<void> switchUser(int id) async {
  final allUsers = database
    .update(database.dbContacts)
    ..where((c) => c.isLocal.equals(true))
    ..where((c) => c.id.isNotValue(id));

  allUsers.write(DbContactsCompanion(
      active: Value(false),
    )
  );

  final user = database
    .update(database.dbContacts)
    ..where((c) => c.id.equals(id));

  user.write(DbContactsCompanion(
      active: Value(true),
    )
  );
}

Future<Contact> createContactFromNpubs(List<Npub> npubs, String name,
    {bool active = false}) async {
  bool isLocal = false;
  npubs.forEach((npub) {
    if (npub.privkey.length > 0) {
      isLocal = true;
    }
  });

  DbContactsCompanion db_contact = DbContactsCompanion.insert(
          name: name,
          isLocal: isLocal,
          active: active,
          npub: npubs[0].pubkey,
        );

  final contactId = await database.into(database.dbContacts).insert(
        db_contact,
        onConflict: DoUpdate(
          (old) => db_contact,
          target: [database.dbContacts.npub],
        ),
      );

  if (active) {
    assert(isLocal, "Did not find a privkey for user $name");
  }

  Contact contact = Contact(
    DbContact(
      id: contactId,
      name: name,
      isLocal: isLocal,
      active: active,
      npub: npubs[0].pubkey,
    ),
    npubs,
  );
  writeContact(contact);
  return contact;
}

Future<Contact> createContact(
  List<String> npubs,
  String name, {
  bool isLocal = false,
  bool active = false,
}) async {
  for (String npubStr in npubs) {
    try {
      Npub npub = await getNpub(npubStr);
    } catch (err) {
      int npubId = await insertNpub(npubStr, name);
    }
  }

  final contactId = await database.into(database.dbContacts).insert(
        DbContactsCompanion.insert(
          name: name,
          isLocal: isLocal,
          active: active,
          npub: npubs[0],
        ),
        onConflict: DoNothing(),
      );

  final List<Npub> npubEntries = [];
  for (String npubStr in npubs) {
    Npub npub = (await getNpub(npubStr))!;
    if (npub.privkey.length > 0) {
      isLocal = true;
    }
    npubEntries.add(npub);
  }

  if (active) {
    assert(isLocal, "Did not find a privkey for user $name");
  }

  Contact contact = Contact(
      DbContact(
        id: contactId,
        name: name,
        isLocal: isLocal,
        active: active,
        npub: npubEntries[0].pubkey,
      ),
      npubEntries);
  writeContact(contact);
  return contact;
}

/*
Future<void> createEventHELPER(nostr.Event event, {String? plaintext, String? fromRelay,}) async {
  bool locallySent = (event.pubkey == getKey('bob', 'pub'));
  if (plaintext == null && !locallySent) {
    bool decryptError = false;
    try {
      plaintext = (event as nostr.EncryptedDirectMessage).getPlaintext(getKey('bob', 'priv'));
    } catch(err) {
      decryptError = true;
      print(err);
    }
    updateEventPlaintext(event, decryptError ? "" : plaintext!, decryptError, fromRelay!);
  }
  logEvent(event, plaintext);
}

Future<void> updateEventPlaintext(
    nostr.Event event,
    String plaintext,
    bool decryptError,
    String fromRelay,
  ) async {
  final insert = DbEventsCompanion.insert(
      id: event.id,
      pubkey: event.pubkey,
      receiver: (event as nostr.EncryptedDirectMessage).receiver!,
      content: event.content,
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      fromRelay: fromRelay,
      kind: event.kind,
      plaintext: plaintext,
      decryptError: decryptError,
  );
  database
    .into(database.dbEvents)
    .insert(insert, mode: InsertMode.insertOrReplace)
    .catchError((err) => print(err));
}
*/

Future<DbEvent> getEvent(String id) async {
  return (database.select(database.dbEvents)
        ..where((e) => e.eventId.equals(id)))
      .getSingle();
}

// Locally sourced events call this directly
Future<int> insertEvent(
  nostr.Event event, 
  Contact fromContact,
  Contact toContact, {
  String? plaintext,
  String? fromRelay,
}) async {
  final insert = DbEventsCompanion.insert(
    eventId: event.id,
    pubkeyRef: fromContact.npubs[0].id,
    receiverRef: toContact.npubs[0].id,
    fromContact: fromContact.contact.id,
    toContact: toContact.contact.id,
    content: event.content,
    createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
    fromRelay: fromRelay ?? "", // relay this event is received from, should be ref
    kind: event.kind,
    plaintext: plaintext ?? "",
    decryptError: false,
  );

  return database.into(database.dbEvents).insert(
        insert,
        onConflict: DoNothing(),
      );
}


// called by pages/chat
Future<int> storeSentEvent(
    nostr.Event event, 
    Contact fromContact,
    Contact toContact, {
    String? plaintext,
    String? fromRelay,
  }) async {
  logEvent(event.createdAt * 1000, fromContact, toContact, plaintext ?? "<not decrypted>", rx: false);
  return insertEvent(
    event,
    fromContact,
    toContact,
    plaintext: plaintext,
    fromRelay: fromRelay,
  );
}

// called by relay socket
Future<void> storeReceivedEvent(
  nostr.Event event, {
  String? plaintext,
  String? fromRelay,
}) async {
  try {
    DbEvent entry = await getEvent(event.id);
    // If it's there then nothing to do
    return;
  } catch (err) {
    // event hasn't been seen/stored
  }
  String? receiver = (event as nostr.EncryptedDirectMessage).receiver;
  if (receiver == null) {
    print('Filter: event destination (tag p) is not present');
    return;
  }
  Contact? toContact = await getContactFromNpub(receiver!);
  if (toContact == null || !toContact.isLocal) {
    // TODO: This must be optimized.
    // Current idea: relay watches a stream of local users' npubs, and
    // filters event if the receiver npub is not in the list
    print('Filter: event destination is not a local user: ${receiver}');
    return;
  }
  print('Received event ${event.id}');

  Contact? fromContact = await getContactFromNpub(event.pubkey);
  if (fromContact == null) {
    // TODO: SPAM/DOS Protection
    fromContact = await createContact([event.pubkey], "no name");
  }

  logEvent(event.createdAt * 1000, fromContact, toContact, plaintext ?? "<not decrypted>", rx: true);
  insertEvent(
    event,
    fromContact,
    toContact,
    plaintext: plaintext,
    fromRelay: fromRelay
  );
}

nostr.EncryptedDirectMessage nostrEvent(Npub npub, DbEvent event) {
  nostr.Event nEvent = nostr.Event.partial();
  nEvent.id = event.eventId;
  nEvent.pubkey = npub.pubkey;
  nEvent.content = event.content;
  nEvent.createdAt = event.createdAt.millisecondsSinceEpoch;
  nEvent.kind = event.kind;
  // TODO: Need TAGS for id to pass isValid()
  return nostr.EncryptedDirectMessage(nEvent, verify: false);
}

Future<List<MessageEntry>> messageEntries(
    List<DbEvent> events, [
    Contact? userHint,
    Contact? peerHint,
  ]) async {
  List<MessageEntry> messages = [];
  for (final event in events) {
    Contact? from;
    Contact? to;
    if (userHint != null) {
      Npub? npub;
      try {
        npub = userHint?.npubs.singleWhere((npub) => npub.id == event.pubkeyRef);
      } catch (error) {
        // orElse was giving error:
        // The value 'null' can't be returned from a function with return type 'Npub'
        // because 'Npub' is not nullable.
      }
      from = npub != null ? userHint : peerHint;
      if (peerHint == null) {
        Npub? npub;
        try {
          npub = userHint?.npubs.singleWhere((npub) => npub.id == event.receiverRef);
        } catch (error) {
        }
        to = npub != null ? userHint : peerHint;
      } else {
        Npub? npub;
        try {
          npub = peerHint?.npubs.singleWhere((npub) => npub.id == event.receiverRef);
        } catch (error) {
        }
        to = npub != null ? peerHint : userHint;
      }
    }
    String toStr = to?.id == userHint?.id ? "Me" : "unknown";
    if (toStr == "Me") toStr += '(${userHint?.name})';

    print('@@@@@@@@@@@@@@@@@@@@@@@@@@ from ${from?.name}');
    print('@@@@@@@@@@@@@@@@@@@@@@@@@@ to $toStr');
    Npub npub = await getNpubFromId(event.pubkeyRef);
    messages.add(
      MessageEntry(
        npub,
        event,
        nostrEvent(npub, event),
        from: from,
        to: to,
      )
    );
  }
  return messages;
}

Future<List<MessageEntry>> getUserMessages(Contact user) async {
  List<DbEvent> entries = await (database.select(database.dbEvents)
        ..where((t) => t.toContact.equals(user.id) | t.fromContact.equals(user.id))
        ..orderBy([
          (t) => OrderingTerm(
                expression: t.createdAt,
                mode: OrderingMode.desc,
              )
        ]))
      .get();
  List<MessageEntry> messages = await messageEntries(entries, user);
  return messages;
}

Future<List<MessageEntry>> getChatMessages(Contact user, Contact peer) async {
  List<DbEvent> entries = await (database.select(database.dbEvents)
        ..where((t) => (t.toContact.equals(user.id) & t.fromContact.equals(peer.id)) |
                        (t.toContact.equals(peer.id) & t.fromContact.equals(user.id)))
        ..orderBy([
          (t) => OrderingTerm(
                expression: t.createdAt,
                mode: OrderingMode.desc,
              )
        ]))
      .get();
  List<MessageEntry> messages = await messageEntries(entries, user, peer);
  return messages;
}

Stream<List<MessageEntry>> watchMessages() async* {
  Stream<List<DbEvent>> entries = await database.select(database.dbEvents)
      .watch();
  await for (final entryList in entries) {
    // intermediate step of converting to nostr events in order to
    // perform the decryption
    List<MessageEntry> messages = await messageEntries(entryList);
    yield messages;
  }
}

Future<Npub> getNpub(String publickey) async {
  return (database.select(database.npubs)
        ..where((n) => n.pubkey.equals(publickey)))
      .getSingle();
}

Future<List<Npub>> getNpubs() async {
  return database.select(database.npubs).get();
}

Future<Npub> getNpubFromId(int id) async {
  return (database.select(database.npubs)..where((n) => n.id.equals(id)))
      .getSingle();
}

Future<List<DbContact>> getContactsWithName(String name) async {
  return (database.select(database.dbContacts)
        ..where((c) => c.name.equals(name)))
      .get();
}

Future<int> insertNpub(String pubkey, String label, {String? privkey}) async {
  NpubsCompanion npub = NpubsCompanion.insert(
    pubkey: pubkey,
    label: label,
    privkey: privkey ?? "",
  );
  return database.into(database.npubs).insert(
        npub,
        onConflict: DoUpdate(
          (old) => npub,
          target: [database.npubs.pubkey],
        ),
      );
}

Future<void> writeContact(Contact entry) async {
  DbContact contact = entry.contact;

  await database
      .into(database.dbContacts)
      .insert(contact, mode: InsertMode.replace);

  await (database.delete(database.contactNpubs)
        ..where((item) => item.contact.equals(contact.id)))
      .go();

  for (final npub in entry.npubs) {
    await database
        .into(database.contactNpubs)
        .insert(ContactNpubsCompanion.insert(
          contact: contact.id,
          npub: npub.id,
        ));
  }
}

String npubPlaceHolder = "0000000000000000000000000000000000000000000000000000000000000000";

Future<Contact> createEmptyContact(String name,
    {bool isLocal = false, bool active = false}) async {
  final id = await database
      .into(database.contactNpubs)
      .insert(ContactNpubsCompanion());
  final contact =
      DbContact(id: id, name: name, isLocal: isLocal, active: active, npub: npubPlaceHolder);
  return Contact(contact, []);
}

Stream<Contact> watchContact(int id) {
  final contactQuery = database.select(database.dbContacts)
    ..where((contact) => contact.id.equals(id));

  final npubsQuery = database.select(database.contactNpubs).join(
    [
      innerJoin(
        database.npubs,
        database.npubs.id.equalsExp(database.contactNpubs.npub),
      ),
    ],
  )..where(database.contactNpubs.contact.equals(id));

  final contactStream = contactQuery.watchSingle();

  final npubStream = npubsQuery.watch().map((rows) {
    // we join the contactNpubs with the npubs, but we only care about
    // the npub here
    return rows.map((row) => row.readTable(database.npubs)).toList();
  });

  // now, we can merge the two queries together in one stream
  return Rx.combineLatest2(contactStream, npubStream,
      (DbContact contact, List<Npub> npubs) {
    return Contact(contact, npubs);
  });
}

Future<Contact?> getContactFromNpub(String publickey) async {
  final npubQuery = database.select(database.npubs)
    ..where((n) => n.pubkey.equals(publickey));

  Npub npub;
  try {
    npub = await npubQuery.getSingle();
  } catch (error) {
    return null;
  }

  final contactsQuery = database.select(database.contactNpubs).join(
    [
      innerJoin(
        database.dbContacts,
        database.dbContacts.id.equalsExp(database.contactNpubs.contact),
      ),
    ],
  )..where(database.contactNpubs.npub.equals(npub.id));

  // BUG: https://github.com/adamlofts/mysql1_dart/issues/106
  await contactsQuery.get();
  List<TypedResult> result = await contactsQuery.get();

  final contacts = result.map((row) {
    return row.readTable(database.dbContacts);
  }).toList();

  if (contacts.length > 0) {
    return Contact(contacts[0], [npub]);
  }
}

Future<Contact> getUser() async {
  final contactQuery = database.select(database.dbContacts)
    ..where((c) => c.active.equals(true));
  return getContact(await contactQuery.getSingle());
}

Future<List<Contact>> getUsers() async {
  final contactQuery = database.select(database.dbContacts)
    ..where((c) => c.isLocal.equals(true));

  List<Contact> contacts = [];
  for (DbContact contact in await contactQuery.get()) {
    contacts.add(await getContact(contact));
  }
  return contacts;
}

Future<Contact> getContactFromId(int id) async {
  final contactQuery = database.select(database.dbContacts)
    ..where((c) => c.id.equals(id));

  return getContact(await contactQuery.getSingle());
}

Future<List<Contact>> getContacts(List<int> ids) async {
  final contactQuery = database.select(database.dbContacts)
    ..where((c) => c.id.isIn(ids));

  List<Contact> contacts = [];
  for (final contact in await contactQuery.get()) {
    contacts.add(await getContact(contact));
  }
  return contacts;
}

Future<Contact> getContact(DbContact contact) async {
  final npubsQuery = database.select(database.contactNpubs).join(
    [
      innerJoin(
        database.npubs,
        database.npubs.id.equalsExp(database.contactNpubs.npub),
      ),
    ],
  )..where(database.contactNpubs.contact.equals(contact.id));

  final npubs = (await npubsQuery.get()).map((row) {
    return row.readTable(database.npubs);
  }).toList();

  return Contact(contact, npubs);
}

Future<Context> getContext({int id = 1}) async {
  final contextQuery = database.select(database.dbContexts)
    ..where((c) => c.id.equals(id));

  final relaysQuery = database.select(database.defaultRelays).join(
    [
      innerJoin(
        database.relays,
        database.relays.id.equalsExp(database.defaultRelays.relay),
      ),
    ],
  )..where(database.defaultRelays.context.equals(id));

  final relays = (await relaysQuery.get()).map((row) {
    return row.readTable(database.relays);
  }).toList();

  DbContext context = await contextQuery.getSingle();

  return Context(context, relays, await getContactFromId(context.currentUser));
}

Future<void> createContext(List<Relay> relays, Contact currentUser) async {
  Context context = Context(
    DbContext(
      id: 1,
      currentUser: currentUser.contact.id,
    ),
    relays,
    currentUser,
  );
  writeContext(context);
}

Future<void> writeContext(Context entry) async {
  DbContext context = entry.context;

  await database
      .into(database.dbContexts)
      .insert(context, mode: InsertMode.replace);

  await (database.delete(database.defaultRelays)
        ..where((item) => item.context.equals(context.id)))
      .go();

  for (final relay in entry.defaultRelays) {
    await database
        .into(database.defaultRelays)
        .insert(DefaultRelaysCompanion.insert(
          context: context.id,
          relay: relay.id,
        ));
  }
}

Future<int> createRelay(String url, String name) {
  RelaysCompanion relay = RelaysCompanion.insert(
    url: url,
    name: name,
  );
  return database.into(database.relays).insert(
        relay,
        onConflict: DoUpdate(
          (old) => relay,
          target: [database.relays.id],
        ),
      );
}

Future<List<Relay>> getDefaultRelays() {
  return database.select(database.relays).get();
}
