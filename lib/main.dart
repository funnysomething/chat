import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';

Map<int, List<Message>> messageList = {};
Map<String, int> NameToID = {
  "Daniel": 1,
  "Naia": 2,
  "Brandon": 3,
  "Ethan": 4,
  "Victor": 5,
  "Kayla": 6
};
Map<int, String> IDToName = {
  1: "Daniel",
  2: "Naia",
  3: "Brandon",
  4: "Ethan",
  5: "Victor",
  6: "Kayla"
};
List<String> contacts = [
  "Daniel",
  "Naia",
  "Brandon",
  "Ethan",
  "Victor",
  "Kayla"
];
int homeID = 1;

void main() {
  runApp(const MainApp());
}

class Message {
  final String text;
  final bool fromSelf;

  Message(this.text, this.fromSelf);
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final channel = IOWebSocketChannel.connect('ws://192.168.2.128:8764/');

  @override
  void initState() {
    super.initState();
    _updateMessages();
    _listenForMessages();
  }

  Future<void> _listenForMessages() async {
    try {
      await for (var rawMessage in channel.stream) {
        print('Received message: $rawMessage');
        final dynamic decodedMessage = json.decode(rawMessage);
        final String messageText = decodedMessage['message'];
        final int chatID = decodedMessage['homeID'];
        messageList[chatID]!.add(Message(messageText, false));
        setState(() {});
      }
    } catch (error) {
      print("Error receiving message: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: messageList.length,
        itemBuilder: (context, index) {
          final int chatID = NameToID[contacts[index]]!;
          final Message lastMessage = messageList[chatID]!.isNotEmpty
              ? messageList[chatID]!.last
              : Message("", false);

          return Card(
            elevation: 2,
            margin: const EdgeInsets.all(5),
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
                            contacts[index],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lastMessage.text,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
    super.dispose();
  }
}

class ChatScreen extends StatefulWidget {
  final IOWebSocketChannel channel;
  final int chatID;

  const ChatScreen({super.key, required this.channel, required this.chatID});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  bool connected = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(IDToName[widget.chatID]!),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: messageList[widget.chatID]!.length,
              itemBuilder: (context, index) {
                final bool alignRight =
                    messageList[widget.chatID]![index].fromSelf;
                return Align(
                  alignment:
                      alignRight ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 190),
                    child: Card(
                      color: Colors.blue,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          messageList[widget.chatID]![index].text,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Card(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(10),
                    border: InputBorder.none,
                    hintText: 'Type your message...',
                    suffixIcon: IconButton(
                      onPressed: () async {
                        await _sendMessage(widget.chatID);
                      },
                      icon: const Icon(Icons.send),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(chatID) async {
    try {
      widget.channel.sink.add(
          '{"dest": $chatID, "message": "${_textController.text}", "homeID": $homeID}');
      messageList[widget.chatID]!.add(Message(_textController.text, true));
      _textController.clear();
      FocusScope.of(context).unfocus();
    } catch (error) {
      print("Error sending message: $error");
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

void _updateMessages() {
  messageList[1] = [];
  messageList[2] = [];
  messageList[3] = [];
  messageList[4] = [];
  messageList[5] = [];
  messageList[6] = [];
}

Widget getIcon(int chatID) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: CircleAvatar(
      backgroundColor: Colors.white,
      child: Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 2)),
        child: const Icon(Icons.person),
      ),
    ),
  );
}
