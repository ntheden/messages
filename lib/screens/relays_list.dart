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

class RelaysList extends StatefulWidget {
  final String title;
  List<Widget> relays = [];
  RelaysList({Key? key, this.title='Relays'}) : super(key: key) {
    getAllRelays().then(
      (entries) => relays = getRelayWidgets(entries));
  }
  @override
  _RelaysListState createState() => _RelaysListState();
}

class _RelaysListState extends State<RelaysList> {
  @override RelaysList get widget => super.widget;
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
        child: Icon(Icons.add_rounded),
      ),
    );
  }
}

getRelayWidgets(relays) {
  List<Widget> entries = [];
  for (final relay in relays) {
    entries.add(
      RelaysEntry(
        name: '${relay!.name}',
        relay: relay!,
        picture: NetworkImage(
          "https://randomuser.me/api/portraits/men/${Random().nextInt(100)}.jpg",
        ),
      )
    );
  };
  return entries;
}

