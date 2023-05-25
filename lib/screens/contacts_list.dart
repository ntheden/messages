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
import '../router/delegate.dart';

class ContactsList extends StatefulWidget {
  final String title;
  List<Widget> contacts = [];
  ContactsList({Key? key, this.title='Contacts'}) : super(key: key) {
    getAllContacts().then(
      (entries) => contacts = getContactWidgets(entries));
  }
  @override
  _ContactsListState createState() => _ContactsListState();
}

class _ContactsListState extends State<ContactsList> {
  @override ContactsList get widget => super.widget;
  bool newContactToggle = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    /*
    watchAllContacts().listen((entries) {
      print('@@@@@@@@@@@@@@@@@@@ entries $entries');
      List<Contact> contacts = [];
      for (final entry in entries) {
        getContact(entry).then((contact) => contacts.add(contact));
      }
      widget.contacts = getContactWidgets(contacts);
      print('@@@@@@@@@@@@@@@@@@@ contacts len ${widget.contacts.length}');
      setState(() => newContactToggle = !newContactToggle);
    });
    */
    getAllContacts().then(
      (entries) {
        widget.contacts = getContactWidgets(entries);
        setState(() => newContactToggle = !newContactToggle);
    });
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
              widget.contacts[index],
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
}

getContactWidgets(contacts) {
  List<Widget> entries = [];
  for (final contact in contacts) {
    entries.add(
      ContactsEntry(
        name: '${contact!.name}',
        contact: contact!,
        picture: NetworkImage(
          "https://randomuser.me/api/portraits/men/${Random().nextInt(100)}.jpg",
        ),
      )
    );
  };
  return entries;
}
