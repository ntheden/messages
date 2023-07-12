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

Future<DbContact> getDbContact(int id) async {
  return (database.select(database.dbContacts)
    ..where((c) => c.id.equals(id))).getSingle();
}

Future<DbContact> getDbContactFromKey(String pubkey) async {
  return (database.select(database.dbContacts)
    ..where((c) => c.pubkey.equals(pubkey))).getSingle();
}

Future<Contact> createContact(
    String pubkey,
    String name,
    {String? privkey,
    }) async {

  bool isLocal = privkey == null ? false : true;

  DbContactsCompanion insertable = DbContactsCompanion.insert(
    pubkey: pubkey,
    name: name,
    privkey: privkey ?? "",
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
    createdAt: DateTime.now(),
    isLocal: isLocal,
    active: false,
    npub: pubkey,
  );

  await database.into(database.dbContacts).insert(
        insertable,
        onConflict: DoUpdate(
          (old) {
            return DbContactsCompanion.custom(
              name: Constant(name), // will add more fields once working right.
              privkey: privkey == null ? old.privkey : Constant(privkey),
            );
          },
          target: [database.dbContacts.pubkey],
        ),
      );

  DbContact dbContact = await getDbContactFromKey(pubkey);

  Contact contact = Contact(
    dbContact,
    [], // TODO
  );
  return contact;
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
    fromContact: fromContact.contact.id,
    toContact: toContact.contact.id,
    content: event.content,
    createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
    kind: event.kind,
    plaintext: plaintext ?? "",
    decryptError: decryptError ?? false,
  );
  return insert;
}

