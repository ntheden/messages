import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:web_socket_channel/io.dart';
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
  final String url;
  final bool read;
  final bool write;
  bool _listening = false;
  bool _connected = false;
  late WebSocketChannel _channel;
  List<int>? supportedNips;
  List<nostr.Filter> _filters = [];
  Map<String, Queue<DeferredEvent>> queues = {};

  WebSocketChannel get channel => _channel;
  void set filters(List<nostr.Filter> newFilters) => _filters = newFilters;

  Relay(this.url, {this.read: true, this.write: true, List<nostr.Filter>? filters,}) {
    _filters = _filters + (filters ?? []);
    channelConnect(url);
    if (read == true && _filters.isNotEmpty) {
      subscribe();
    }
  }

  @override
  String toString() {
    return (StringBuffer('Relay(')
          ..write('url: $url, ')
          ..write('read: $read, ')
          ..write('write: $write, ')
          ..write(')'))
        .toString();
  }

  factory Relay.fromDb(db.Relay relay, [filters]) {
    return Relay(
      relay.url,
      read: relay.read,
      write: relay.write,
      filters: filters
    );
  }

  void channelConnect(String host) {
    if (!host.startsWith(RegExp(r'^(wss?://)'))) {
      host = 'wss://' + host.split('//').last;
    }
    _channel = IOWebSocketChannel.connect(Uri.parse(host));
    _connected = true;
  }

  void subscribe() {
    // TODO: query supported nips
    nostr.Request requestWithFilter =
        nostr.Request(nostr.generate64RandomHexChars(), _filters);
    print('sending request: ${requestWithFilter.serialize()}');
    _channel.sink.add(requestWithFilter.serialize());
  }

  void listen(void Function(dynamic)? func) {
    if (_listening) {
      return;
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
      onError: (err) {
        _listening = false;
        print('onError: $url');
        print('$err');
      },
      onDone: () {
        _connected = false;
        print('onDone: $url');
      },
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
    db.Contact? toContact = await getContactFromKey(receiver!);
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
    db.Contact? fromContact = await getContactFromKey(pubkey);
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
          ).then((_) => getContactFromKey(pubkey).then((fromContact) {
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
    db.NostrKey receiveNpub = await getKeyFromNpub(receiver);
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
