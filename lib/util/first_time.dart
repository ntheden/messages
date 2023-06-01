import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../db/crud.dart';
import '../db/db.dart';

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
  return data;
}
