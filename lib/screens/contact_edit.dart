import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../router/delegate.dart';

class ContactEdit extends StatefulWidget {
  final String title;
  final String npub;

  const ContactEdit(this.npub, {Key? key, this.title='<Name of Contact>'}) : super(key: key);

  @override
  _ContactEditState createState() => _ContactEditState();
}

class _ContactEditState extends State<ContactEdit> {
  final RouterDelegate routerDelegate = Get.put(MyRouterDelegate());

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
                      Text('Contact.Name',
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
    );
  }
}

