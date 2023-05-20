import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nostr/nostr.dart';

import '../components/contacts/contacts_entry.dart';
import '../components/drawer/index.dart';
import '../nostr/relays.dart';
import '../db/crud.dart';
import '../db/db.dart';
import '../util/date.dart';

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
                  icon: Icon(Icons.arrow_back,color: Colors.black,),
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
                Icon(Icons.settings,color: Colors.black54,),
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
        },
        child: Icon(Icons.add_rounded),
      ),
    );
  }
}

getContactWidgets(contacts) {
  List<Widget> entries = [];
  for (final contact in contacts) {
    print('@@@@@@@@@@@@@ contact $contact');
    // TODO: This formatting goes in the widget definition
    String pubkey = contact.npubs[0].pubkey;
    String npubHint = pubkey.substring(0, 5) + '...' + pubkey.substring(59, 63);
    entries.add(
      ContactsEntry(
        name: '${contact.name} ($npubHint)',
        npub: pubkey,
        picture: NetworkImage(
          "https://randomuser.me/api/portraits/men/${Random().nextInt(100)}.jpg",
        ),
      )
    );
  };
  return entries;
}
