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
  bool newMessageToggle = false;
  Contact currentUser;
  Contact peerContact;
  Set<int> _seen = {};

  ChatState(this.currentUser, this.peerContact);
  StreamController<List<MessageEntry>> _stream = StreamController<List<MessageEntry>>();
  StreamSubscription<List<MessageEntry>>? subscription;

  double screenAwareHeight(double size, BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    double drawingHeight = mediaQuery.size.height - mediaQuery.padding.top;
    return size * drawingHeight;
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
    _stream.addStream(watchMessages(currentUser, peerContact));
    subscription = _stream.stream.listen((entries) {
      print('@@@@@@@@@@@@@@@@@@ number of entries: ${entries.length}');
      for (final message in entries) {
        // TODO: This needs to be optimized - possibly cancel the stream
        // and restart it from the latest message.id
        if (_seen.contains(message.id)) {
          //print('"${message.content}" was already seen');
          continue;
        }
        _seen.add(message.id);
        addMessage(message);
      }
      setState(() => newMessageToggle = !newMessageToggle);
    });
  }

  @override
  void dispose() {
    textEntryField.dispose();
    subscription?.cancel();
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
          Container(
            height: screenAwareHeight(0.85, context),
            child: ListView.builder(
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
                      child: Text(_messages[index].content, style: TextStyle(fontSize: 15),),
                    ),
                  ),
                );
              },
            ),
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
    //print('@@@@@@@@@@@@@@@@@ received a msg "${entry.content}"');
    _messages.insert(0, entry);
  }
}