void insertEvent(
  nostr.Event event,
  Contact fromContact,
  Contact toContact, {
  String? plaintext,
  bool? decryptError,
}) async {
  try {
    await database.into(database.dbEvents).insert(
          _insertQuery(event, fromContact, toContact,
              plaintext: plaintext, decryptError: decryptError),
          onConflict: DoNothing(),
        );
  } catch (err) {
    // don't care, do nothing. Not sure why DoNothing() doesn't work
  }
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
void storeSentEvent(
  nostr.Event event,
  Contact fromContact,
  Contact toContact,
  String plaintext,
) async {
  logEvent(event.createdAt * 1000, fromContact, toContact, plaintext,
      rx: false);
  insertEvent(
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
  Contact? toContact = await getContactFromKey(receiver!);
  if (toContact == null || !toContact.isLocal) {
    // TODO: This must be optimized.
    // FIXME: toContact dones't have to be a local user!!!
    print('Filter: event destination is not a local user: ${receiver}');
    return;
  }
  Contact? fromContact = await getContactFromKey(event.pubkey);
  if (fromContact == null) {
    // TODO: SPAM/DOS Protection
    print('New contact? From ${event.pubkey}');
    await createContact(
      event.pubkey,
      "Unnamed", // TODO: Look up name from directory
    );
    fromContact = await getContactFromKey(event.pubkey);
    print('created contact $fromContact');
  }

  String? plaintext = null;
  bool decryptError = false;
  try {
    plaintext = event.getPlaintext(toContact.privkey);
  } catch (error) {
    decryptError = true;
  }

  logEvent(
    event.createdAt * 1000,
    fromContact!,
    toContact!,
    plaintext ?? "<not decrypted>",
    rx: true
  );
  insertEvent(
    event,
    fromContact,
    toContact,
    plaintext: plaintext ?? "",
    decryptError: decryptError,
  );
}

nostr.EncryptedDirectMessage nostrEvent(String pubkey, DbEvent event) {
  nostr.Event nEvent = nostr.Event.partial();
  nEvent.id = event.eventId;
  nEvent.pubkey = pubkey;
  nEvent.content = event.content;
  nEvent.createdAt = event.createdAt.millisecondsSinceEpoch;
  nEvent.kind = event.kind;
  // TODO: Need TAGS for id to pass isValid()
  return nostr.EncryptedDirectMessage(nEvent, verify: false);
}

Future<List<MessageEntry>> getMessagesHELPER(
  List<DbEvent> events,
) async {
  List<MessageEntry> messages = [];
  for (final event in events) {
    final fromContact = await getContactFromId(event.fromContact);
    messages.add(
      MessageEntry(
        event,
        nostrEvent(fromContact.pubkey, event),
        fromContact,
        await getContactFromId(event.toContact),
      )
    );
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
  List<MessageEntry> messages = await getMessagesHELPER(entries);
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
  List<MessageEntry> messages = await getMessagesHELPER(entries);
  return messages;
}

// Watches all messages to/from current user
Stream<List<MessageEntry>> watchUserMessages(Contact user, {
    OrderingMode orderingMode: OrderingMode.asc
  }) async* {
  Stream<List<DbEvent>> entries = await (database.select(database.dbEvents)
        ..where(
            (m) => m.fromContact.equals(user.id) | m.toContact.equals(user.id))
        ..orderBy([
          (t) => OrderingTerm(
                // this doesn't seem to work
                expression: t.createdAt,
                mode: orderingMode,
              )
        ]))
      .watch();
  await for (final entryList in entries) {
    // intermediate step of converting to nostr events in order to
    // perform the decryption
    List<MessageEntry> messages = await getMessagesHELPER(entryList);
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
    List<MessageEntry> messages = await getMessagesHELPER(entryList);
    yield messages;
  }
}

Future<List<DbContact>> getContactsWithName(String name) async {
  return (database.select(database.dbContacts)
        ..where((c) => c.name.equals(name)))
      .get();
}

Stream<Contact> watchContact(int id) async* {
  final contactQuery = database.select(database.dbContacts)
    ..where((contact) => contact.id.equals(id));

  await for (final contact in contactQuery.watchSingle()) {
    yield Contact(contact, []);
  }
}

Stream<List<DbContact>> watchAllUsers() {
  final contactQuery = database.select(database.dbContacts)
    ..where((c) => c.isLocal.equals(true));

  return contactQuery.watch();
}

Stream<List<DbContact>> watchAllDbContacts() {
  // Would be cool to transform this stream into a Stream<List<Contact>>
  // and return that.
  return database.select(database.dbContacts).watch();
}

Future<Contact?> getContactFromKey(String publickey) async {
  final contactsQuery = database.select(database.dbContacts)
    ..where((c) => c.pubkey.equals(publickey));

  DbContact? contact;
  try {
    contact = await contactsQuery.getSingle();
    return Contact(contact, []);
  } catch (error) {
    // didn't find it
  }
  return null;
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

Future<List<Contact>> getContacts(List<int> ids, {
  OrderingMode orderingMode: OrderingMode.asc,
}) async {
  final contactQuery = database.select(database.dbContacts)
    ..where((c) => c.id.isIn(ids))
    ..orderBy([
      (c) => OrderingTerm(
            expression: c.createdAt,
            mode: orderingMode,
          )
    ]);

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
  final contactQuery = database.select(database.dbContacts)
    ..where((c) => c.id.equals(contact.id));
  return Contact(contact, []);
}

Future<int> insertRelay({
  required String url,
  required bool read,
  required bool write,
  List<String> groups: const [], // TODO
  String notes: "",
}) async {
  DbRelaysCompanion relay = DbRelaysCompanion.insert(
    url: url,
    notes: notes,
    read: read,
    write: read,
  );
  return database.into(database.dbRelays).insert(
        relay,
        onConflict: DoUpdate(
          (old) => DbRelaysCompanion.custom(
            notes: notes.isEmpty ? old.notes : Constant(notes),
            read: Constant(read),
            write: Constant(write),
          ),
          target: [database.dbRelays.url],
        ),
      );
}

Future<Relay?> getRelay(String url) async {
  try {
    DbRelay relay = await ((database.select(database.dbRelays)
      ..where((r) => r.url.equals(url))).getSingle());
    return Relay(relay, []);
  } catch (error) {
    return null;
  }
}

List<Relay> getRelaysHELPER(relaysList) {
  List<Relay> relays = [];
  for (final relay in relaysList) {
    relays.add(Relay(relay, []));
  }
  return relays;
}

Future<List<Relay>> getAllRelays() async {
  final List<DbRelay> entries = await (database.select(database.dbRelays).get());
  return getRelaysHELPER(entries);
}

Stream<List<Relay>> watchAllRelays() async* {
  Stream<List<DbRelay>> entries = await (database.select(database.dbRelays).watch());
  await for (final entryList in entries) {
    yield getRelaysHELPER(entryList);
  }
}

Future<void> deleteRelay(String url) async {
  (database.delete(database.dbRelays)..where((r) => r.url.equals(url))).go();
}

