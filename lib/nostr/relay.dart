import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:nostr/nostr.dart' as nostr;

import '../config/settings.dart';
import '../db/crud.dart';
import '../db/db.dart' as db;


class Relay {
  String name;
  String url;
  Map<String, WebSocketChannel> socketMap = {};
  List<int>? supportedNips;
  List<nostr.Filter> filters = [nostr.Filter(
    //kinds: [0, 1, 4, 2, 7],
    kinds: [4],
    since: 1681878751, // TODO: Today minus 30 or something, or based on last received in db
    limit: 450,
  )];

  Relay(this.name, this.url, [filters]) {
    this.filters = this.filters + (filters ?? []);
    socketMap[name] = socketConnect(url);
    subscribe();
  }

  WebSocketChannel get socket => socketMap[name]!;

  static WebSocketChannel socketConnect(String host) {
    host = host.split('//').last;
    WebSocketChannel socket;
    try {
      // with 'wss' seeing WRONG_VERSION_NUMBER error against some servers
      socket = WebSocketChannel.connect(Uri.parse('ws://${host}'));
    } on HandshakeException catch(e) {
      socket = WebSocketChannel.connect(Uri.parse('wss://${host}'));
    }
    return socket;
  }

  void subscribe() {
    // TODO: query supported nips
    nostr.Request requestWithFilter = nostr.Request(nostr.generate64RandomHexChars(), filters);
    print('sending request: ${requestWithFilter.serialize()}');
    socket.sink.add(requestWithFilter.serialize());
  }

  void listen(void Function(dynamic)? func) {
    func ??= (data) {
      if (data == null || data == 'null') {
          return;
      }
      nostr.Message m = nostr.Message.deserialize(data);
      if ([m.type,].contains("EVENT")) {
        nostr.Event event = m.message;
        storeReceivedEvent(event);
      }
    };
    socket.stream.listen(
      func,
      onError: (err) => print("Error in creating connection to $url."),
      onDone: () => print('Relay[$name]: In onDone'),
    );
  }

  void close() {
    try {
      socket.sink.close();
    } catch(err) {
      // TODO: Logging
      print('Close exception error $err for relay $name');
    }
  }

  Future<void> send(String request) async {
    socket.sink.add(request);
    // TODO: check the return OK if relay supports that NIP
  }

  Future<void> sendEvent(
    nostr.Event event,
    db.Contact from,
    db.Contact to, [
    String? plaintext
    ]) async {
    // we don't await it, but we might want to to get confirmation
    send(event.serialize());
  }
}


