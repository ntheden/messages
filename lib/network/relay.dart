import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:nostr/nostr.dart' as nostr;

import '../db/crud.dart';
import '../db/db.dart' as db;
import 'network.dart';

class DeferredEvent {
  nostr.Event event;
  db.Contact toContact;

  DeferredEvent(this.event, this.toContact);
}

class Relay {
  final String url;
  final bool read;
  final bool write;
  final Network network;
  bool _listening = false;
  bool _connected = false;
  late WebSocketChannel _channel;
  List<int>? supportedNips;
  Map<String, Queue<DeferredEvent>> queues = {};
  String _subscriptionId = '';

  WebSocketChannel get channel => _channel;

  Relay(this.url, this.network, {this.read: true, this.write: true}) {
    channelConnect(url);
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

  factory Relay.fromDb(db.Relay relay, Network network) {
    return Relay(
      relay.url,
      network,
      read: relay.read,
      write: relay.write,
    );
  }

  void channelConnect(String host) {
    if (!host.startsWith(RegExp(r'^(wss?://)'))) {
      host = 'wss://' + host.split('//').last;
    }
    _channel = WebSocketChannel.connect(Uri.parse(host));
    _connected = true;
  }

  void subscribe() {
    // TODO: query supported nips
    // TODO: make consistent with listen, like accept filter as arg
    // and re-subscribe if it changed or something
    print('$url SUBSCRIBE CALLED');
    if (read == false ||  network.filters.isEmpty || network.subscriptionId.isEmpty) {
      print('$url NOT SUBSCRIBING NOW');
      return;
    }
    if (_subscriptionId == network.subscriptionId) {
      // we already have this subscription
      print('$url ALREADY HAVE THIS SUBSCRIPTION (subscribing anyways)');
      //return;
    }
    _subscriptionId = network.subscriptionId;
    nostr.Request requestWithFilter = nostr.Request(_subscriptionId, network.filters);
    print('TO $url: ${requestWithFilter.serialize()}');
    _channel.sink.add(requestWithFilter.serialize());
  }

  void listen(void Function(dynamic)? func) {
    print('$url LISTEN CALLED $func');
    if (_listening) {
      print('$url ALREADY LISTENING');
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
      if ([m.type,].contains("EVENT")) {
        if (network.uniqueIdsReceived.contains(m.message.id)) {
          return;
        }
        network.uniqueIdsReceived.add(m.message.id);
        storeDirectMessage(m.message);
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

  Future<void> storeDirectMessage(nostr.Event event) async {
    String? receiver = (event as nostr.EncryptedDirectMessage).receiver;
    if (receiver == null || !network.recipients.contains(receiver)) {
      // - null: Filter: event destination (tag p) is not present, required for NIP04
      // - not in recipient list: filter it
      return;
    }
    try {
      db.DbEvent entry = await getEvent(event.id);
      // If it's there then nothing to do
      return;
    } catch (err) {
      // event hasn't been seen/stored
    }
    db.Contact? toContact = await getContactFromKey(receiver!);
    if (toContact == null || !toContact.isLocal) {
      // TODO: This must be optimized, avoid db lookup every rx
      print("TODO: receiver pubkey list");
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
      return receiveBottom(event, fromContact, toContact);
    }
    if (queues.containsKey(pubkey)) {
      queues[pubkey]?.add(DeferredEvent(event, toContact));
    } else {
      queues[pubkey] = Queue<DeferredEvent>();
      queues[pubkey]?.add(DeferredEvent(event, toContact));
      // TODO: Look up name from directory
      // TODO: SPAM/DOS Protection
      createContact(pubkey, "Unnamed",
          ).then((_) => getContactFromKey(pubkey).then((fromContact) {
                // TODO: batch these
                Queue<DeferredEvent> q = queues[pubkey]!;
                while (q.isNotEmpty) {
                  DeferredEvent ev = q.removeFirst();
                  receiveBottom(ev.event, fromContact!, ev.toContact);
                }
              }));
    }
  }

  void receiveBottom(nostr.Event event, db.Contact fromContact,
      db.Contact toContact) async {
    String? plaintext = null;
    bool decryptError = false;
    assert(toContact.privkey.isNotEmpty);
    try {
      plaintext = (event as nostr.EncryptedDirectMessage)
          .getPlaintext(toContact.privkey);
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
