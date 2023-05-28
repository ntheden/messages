import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nostr/nostr.dart';

import '../components/contacts/contacts_entry.dart';
import '../components/drawer/index.dart';
import '../nostr/relays.dart';
import '../db/crud.dart';
import '../db/db.dart';
import '../util/date.dart';
import '../util/pair.dart';
import '../router/delegate.dart';

class ContactsList extends StatefulWidget {
  final String title;
  List<Contact> contacts = [];
  late Contact currentUser;
  late String intent;
  late StreamController<List<DbContact>> stream;
  late StreamSubscription<List<DbContact>> subscription;

  ContactsList(Map<String, dynamic> options, {Key? key, this.title='Contacts'}) : super(key: key) {
    currentUser = options['user'];
    intent = options['intent']; // either 'chat' or 'lookup'

    stream = StreamController<List<DbContact>>();
    stream.addStream(watchAllDbContacts());
    subscription = stream.stream.listen((entries) {
      makeContactsList(entries);
    });
  }

  void makeContactsList(dbContacts) async {
    List<int> ids = [];
    dbContacts.forEach((c) => ids.add(c.id));
    contacts = await getContacts(ids);
  }

  @override
  _ContactsListState createState() => _ContactsListState();
}

class _ContactsListState extends State<ContactsList> {

  @override
  void dispose() {
    widget.subscription.cancel();
    widget.stream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: Container(
            padding: EdgeInsets.only(right: 16),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back, color: Colors.white,),
                ),
                SizedBox(width: 12,),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('Contacts',
                        style: TextStyle( fontSize: 16 ,fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.settings, color: Colors.white,),
              ],
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: widget.contacts.length,
        itemBuilder: (BuildContext context, int index) {
          return Column(
            children: [
              getContactWidget(context, index),
              Divider(height: 0),
            ]);
        },
      ),
      drawer: DrawerScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final routerDelegate = Get.put(MyRouterDelegate());
          routerDelegate.pushPage(name: '/contactEdit', arguments: null);
        },
        child: Icon(Icons.person_add),
      ),
    );
  }

  Widget getContactWidget(context, int index) {
    Contact contact = widget.contacts[index];
    return ContactsEntry(
      name: '${contact.name}',
      contact: contact,
      user: widget.currentUser,
      picture: NetworkImage(
        "https://randomuser.me/api/portraits/men/${Random().nextInt(100)}.jpg",
      ),
      onTapIntent: widget.intent,
    );
  }
}
