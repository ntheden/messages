import 'package:flutter/material.dart';

import 'constants/color.dart';
import 'pages/contact_list_page.dart';
import 'pages/contact_page.dart';
import 'pages/edit_contact_page.dart';
import 'pages/groups_page.dart';
import 'screens/login.dart';
import 'screens/chat.dart';
import 'screens/chats_list.dart';
import 'src/db/crud.dart';
import 'src/db/db.dart';
import 'src/db/sink.dart';

void main() {
  getContext().then((context) {
    EventSink sink = EventSink();
    sink.listen(); // is there a better place to put this
    runApp(MessagesApp(user: context.user));
  }).catchError((err) => runApp(MessagesApp()));
}

class MessagesApp extends StatelessWidget {
  Contact? user;

  MessagesApp({super.key, Contact? this.user});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Messages',
      theme: ThemeData(
        primaryColor: PacificBlue,
        brightness: Brightness.dark, // light
        accentColor: PacificBlue,
      ),
      initialRoute: user == null ? '/login' : '/chats',
      routes: {
        '/chats': (context) => ChatsList(),
        '/chat': (context) => Chat(),
        '/contactList': (context) => ContactListPage(),
        '/contact': (context) => ContactPage(),
        '/editContact': (context) => EditContactPage(),
        '/login': (context) => Login(),
        '/groups': (context) => GroupsPage(),
      },
    );
  }
}
