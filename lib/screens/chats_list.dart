import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nostr/nostr.dart';

import '../components/chats/chats_entry.dart';
import '../components/drawer/index.dart';
import '../src/relays.dart';
import '../src/db/crud.dart';

class ChatsList extends StatefulWidget {
  const ChatsList({Key? key, this.title='Messages'}) : super(key: key);
  final String title;

  @override
  _ChatsListState createState() => _ChatsListState();
}

List<Widget> myChatsEntries = [];

List<Widget> getSome() {
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
    ),
    Divider(height: 0),
  ];

  myChatsEntries.addAll(newEntries);
  return myChatsEntries;
}

class _ChatsListState extends State<ChatsList> {
  bool showOtherUsers = false;
  int selectedUser = 0;

  @override
  void initState() {
    super.initState();
  }

  final bool _running = true;

  Stream<String> _event() async* {
    while (!_running) {
    }
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
              children: getSome(),
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
}
