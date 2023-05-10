import 'package:nostr/nostr.dart';

import 'db.dart';
import 'crud.dart';
import '../nostr/relays.dart';
import '../config/settings.dart';

class EventSink {
  //late User user;
  //late Relays relays;
  List<Npub> npubs;
  Set<String> pubkeys = {};
  Relays? relays;

  //EventSink(this.user, this.relays);
  EventSink(this.npubs) {
    npubs.forEach((npub) => pubkeys.add(npub.pubkey));
    relays = getRelays(pubkeys);
  }

  listen() {
    relays?.listen();
  }

  close() {
    relays?.close();
  }
}

EventSink? sink;

void runEventSink() async {
  if (sink != null) {
    sink?.close(); // how to dispose?
  }
  List<Contact> users = await getUsers();
  List<Npub> npubs = [];
  users.forEach((user) => npubs = [...npubs, ...user.npubs]);
  sink = EventSink(npubs);
  sink?.listen(); // is there a better place to put this
}

