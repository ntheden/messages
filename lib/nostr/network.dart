import 'dart:io';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:nostr/nostr.dart' as nostr;

import '../db/crud.dart';
import '../db/db.dart' as db;
import 'node.dart';
import '../util/date.dart';


class Network {
  String groupName; // private relay, group/org relay, public relay, etc.
  List<Node> _nodes = [];
  Set<nostr.Event>? rEvents;
  Set<String>? uniqueIdsReceived; // to reject duplicates, but may check database instead
  late List<nostr.Filter> _filters;
  late String _subscriptionId;
  DateTime? _listenStart;
   
  Network({
    this.groupName='default',
  }) {
    _nodes = [];
    rEvents = {};
    uniqueIdsReceived = {};
    _filters = initFilters();
    _subscriptionId = nostr.generate64RandomHexChars();
  }

  List<nostr.Filter> initFilters() {
    return [
      nostr.Filter(
        //kinds: [0, 1, 4, 2, 7],
        kinds: [4],
        //  date -d @1681878751
        //Tue Apr 18 09:32:31 PM PDT 2023
        since: 1681878751,//yesterday(),
        limit: 450,
      )
    ];
  }

  void updateFilters(List<db.Contact> users) {
    // TODO: This will also need to be called when a user gets
    // added or deleted
        /*
        ["REQ","26753b65-35a7-4f9f-9a16-d7086fda3d79", {
           "kinds":[0],
           "authors":["0f76c800a7ea76b83a3ae87de94c6046b98311bda8885cedd8420885b50de181"]
         }]
        */
    int since = users[0].lastEventTime;
    users.map((user) {
      if (user.lastEventTime > 0 && user.lastEventTime < since) {
        since = user.lastEventTime;
      }
    });
    _filters = [
      nostr.Filter(
        //kinds: [0, 1, 4, 2, 7],
        kinds: [4],
        //  date -d @1681878751
        //Tue Apr 18 09:32:31 PM PDT 2023
        since: since > 0 ? since : null,
        limit: 450,
        authors: List.from(users.map((user) => user.pubkey)),
        p: List.from(users.map((user) => user.pubkey)),
      ),
    ];
  }

    
  void close() {
    _nodes.forEach((node) {
      node.close();
    });
  }

  void addNode(Node node) {
    // TODO: properties such as read/write may have changed
    if (node.channel != null) {
      _nodes.add(node);
      if (_listenStart != null) {
        node.listen();
      }
      node.subscribe(_subscriptionId, _filters);
    }
  }

  send(String request) {
    _nodes.forEach((node) {
      node.send(request);
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
    assert(_nodes.isNotEmpty);
    _nodes.forEach((node) {
      node.sendEvent(event, from, to, plaintext);
    });
    storeSentEvent(event, from, to, plaintext);
  }

  void listen([void Function(dynamic)? func=null]) {
    _listenStart = DateTime.now();
    _nodes.forEach((node) => node.listen(func));
  }
}


NetworkWatcher? watcher;


Network getNetwork() {
  if (watcher != null) {
    return watcher!.network;
  }
  watcher = NetworkWatcher();
  return watcher!.network;
}

class NetworkWatcher {
  late Network network;
  late StreamController<List<db.Relay>> _stream;
  late StreamSubscription<List<db.Relay>> _subscription;

  NetworkWatcher() {
    network = Network();
    getUsers().then((users) {
      if (users.isNotEmpty) {
        network.updateFilters(users);
      }
      _stream = StreamController<List<db.Relay>>();
      _stream.addStream(watchAllRelays());
      _subscription = _stream.stream.listen((entries) {
        for (final db.Relay relay in entries) {
          // TODO: manage these fully
          if (!network._nodes.any((entry) => entry.url == relay.url)) {
            Node node = Node.fromDb(relay);
            network.addNode(node);
          }
        }
        network.listen();
      });
    });
  }

  void close() {
    _subscription.cancel();
    _stream.close();
  }
}
