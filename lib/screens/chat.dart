import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nostr/nostr.dart';

import '../config/settings.dart';
import '../components/chats/chats_entry.dart';
import '../components/drawer/index.dart';
import '../constants/messages.dart';
import '../db/crud.dart';
import '../db/db.dart';
import '../nostr/relays.dart';

class Chat extends StatefulWidget {
  late Contact currentUser;
  late Contact peerContact;

  Chat(Map<String, dynamic> args, {Key? key}) : super(key: key) {
    currentUser = args['user'];
    peerContact = args['peer'];
  }

  @override
  ChatState createState() => ChatState(currentUser, peerContact);
}

class ChatState extends State<Chat> {
  final List<MessageEntry> _messages = [];
  final TextEditingController textEntryField = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final ScrollController scrollController = ScrollController();
  StreamController<MessageEntry> _chat = StreamController<MessageEntry>();
  Contact currentUser;
  Contact peerContact;
  // These filters should be done at the db query level, not sure how else
  // to fix right now.
  Set<int> _contactFilter = {};
  Set<int> _seenFilter = {};

  ChatState(this.currentUser, this.peerContact) {
    _contactFilter = {currentUser.id, peerContact.id};
  }

  @override
  void initState() {
    super.initState();
    textEntryField.addListener(() {
      final String text = textEntryField.text;
      textEntryField.value = textEntryField.value.copyWith(
        text: text,
        selection:
            TextSelection(baseOffset: text.length, extentOffset: text.length),
        composing: TextRange.empty,
      );
    });
    getChatMessages(currentUser, peerContact).then((messages) {
      for (final message in messages) {
        addMessage(message);
      }
    }).catchError((err) => print(err));
    watchMessages(currentUser, peerContact).listen((entries) {
      for (final message in entries) {
        _chat.add(message);
      }
    });
  }

  @override
  void dispose() {
    textEntryField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        //backgroundColor: Colors.white, // white for light mode
        flexibleSpace: SafeArea(
          child: Container(
            padding: EdgeInsets.only(right: 16),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back,color: Colors.black,),
                ),
                SizedBox(width: 2,),
                CircleAvatar(
                  backgroundImage: NetworkImage("https://randomuser.me/api/portraits/men/5.jpg"),
                  maxRadius: 20,
                ),
                SizedBox(width: 12,),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('${peerContact.name}(${peerContact.npubs[0].pubkey.substring(0, 5)})',
                        style: TextStyle( fontSize: 16 ,fontWeight: FontWeight.w600),),
                      SizedBox(height: 6,),
                      Text("Online",style: TextStyle(color: Colors.grey.shade600, fontSize: 13),),
                    ],
                  ),
                ),
                Icon(Icons.settings,color: Colors.black54,),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          StreamBuilder(
            stream: _chat.stream,
            builder: (context, AsyncSnapshot<MessageEntry> snapshot) {
              if (snapshot.hasData) {
                addMessage(snapshot.data!);

                return ListView.builder(
                  reverse: true,
                  controller: scrollController,
                  itemCount: _messages.length,
                  shrinkWrap: true,
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  itemBuilder: (context, index) {
                    return Container(
                      padding: EdgeInsets.only(left: 14,right: 14,top: 10,bottom: 10),
                      child: Align(
                        alignment: (_messages[index].toId == currentUser.id ? Alignment.topLeft : Alignment.topRight),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: (_messages[index].toId == currentUser.id ? Colors.green.shade400 : Colors.blue[400]),
                          ),
                          padding: EdgeInsets.all(16),
                          child: Text(_messages[index].getContent(currentUser.privkey), style: TextStyle(fontSize: 15),),
                        ),
                      ),
                    );
                  },
                );
              }
              return const LinearProgressIndicator();
            }
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: EdgeInsets.only(left: 10,bottom: 10,top: 10),
              height: 60,
              width: double.infinity,
              //color: Colors.white, // white for light mode
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                    },
                    child: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        color: Colors.lightBlue,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(Icons.add, color: Colors.white, size: 20, ),
                    ),
                  ),
                  SizedBox(width: 15,),
                  Expanded(
                    child: TextField(
                      focusNode: focusNode,
                      controller: textEntryField,
                      decoration: InputDecoration(
                        hintText: "Write message...",
                        hintStyle: TextStyle(color: Colors.black54),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (String value) {
                        sendMessage(value);
                        textEntryField.clear();
                        focusNode.requestFocus();
                        /*
                        scrollController.animateTo(
                          scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 100),
                          curve: Curves.easeOut
                        );
                        */
                      },
                    ),
                  ),
                  SizedBox(width: 15,),
                  FloatingActionButton(
                    onPressed: () {},
                    child: Icon(Icons.send, color: Colors.white,size: 18,),
                    backgroundColor: Colors.blue,
                    elevation: 0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  sendMessage(String content) {
    Relays relays = getRelays({});
    relays.sendMessage(content, from: currentUser, to: peerContact);
  }

  void addMessage(MessageEntry entry) {
    //
    // Open to ways to improve this! Ideally at the database query level
    //
    // The reason we could see dups:
    // 1. After getPlaintext() the message entry in the db is updated
    //    causing an event.
    // 2. A db store that hits a conflict and is ignored because it is
    //    already there still produces an event, I think.
    if (_seenFilter.contains(entry.id)) {
      return;
    }
    _seenFilter.add(entry.id);
    _messages.add(entry);
    _messages.sort((b, a) => a.timestamp.compareTo(b.timestamp));
  }
}
