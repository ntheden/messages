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
  const ChatsList(this.currentUser, {Key? key, this.title='Messages'}) : super(key: key);

  @override
  _ChatsListState createState() => _ChatsListState(currentUser);
}

class _ChatsListState extends State<ChatsList> {
  final Contact currentUser;
  final List<Widget> _entries = [];
  _ChatsListState(this.currentUser);

  @override
  void initState() {
    super.initState();
    getUserMessages(currentUser, 0).then((messages) {
      // sort messages by peer and timestamp
      print('@@@@@@@@@@@@@@@@@@@@@@ messages $messages');
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
      body: SingleChildScrollView(
        child: StreamBuilder(
          //stream: watchEvents(),
          /*
          initialData: () {
            return Column(
              children: getSome(),
            );
          },
          */
          builder: (context, AsyncSnapshot<String> snapshot) {
            return Column(
              children: getChatEntries(),
            );
          },
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

  List<Widget> myChatsEntries = [];

  List<Widget> getChatEntries() {
    List<Widget> newEntries = [
      ChatsEntry(
        name: "John Jacob",
        picture: NetworkImage(
          "https://i.ytimg.com/vi/D7h9UMADesM/maxresdefault.jpg",
        ),
        type: "group",
        sending: "Your",
        lastTime: "02:45",
        seeing: 2,
        lastMessage: "https://github.com/",
        currentUser: currentUser,
      ),
      Divider(height: 0),
      ChatsEntry(
        name: "Jinkle Hiemer",
        picture: NetworkImage(
          "https://i.ytimg.com/vi/D7h9UMADesM/maxresdefault.jpg",
        ),
        lastTime: "02:16",
        type: "group",
        sending: "Mesud",
        lastMessage: "gece gece sinirim bozuldu.",
        currentUser: currentUser,
      ),
      Divider(height: 0),
    ];

    myChatsEntries.addAll(newEntries);
    return myChatsEntries;
  }
}

