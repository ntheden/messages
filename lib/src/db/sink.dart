import 'package:nostr/nostr.dart';

import 'db.dart' as db;
import 'crud.dart';
import '../relays.dart';
import '../../config/settings.dart';

class EventSink {
  //late User user;
  //late Relays relays;

  //EventSink(this.user, this.relays);
  EventSink();

  listen() {
    Relays relays = getRelays();
    relays?.listen();
  }
}
