import 'dart:math';
import 'package:flutter/material.dart';
 
class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}
 
class _LoginState extends State<Login> {
  TextEditingController nameController = TextEditingController();
  TextEditingController nsecController = TextEditingController();

  double screenAwareHeight(double size, BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    double drawingHeight = mediaQuery.size.height - mediaQuery.padding.top;
    return size * drawingHeight;
  }

  double screenAwareWidth(double size, BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    double drawingWidth = mediaQuery.size.width
           - (mediaQuery.padding.left + mediaQuery.padding.right);
    return size * drawingWidth;
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.center,
        child: Container(
          height: screenAwareHeight(0.6, context),
          width: max(350, screenAwareWidth(0.5, context)),
          child: ListView(
            children: <Widget>[
              Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(10),
                  child: const Text(
                    'Messages',
                    style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                        fontSize: 30),
                  )),
              Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(10),
                  child: const Text(
                    'Sign in',
                    style: TextStyle(fontSize: 20),
                  )),
              Container(
                padding: const EdgeInsets.all(10),
                child: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'User Name',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: TextField(
                  obscureText: true,
                  controller: nsecController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Nsec',
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                },
                child: const Text('Create new Nsec',),
              ),
              Container(
                height: 50,
                width: screenAwareWidth(0.5, context),
                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: ElevatedButton(
                  child: Text('Login'),
                  onPressed: () {
                    print(nameController.text);
                    print(nsecController.text);
                  },
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}
