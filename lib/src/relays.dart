import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:nostr/nostr.dart';

import '../config/settings.dart';
import 'db/crud.dart';
import 'db/db.dart' as db;
import 'relay.dart';


class Relays {
  String groupName; // private relay, group/org relay, public relay, etc.
  List<Relay>? relays;
  Set<Event>? rEvents;
  Set<String>? uniqueIdsReceived; // to reject duplicates, but may check database instead
  Set<String> pubkeys;

    
  Relays(this.pubkeys, {
    this.groupName='default',
  }) {
    relays = [];
    rEvents = {};
    uniqueIdsReceived = {};
  }

  void close() {
    relays?.forEach((relay) {
      relay.close();
    });
  }

  void add(name, url) {
    Relay relay = Relay(name, url);
    if (relay.socketMap[name] != null) {
      relays?.add(relay);
    }
  }

  send(String request) {
    relays?.forEach((relay) {
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

  sendEvent(Event event, from, to, [String? plaintext]) {
    relays?.forEach((relay) {
      relay.sendEvent(event, from, to, plaintext);
    });
  }

  void listen({bool Function(dynamic)? action=null}) {
    relays?.forEach((relay) {
      relay.listen(
        (data) {
          if (data == null || data == 'null') {
              return false;
            }
          if (action?.call(data) ?? false)
            return false;
          return true;
        },
      );
    });
  }
}
