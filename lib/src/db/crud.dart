import 'package:drift/drift.dart';
import 'package:nostr/nostr.dart' as nostr;

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
