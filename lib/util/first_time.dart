import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<String> loadJsonData() async {
  return await rootBundle.loadString('assets/data.json');
}

Future<Map<String, dynamic>> firstTime() async {
  WidgetsFlutterBinding.ensureInitialized();
  String jsonData = await loadJsonData();
  Map<String, dynamic> data = json.decode(jsonData);
  return data;
}
