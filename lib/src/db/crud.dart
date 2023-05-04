import 'package:drift/drift.dart';
import 'package:nostr/nostr.dart' as nostr;
import 'package:rxdart/rxdart.dart';

import 'db.dart';
import '../../config/settings.dart';
import '../../models/message_entry.dart';
import '../contact.dart' as contact;
import '../logging.dart';


Future<Contact> createContact(
    List<String> npubs,
    String name, {
    bool isLocal=false
  }) async {

  for (String npub in npubs) {
    int npubId = await insertNpub(npub, name);
  }
  
  final contactId = await database
    .into(database.dbContacts)
    .insert(DbContactsCompanion.insert(
        name: name,
        isLocal: isLocal,
      ),
    );

  final List<Npub> npubEntries = [];
  for (String npub in npubs) {
    npubEntries.add(await getNpub(npub));
  }

  Contact contact = Contact(
    DbContact(
      id: contactId,
      name: name,
      isLocal: isLocal
    ),
    npubEntries
  );
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
  return (database
    .select(database.dbEvents)
    ..where((e) => e.eventId.equals(id)))
    .getSingle();
}


Future<int> createEvent(nostr.Event event, {String? plaintext, String? fromRelay,}) async {
  fromRelay ??= "";
  try {
    DbEvent entry = await getEvent(event.id);
    // If it's there then nothing to do
    return entry.id;
  } catch (err) {
    print('Creating event ${event.id}');
  }

  int pubkeyRef;
  try {
    Npub npub = await getNpub(event.pubkey);
    pubkeyRef = npub.id;
  } catch (err) {
    pubkeyRef = await insertNpub(event.pubkey, "no name");
  }

  String? receivePubkey = (event as nostr.EncryptedDirectMessage).receiver;
  int receiverId = 0;
  if (receivePubkey != null) {
    try {
      Npub receiver = await getNpub(receivePubkey);
      receiverId = receiver.id;
    } catch (err) {
      receiverId = await insertNpub(receivePubkey, "no name");
    }
  }

  logEvent(event, plaintext ?? "<not decrypted>");

  final insert = DbEventsCompanion.insert(
    eventId: event.id,
    pubkeyRef: pubkeyRef,
    receiverRef: receiverId,
    content: event.content,
    createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
    fromRelay: fromRelay, // relay this event is received from, should be ref
    kind: event.kind,
    plaintext: (plaintext != null) ? plaintext : "",
    decryptError: false,
  );

  return database
    .into(database.dbEvents).insert(
      insert,
      onConflict: DoNothing(),
    );
}

class NostrEvent extends nostr.EncryptedDirectMessage {
  final String plaintext;
  final int index;
  NostrEvent(nostr.Event event, this.plaintext, this.index): super(event, verify: false);
}

Future<List<NostrEvent>> nostrEvents(List<DbEvent> entries) async {
  List<NostrEvent> events = [];
  for (final entry in entries) {
    nostr.Event event = nostr.Event.partial();
    event.id = entry.eventId;
    event.pubkey = (await getNpubFromId(entry.pubkeyRef)).pubkey;
    event.content = entry.content;
    event.createdAt = entry.createdAt.millisecondsSinceEpoch;
    event.kind = entry.kind;
    assert(event.kind == 4);
    // TODO: Need TAGS for id to pass isValid()
    events.add(NostrEvent(event, entry.plaintext!, entry.id));
  }
  return events;
}

Future<List<NostrEvent>> readEvent(String id) async {
  List<DbEvent> entries = await (database.select(database.dbEvents)
        ..where((t) => t.eventId.equals(id)))
      .get();
  return nostrEvents(entries);
}

Future<List<MessageEntry>> messageEntries(List<NostrEvent> events) async {
  List<MessageEntry> messages = [];
  for (final event in events) {
    Contact? contact = await getContactFromNpub(event.pubkey);
    if (contact == null) {
      contact = await createContact([event.pubkey], "no name");
    }
    messages.add(MessageEntry(
        content: event.plaintext,
        // check for if the pubkey is bob then he is the sender, ie local, sending to self
        source: contact.isLocal ? "local" : "remote",
        timestamp: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
        contact: contact,
        index: event.index,
      )
    );
  }
  return messages;
}

