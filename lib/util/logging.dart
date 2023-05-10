import 'package:intl/intl.dart'; // for date format
import 'package:intl/date_symbol_data_local.dart'; // for other locales
import 'package:timezone/timezone.dart';
import 'package:timezone/data/latest.dart';

import '../config/settings.dart';
import '../db/db.dart';

//initializeDateFormatting('fr_FR', null).then((_) => runMyCode());

DateTime timezoned(DateTime date) {
  initializeTimeZones();
  //var locations = timeZoneDatabase.locations;
  //locations.keys.forEach((key) => print(key));
  final timeZone = getLocation(timezone);
  return TZDateTime.from(date, timeZone);
}


void logEvent(timestamp, Contact from, Contact to, String text, {required bool rx}) {
  DateTime stamp = timezoned(DateTime.fromMillisecondsSinceEpoch(timestamp));
  String date = DateFormat('yyyy-MM-dd').format(stamp);
  String time = DateFormat('hh:mm:ss').format(stamp);
  String direction = rx ? "RX" : "TX";
  print('$direction: Message to ${to.name} from ${from.name} on $date at $time "$text"');
}

