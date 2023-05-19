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
import 'db/crud.dart';
import 'db/db.dart';
import 'db/sink.dart';
import 'router/delegate.dart';
import 'util/date.dart';

void main() async {
  initTimezone('Europe/Brussels');
  getUser().then((user) {
    runApp(MessagesApp(user: user));
  }).catchError((error) => runApp(MessagesApp()));
}

class MessagesApp extends StatelessWidget {
  final routerDelegate = Get.put(MyRouterDelegate());
  Contact? user;

  MessagesApp({super.key, Contact? this.user}) {
    routerDelegate.pushPage(name: user == null ? '/login' : '/chats', arguments: user);
    if (user != null) {
      // FIXME: This is causing performance bottleneck at startup
      runEventSink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Messages',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: PacificBlue,
        brightness: Brightness.dark,
      ),
      home: Router(
        routerDelegate: routerDelegate,
        backButtonDispatcher: RootBackButtonDispatcher(),
      ),
    );
  }
}
