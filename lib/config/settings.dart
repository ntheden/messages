import '../nostr/relays.dart';

List<String> relaySettings = [
  //'ws://192.168.50.162:6969',
  'ws://192.168.50.144:8081',
];

// Maybe getRelays should be off of a User
Relays getRelays(Set<String> pubkeys) {
  Relays relays = Relays(pubkeys);
  // TODO: Maybe Relays should decide which relays to connect to
  // based on the passed in pubkeys
  relaySettings.forEach((url) {
    relays.add(url);
  });
  return relays;
}
