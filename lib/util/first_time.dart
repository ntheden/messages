import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:nostr/nostr.dart';

import '../db/crud.dart';
import '../db/db.dart';
import '../nostr/network.dart';
import '../router/delegate.dart';

Future<String> loadJsonData() async {
  return await rootBundle.loadString('assets/data.json');
}

Future<Map<String, dynamic>> firstTime() async {
  WidgetsFlutterBinding.ensureInitialized();
  String jsonData = await loadJsonData();
  Map<String, dynamic> data = json.decode(jsonData);
  data['relays'].forEach((relay) =>
    insertRelay(
      url: relay['url'],
      read: relay['read'],
      write: relay['write'],
      groups: [],
      notes: "from data.json",
    )
  );
  data['keys'].forEach((key) async {
    Keychain keys = Keychain.from_bech32(key['nsec']);
    await insertNpub(keys.public, key['name'], privkey: keys.private);
    List<Contact> users = [];
    Contact user;
    try {
      user = await createContactFromNpubs(
        [await getNpub(keys.public)],
        key['name'],
      );
      users.add(user);
    } catch (error) {
      print(error);
    }
    await switchUser(users[0].contact.id);
    final routerDelegate = Get.put(MyRouterDelegate());
    routerDelegate.pushPage(name: '/chats', arguments: users[0]);
    getNetwork();
  });
  return data;
}
