import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nostr/nostr.dart';

import '../models/message_entry.dart';
import '../components/chats/chats_entry.dart';
import '../components/drawer/index.dart';
import '../constants/messages.dart';
import '../src/db/crud.dart';
import '../src/relays.dart';
import '../config/settings.dart';
import '../src/db/db.dart';

class Chat extends StatefulWidget {

  @override
  ChatState createState() => ChatState();
}

class ChatState extends State<Chat> {
  int _index = 0;
  final List<MessageEntry> _messages = [];
  final TextEditingController textEntryField = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final ScrollController scrollController = ScrollController();
  Contact? currentUser;

  void queryUsers() async {
    List<Contact> myUsers = await getUsers();
    Contact myUser = myUsers.singleWhere((user) => user.active == true);
    setState(() {
      currentUser = myUser;
    });
  }

  @override
  void initState() {
    super.initState();
    queryUsers();
    textEntryField.addListener(() {
      final String text = textEntryField.text;
      textEntryField.value = textEntryField.value.copyWith(
        text: text,
        selection:
            TextSelection(baseOffset: text.length, extentOffset: text.length),
        composing: TextRange.empty,
      );
    });
    getMessages(0).then((messages) {
      for (final message in messages) {
        _messages.add(message);
        if (message.index > _index) {
          _index = message.index;
        }
      }
    }).catchError((err) => print(err));
    watchMessages(_index).listen((entries) {
      for (final message in entries) {
        _index = message.index;
        _chat.add(message);
      }
    });
  }

  @override
  void dispose() {
    textEntryField.dispose();
    super.dispose();
  }

  StreamController<MessageEntry> _chat = StreamController<MessageEntry>();

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
                      Text("Kriss Benwat",style: TextStyle( fontSize: 16 ,fontWeight: FontWeight.w600),),
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
                        alignment: (_messages[index].source == "remote" ? Alignment.topLeft:Alignment.topRight),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: (_messages[index].source == "remote" ? Colors.green.shade400:Colors.blue[400]),
                          ),
                          padding: EdgeInsets.all(16),
                          child: Text(_messages[index].content, style: TextStyle(fontSize: 15),),
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
    Relays relays = getRelays();
    relays.sendMessage(content, from: currentUser!, to: currentUser!); // TODO
  }

  void addMessage(MessageEntry entry) {
    _messages.insert(0, entry);
  }

  void addMessages1(List<MessageEntry> entries) {
    for (final message in entries.sublist(_index)) {
      _messages.add(message);
    }
    _index = entries.length;
  }
}
