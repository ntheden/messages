import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../screens/relay_edit.dart';
import '../../db/db.dart';
import '../../router/delegate.dart';

class RelaysEntry extends StatelessWidget {
  final String url;
  final Relay relay;
  final Contact user;
  final ImageProvider<Object>? picture;
  final String type;
  final bool pinned;
  final bool mute;
  final String badge;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;

  const RelaysEntry({
    Key? key,
    required this.url,
    required this.relay,
    required this.user,
    this.picture,
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
            Icon(Icons.push_pin_rounded, size: 10, color: Colors.grey.shade500)
        ],
      ),
      leading: SizedBox.fromSize(
        size: const Size(20, 20),
        child: CircleAvatar(
          backgroundImage: picture,
          backgroundColor: Colors.grey,
        ),
      ),
      onTap: () {
        final routerDelegate = Get.put(MyRouterDelegate());
        routerDelegate.pushPage(name: '/relayEdit', arguments: {
          'user': user,
          'relay': relay,
        });
      },
    );
  }

  String getTitle() {
    return relay.url;
  }
}
