import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;

import '../../db/db.dart';


class DrawerUserListTile extends StatelessWidget {
  final String? picture;
  final IconData? icon;
  final String name;
  final Contact? contact;
  final Color backgroundColor;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;
  final bool selected;

  const DrawerUserListTile({
    Key? key,
    this.picture = "",
    this.contact,
    this.icon,
    required this.name,
    this.backgroundColor = Colors.grey,
    this.onTap,
    this.onLongPress,
    this.selected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: selected
          ? badges.Badge(
              position: badges.BadgePosition.bottomEnd(bottom: -3, end: 0),
              badgeStyle: badges.BadgeStyle(
                badgeColor: Colors.green,
              ),
              badgeContent: Icon(
                Icons.done_rounded,
                color: Colors.white,
                size: 8,
              ),
              child: SizedBox.fromSize(
                size: Size(35, 35),
                child: contact != null ?
                  contact!.avatar
                  : CircleAvatar(
                      backgroundColor: Colors.grey,
                  ),
              ),
            )
          : SizedBox.fromSize(
              size: Size(35, 35),
              child: this.icon != null
                  ? Icon(this.icon!)
                  : contact != null ? contact!.avatar
                  : CircleAvatar(
                      backgroundColor: Colors.grey,
                    ),
            ),
      title: Text(this.name),
      onTap: this.onTap,
      onLongPress: this.onLongPress,
    );
  }
}
