import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';

Map<String, List<Message>> messageList = {};
Map<String, int> NameToID = {
  "Daniel": 1,
  "Naia": 2,
  "Brandon": 3,
  "Ethan": 4,
  "Victor": 5,
  "Kayla": 6,
  "Adi": 7
};
Map<int, String> IDToName = {
  1: "Daniel",
  2: "Naia",
  3: "Brandon",
  4: "Ethan",
  5: "Victor",
  6: "Kayla",
  7: "Adi"
};
List<String> contacts = [
  "Daniel",
  "Naia",
  "Brandon",
  "Ethan",
  "Victor",
  "Kayla"
];
int homeID = 7;

void main() {
  runApp(const MainApp());
}

class Message {
  final String text;
  final bool fromSelf;

  Message(this.text, this.fromSelf);

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'fromSelf': fromSelf,
    };
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: readFromFile(),
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const MaterialApp(
            home: MainScreen(),
          );
        }
        return Container(
          color: Colors.white,
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final channel = IOWebSocketChannel.connect('ws://98.237.89.87:91/');

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final int chatID = NameToID[contacts[index]]!;
          final Message lastMessage = messageList[chatID.toString()] != null &&
                  messageList[chatID.toString()]!.isNotEmpty
              ? messageList[chatID.toString()]!.last
              : Message("", false);
          print("LastMessage: ${lastMessage.text}");
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
    channel.sink.close(); // Close the WebSocket channel when disposing
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
    _listenForMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(IDToName[widget.chatID] ?? ''),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: messageList[widget.chatID.toString()]?.length ?? 0,
              itemBuilder: (context, index) {
                final bool alignRight =
                    messageList[widget.chatID.toString()]![index].fromSelf;
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
                          messageList[widget.chatID.toString()]![index].text,
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
  Future<void> _listenForMessages() async {
    try {
      await for (var rawMessage in widget.channel.stream) {
        print('Received message: $rawMessage');
        final dynamic decodedMessage = json.decode(rawMessage);
        final String messageText = decodedMessage['message'];
        final String chatID = decodedMessage['homeID'].toString();

        messageList[chatID.toString()] ??= [];
        messageList[chatID.toString()]!.add(Message(messageText, false));
        await writeToFile();
        setState(() {});
        _MainScreenState().setState(() {});
      }
    } catch (error) {
      print("Error receiving message: $error");
    }
  }

  Future<void> _sendMessage(chatID) async {
    try {
      print(chatID);
      print(messageList[chatID]);

      widget.channel.sink.add(
          '{"dest": $chatID, "message": "${_textController.text}", "homeID": $homeID}');

      if (messageList[chatID.toString()] == null) {
        messageList[chatID.toString()] = [Message(_textController.text, true)];
      } else {
        messageList[chatID.toString()]!
            .add(Message(_textController.text, true));
      }
      await writeToFile();

      _textController.clear();
      FocusScope.of(context).unfocus();
      setState(() {});
      _MainScreenState().setState(() {});
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

Future<void> writeToFile() async {
  try {
    final directory = await getApplicationDocumentsDirectory();

    final messageListFile = File('${directory.path}/messagelist.txt');
    String encodedlist = json.encode(messageList);
    print(encodedlist);
    await messageListFile.writeAsString(encodedlist);

    print('Data written to files');
  } catch (e) {
    print("Error writing to file: $e");
  }
}

Future<void> readFromFile() async {
  try {
    final directory = await getApplicationDocumentsDirectory();

    final messageListFile = File('${directory.path}/messagelist.txt');
    if (await messageListFile.exists()) {
      final String messageListContent = await messageListFile.readAsString();
      final Map<String, dynamic> decodedList = json.decode(messageListContent);

      for (var entry in decodedList.keys) {
        messageList[entry] = [];
        for (var message in decodedList[entry]) {
          messageList[entry]
              ?.add(Message(message['text'], message['fromSelf']));
        }
      }
      print("Messagelist content: $messageListContent");
    } else {
      print("Setting message list values to default");
      messageList["1"] = [];
      messageList["2"] = [];
      messageList["3"] = [];
      messageList["4"] = [];
      messageList["5"] = [];
      messageList["6"] = [];
    }
  } catch (e) {
    print("Error reading from file: $e");
  }
}
