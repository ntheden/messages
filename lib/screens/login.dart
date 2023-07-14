import 'dart:math';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:nostr/nostr.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multiavatar/multiavatar.dart';

import '../db/db.dart';
import '../db/crud.dart';
import '../router/delegate.dart';
import '../network/network.dart';
import '../util/screen.dart';

class Login extends StatefulWidget {
  bool cancelable = false;
  Login(this.cancelable, {Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final routerDelegate = Get.put(MyRouterDelegate());

  TextEditingController nameController = TextEditingController();
  TextEditingController nsecController = TextEditingController();
  FocusNode nameFocus = FocusNode();
  FocusNode nsecFocus = FocusNode();
  final borderDecoration = InputDecoration(
    labelText: 'User Name',
    labelStyle: TextStyle(color: Colors.grey),
    border: OutlineInputBorder(),
  );
  bool invalidNsec = false;
  String _npub = "Welcome!";
  String _title = "Messages";
  Keychain? _keys;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    nameFocus.dispose();
    nsecFocus.dispose();
    nameController.dispose();
    nsecController.dispose();
    super.dispose();
  }

  bool validateNsec() {
    String text = nsecController.text;
    var regexp = RegExp(r'[a-zA-Z0-9]+$');
    if (text.startsWith('nsec') && text.contains(regexp)) {
      return true;
    }
    return false;
  }

  void createUserAndLogin(Keychain keys, String name) async {
    Contact user = await createContact(keys.public, name, privkey: keys.private);
    // trying to get rid of that flash of the wrong avatar
    //widget.instance.addPostFrameCallback((_) => setState(_npub = keys.npub));
    await switchUser(user.contact.id);
    Navigator.pop(context);
    routerDelegate.pushPage(name: '/chats', arguments: user);
    getNetwork();
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
                if (widget.cancelable)
                  IconButton(
                    onPressed: (){
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.arrow_back, color: Colors.white,),
                  ),
                SizedBox(width: 12,),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                  ),
                ),
                // TODO: This icon will allow you to configure relays
                Icon(Icons.settings, color: Colors.white,),
              ],
            ),
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.center,
        child: Container(
          height: screenAwareHeight(0.85, context),
          width: max(350, screenAwareWidth(0.5, context)),
          child: ListView(
            children: <Widget>[
              SvgPicture.string(multiavatar(_npub)),
              Container(
                alignment: Alignment.center,
                padding: EdgeInsets.all(10),
                child: Text(
                  _title.isEmpty ? "Messages" : _title,
                  style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                      fontSize: 30),
                ),
              ),
              Container(
                alignment: Alignment.center,
                padding: EdgeInsets.all(10),
                child: Text(
                  'Sign in',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              Container(
                padding: EdgeInsets.all(10),
                child: Focus(
                  onFocusChange: (hasFocus) {},
                  child: TextField(
                    focusNode: nameFocus,
                    controller: nameController,
                    onChanged: (value) {
                      setState(() => _title = value);
                    },
                    decoration: borderDecoration,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                child: Focus(
                  onFocusChange: (hasFocus) {
                    if (invalidNsec == true && validateNsec()) {
                      setState(() => invalidNsec = false);
                    }
                  },
                  child: TextField(
                    controller: nsecController,
                    focusNode: nsecFocus,
                    obscureText: true,
                    decoration: invalidNsec
                        ? borderDecoration.copyWith(
                            labelText: "Nsec is invalid",
                            labelStyle: TextStyle(
                              color: Colors.red,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                            ),
                          )
                        : borderDecoration.copyWith(labelText: "Nsec"),
                  ),
                ),
              ),
              Container(
                height: 50,
                width: screenAwareWidth(0.5, context),
                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: ElevatedButton(
                  child: Text('Login'),
                  onPressed: () {
                    if (!validateNsec()) {
                      setState(() => invalidNsec = true);
                    } else {
                      setState(() => invalidNsec = false);
                    }
                    if (!invalidNsec) {
                      createUserAndLogin(
                        Keychain.from_bech32(nsecController.text),
                        nameController.text.isEmpty ? "Unnamed" : nameController.text,
                      );
                    }
                  },
                ),
              ),
              Container(
                height: 50,
                width: screenAwareWidth(0.5, context),
                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: TextButton(
                  onPressed: () {
                    _keys = Keychain.generate();
                    setState(() {
                      _npub = _keys!.npub;
                      nsecController.text = _keys!.nsec;
                    });
                  },
                  child: Text(
                    'Generate New User',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
