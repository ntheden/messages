import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
import 'router/delegate.dart';

void main() async {
  // I may get rid of "context", just get the active user,
  // store the list of relays in the user - switch to
  // them when the user changes
  getContext().then((context) {
    runEventSink();
    runApp(MessagesApp(user: context.user));
  }).catchError((error) => runApp(MessagesApp()));
}

void runEventSink() async {
  List<Contact> users = await getUsers();
  List<Npub> npubs = [];
  users.forEach((user) => npubs = [...npubs, ...user.npubs]);
  EventSink sink = EventSink(npubs);
  sink.listen(); // is there a better place to put this
}

class MessagesApp extends StatelessWidget {
  final routerDelegate = Get.put(MyRouterDelegate());
  Contact? user;

  MessagesApp({super.key, Contact? this.user}) {
    routerDelegate.pushPage(name: user == null ? '/login' : '/chats');
  }

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
      home: Router(
        routerDelegate: routerDelegate,
        backButtonDispatcher: RootBackButtonDispatcher(),
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
      */
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
