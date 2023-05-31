import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nostr/nostr.dart';

import '../components/relays/relays_entry.dart';
import '../components/drawer/index.dart';
import '../nostr/relays.dart';
import '../db/crud.dart';
import '../db/db.dart';
import '../util/date.dart';
import '../router/delegate.dart';

class RelaysList extends StatefulWidget {
  final String title;
  List<Relay> relays = [];
  late Contact currentUser; // will be per-user later
  late StreamController<List<Relay>> stream;
  late StreamSubscription<List<Relay>> subscription;
  _RelaysListState? _stateObj;

  RelaysList(Map<String, dynamic> options, {Key? key, this.title='Relays'}) : super(key: key) {
    currentUser = options['user'];

    stream = StreamController<List<Relay>>();
    stream.addStream(watchAllRelays());
    subscription = stream.stream.listen((entries) {
      relays = entries;
      relays.sort((a, b) {
        return a.url.toLowerCase().compareTo(b.url.toLowerCase());
      });
      _stateObj?.toggleState();
    });
  }

  @override
  _RelaysListState createState() {
    _stateObj = _RelaysListState();
    return _stateObj!;
  }
}

class _RelaysListState extends State<RelaysList> {

  bool _stateToggle = false;
  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  ScrollController _scrollController = ScrollController();

  void toggleState() {
    setState(() => _stateToggle = !_stateToggle);
  }

  @override
  void dispose() {
    widget.subscription.cancel();
    widget.stream.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Timer(Duration(milliseconds: 500), () {
        _scrollController.animateTo(
          //0.0,
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    );
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
                      Text('Relays',
                        style: TextStyle( fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                //Icon(Icons.settings, color: Colors.white,),
              ],
            ),
          ),
        ),
      ),
      body: ListView.builder(
        key: _listKey,
        controller: _scrollController,
        itemCount: widget.relays.length,
        itemBuilder: (BuildContext context, int index) {
          return Column(
            children: [
              getRelayWidget(context, index),
              Divider(height: 0),
            ]);
        },
      ),
      drawer: DrawerScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final routerDelegate = Get.put(MyRouterDelegate());
          routerDelegate.pushPage(name: '/relayEdit', arguments: {
            'user': widget.currentUser, 'relay': null,
          });
        },
        child: Icon(Icons.add_rounded),
      ),
    );
  }

  getRelayWidget(BuildContext context, int index) {
    Relay relay = widget.relays[index];
    return RelaysEntry(
      url: '${relay.url}',
      user: widget.currentUser,
      relay: relay,
      picture: AssetImage('assets/server.jpg'),
    );
  }
}
