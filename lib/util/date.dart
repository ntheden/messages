import 'package:intl/intl.dart'; // for date format
import 'package:intl/date_symbol_data_local.dart'; // for other locales
import 'package:timezone/timezone.dart';
import 'package:timezone/data/latest.dart';


//initializeDateFormatting('fr_FR', null).then((_) => runMyCode());
String _timezone = "";
Location? _location;


// TODO: Store timezone string in db
void initTimezone(String timezone) {
  initializeTimeZones();
  _timezone = timezone;
  _location = getLocation(timezone);
}

DateTime _timezoned(DateTime date) {
  //var locations = timeZoneDatabase.locations;
  //locations.keys.forEach((key) => print(key));
  return TZDateTime.from(date, _location!);
}

DateTime timezoned(int timestamp) {
  return _timezoned(DateTime.fromMillisecondsSinceEpoch(timestamp));
}

String formattedDate(String format, timestamp) {
  return DateFormat(format).format(timezoned(timestamp));
}

extension DateHelpers on DateTime {
  String formattedDate() {
    final now = DateTime.now();
    final difference = now.difference(this).inDays;

    if (difference < 7) {
      return this.weekday == now.weekday
          ? 'Today'
          : this.weekday == now.weekday - 1
              ? 'Yesterday'
              : DateFormat('EEEE').format(this);
    } else {
      return DateFormat.yMd().format(this);
    }
  }
}

int xtimestamp(DateTime date) {
  DateTime now = DateTime.now();
  return (now.millisecondsSinceEpoch / 1000).floor();
}

int xyesterday() {
    DateTime today = DateTime.now();
    DateTime yesterday = today.subtract(Duration(days: 1));
    return int.parse(DateFormat('yyyyMMdd').format(yesterday));
}

int yesterday() {
  // i.e., 24 hours ago
  return DateTime.now().subtract(Duration(days: 1)).millisecondsSinceEpoch;
}

