import 'dart:async';
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

class Node {
  final String url;
  final bool read;
  final bool write;
  bool _listening = false;
  late WebSocketChannel _channel;
  List<int>? supportedNips;
  Map<String, Queue<DeferredEvent>> queues = {};

  WebSocketChannel get channel => _channel;

  Node(this.url, {this.read: true, this.write: true}) {
    _channel = channelConnect(url);
  }

  @override
  String toString() {
    return (StringBuffer('Node(')
          ..write('url: $url, ')
          ..write('read: $read, ')
          ..write('write: $write, ')
          ..write(')'))
        .toString();
  }

  factory Node.fromDb(db.Relay relay) {
    return Node(
      relay.url,
      read: relay.read,
      write: relay.write,
    );
  }

  static WebSocketChannel channelConnect(String host) {
    if (!host.startsWith(RegExp(r'^(wss?://)'))) {
      host = 'wss://' + host.split('//').last;
    }
    return WebSocketChannel.connect(Uri.parse(host));
  }

  void subscribe(String subscriptionId, List<nostr.Filter> filters) {
    // TODO: query supported nips
    nostr.Request requestWithFilter = nostr.Request(subscriptionId, filters);
    print('${url} ${requestWithFilter.serialize()}');
    _channel.sink.add(requestWithFilter.serialize());
  }

  void listen([void Function(dynamic)? func]) {
    if (_listening) {
      close();
    }
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
    _listening = true;
    _channel.stream.listen(
      func,
      onError: (err) => _listening = false,
      onDone: () => _listening = false,
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
      // Filter: event destination (tag p) is not present
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
      _channel.sink.close();
      _listening = false;
    } catch (err) {
      // TODO: Logging
      print('Close exception error $err for relay $url');
    }
  }

  Future<void> send(String request) async {
    _channel.sink.add(request);
    // TODO: check the return OK if relay supports that NIP
  }

  Future<void> sendEvent(nostr.Event event, db.Contact from, db.Contact to,
      [String? plaintext]) async {
    // we don't await it, but we might want to get confirmation
    send(event.serialize());
  }
}
