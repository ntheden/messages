import 'package:flutter/material.dart';

import '../../src/db/db.dart';
import '../../src/db/crud.dart';
import 'drawer_list_tile.dart';
import 'drawer_user_list_tile.dart';

class DrawerScreen extends StatefulWidget {
  DrawerScreen({Key? key}) : super(key: key);

  @override
  DrawerScreenState createState() => DrawerScreenState();
}

class DrawerScreenState extends State<DrawerScreen> {
  bool showOtherUsersFlag = false;
  List<Contact> users = [];
  Contact? currentUser;
 
  @override
  void initState() {
    super.initState();
    queryUsers();
  }

  void queryUsers() async {
    List<Contact> myUsers = await getUsers();
    Contact myUser = myUsers.singleWhere((user) => user.active == true);
    setState(() {
      users = myUsers;
      currentUser = myUser;
    });
  }

  List<DrawerUserListTile> otherUserTiles() {
    List<DrawerUserListTile> tiles = [];
    users.asMap().forEach((index, user) =>
        tiles.add(DrawerUserListTile(
          name: user.name,
          picture: "https://avatars.githubusercontent.com/u/75714882",
          selected: user.active,
          onTap: () {
            switchUser(user.contact.id).then((_) => queryUsers());
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
        onTap: () => Navigator.of(context).pushNamed('/login'),
      ),
      Divider(),
    ];
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
            currentAccountPicture: CircleAvatar(
              backgroundImage: NetworkImage(
                  "https://avatars.githubusercontent.com/u/75714882"),
              backgroundColor: Colors.grey.shade400,
            ),
            currentAccountPictureSize: Size(60, 60),
            otherAccountsPictures: [
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.dark_mode_rounded,
                  /* Icons.light_mode_rounded */
                  color: Colors.white,
                ),
              )
            ],
          ),
          if (showOtherUsersFlag)
            ...showOtherUsers(),
          DrawerListTile(
            title: "Messages",
            icon: Icons.person_outline_rounded,
            onTap: () => Navigator.of(context).pushNamed('/chats'),
          ),
          DrawerListTile(
            title: "Channels",
            icon: Icons.people_outline_rounded,
            onTap: () => Navigator.of(context).pushNamed('/channels'),
          ),
          DrawerListTile(
            title: "Bookmarks",
            icon: Icons.bookmark_border_rounded,
            onTap: () {},
          ),
          DrawerListTile(
            title: "Contacts", // This will be a separate app in the future!
            icon: Icons.contacts_rounded,
            onTap: () => Navigator.of(context).pushNamed('/contacts'),
          ),
          DrawerListTile(
            title: "Settings",
            icon: Icons.settings_outlined,
            onTap: () {},
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
}
