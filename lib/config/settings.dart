import '../nostr/relays.dart';

Map<String, String> relaySettings = {
  //'nostr_relay': 'ws://192.168.50.162:6969',
  'monstr_relay': 'ws://192.168.50.144:8081',
};

// Maybe getRelays should be off of a Contact
Relays getRelays(Set<String> pubkeys) {
  Relays relays = Relays(pubkeys);
  // TODO: Maybe Relays should decide which relays to connect to
  // based on the passed in pubkeys
  relaySettings.forEach((name, url) {
    relays?.add(name, url);
  });
  return relays!;
}
