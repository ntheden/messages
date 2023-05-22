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
import 'config/preferences.dart';
import 'db/crud.dart';
import 'db/db.dart';
import 'db/sink.dart';
import 'router/delegate.dart';
import 'util/date.dart';
import 'util/messages_localizations.dart';

void main() async {
  initTimezone('Europe/Brussels');
  getUser().then((user) {
    runApp(MessagesApp(user: user));
  }).catchError((error) => runApp(MessagesApp()));
}

class MessagesApp extends StatefulWidget {
  Contact? user;

  MessagesApp({super.key, Contact? this.user});

  @override
  MessagesAppState createState() => MessagesAppState(user: user);
}

class MessagesAppState extends State<MessagesApp> {
  Contact? user;
  final routerDelegate = Get.put(MyRouterDelegate());
  DarkThemeProvider themeChangeProvider = DarkThemeProvider();

  MessagesAppState({Contact? this.user}) {
    routerDelegate.pushPage(name: user == null ? '/login' : '/chats', arguments: user);
    if (user != null) {
      // FIXME: This is causing performance bottleneck at startup
      runEventSink();
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentAppTheme();
  }

  void getCurrentAppTheme() async {
    themeChangeProvider.darkTheme =
      await themeChangeProvider.darkThemePreference.getTheme();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: themeChangeProvider,
        builder: (BuildContext context, Widget? child) {
          return MaterialApp(
            title: 'Messages',
            debugShowCheckedModeBanner: false,
            theme: themeChangeProvider.darkTheme ?
              ThemeData(
                primaryColor: PacificBlue,
                brightness: Brightness.dark,
              ) : ThemeData(
                primaryColor: PacificBlue,
                brightness: Brightness.light,
              ),
            darkTheme: ThemeData(
              primaryColor: PacificBlue,
              brightness: Brightness.dark,
            ),
            localizationsDelegates: MessagesLocalizations.localizationsDelegates,
            supportedLocales: MessagesLocalizations.supportedLocales,
            home: Router(
              routerDelegate: routerDelegate,
              backButtonDispatcher: RootBackButtonDispatcher(),
            ),
          );
        },
      );
  }
}
