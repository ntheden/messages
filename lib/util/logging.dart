import '../config/settings.dart';
import '../db/db.dart';
import '../util/date.dart';

void logEvent(timestamp, Contact from, Contact to, String text, {required bool rx}) {
  String date = formattedDate('yyyy-MM-dd', timestamp);
  String time = formattedDate('hh:mm:ss', timestamp);
  String direction = rx ? "RX" : "TX";
  print('$direction: Message to ${to.name} from ${from.name} on $date at $time "$text"');
}
