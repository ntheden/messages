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
  List<Widget> _chats = [];
  _ChatsListState(this.currentUser);
  StreamController<DbContact> _users = StreamController<DbContact>();

  void updateChatsList() {
    print('@@@@@@@@@@@@@@@@@@@@@ updateChatsList: currentUser is $currentUser');
    getUserMessages(currentUser).then((messages) {
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
      print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ updateChatsList: peers $peers');
      getContacts(peers.keys.toList()).then((contacts) {
        setState(() {
          _chats = getChatEntries(peers, contacts);
        });
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    updateChatsList();
    print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ why doesnt watchUser work??');
    watchUser().listen((contact) => updateChatsList());
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
              children: _chats,
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

  List<Widget> getChatEntries(Map<int, dynamic> peers, List<Contact> contacts) {
    List<Widget> newEntries = [];
    contacts.forEach((contact) {
      newEntries = [...newEntries, ...[
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
          ),
          Divider(height: 0),
        ]];
    });
    return newEntries;
  }
}
