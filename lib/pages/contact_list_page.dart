import 'package:after_layout/after_layout.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messages/util/avatar.dart';

import '../router/delegate.dart';

class ContactListPage extends StatefulWidget {
  @override
  _ContactListPageState createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage>
    with AfterLayoutMixin<ContactListPage> {
  List<Contact> _contacts = [];
  bool _permissionDenied = false;
  final routerDelegate = Get.put(MyRouterDelegate());

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _fetchContacts();
  }

  Future _fetchContacts() async {
    if (!await FlutterContacts.requestPermission()) {
      setState(() {
        _contacts = [];
        _permissionDenied = true;
      });
      return;
    }

    await _refetchContacts();

    // Listen to DB changes
    FlutterContacts.addListener(() async {
      print('Contacts DB changed, refecthing contacts');
      await _refetchContacts();
    });
  }

  Future _refetchContacts() async {
    // First load all contacts without photo
    await _loadContacts(false);

    // Next with photo
    await _loadContacts(true);
  }

  Future _loadContacts(bool withPhotos) async {
    final contacts = withPhotos
        ? (await FlutterContacts.getContacts(withThumbnail: true)).toList()
        : (await FlutterContacts.getContacts()).toList();
    setState(() {
      _contacts = contacts;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Messages'),
          actions: <Widget>[
            PopupMenuButton<String>(
              onSelected: _handleOverflowSelected,
              itemBuilder: (BuildContext context) {
                return ['Groups'].map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
            ),
          ],
        ),
        body: _body(),
        floatingActionButton: FloatingActionButton(
          onPressed: () => routerDelegate.pushPage(name: '/edit_contact'),
          child: Icon(Icons.add),
        ),
      );

  Widget _body() {
    if (_permissionDenied) {
      return Center(child: Text('Permission denied'));
    }
    if (_contacts.length == 0) {
      return Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
        itemCount: _contacts.length,
        itemBuilder: (context, i) {
          final contact = _contacts[i];
          return ListTile(
            leading: avatar(contact, 18.0),
            title: Text(contact.displayName),
            onTap: () =>
                routerDelegate.pushPage(name: '/contact', arguments: contact),
          );
        });
  }

  void _handleOverflowSelected(String value) {
    if (value == 'Groups') {
      routerDelegate.pushPage(name: '/groups');
    }
  }
}
