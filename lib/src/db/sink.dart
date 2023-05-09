import 'package:nostr/nostr.dart';

import 'db.dart';
import 'crud.dart';
import '../relays.dart';
import '../../config/settings.dart';

class EventSink {
  //late User user;
  //late Relays relays;
  List<Npub> npubs;
  Set<String> pubkeys = {};

  //EventSink(this.user, this.relays);
  EventSink(this.npubs) {
    npubs.forEach((npub) => pubkeys.add(npub.pubkey));
  }

  listen() {
    Relays relays = getRelays(pubkeys);
    relays?.listen();
  }
}
