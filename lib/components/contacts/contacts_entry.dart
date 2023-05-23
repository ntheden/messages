import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../db/db.dart';
import '../../router/delegate.dart';

class ContactsEntry extends StatelessWidget {
  final String name;
  final Contact contact;
  final ImageProvider<Object> picture;
  final String type;
  final bool pinned;
  final bool mute;
  final String badge;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;

  const ContactsEntry({
    Key? key,
    required this.name,
    required this.contact,
    required this.picture,
    this.type = "user",
    this.pinned = false,
    this.mute = false,
    this.badge = "",
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Text(getTitle()),
          if (mute) SizedBox(width: 5),
          if (mute)
            Icon(
              Icons.volume_off_rounded,
              color: Colors.grey.shade400,
              size: 15,
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
        size: const Size(40, 40),
        child: contact.avatar,
        /*
        child: CircleAvatar(
          backgroundImage: picture,
          backgroundColor: Colors.grey,
        ),
        */
      ),
      onTap: () {
        final routerDelegate = Get.put(MyRouterDelegate());
        routerDelegate.pushPage(name: '/contactEdit', arguments: contact);
      },
    );
  }

  String getTitle() {
    String npubHint = contact.npub.substring(0, 5) + '...' + contact.npub.substring(59, 63);
    return npubHint;
  }
}
