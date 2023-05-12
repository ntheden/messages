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
    getChats().then((widgets) => chats = widgets);
  }

  @override
  _ChatsListState createState() => _ChatsListState();

  Future<List<Widget>> getChats() async {
    List<MessageEntry> messages = await getUserMessages(currentUser);

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
      entries.add(
        ChatsEntry(
          name: contact.id == currentUser.id ? "Me" : contact.name,
          picture: NetworkImage(
            "https://i.ytimg.com/vi/D7h9UMADesM/maxresdefault.jpg",
          ),
          type: "group",
          sending: "Your",
          lastTime: "02:45",
          seeing: 2,
          lastMessage: "https://github.com/",
          currentUser: currentUser,
        )
      );
    };
    return entries;
  }
}

class _ChatsListState extends State<ChatsList> {
  @override
  ChatsList get widget => super.widget;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
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
      body: SingleChildScrollView(
        child: Column(
          children: widget.chats,
        ),
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
