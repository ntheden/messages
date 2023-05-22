import 'dart:math';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:nostr/nostr.dart';

import '../db/db.dart';
import '../db/crud.dart';
import '../db/sink.dart';
import '../router/delegate.dart';
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
  bool missingName = false;
  bool invalidNsec = false;

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
    await insertNpub(keys.public, nameController.text,
        privkey: keys.private);
    Contact? user;
    try {
      user = await createContactFromNpubs(
        [await getNpub(keys.public)],
        nameController.text,
        active: true,
      );
    } catch (error) {
      print(error);
    }
    await switchUser(user!.contact.id);
    createContext(await getDefaultRelays(), user!);
    print('Successful login!');
    Navigator.pop(context);
    routerDelegate.pushPage(name: '/chats', arguments: user!);
    runEventSink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: Container(
            padding: EdgeInsets.only(right: 16, top: 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back, color: Colors.white,),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.center,
        child: Container(
          height: screenAwareHeight(0.6, context),
          width: max(350, screenAwareWidth(0.5, context)),
          child: ListView(
            children: <Widget>[
              Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(10),
                  child: Text(
                    'Messages',
                    style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                        fontSize: 30),
                  )),
              Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(10),
                  child: Text(
                    'Sign in',
                    style: TextStyle(fontSize: 20),
                  )),
              Container(
                padding: EdgeInsets.all(10),
                child: Focus(
                  onFocusChange: (hasFocus) {
                    if (missingName == true && !nameController.text.isEmpty) {
                      setState(() => missingName = false);
                    }
                  },
                  child: RawKeyboardListener(
                    focusNode: nameFocus,
                    onKey: (dynamic key) {
                      if (key.data.keyCode == 9) {
                        FocusScope.of(context).requestFocus(nsecFocus);
                      }
                    },
                    child: TextField(
                      controller: nameController,
                      decoration: missingName
                          ? borderDecoration.copyWith(
                              labelText: "User Name required",
                              labelStyle: TextStyle(
                                color: Colors.red,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                              ),
                            )
                          : borderDecoration,
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(10),
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
              TextButton(
                onPressed: () {
                  if (nameController.text.isEmpty) {
                    setState(() => missingName = true);
                    setState(() => invalidNsec = false);
                    return;
                  } else {
                    setState(() => missingName = false);
                  }
                  setState(() => invalidNsec = false);
                  createUserAndLogin(Keychain.generate(), nameController.text);
                },
                child: Text(
                  'Create new Nsec',
                ),
              ),
              Container(
                  height: 50,
                  width: screenAwareWidth(0.5, context),
                  padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: ElevatedButton(
                    child: Text('Login'),
                    onPressed: () {
                      if (nameController.text.isEmpty) {
                        setState(() => missingName = true);
                      } else {
                        setState(() => missingName = false);
                      }
                      if (!validateNsec()) {
                        setState(() => invalidNsec = true);
                      } else {
                        setState(() => invalidNsec = false);
                      }
                      if (!invalidNsec && !missingName) {
                        createUserAndLogin(
                          Keychain.from_bech32(nsecController.text),
                          nameController.text,
                        );
                      }
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
