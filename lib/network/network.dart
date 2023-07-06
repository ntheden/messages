import 'dart:io';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:nostr/nostr.dart' as nostr;

import '../db/crud.dart';
import '../db/db.dart' as db;
import 'relay.dart';


class Network {
  String groupName; // private relay, group/org relay, public relay, etc.
  List<Relay> _relays = [];
  Set<nostr.Event>? rEvents;
  List<nostr.Filter> _filters = [];
  Set<String>? uniqueIdsReceived; // to reject duplicates, but may check database instead

    
  Network({
    this.groupName='default',
  }) {
    _relays = [];
    rEvents = {};
    uniqueIdsReceived = {};
  }

  void updateFilters(List<db.Contact> users) {
    // TODO: This will also need to be called when a user gets added or deleted
    /*
    ["REQ","26753b65-35a7-4f9f-9a16-d7086fda3d79", {
       "kinds":[0],
       "authors":["0f76c800a7ea76b83a3ae87de94c6046b98311bda8885cedd8420885b50de181"]
     }]
    */
    int since = 0;//users[0].lastEventTime;
    /*
    users.map((user) {
      if (user.lastEventTime > 0 && user.lastEventTime < since) {
        since = user.lastEventTime;
      }
    });
    */
    _filters = [
      nostr.Filter(
        //kinds: [0, 1, 4, 2, 7],
        kinds: [4],
        //  date -d @1681878751
        //Tue Apr 18 09:32:31 PM PDT 2023
        //since: since > 0 ? since : null,
        since: 1681878751,
        limit: 450,
        //authors: List.from(users.map((user) => user.pubkey)),
        //p: List.from(users.map((user) => user.pubkey)),
      ),
    ];
    _relays.forEach((relay) {
      relay.filters = _filters;
    });
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
    nostr.EncryptedDirectMessage event = nostr.EncryptedDirectMessage.redact(
      from.privkey,
      to.pubkey,
      content,
    );
    sendEvent(event, from, to, content);
  }

  sendEvent(nostr.Event event, from, to, plaintext) {
    assert(_relays.isNotEmpty);
    _relays.forEach((relay) {
      relay.sendEvent(event, from, to, plaintext);
    });
    storeSentEvent(event, from, to, plaintext);
  }

  void restart([void Function(dynamic)? listenFunc=null]) {
    _relays.forEach((relay) {
      relay.subscribe();
      relay.listen(listenFunc);
    });
  }
}


NetworkWatcher? watcher;


Future<Network> getNetwork() async {
  if (watcher != null) {
    return watcher!.network;
  }
  watcher = NetworkWatcher();
  return watcher!.network;
}

class NetworkWatcher {
  late Network network;
  late StreamController<List<db.Relay>> _relayStream;
  late StreamSubscription<List<db.Relay>> _relaySubscription;
  late StreamController<List<db.DbContact>> _userStream;
  late StreamSubscription<List<db.DbContact>> _userSubscription;

  NetworkWatcher() {
    network = Network();
    _relayStream = StreamController<List<db.Relay>>();
    _relayStream.addStream(watchAllRelays());
    _userStream = StreamController<List<db.DbContact>>();
    _userStream.addStream(watchAllUsers());
    start();
  }

  Future<void> start() async {
    // TODO: Also need to listen to changes on users
    List<db.Contact> users = await getUsers();
      if (users.isNotEmpty) {
        network.updateFilters(users);
        network.restart();
    }
    _userSubscription = _userStream.stream.listen((entries) async {
      if (users.isNotEmpty) {
        List<db.Contact> users = await getUsers();
        network.updateFilters(users);
        network.restart();
      }
    });
    _relaySubscription = _relayStream.stream.listen((entries) {
      for (final db.Relay relay in entries) {
        // TODO: manage these fully:
        // 1. Delete relays that were removed, close nostr subscription, cancel stream
        // 2. Change of read/write settings
        if (!network._relays.any((entry) => entry.url == relay.url)) {
          network.addRelay(Relay.fromDb(relay));
        }
      }
      network.restart();
    });
  }

  void close() {
    _relaySubscription.cancel();
    _relayStream.close();
    _userSubscription.cancel();
    _userStream.close();
  }
}
