import 'dart:io';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:nostr/nostr.dart';

import '../db/crud.dart';
import '../db/db.dart' as db;
import 'relay.dart';


class Relays {
  String groupName; // private relay, group/org relay, public relay, etc.
  List<Relay> _relays = [];
  Set<Event>? rEvents;
  Set<String>? uniqueIdsReceived; // to reject duplicates, but may check database instead

    
  Relays({
    this.groupName='default',
  }) {
    _relays = [];
    rEvents = {};
    uniqueIdsReceived = {};
  }

  void close() {
    _relays.forEach((relay) {
      relay.close();
    });
  }

  void addRelay(Relay relay) {
    // TODO: properties such as read/write may have changed
    if (relay.channel != null) {
      _relays.add(relay);
    }
  }

  void add(url) {
    Relay relay = Relay(url);
    if (relay.channel != null) {
      _relays.add(relay);
    }
  }

  send(String request) {
    _relays.forEach((relay) {
      relay.send(request);
    });
  }

  sendMessage(
    String content, {
    required db.Contact from,
    required db.Contact to
  }) {
    EncryptedDirectMessage event = EncryptedDirectMessage.redact(
      from.privkey,
      to.pubkey,
      content,
    );
    sendEvent(event, from, to, content);
  }

  sendEvent(Event event, from, to, plaintext) {
    assert(_relays.isNotEmpty);
    _relays.forEach((relay) {
      relay.sendEvent(event, from, to, plaintext);
    });
    storeSentEvent(event, from, to, plaintext);
  }

  void listen([void Function(dynamic)? func=null]) {
    _relays.forEach((relay) {
      relay.listen(func);
    });
  }
}


RelaysWatcher? watcher;


Relays getRelays() {
  if (watcher != null) {
    return watcher!.relays;
  }
  watcher = RelaysWatcher();
  return watcher!.relays;
}


class RelaysWatcher {
  late Relays relays;
  late StreamController<List<db.Relay>> _stream;
  late StreamSubscription<List<db.Relay>> _subscription;

  RelaysWatcher() {
    relays = Relays();
    _stream = StreamController<List<db.Relay>>();
    _stream.addStream(watchAllRelays());
    _subscription = _stream.stream.listen((entries) {
      for (final db.Relay relay in entries) {
        // TODO: manage these fully
        if (!relays._relays.any((entry) => entry.url == relay.url)) {
          relays.addRelay(Relay.fromDb(relay));
        }
      }
      relays.listen();
    });
  }

  void close() {
    _subscription.cancel();
    _stream.close();
  }
}
