import 'package:drift/drift.dart';
import 'package:nostr/nostr.dart' as nostr;
import 'package:rxdart/rxdart.dart';

import 'db.dart';
import '../util/logging.dart';

Future<void> switchUser(int id) async {
  final allUsers = database.update(database.dbContacts)
    ..where((c) => c.isLocal.equals(true))
    ..where((c) => c.id.isNotValue(id));

  allUsers.write(const DbContactsCompanion(
    active: Value(false),
  ));

  final user = database.update(database.dbContacts)
    ..where((c) => c.id.equals(id));

  user.write(const DbContactsCompanion(
    active: Value(true),
  ));
}

Future<Contact> createContactFromNpubs(List<Npub> npubs, String name,
    {bool active = false}) async {
  bool isLocal = false;
  npubs.forEach((npub) {
    if (npub.privkey.length > 0) {
      isLocal = true;
    }
  });

  /*
  DbContact? dbContact;
  try {
    dbContact = await (database.select(database.dbContacts)
      ..where((c) => c.npub.equals(npubs[0].pubkey))).getSingle();
  } catch (error) {
  }
  */

  DbContactsCompanion db_contact = DbContactsCompanion.insert(
    name: name,
    surname: "",
    username: "",
    address: "",
    city: "",
    phone: "",
    email: "",
    email2: "",
    notes: "",
    picture_url: "",
    picture_pathname: "",
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
      surname: "",
      username: "",
      address: "",
      city: "",
      phone: "",
      email: "",
      email2: "",
      notes: "",
      picture_url: "",
      picture_pathname: "",
      isLocal: isLocal,
      active: active,
      npub: npubs[0].pubkey,
    ),
    npubs,
  );
  writeContact(contact);
  return contact;
}

Future<void> createContact(
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
          surname: "",
          username: "",
          address: "",
          city: "",
          phone: "",
          email: "",
          email2: "",
          notes: "",
          picture_url: "",
          picture_pathname: "",
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
      surname: "",
      username: "",
      address: "",
      city: "",
      phone: "",
      email: "",
      email2: "",
      notes: "",
      picture_url: "",
      picture_pathname: "",
      isLocal: isLocal,
      active: active,
      npub: npubEntries[0].pubkey,
    ),
    npubEntries,
  );
  writeContact(contact);
}

Future<DbEvent> getEvent(String id) async {
  return (database.select(database.dbEvents)
        ..where((e) => e.eventId.equals(id)))
      .getSingle();
}

DbEventsCompanion _insertQuery(
  nostr.Event event,
  Contact fromContact,
  Contact toContact, {
  String? plaintext,
  bool? decryptError,
}) {
  final insert = DbEventsCompanion.insert(
    eventId: event.id,
    pubkeyRef: fromContact.npubs[0].id,
    receiverRef: toContact.npubs[0].id,
    fromContact: fromContact.contact.id,
    toContact: toContact.contact.id,
    content: event.content,
    createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
    kind: event.kind,
    plaintext: plaintext ?? "",
    decryptError: decryptError ?? false,
  );
  print('@@@@@@@@@@@@@@@@@ insert $insert');
  return insert;
}

Future<int> insertEvent(
  nostr.Event event,
  Contact fromContact,
  Contact toContact, {
  String? plaintext,
  bool? decryptError,
}) async {
  return database.into(database.dbEvents).insert(
        _insertQuery(event, fromContact, toContact,
            plaintext: plaintext, decryptError: decryptError),
        onConflict: DoNothing(),
      );
}

Future<int> updateEvent(
  nostr.Event event,
  Contact fromContact,
  Contact toContact, {
  String? plaintext,
  bool? decryptError,
}) async {
  return database.into(database.dbEvents).insert(
        _insertQuery(event, fromContact, toContact,
            plaintext: plaintext, decryptError: decryptError),
        mode: InsertMode.insertOrReplace,
      );
}

// Locally sourced events call this directly, called by pages/chat
Future<int> storeSentEvent(
  nostr.Event event,
  Contact fromContact,
  Contact toContact,
  String plaintext,
) async {
  logEvent(event.createdAt * 1000, fromContact, toContact, plaintext,
      rx: false);
  print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ store sent event');
  return insertEvent(
    event,
    fromContact,
    toContact,
    plaintext: plaintext,
  );
}

