import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'constants/color.dart';
import 'screens/login.dart';
import 'screens/chat.dart';
import 'screens/chats_list.dart';
import 'config/preferences.dart';
import 'db/crud.dart';
import 'db/db.dart';
import 'router/delegate.dart';
import 'util/date.dart';
import 'util/first_time.dart';
import 'network/network.dart';

void main() async {
  try {
    Contact user = await getUser();
    initTimezone('Europe/Brussels'); // TODO: get prefs
    runApp(MessagesApp(user: user));
  } catch (error) {
    Map<String, dynamic> data = await firstTime();
    initTimezone(data["timezone"]);
    runApp(MessagesApp());
  }
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
    if (user == null) {
      routerDelegate.pushPage(name: '/login', arguments: false);
    } else {
      routerDelegate.pushPage(name: '/chats', arguments: user);
      // FIXME: This is causing performance bottleneck at startup
      getNetwork();
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
            home: Router(
              routerDelegate: routerDelegate,
              backButtonDispatcher: RootBackButtonDispatcher(),
            ),
          );
        },
      );
  }
}
