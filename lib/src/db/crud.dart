import 'package:drift/drift.dart';
import 'package:nostr/nostr.dart' as nostr;
import 'package:rxdart/rxdart.dart';

import 'db.dart';
import '../../config/settings.dart';
import '../../models/message_entry.dart';
import '../contact.dart' as contact;
import '../logging.dart';


Future<void> createContact(String npub, {String? name,}) async {
}


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


Future<void> createEvent(nostr.Event event, {String? plaintext, String? fromRelay,}) async {
  fromRelay ??= "";
  database.into(database.events).insert(
    EventsCompanion.insert(
      id: event.id,
      pubkey: event.pubkey,
      receiver: (event as nostr.EncryptedDirectMessage).receiver!,
      content: event.content,
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      fromRelay: fromRelay,
      kind: event.kind,
      plaintext: (plaintext != null) ? plaintext : "",
      decryptError: false,
    ),
    onConflict: DoNothing(),
  ).then((_) {
    // TODO: Either decrypt them later, on demand, OR do this in a separate thread.
    createEventHELPER(event, plaintext: plaintext, fromRelay: fromRelay);
  }).catchError((err) {
    if (err.toString().contains("UNIQUE constraint failed")) {
      // the entry already exists.
      return;
    }
    print(err);
    createEventHELPER(event, plaintext: plaintext, fromRelay: fromRelay);
  });
}

Future<void> updateEventPlaintext(
    nostr.Event event,
    String plaintext,
    bool decryptError,
    String fromRelay,
  ) async {
  final insert = EventsCompanion.insert(
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
    .into(database.events)
    .insert(insert, mode: InsertMode.insertOrReplace)
    .catchError((err) => print(err));
}

class NostrEvent extends nostr.EncryptedDirectMessage {
  final String plaintext;
  final int index;
  NostrEvent(nostr.Event event, this.plaintext, this.index): super(event, verify: false);
}

List<NostrEvent> nostrEvents(List<Event> entries) {
  List<NostrEvent> events = [];
  for (final entry in entries) {
    nostr.Event event = nostr.Event.partial();
    event.id = entry.id;
    event.pubkey = entry.pubkey;
    event.content = entry.content;
    event.createdAt = entry.createdAt.millisecondsSinceEpoch;
    event.kind = entry.kind;
    assert(event.kind == 4);
    // TODO: Need TAGS for id to pass isValid()
    events.add(NostrEvent(event, entry.plaintext!, entry.rowId));
  }
  return events;
}

Future<List<NostrEvent>> readEvent(String id) async {
  List<Event> entries = await (database.select(database.events)
        ..where((t) => t.id.equals(id)))
      .get();
  return nostrEvents(entries);
}

List<MessageEntry> messageEntries(List<NostrEvent> events) {
  List<MessageEntry> messages = [];
  for (final event in events) {
    messages.add(MessageEntry(
        content: event.plaintext,
        // check for if the pubkey is bob then he is the sender, ie local, sending to self
        source: (event.pubkey != getKey('bob', 'pub')) ? "remote" : "local",
        timestamp: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
        contact: contact.Contact(event.pubkey),
        index: event.index,
      )
    );
  }
  return messages;
}

Future<List<MessageEntry>> readMessages(int index) async {
  List<Event> entries = await
    (database
      .select(database.events)
      ..where((t) => t.rowId.isBiggerOrEqualValue(index))
      ..orderBy([(t) => OrderingTerm(
           expression: t.createdAt,
           mode: OrderingMode.desc,
      )])).get();
  List<NostrEvent> events = nostrEvents(entries);
  List<MessageEntry> messages = messageEntries(events);
  return messages;
}

Stream<List<MessageEntry>> watchMessages(int index) async* {
  Stream<List<Event>> entries = await (
    database
      .select(database.events)
      ..where((t) => t.rowId.isBiggerOrEqualValue(index))
    ).watch();
  await for (final entryList in entries) {
    List<NostrEvent> events = nostrEvents(entryList);
    List<MessageEntry> messages = messageEntries(events);
    yield messages;
  }
}

Future<List<Npub>> getNpubs() async {
  return database
    .select(database.npubs)
    .get();
}

Future<List<Npub>> getNpubsWithLabel(String label) async {
  return (database
    .select(database.npubs)
    ..where((n) => n.label.equals(label)))
    .get();
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

void insertContactIfNew(String name, {bool isLocal=false}) async {
  List<DbContact> entries = await getContactsWithName(name);

  if (entries.length > 0) {
    return;
  }

  database
    .into(database.dbContacts)
    .insert(DbContactsCompanion.insert(
        name: name,
        isLocal: isLocal,
      ),
    );
}

void insertNpub(String label, String pubkey) async {
  NpubsCompanion npub = NpubsCompanion.insert(
    pubkey: pubkey,
    label: label,
  );
  database
    .into(database.npubs)
    .insert(
      npub,
      onConflict: DoUpdate(
        (old) => npub,
        target: [database.npubs.pubkey],
      ),
    );
}


Future<void> writeContact(entry) async {
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

Future<Contact> getContactFromNpub(String publickey) async {
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

  return Contact(contacts[0], [npub]);
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

