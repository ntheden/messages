import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nostr/nostr.dart';

import '../config/settings.dart';
import '../components/chats/chats_entry.dart';
import '../components/drawer/index.dart';
import '../constants/messages.dart';
import '../db/crud.dart';
import '../db/db.dart';
import '../nostr/relays.dart';
import '../util/date.dart';
import '../util/screen.dart';

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
  final List<dynamic> _messages = [];
  final TextEditingController textEntryField = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final ScrollController scrollController = ScrollController();
  bool newMessageToggle = false;
  Contact currentUser;
  Contact peerContact;
  Set<int> _seen = {};
  StreamController<List<MessageEntry>> _stream = StreamController<List<MessageEntry>>();
  StreamSubscription<List<MessageEntry>>? subscription;

  ChatState(this.currentUser, this.peerContact) {
    focusNode.requestFocus();
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
      addMarkers();
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
        flexibleSpace: SafeArea(
          child: Container(
            padding: EdgeInsets.only(right: 16),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back, color: Colors.white,),
                ),
                SizedBox(width: 2,),
                SizedBox.fromSize(
                  size: Size(50, 50),
                  /*
                  child: CircleAvatar(
                    backgroundImage: picture,
                    backgroundColor: Colors.grey,
                  ),
                  */
                  child: peerContact.avatar,
                ),
                /*
                CircleAvatar(
                  backgroundImage: NetworkImage(
                    "https://randomuser.me/api/portraits/men/${Random().nextInt(100)}.jpg",
                  ),
                  maxRadius: 20,
                ),
                */
                SizedBox(width: 12,),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('${peerContact.name}(${peerContact.npubs[0].pubkey.substring(0, 5)})',
                        style: TextStyle( fontSize: 16 ,fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.settings, color: Colors.white,),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Container(
            height: scaledListBox(context),
            child: ListView.builder(
              reverse: true,
              controller: scrollController,
              itemCount: _messages.length,
              shrinkWrap: true,
              padding: EdgeInsets.only(top: 10, bottom: 10),
              itemBuilder: (context, index) {
                return listBuilderEntry(context, index);
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: EdgeInsets.only(left: 10, bottom: 10, top: 10),
              height: 60,
              width: double.infinity,
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
                    onPressed: () {
                    },
                    child: Icon(Icons.send, color: Colors.white, size: 18,),
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

  void addMarkers() {
    // Remove markers before re-adding them
    List<dynamic> cleaned = _messages.where((widget) => !(widget is String)).toList();
    _messages.clear();
    _messages.addAll(cleaned);
    _messages.replaceRange(0, _messages.length, insertStrings(_messages));
    /*
    for (int index = 1; index < _messages.length; index += 2) {
      _messages.insert(index, DateTime.now().formattedDate());
    }
    */
  }

  Widget? listBuilderEntry(context, index) {
    if (_messages[index] is String) {
      return Container(
        padding: EdgeInsets.only(left: 14,right: 14,top: 5, bottom: 5),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            child: Text(_messages[index], style: TextStyle(fontSize: 10),),
          ),
        ),
      );
    }
    Alignment alignment;
    Color? color;
    if (_messages[index].toId == currentUser.id && _messages[index].toId != peerContact.id) {
      alignment = Alignment.topLeft;
      color = Colors.green.shade400;
    } else {
      alignment = screenAwareWidth(1, context) < 675 ? Alignment.topRight : Alignment.topLeft;
      color = Colors.blue[400];
    }
    return Container(
      padding: EdgeInsets.only(left: 14, right: 14,top: 10,bottom: 10),
      child: Align(
        alignment: alignment,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: color,
          ),
          padding: EdgeInsets.all(16),
          child: Text(_messages[index].content, style: TextStyle(fontSize: 15),),
        ),
      ),
    );
  }
}

List<dynamic> insertStrings(List<dynamic> messages) {
  List<dynamic> result = [];

  DateTime firstMessage = timezoned(messages[messages.length - 1].timestamp);

  for (int i = 0; i < messages.length; i++) {
    MessageEntry currentMessage = messages[i];
    DateTime currentTimestamp = timezoned(currentMessage.timestamp);

    if (i == 0) {
      result.add(currentMessage);
      continue;
    }

    MessageEntry previousMessage = messages[i - 1];
    DateTime previousTimestamp = timezoned(previousMessage.timestamp);

    if (currentTimestamp.difference(previousTimestamp).inHours >= 5 &&
        currentTimestamp.day == previousTimestamp.day) {
      result.add(formattedDate("hh:mm", currentMessage.timestamp));
    }

    if (currentTimestamp.day != previousTimestamp.day) {
      if (currentTimestamp.day != firstMessage.day) { // firstMessage gets inserted at the end
        result.add(currentTimestamp.formattedDate());
      }
    }

    result.add(currentMessage);

    if (i == messages.length - 1) {
      // insert timestamp before 1st message
      result.add(currentTimestamp.formattedDate());
    }
  }

  return result;
}

scaledListBox(context) {
  // Not sure how else to do it
  double scale = 0.85;
  double size = screenAwareHeight(1, context);
  if (size < 310) {
    scale = 0.65;
  } else if (size < 450) {
    scale = 0.70;
  } else if (size < 650) {
    scale = 0.8;
  }
  return screenAwareHeight(scale, context);
}
