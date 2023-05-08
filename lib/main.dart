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
  // I may get rid of "context", just get the active user,
  // store the list of relays in the user - switch to
  // them when the user changes
  getContext().then((context) {
    EventSink sink = EventSink();
    sink.listen(); // is there a better place to put this
    runApp(MessagesApp(user: context.user));
  }).catchError((error) => runApp(MessagesApp()));
}

class MessagesApp extends StatelessWidget {
  Contact? user;

  MessagesApp({super.key, Contact? this.user});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Messages',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: PacificBlue,
        brightness: Brightness.dark, // light
        accentColor: PacificBlue,
      ),
      /*
      home: Navigator(
        pages: [
          ...initialPage(),
        ],
        onPopPage: (route, result) {
          if (!route.didPop(result)) {
            return false;
          }
          // call setState?
          return true;
        },
      ),
      */
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

  List<MaterialPage> initialPage() {
    if (user == null) {
      return [
        MaterialPage(
          key: ValueKey('LoginPage'),
          child: Login(),
        ),
      ];
    }
    return [
      MaterialPage(
        key: ValueKey('ChatsList'),
        child: ChatsList(),
      ),
    ];
  }
}