// called by relay socket
Future<void> storeReceivedEvent(
  nostr.Event event, {
  String? plaintext,
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
    // FIXME: toContact dones't have to be a local user!!!
    print('Filter: event destination is not a local user: ${receiver}');
    return;
  }
  print('#################################');
  print('Received event ${event.id}');
  print('receiver ${event.receiver}');
  print('sender ${event.pubkey}');
  print('#################################');

  Contact? fromContact = await getContactFromNpub(event.pubkey);
  if (fromContact == null) {
    // TODO: SPAM/DOS Protection
    print('New contact? From ${event.pubkey}');
    await createContact(
        [event.pubkey], "Unnamed"); // TODO: Look up name from directory
    fromContact = await getContactFromNpub(event.pubkey);
    print('@@@@@@@@@@@@@@@@@@@@@@ created contact $fromContact');
  }

  Npub receiveNpub = await getNpub(receiver!);
  String? plaintext = null;
  bool decryptError = false;
  try {
    plaintext = event.getPlaintext(receiveNpub.privkey);
  } catch (error) {
    decryptError = true;
  }

  logEvent(event.createdAt * 1000, fromContact!, toContact!,
      plaintext ?? "<not decrypted>",
      rx: true);
  insertEvent(
    event,
    fromContact,
    toContact,
    plaintext: plaintext ?? "",
    decryptError: decryptError,
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
  List<DbEvent> events,
  Contact userHint, [
  // Are these hint optimizations worth it?
  Contact? peerHint,
]) async {
  List<MessageEntry> messages = [];
  for (final event in events) {
    Npub npub = await getNpubFromId(event.pubkeyRef);
    Npub receiver = await getNpubFromId(event.receiverRef);
    Contact? from = await getContactFromNpub(npub.pubkey);
    Contact? to = await getContactFromNpub(receiver.pubkey);
    /* Stupid optimizations
    try {
      userHint.npubs.firstWhere((n) => n.pubkey == npub.pubkey);
      from = userHint;
      if (peerHint == null) {
        Npub receiver = await getNpubFromId(event.receiverRef);
        to = await getContactFromNpub(receiver.pubkey);
      } else {
        to = peerHint;
      }
    } catch (error) {
      to = userHint;
      from = peerHint == null ? await getContactFromNpub(npub.pubkey) : peerHint;
    }
    */
    messages
        .add(MessageEntry(npub, event, nostrEvent(npub, event), from!, to!));
  }
  return messages;
}

// Gets all messages to/from current user
Future<List<MessageEntry>> getUserMessages(Contact user) async {
  List<DbEvent> entries = await (database.select(database.dbEvents)
        ..where(
            (t) => t.toContact.equals(user.id) | t.fromContact.equals(user.id))
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

// Gets all messages from/to current user and particular contact
Future<List<MessageEntry>> getChatMessages(Contact user, Contact peer) async {
  List<DbEvent> entries = await (database.select(database.dbEvents)
        ..where((t) =>
            (t.toContact.equals(user.id) & t.fromContact.equals(peer.id)) |
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

// Watches all messages to/from current user
Stream<List<MessageEntry>> watchUserMessages(Contact user) async* {
  Stream<List<DbEvent>> entries = await (database.select(database.dbEvents)
        ..where(
            (m) => m.fromContact.equals(user.id) | m.toContact.equals(user.id))
        ..orderBy([
          (t) => OrderingTerm(
                expression: t.createdAt,
                mode: OrderingMode.desc,
              )
        ]))
      .watch();
  await for (final entryList in entries) {
    // intermediate step of converting to nostr events in order to
    // perform the decryption
    List<MessageEntry> messages = await messageEntries(entryList, user);
    yield messages;
  }
}

// Watches all messages from/to current user and particular contact
Stream<List<MessageEntry>> watchMessages(Contact user, Contact peer) async* {
  Stream<List<DbEvent>> entries = await (database.select(database.dbEvents)
        ..where((t) =>
            (t.toContact.equals(user.id) & t.fromContact.equals(peer.id)) |
            (t.toContact.equals(peer.id) & t.fromContact.equals(user.id)))
        ..orderBy([
          (t) => OrderingTerm(
                expression: t.createdAt,
                mode: OrderingMode.asc,
              )
        ]))
      .watch();
  await for (final entryList in entries) {
    List<MessageEntry> messages = await messageEntries(entryList, user, peer);
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

String npubPlaceHolder =
    "0000000000000000000000000000000000000000000000000000000000000000";

Future<Contact> createEmptyContact(String name,
    {bool isLocal = false, bool active = false}) async {
  final id = await database
      .into(database.contactNpubs)
      .insert(ContactNpubsCompanion());
  final contact = DbContact(
      id: id,
      name: name,
      surname: "",
      username: "",
      address: "",
      city: "",
      phone: "",
      email: "",
      email2: "",
      notes: "",
      picture_url: "",
      picture_pathname: "",
      isLocal: isLocal,
      active: active,
      npub: npubPlaceHolder);
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

Stream<List<DbContact>> watchAllContacts() {
  return database.select(database.dbContacts).watch();
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

Future<List<Contact>> getAllContacts() async {
  final contactQuery = database.select(database.dbContacts);

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

Future<List<Relay>> getAllRelays() {
  return database.select(database.relays).get();
}
