import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../db/db.dart';
import '../../db/crud.dart';
import 'drawer_list_tile.dart';
import 'drawer_user_list_tile.dart';
import '../../router/delegate.dart';
import '../../config/preferences.dart';

class DrawerScreen extends StatefulWidget {
  DrawerScreen({Key? key}) : super(key: key);

  @override
  DrawerScreenState createState() => DrawerScreenState();
}

class DrawerScreenState extends State<DrawerScreen> {
  bool showOtherUsersFlag = false;
  List<Contact> users = [];
  Contact? currentUser;
  final routerDelegate = Get.put(MyRouterDelegate());
  final DarkThemeProvider themeChange = DarkThemeProvider();
 
  @override
  void initState() {
    super.initState();
    queryUsers();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> queryUsers() async {
    List<Contact> myUsers = await getUsers();
    Contact myUser = myUsers.singleWhere((user) => user.active == true);
    setState(() {
      users = myUsers;
      currentUser = myUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: currentUser == null ? Text("?") : Text(currentUser!.name),
            // TODO: This should display bech32 not hex
            accountEmail: currentUser == null ? Text("npub...") : Text(currentUser!.pubkey),
            onDetailsPressed: () {
              setState(() {
                showOtherUsersFlag = showOtherUsersFlag ? false : true;
              });
            },
            currentAccountPicture: InkWell(
              onTap: () => print('@@@@@ open edit contact'),
              child: CircleAvatar(
                backgroundImage: NetworkImage(
                  "https://randomuser.me/api/portraits/men/${Random().nextInt(20)}.jpg",
                ),
                backgroundColor: Colors.grey.shade400,
              ),
            ),
            currentAccountPictureSize: Size(60, 60),
            otherAccountsPictures: [
              Switch(
                // FIXME: fix it later, consider animated switch
                value: themeChange.darkTheme,
                onChanged: (bool? value) {
                  themeChange.darkTheme = value!;
                },
                /*
                icon: Icon(
                  Icons.dark_mode_rounded,
                  // Icons.light_mode_rounded
                  color: Colors.white,
                ),
                */
              )
            ],
          ),
          if (showOtherUsersFlag)
            ...showOtherUsers(),
          DrawerListTile(
            title: "Messages",
            icon: Icons.person_outline_rounded,
            onTap: () {
              routerDelegate.pushPage(name: '/chats', arguments: currentUser);
              Navigator.pop(context);
            }
          ),
          DrawerListTile(
            title: "Channels",
            icon: Icons.people_outline_rounded,
            onTap: () {},//=> routerDelegate.pushPage(name: '/channels'),
          ),
          DrawerListTile(
            title: "Saved Messages",
            icon: Icons.bookmark_border_rounded,
            onTap: () {},
          ),
          DrawerListTile(
            title: "Contacts", // Maybe a separate app in the future?
            icon: Icons.contacts_rounded,
            onTap: () {
              routerDelegate.pushPage(name: '/contactList');
              Navigator.pop(context);
            },
          ),
          DrawerListTile(
            title: "Settings",
            icon: Icons.settings_outlined,
            onTap: () {
              routerDelegate.pushPage(name: '/relays', arguments: currentUser);
              Navigator.pop(context);
            },
          ),
          Divider(),
          DrawerListTile(
            title: "Invite Friends",
            icon: Icons.person_add_alt_outlined,
            onTap: () {},
          ),
          DrawerListTile(
            title: "Messages Features",
            icon: Icons.info_outline_rounded,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  List<DrawerUserListTile> otherUserTiles() {
    List<DrawerUserListTile> tiles = [];
    users.asMap().forEach((index, user) =>
        tiles.add(DrawerUserListTile(
          name: user.name,
          picture: "https://avatars.githubusercontent.com/u/75714882",
          selected: user.active,
          onTap: () {
            switchUser(user.contact.id).then(
              (_) => queryUsers().then(
              // TODO: Need to remove pages that have the old user, pushing does it for
              // chats, but once we have channels working, then we can't just push
              // chats here.
              (_) => routerDelegate.pushPage(name: '/chats', arguments: currentUser)));
              Navigator.pop(context);
          },
        ),
      ),
    );
    return tiles;
  }

  
  List<dynamic> showOtherUsers() {
    return [
      ...otherUserTiles(),
      DrawerUserListTile(
        name: "New User Identity",
        icon: Icons.person_add_outlined,
        onTap: () => routerDelegate.pushPage(name: '/login', arguments: true),
      ),
      Divider(),
    ];
  }
}
