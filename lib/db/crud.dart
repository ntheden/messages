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

Future<DbContact> getDbContactFromKey(String npub) async {
  return (database.select(database.dbContacts)
    ..where((c) => c.npub.equals(npub))).getSingle();
}

Future<Contact> createContactFromKey(
    NostrKey npub,
    String name) async {

  bool isLocal = npub.privkey.length > 0 ? true : false;

  DbContactsCompanion insertable = DbContactsCompanion.insert(
    name: name,
    username: "",
    surname: "",
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
    npub: npub.pubkey,
    keyRef: npub.id,
  );

  await database.into(database.dbContacts).insert(
        insertable,
        onConflict: DoUpdate(
          (old) {
            return DbContactsCompanion.custom(
              name: Constant(name), // will add more fields once working right.
            );
          },
          target: [database.dbContacts.npub],
        ),
      );

  DbContact dbContact = await getDbContactFromKey(npub.pubkey);

  Contact contact = Contact(
    await getDbContactFromKey(npub.pubkey),
    npub,
    [], // TODO
  );
  writeContact(contact);
  return contact;
}

Future<Contact> createContact(
  npub,
  String name,
  DateTime createdAt, {
  bool isLocal = false,
  bool active = false,
}) async {
  NostrKey key = await getKeyFromNpub(npub);
  return createContactFromKey(key, name);
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
    pubkeyRef: fromContact.key.id,
    receiverRef: toContact.key.id,
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
  Contact? toContact = await getContactFromKey(receiver!);
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

  Contact? fromContact = await getContactFromKey(event.pubkey);
  if (fromContact == null) {
    // TODO: SPAM/DOS Protection
    print('New contact? From ${event.pubkey}');
    await createContact(
      [event.pubkey],
      "Unnamed", // TODO: Look up name from directory
      DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
    );
    fromContact = await getContactFromKey(event.pubkey);
    print('created contact $fromContact');
  }

  NostrKey receiveNpub = await getKeyFromNpub(receiver!);
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

nostr.EncryptedDirectMessage nostrEvent(NostrKey npub, DbEvent event) {
  nostr.Event nEvent = nostr.Event.partial();
  nEvent.id = event.eventId;
  nEvent.pubkey = npub.pubkey;
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
    NostrKey npub = await getKeyFromId(event.pubkeyRef);
    NostrKey receiver = await getKeyFromId(event.receiverRef);
    Contact? from = await getContactFromKey(npub.pubkey);
    Contact? to = await getContactFromKey(receiver.pubkey);
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

Future<NostrKey> getKeyFromNpub(String publickey) async {
  return (database.select(database.nostrKeys)
        ..where((n) => n.pubkey.equals(publickey)))
      .getSingle();
}

Future<List<NostrKey>> getKeys() async {
  return database.select(database.nostrKeys).get();
}

Future<NostrKey> getKeyFromId(int id) async {
  return (database.select(database.nostrKeys)..where((n) => n.id.equals(id)))
      .getSingle();
}

Future<List<DbContact>> getContactsWithName(String name) async {
  return (database.select(database.dbContacts)
        ..where((c) => c.name.equals(name)))
      .get();
}

Future<int> insertKey(String pubkey, String label, {String? privkey}) async {
  NostrKeysCompanion npub = NostrKeysCompanion.insert(
    pubkey: pubkey,
    label: label,
    privkey: privkey ?? "",
  );

  return database.into(database.nostrKeys).insert(
        npub,
        onConflict: DoUpdate(
          (old) {
            return NostrKeysCompanion.custom(
              privkey: privkey == null ? old.privkey : Constant(privkey),
              label: Constant(label),
            );
          },
          target: [database.nostrKeys.pubkey],
        ),
      );
}

Future<void> writeContact(Contact entry) async {
  DbContact contact = entry.contact;

  await database
      .into(database.dbContacts)
      .insert(contact, mode: InsertMode.replace);
}

Stream<Contact> watchContact(int id) async* {
  final contactQuery = database.select(database.dbContacts)
    ..where((contact) => contact.id.equals(id));

  await for (final contact in contactQuery.watchSingle()) {
    yield Contact(contact, await(getKeyFromId(contact.keyRef)), []);
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
  final keyQuery = database.select(database.nostrKeys)
    ..where((n) => n.pubkey.equals(publickey));

  NostrKey npub;
  try {
    npub = await keyQuery.getSingle();
  } catch (error) {
    print("key not in db, return null");
    return null;
  }

  final contactsQuery = database.select(database.dbContacts)
    ..where((c) => c.keyRef.equals(npub.id));

  DbContact? contact;
  try {
    contact = await contactsQuery.getSingle();
  } catch (error) {
    print("Error find contact with this key, create new contact");
  }

  if (contact != null) {
    return Contact(contact, npub, []);
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
  final keyQuery = await database.select(database.nostrKeys)
    ..where((k) => k.id.equals(contact.keyRef));
  return Contact(contact, await keyQuery.getSingle(), []);
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

