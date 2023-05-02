import 'package:intl/intl.dart'; // for date format
import 'package:intl/date_symbol_data_local.dart'; // for other locales
import 'package:timezone/timezone.dart';
import 'package:timezone/data/latest.dart';

import '../../config/settings.dart';

//initializeDateFormatting('fr_FR', null).then((_) => runMyCode());

DateTime timezoned(DateTime date) {
  initializeTimeZones();
  //var locations = timeZoneDatabase.locations;
  //locations.keys.forEach((key) => print(key));
  final timeZone = getLocation(timezone);
  return TZDateTime.from(date, timeZone);
}


void logEvent(event, text) {
  String to = whoseKey(event.receiver) ?? "unknown";
  String from = whoseKey(event.pubkey) ?? "unknown";
  DateTime timestamp = timezoned(DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000));
  String date = DateFormat('yyyy-MM-dd').format(timestamp);
  String time = DateFormat('hh:mm:ss').format(timestamp);
  print('Message to $to from $from on $date at $time "$text"');
}

