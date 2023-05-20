import 'package:badges/badges.dart' as badges;
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../constants/color.dart';
import '../../router/delegate.dart';

class ContactsEntry extends StatelessWidget {
  const ContactsEntry({
    Key? key,
    required this.name,
    required this.npub,
    required this.picture,
    this.type = "user",
    this.pinned = false,
    this.mute = false,
    this.badge = "",
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  final String name;
  final String npub;
  final ImageProvider<Object> picture;
  final String type;
  final bool pinned;
  final bool mute;
  final String badge;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Text(name),
          if (mute) SizedBox(width: 5),
          if (mute)
            Icon(
              Icons.volume_off_rounded,
              color: Colors.grey.shade400,
              size: 15,
            ),
        ],
      ),
      subtitle: type == "user"
          ? Text("last seen")
          : Row(
              children: [
                Text(
                  "hi: ",
                  style: TextStyle(color: PacificBlue),
                ),
                Text("",
                ),
              ],
            ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (pinned && badge == "")
            Icon(Icons.push_pin_rounded, size: 20, color: Colors.grey.shade500)
        ],
      ),
      leading: SizedBox.fromSize(
        size: Size(50, 50),
        child: CircleAvatar(
          backgroundImage: picture,
          backgroundColor: Colors.grey,
        ),
      ),
      onTap: () {
        final routerDelegate = Get.put(MyRouterDelegate());
        routerDelegate.pushPage(name: '/contactEdit', arguments: npub);
      },
    );
  }
}
