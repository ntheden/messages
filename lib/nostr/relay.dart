import 'dart:collection';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:nostr/nostr.dart' as nostr;

import '../db/crud.dart';
import '../db/db.dart' as db;

class DeferredEvent {
  nostr.Event event;
  String receiver;
  db.Contact toContact;

  DeferredEvent(this.event, this.receiver, this.toContact);
}

class Relay {
  String url;
  Map<String, WebSocketChannel> socketMap = {};
  List<int>? supportedNips;
  List<nostr.Filter> filters = [
    nostr.Filter(
      //kinds: [0, 1, 4, 2, 7],
      kinds: [4],
      since:
          1681878751, // TODO: Today minus 30 or something, or based on last received in db
      limit: 450,
    )
  ];
  Map<String, Queue<DeferredEvent>> queues = {};

  Relay(this.url, [filters]) {
    this.filters = this.filters + (filters ?? []);
    socketMap[url] = socketConnect(url);
    subscribe();
  }

  WebSocketChannel get socket => socketMap[url]!;

  static WebSocketChannel socketConnect(String host) {
    host = host.split('//').last;
    WebSocketChannel socket;
    try {
      // with 'wss' seeing WRONG_VERSION_NUMBER error against some servers
      socket = WebSocketChannel.connect(Uri.parse('ws://${host}'));
    } on HandshakeException catch (e) {
      socket = WebSocketChannel.connect(Uri.parse('wss://${host}'));
    }
    return socket;
  }

  void subscribe() {
    // TODO: query supported nips
    nostr.Request requestWithFilter =
        nostr.Request(nostr.generate64RandomHexChars(), filters);
    print('sending request: ${requestWithFilter.serialize()}');
    socket.sink.add(requestWithFilter.serialize());
  }

  void listen(void Function(dynamic)? func) {
    func ??= (data) {
      if (data == null || data == 'null') {
        return;
      }
      nostr.Message? m;
      try {
        m = nostr.Message.deserialize(data);
      } catch (error) {
        // error deserializing. Log it (maybe) and punt
        return;
      }
      if ([
        m!.type,
      ].contains("EVENT")) {
        storeEvent(m.message);
      }
    };
    socket.stream.listen(
      func,
      onError: (err) => print("Error in creating connection to $url."),
      onDone: () => print('Relay[$url]: In onDone'),
    );
  }

  Future<void> storeEvent(nostr.Event event) async {
    try {
      db.DbEvent entry = await getEvent(event.id);
      // If it's there then nothing to do
      return;
    } catch (err) {
      // event hasn't been seen/stored
    }

    String? receiver = (event as nostr.EncryptedDirectMessage).receiver;
    if (receiver == null) {
      print('{url} Filter: event destination (tag p) is not present');
      return;
    }
    db.Contact? toContact = await getContactFromNpub(receiver!);
    if (toContact == null || !toContact.isLocal) {
      // TODO: This must be optimized, avoid db lookup every rx
      return;
    }
    print('#################################');
    print(url);
    print('Received event ${event.id}');
    print('receiver ${event.receiver}');
    print('sender ${event.pubkey}');
    print('#################################');

    String pubkey = event.pubkey;
    db.Contact? fromContact = await getContactFromNpub(pubkey);
    if (fromContact != null) {
      return receiveBottom(event, fromContact, toContact, receiver!);
    }
    if (queues.containsKey(pubkey)) {
      queues[pubkey]?.add(DeferredEvent(event, receiver, toContact));
    } else {
      queues[pubkey] = Queue<DeferredEvent>();
      queues[pubkey]?.add(DeferredEvent(event, receiver, toContact));
      // TODO: Look up name from directory
      // TODO: SPAM/DOS Protection
      createContact([pubkey], "Unnamed", DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
          ).then((_) => getContactFromNpub(pubkey).then((fromContact) {
                // TODO: batch these
                Queue<DeferredEvent> q = queues[pubkey]!;
                while (q.isNotEmpty) {
                  DeferredEvent ev = q.removeFirst();
                  receiveBottom(
                      ev.event, fromContact!, ev.toContact, ev.receiver);
                }
              }));
    }
  }

  void receiveBottom(nostr.Event event, db.Contact fromContact,
      db.Contact toContact, String receiver) async {
    db.Npub receiveNpub = await getNpub(receiver);
    String? plaintext = null;
    bool decryptError = false;
    try {
      plaintext = (event as nostr.EncryptedDirectMessage)
          .getPlaintext(receiveNpub.privkey);
    } catch (error) {
      decryptError = true;
    }
    storeReceivedEvent(event);
  }

  void close() {
    try {
      socket.sink.close();
    } catch (err) {
      // TODO: Logging
      print('Close exception error $err for relay $url');
    }
  }

  Future<void> send(String request) async {
    socket.sink.add(request);
    // TODO: check the return OK if relay supports that NIP
  }

  Future<void> sendEvent(nostr.Event event, db.Contact from, db.Contact to,
      [String? plaintext]) async {
    // we don't await it, but we might want to to get confirmation
    send(event.serialize());
  }
}
