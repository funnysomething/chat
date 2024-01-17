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
late String username;

final channel = IOWebSocketChannel.connect('ws://192.168.2.126:8764/');
final messageStream = channel.stream.asBroadcastStream();

Future<bool> _login(String username, String password) async {
  try {
    channel.sink.add('{"type": "login", "username": "$username", "password": "$password"}');
    var response;
    await for (var rawMessage in messageStream) {
      response = json.decode(rawMessage);
      print("RESPONSE: ${response}");
      break; // exit the loop after receiving the first message
    }
    if (response['Type'] == 'login'){
      print("Checking status");

      return response['Stat'] == 'true';
    } else {
      return false;
    }
  } catch(e) {
    return false;
  }
}

Future<void> _listenForMessages() async {
  try {
    await for (var rawMessage in messageStream) {
      print('Received message: $rawMessage');
      final dynamic decodedMessage = json.decode(rawMessage);
      String messageType = decodedMessage['Type'];
      switch(messageType) {
        case("message"):
          final String messageText = decodedMessage['Content'];
          final String chatID = decodedMessage['Home'];
          Message message = Message(messageText, chatID, false);
          addMessage(chatID, message);
          break;
        case("error"):
          print("Error message received: ${decodedMessage['ErrorType']}");
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
  runApp(MainApp());
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

class MainApp extends StatefulWidget {
  final bool loggedIn = false;

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
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
            return loggedIn ? const MainScreen() : LoginScreen(setLoggedIn: setLoggedIn);
          }
          return Container(
            color: Colors.white,
          );
        },
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key, required this.setLoggedIn}) : super(key: key);

  final Function(bool) setLoggedIn;

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[400]!, Colors.grey[800]!],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person, color: Colors.grey[800]),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock, color: Colors.grey[800]),
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            if (await _login(_usernameController.text, _passwordController.text)) {
                              username = _usernameController.text;
                              widget.setLoggedIn(true);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: Colors.grey[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            'Login',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key});

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
        stream: messageStream,
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
    List<Message> reverseMessageList = messageList[widget.chatID] == null? []:messageList[widget.chatID]!.reversed.toList();
    return StreamBuilder(
      stream: messageStream,
      builder: (context, snapshot) {
        return ListView.builder(
          reverse: true,
          shrinkWrap: true,
          itemCount: reverseMessageList.length,
          itemBuilder: (context, index) {
            final bool alignRight =
                reverseMessageList[index].fromSelf;
            return Align(
              alignment:
              alignRight ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 190),
                child: Card(
                  color: Colors.black26,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      reverseMessageList[index].text,
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
