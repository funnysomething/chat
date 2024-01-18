import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/message.dart';

String username = '';

Map<String, String> contacts = {
  "thealphatwo": 'Adi Satheesh',
  "miniicecream": 'Daniel Zhang'
};

/// Basic theme to change the look and feel of the app
final appTheme = ThemeData.light().copyWith(
  primaryColorDark: Colors.orange,
  appBarTheme: const AppBarTheme(
    elevation: 1,
    backgroundColor: Colors.white,
    iconTheme: IconThemeData(color: Colors.black),
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 18,
    ),
  ),
  primaryColor: Colors.orange,
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.orange,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.orange,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    floatingLabelStyle: const TextStyle(
      color: Colors.orange,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Colors.grey,
        width: 2,
      ),
    ),
    focusColor: Colors.orange,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Colors.orange,
        width: 2,
      ),
    ),
  ),
);

Future<void> listenForMessages() async {
  try {
    await for (var rawMessage in messageStream) {
      print('Received message: $rawMessage');
      final dynamic decodedMessage = json.decode(rawMessage);
      String messageType = decodedMessage['Type'];
      switch (messageType) {
        case ("message"):
          final String messageText = decodedMessage['Content'];
          final String chatID = decodedMessage['Home'];
          Message message = Message(messageText, chatID, DateTime.now(), false);
          addMessage(chatID, message);
          break;
        case ("error"):
          print("Error message received: ${decodedMessage['ErrorType']}");
      }
    }
  } catch (error) {
    print("Error receiving message: $error");
  }
}