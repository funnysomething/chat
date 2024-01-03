import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';

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
  final channel = IOWebSocketChannel.connect('https://n64r5h6x-8764.use.devtunnels.ms/');
  final TextEditingController _textController = TextEditingController();
  final List<Message> messages = [];

  @override
  void initState() {
    super.initState();
    _listenForMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final bool alignRight = messages[index].fromSelf;
                return Align(
                  alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 190),
                    child: Card(
                        color: Colors.blue,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            messages[index].text,
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
                        await _sendMessage();
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

  Future<void> _sendMessage() async {
    try {
      channel.sink.add(
          '{"dest":"192.168.2.128", "message": "${_textController.text}"}');
      messages.add(Message(_textController.text, true));
      _textController.clear();
      FocusScope.of(context).unfocus();
    } catch (error) {
      print("Error sending message: $error");
    }
  }

  Future<void> _listenForMessages() async {
    try {
      await for (var rawMessage in channel.stream) {
        print('Received message: $rawMessage');
        final dynamic decodedMessage = json.decode(rawMessage);
        final String text = decodedMessage['message'];
        messages.add(Message(text, false));
        setState(() {});
      }
    } catch (error) {
      print("Error receiving message: $error");
    }
  }

  @override
  void dispose() {
    channel.sink.close();
    _textController.dispose();
    super.dispose();
  }
}
