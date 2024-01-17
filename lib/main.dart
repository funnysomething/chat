import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';

Map<String, List<Message>> messageList = {};
Map<String, String> contacts = {
  "thealphatwo": "Adi Satheesh",
  "miniicecream": "Daniel Zhang"
};
String username = 'thealphatwo';

final channel = IOWebSocketChannel.connect('ws://192.168.2.126:8764/');
final messageStream = StreamController<Message>.broadcast();

Future<void> _listenForMessages() async {
  try {
    await for (var rawMessage in channel.stream) {
      print('Received message: $rawMessage');
      final dynamic decodedMessage = json.decode(rawMessage);
      if (decodedMessage['type'] == "message"){
        final String messageText = decodedMessage['content'];
        final String chatID = decodedMessage['home'].toString();
        Message message = Message(messageText, chatID, false);
        addMessage(chatID, message);
        messageStream.add(message);
      }
    }
  } catch (error) {
    print("Error receiving message: $error");
  }
}

void addMessage(String chatID, Message message){
  if (messageList[chatID.toString()] == null) {
    messageList[chatID.toString()] = [message];
  } else {
    messageList[chatID.toString()]!.add(message);
  }
}

void main() {
  _listenForMessages();
  channel.sink.add('{"type": "login", "username": "$username", "password": "1234"}');
  runApp(const MainApp());
}

class Message {
  final String text;
  final String sender;
  final bool fromSelf;

  Message(this.text, this.sender, this.fromSelf);

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'sender': sender,
      'fromSelf': fromSelf,
    };
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: placeholder(), //readFromFile(),
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
          List<String> contactList = contacts.keys.toList();
          final String chatID = contactList[index];
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
                            contacts[contacts.keys.toList()[index]]!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
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

class ChatScreen extends StatefulWidget {
  final IOWebSocketChannel channel;
  final String chatID;

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
        title: Text(contacts[widget.chatID] ?? ''),
      ),
      body: Column(
        children: [
          Expanded(child: Chats(chatID: widget.chatID)),
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
      print(chatID);
      print(messageList[chatID]);

      Message message = Message(_textController.text, username, true);
      widget.channel.sink.add(
          '{"type": "message", "content": "${_textController.text}", "dest": "$chatID", "home": "$username"}');

      addMessage(chatID, message);
      // await writeToFile();
      _textController.clear();
      FocusScope.of(context).unfocus();
      messageStream.add(message);

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
        stream: messageStream.stream, 
        builder: (context, snapshot) {
          return Text(
            messageList[widget.chatID] != null &&
                messageList[widget.chatID]!.isNotEmpty
                ? messageList[widget.chatID]!.last.text
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




class Chats extends StatefulWidget {
  const Chats({super.key, required this.chatID});

  final String chatID;

  @override
  State<Chats> createState() => _ChatsState();
}

class _ChatsState extends State<Chats> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Message>(
      stream: messageStream.stream,
      builder: (context, snapshot) {
        return ListView.builder(
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
        );
      },
    );
  }
}

Widget getIcon(String chatID) {
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

Future<void> placeholder() async {}

// Future<void> writeToFile() async {
//   try {
//     final directory = await getApplicationDocumentsDirectory();
//
//     final messageListFile = File('${directory.path}/messagelist.txt');
//     String encodedlist = json.encode(messageList);
//     print(encodedlist);
//     await messageListFile.writeAsString(encodedlist);
//
//     print('Data written to files');
//   } catch (e) {
//     print("Error writing to file: $e");
//   }
// }
//
// Future<void> readFromFile() async {
//   try {
//     final directory = await getApplicationDocumentsDirectory();
//
//     final messageListFile = File('${directory.path}/messagelist.txt');
//     if (await messageListFile.exists()) {
//       final String messageListContent = await messageListFile.readAsString();
//       final Map<String, dynamic> decodedList = json.decode(messageListContent);
//
//       for (var entry in decodedList.keys) {
//         messageList[entry] = [];
//         for (var message in decodedList[entry]) {
//           messageList[entry]
//               ?.add(Message(message['text'], message['fromSelf']));
//         }
//       }
//       print("Messagelist content: $messageListContent");
//     } else {
//       print("Setting message list values to default");
//       messageList["1"] = [];
//       messageList["2"] = [];
//       messageList["3"] = [];
//       messageList["4"] = [];
//       messageList["5"] = [];
//       messageList["6"] = [];
//     }
//   } catch (e) {
//     print("Error reading from file: $e");
//   }
// }
