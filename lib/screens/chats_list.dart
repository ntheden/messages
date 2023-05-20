import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nostr/nostr.dart';
import 'package:get/get.dart';

import '../components/chats/chats_entry.dart';
import '../components/drawer/index.dart';
import '../nostr/relays.dart';
import '../db/crud.dart';
import '../db/db.dart';
import '../router/delegate.dart';
import '../util/date.dart';

class ChatsList extends StatefulWidget {
  final String title;
  final Contact currentUser;
  List<Widget> chats = []; // TODO: move this back to State
  ChatsList(this.currentUser, {Key? key, this.title='Messages'}) : super(key: key) {
    getUserMessages(currentUser).then(
      (entries) => getChats(currentUser, entries).then(
        (widgets) => chats = widgets));
  }
  @override
  _ChatsListState createState() => _ChatsListState();
}

class _ChatsListState extends State<ChatsList> {
  @override ChatsList get widget => super.widget;
  bool newChatToggle = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    watchUserMessages(widget.currentUser).listen((entries) {
      // TODO: This stream should be from not far back in time and
      // has to add its data to the existing list
      getChats(widget.currentUser, entries).then(
        (widgets) => widget.chats = widgets);
      setState(() => newChatToggle = !newChatToggle);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 5),
            child: InkWell(
              customBorder: CircleBorder(),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.search_rounded),
              ),
              onTap: () {
                  final routerDelegate = Get.put(MyRouterDelegate());
                  routerDelegate.pushPage(name: '/contactList');
                },
              ),
            )
        ],
        ),
      body: ListView.builder(
        itemCount: widget.chats.length,
        itemBuilder: (BuildContext context, int index) {
        return Column(
            children: [
            widget.chats[index],
            Divider(height: 0),
            ]);
        },
        ),
      drawer: DrawerScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final routerDelegate = Get.put(MyRouterDelegate());
          routerDelegate.pushPage(name: '/contactList');
        },
        child: Icon(Icons.edit_rounded),
      ),
    );
  }
}


Future<List<Widget>> getChats(user, messages) async {
  // sort messages by peer and timestamp.
  // can I use a sort function here
  Map<int, dynamic> peers = {};
  messages.forEach((message) {
      for (final id in [message.fromId, message.toId]) {
      // This does not need to check if the contact is a local user,
      // just check against currentUser, since this is only for
      // drawing the widgets
      if (id == user.id && (message.fromId != message.toId)) {
        // Record this under the remote contact, only
        continue;
      }
      int? timestamp = peers[id]?.timestamp;
      if (timestamp == null || timestamp < message.timestamp) {
        peers[id] = message;
      }
    }
  });

  List<Contact> contacts = await getContacts(peers.keys.toList());

  List<Widget> entries = [];
  for (final contact in contacts) {
    MessageEntry message = peers[contact.id];
    // TODO: This formatting goes in the widget definition
    String name = contact.id == user.id ? "Me" : contact.name;
    String pubkey = contact.npubs[0].pubkey;
    String npubHint = pubkey.substring(0, 5) + '...' + pubkey.substring(59, 63);
    entries.add(
      ChatsEntry(
        name: '$name ($npubHint)',
        npub: pubkey,
        picture: NetworkImage(
          "https://i.ytimg.com/vi/D7h9UMADesM/maxresdefault.jpg",
        ),
        //type: "group",
        //sending: message.from?.id == user.id ? "You" : "Them",
        //lastTime: formattedDate('hh:mm', message.timestamp),
        lastTime: timezoned(message.timestamp).formattedDate(),
        //seeing: 2,
        lastMessage: peers[contact.id].content,
        currentUser: user,
        peer: contact,
      )
    );
  };
  return entries;
}
