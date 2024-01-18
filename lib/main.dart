import 'package:chat/pages/contacts_page.dart';
import 'package:chat/utils/constants.dart';
import 'package:chat/pages/login_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  final bool loggedIn = false;

  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool loggedIn = false;

  void setLoggedIn(bool value) {
    setState(() {
      loggedIn = value;
    });
  }

  @override
  void initState(){
    listenForMessages();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: loggedIn
          ? const ContactsPage()
          : LoginScreen(setLoggedIn: setLoggedIn)
    );
  }
}
