import 'package:drift/web.dart';

import '../db.dart';


AppDatabase constructDb() {
  return AppDatabase(WebDatabase('db'));
}

