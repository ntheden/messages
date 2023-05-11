import 'package:flutter/material.dart';

import '../pages/contact_list_page.dart';
import '../pages/contact_page.dart';
import '../pages/edit_contact_page.dart';
import '../pages/groups_page.dart';
import '../screens/chat.dart';
import '../screens/chats_list.dart';
import '../screens/login.dart';
import '../db/db.dart';

class MyRouterDelegate extends RouterDelegate<List<RouteSettings>>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<List<RouteSettings>> {
  final pages = <Page>[];

  // note that we are using `=` and not `=>` this prevents a new
  // `GlobalKey` being created evry time we access `navigatorKey`
  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: List.of(pages),
      onPopPage: onPopPage,
    );
  }

  bool onPopPage(Route route, dynamic result) {
    if (!route.didPop(result)) return false;

    popRoute();

    return true;
  }

  @override
  Future<bool> popRoute() {
    if (pages.length > 1) {
      pages.removeLast();
      notifyListeners();
    }
    return Future.value(true);
  }

  @override
  Future<void> setNewRoutePath(List<RouteSettings> configuration) async {}

  MaterialPage createPage(RouteSettings routeSettings) {
    Widget child = Login();

    switch (routeSettings.name) {
      case '/chat':
        child = Chat(routeSettings.arguments as Map<String, dynamic>);
        break;
      case '/chats':
        child = ChatsList(routeSettings.arguments as Contact);
        break;
      case '/contactList':
        child = ContactListPage();
        break;
      case '/contact':
        child = ContactPage();
        break;
      case '/editContact':
        child = EditContactPage();
        break;
      case '/groups':
        child = GroupsPage();
        break;
      case '/login':
        child = Login();
        break;
    }

    return MaterialPage(
      child: child,
      key: ValueKey(routeSettings.name!),
      name: routeSettings.name,
      arguments: routeSettings.arguments,
    );
  }

  void pushPage({required String name, dynamic arguments}) {
    print('@@@@@@@@@@@@@@@@@@@@ pushing page $name');
    pages.removeWhere((page) => page.name == name);
    pages.add(createPage(RouteSettings(name: name, arguments: arguments)));
    print('@@@@@@@@@@@@@@@@@@@@ pages are $pages');

    notifyListeners();
  }
}