Future<List<MessageEntry>> readMessages(int index) async {
  List<DbEvent> entries = await
    (database
      .select(database.dbEvents)
      ..where((t) => t.id.isBiggerOrEqualValue(index))
      ..orderBy([(t) => OrderingTerm(
           expression: t.createdAt,
           mode: OrderingMode.desc,
      )])).get();
  List<MessageEntry> messages = await messageEntries(await nostrEvents(entries));
  return messages;
}

Stream<List<MessageEntry>> watchMessages(int index) async* {
  Stream<List<DbEvent>> entries = await (
    database
      .select(database.dbEvents)
      ..where((t) => t.id.isBiggerOrEqualValue(index))
    ).watch();
  await for (final entryList in entries) {
    // intermediate step of converting to nostr events in order to
    // perform the decryption
    List<MessageEntry> messages = await messageEntries(await nostrEvents(entryList));
    yield messages;
  }
}

Future<Npub> getNpub(String publickey) async {
  return (database
    .select(database.npubs)
    ..where((n) => n.pubkey.equals(publickey)))
    .getSingle();
}

Future<List<Npub>> getNpubs() async {
  return database
    .select(database.npubs)
    .get();
}

Future<Npub> getNpubFromId(int id) async {
  return (database
    .select(database.npubs)
    ..where((n) => n.id.equals(id)))
    .getSingle();
}

Future<List<DbContact>> getContacts() async {
  return database
    .select(database.dbContacts)
    .get();
}

Future<List<DbContact>> getContactsWithName(String name) async {
  return (database
    .select(database.dbContacts)
    ..where((c) => c.name.equals(name)))
    .get();
}

Future<int> insertNpub(String pubkey, String label) async {
  NpubsCompanion npub = NpubsCompanion.insert(
    pubkey: pubkey,
    label: label,
  );
  return database
    .into(database.npubs)
    .insert(
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

  await (database
    .delete(database.contactNpubs)
    ..where((item) => item.contact.equals(contact.id))
  ).go();

  for (final npub in entry.npubs) {
    await database
      .into(database.contactNpubs)
      .insert(ContactNpubsCompanion.insert(
        contact: contact.id,
        npub: npub.id,
      )
    );
  }
}

Future<Contact> createEmptyContact(String name, {bool isLocal=false}) async {
  final id = await database
    .into(database.contactNpubs)
    .insert(ContactNpubsCompanion());
  final contact = DbContact(id: id, name: name, isLocal: isLocal);
  return Contact(contact, []);
}


Stream<Contact> watchContact(int id) {
  final contactQuery = database
    .select(database.dbContacts)
    ..where((contact) => contact.id.equals(id));

  final npubsQuery = database
    .select(database.contactNpubs)
    .join(
      [
        innerJoin(
          database.npubs,
          database.npubs.id.equalsExp(database.contactNpubs.npub),
        ),
      ],
    )
    ..where(database.contactNpubs.contact.equals(id));

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
  final npubQuery = database
    .select(database.npubs)
    ..where((n) => n.pubkey.equals(publickey));

  final npub = await npubQuery.getSingle();

  final contactsQuery = database
    .select(database.contactNpubs)
    .join(
      [
        innerJoin(
          database.dbContacts,
          database.dbContacts.id.equalsExp(database.contactNpubs.contact),
        ),
      ],
    )
    ..where(database.contactNpubs.npub.equals(npub.id));

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

Future<Contact> getContact(int id) async {
  final contactQuery = database
    .select(database.dbContacts)
    ..where((t) => t.id.equals(id));

  final npubsQuery = database
    .select(database.contactNpubs)
    .join(
      [
        innerJoin(
          database.npubs,
          database.npubs.id.equalsExp(database.contactNpubs.npub),
        ),
      ],
    )
    ..where(database.contactNpubs.contact.equals(id));

  final npubs = (await npubsQuery.get()).map((row) {
    return row.readTable(database.npubs);
  }).toList();

  return Contact(await contactQuery.getSingle(), npubs);
}

