import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../db/db.dart';
import '../../db/crud.dart';
import 'drawer_list_tile.dart';
import 'drawer_user_list_tile.dart';
import '../../router/delegate.dart';
import '../../config/preferences.dart';
import '../modal/qr.dart';

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
            accountEmail: currentUser == null ? Text("npub...") : Text(currentUser!.npub),
            onDetailsPressed: () {
              setState(() {
                showOtherUsersFlag = showOtherUsersFlag ? false : true;
              });
            },
            currentAccountPicture: InkWell(
              onTap: () {
                final routerDelegate = Get.put(MyRouterDelegate());
                routerDelegate.pushPage(name: '/contactEdit', arguments: {
                  'user': currentUser,
                  'contact': currentUser,
                  'intent': 'lookup',
                });
                Navigator.pop(context); // dismiss the drawer
              },
              child: SizedBox.fromSize(
                size: Size(50, 50),
                /*
                child: CircleAvatar(
                  backgroundImage: picture,
                  backgroundColor: Colors.grey,
                ),
                */
                child: currentUser?.avatar,
              ),
              /*
              child: CircleAvatar(
                backgroundImage: NetworkImage(
                  "https://randomuser.me/api/portraits/men/${Random().nextInt(20)}.jpg",
                ),
                backgroundColor: Colors.grey.shade400,
              ),
              */
            ),
            currentAccountPictureSize: Size(60, 60),
            otherAccountsPictures: [
              InkWell(
                onTap: () => showQrPopUp(context, currentUser),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                ),
              ),
              InkWell(
                onTap: () => setState(() => themeChange.darkTheme = !themeChange.darkTheme),
                child: Icon(
                  themeChange.darkTheme ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                ),
              ),
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
              routerDelegate.pushPage(name: '/contacts', arguments: {
                'intent': 'lookup',
                'user': currentUser,
              });
              Navigator.pop(context);
            },
          ),
          DrawerListTile(
            title: "Settings",
            icon: Icons.settings_outlined,
            onTap: () {
              routerDelegate.pushPage(name: '/relays', arguments: {'user': currentUser});
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
          contact: user,
          picture: "https://avatars.githubusercontent.com/u/75714882",
          selected: user.active,
          onTap: () {
            switchUser(user.contact.id).then(
              (_) => queryUsers().then(
              (_) {
                routerDelegate.pushPage(name: '/chats', arguments: currentUser);
              }));
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
        onTap: () {
          routerDelegate.pushPage(name: '/login', arguments: true);
          Navigator.pop(context);
        },
      ),
      Divider(),
    ];
  }
}
