import '../src/contact.dart';

class MessageEntry {
  String content;
  String source;
  Contact contact;
  DateTime timestamp;
  int index;
  MessageEntry({
    required this.content,
    required this.source,
    required this.contact,
    required this.timestamp,
    required this.index,
  });
}
