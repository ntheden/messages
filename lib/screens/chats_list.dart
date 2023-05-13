import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nostr/nostr.dart';

import '../components/chats/chats_entry.dart';
import '../components/drawer/index.dart';
import '../nostr/relays.dart';
import '../db/crud.dart';
import '../db/db.dart';

class ChatsList extends StatefulWidget {
  final String title;
  final Contact currentUser;
  List<Widget> chats = [];
  ChatsList(this.currentUser, {Key? key, this.title='Messages'}) : super(key: key) {
    // most recent on top - XXX Not sure if it's working
    getUserMessages(currentUser).then(
      (messages) => getChats(currentUser, messages).then(
        (widgets) => chats = List.from(widgets.reversed)
      )
    );
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
    watchMessages().listen((entries) {
      // TODO: This stream should be from not far back in time and
      // has to add its data to the existing list
      getChats(widget.currentUser, entries).then(
        (widgets) => widget.chats = List.from(widgets.reversed));
      setState(() => newChatToggle = !newChatToggle);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        brightness: Brightness.dark,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 5),
            child: InkWell(
              customBorder: CircleBorder(),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.search_rounded),
              ),
              onTap: () {},
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
    String name = contact.id == user.id ? "Me" : contact.name;
    String pubkey = message.npub.pubkey;
    String npubHint = pubkey.substring(0, 5) + '...' + pubkey.substring(59, 63);
    entries.add(
      ChatsEntry(
        name: '$name ($npubHint)',
        picture: NetworkImage(
          "https://i.ytimg.com/vi/D7h9UMADesM/maxresdefault.jpg",
        ),
        //type: "group",
        //sending: message.from?.id == user.id ? "You" : "Them",
        lastTime: "02:45", // get from timestamp
        seeing: 2,
        lastMessage: peers[contact.id].content,
        currentUser: user,
      )
    );
  };
  return entries;
}
