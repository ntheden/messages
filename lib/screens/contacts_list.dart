import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nostr/nostr.dart';

import '../components/chats/chats_entry.dart';
import '../components/drawer/index.dart';
import '../nostr/relays.dart';
import '../db/crud.dart';
import '../db/db.dart';
import '../util/date.dart';

class ContactsList extends StatefulWidget {
  final String title;
  List<Widget> chats = []; // TODO: move this back to State
  ContactsList({Key? key, this.title='Contacts'}) : super(key: key);

  @override
  _ContactsListState createState() => _ContactsListState();
}

class _ContactsListState extends State<ContactsList> {
  @override ContactsList get widget => super.widget;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 5),
            child: InkWell(
              customBorder: CircleBorder(),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.search_rounded),
              ),
              onTap: () {},
            ),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: 0,
        itemBuilder: (BuildContext context, int index) {
          return Column(
            children: [
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
