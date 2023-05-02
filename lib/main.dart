import 'package:flutter/material.dart';

import 'constants/color.dart';
import 'pages/contact_list_page.dart';
import 'pages/contact_page.dart';
import 'pages/edit_contact_page.dart';
import 'pages/groups_page.dart';
import 'screens/chat.dart';
import 'screens/chats_list.dart';
import 'src/db/sink.dart';

void main() {
  EventSink sink = EventSink();
  sink.listen(); // is there a better place to put this
  runApp(Nostrim());
}

class Nostrim extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nostrim',
      theme: ThemeData(
        primaryColor: PacificBlue,
        brightness: Brightness.dark, // light
        accentColor: PacificBlue,
      ),
      initialRoute: '/chats',
      routes: {
        '/chats': (context) => ChatsList(),
        '/chat': (context) => Chat(),
        '/contactList': (context) => ContactListPage(),
        '/contact': (context) => ContactPage(),
        '/editContact': (context) => EditContactPage(),
        '/groups': (context) => GroupsPage(),
      },
    );
  }
}
