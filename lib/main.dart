import 'dart:async';
import 'dart:convert';
import 'package:chat/login.dart';
import 'package:chat/chatscreen.dart';
import 'package:chat/message.dart';
import 'package:chat/contacticon.dart';
import 'package:flutter/material.dart';

Map<String, String> map = {};

Map<String, String> contacts = {
  "thealphatwo": "Adi Satheesh",
  "miniicecream": "Daniel Zhang"
};

late String username;

Future<void> _listenForMessages() async {
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
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder(
        future: placeholder(),
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return loggedIn
                ? const MainScreen()
                : LoginScreen(setLoggedIn: setLoggedIn);
          }
          return Container(
            color: Colors.white,
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    _listenForMessages();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Chat",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey[800],
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          List<String> contactList = contacts.keys.toList();
          final String chatID = contactList[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.all(5),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      channel: channel,
                      chatID: chatID,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    getIcon(chatID),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contacts[contacts.keys.toList()[index]]!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ChatPreview(chatID: chatID),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    channel.sink.close(); // Close the WebSocket channel when disposing
    super.dispose();
  }
}

class ChatPreview extends StatefulWidget {
  const ChatPreview({super.key, required this.chatID});

  final String chatID;

  @override
  State<ChatPreview> createState() => _ChatPreviewState();
}

class _ChatPreviewState extends State<ChatPreview> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: messageStream,
      builder: (context, snapshot) {
        return Text(
          getMessageList()[widget.chatID] != null &&
              getMessageList()[widget.chatID]!.isNotEmpty
              ? getMessageList()[widget.chatID]!.last.text
              : "",
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

Future<void> placeholder() async {}
