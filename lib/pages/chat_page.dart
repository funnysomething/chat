import 'package:chat/models/message.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';

import '../utils/constants.dart';

class ChatScreen extends StatefulWidget {
  final IOWebSocketChannel channel;
  final String chatID;
  final String contactName;

  const ChatScreen({super.key, required this.channel, required this.chatID, required this.contactName});

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
        title: Text(widget.contactName),
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

      Message message = Message(_textController.text, username, DateTime.now(), true);
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

class Chats extends StatefulWidget {
  const Chats({super.key, required this.chatID});

  final String chatID;

  @override
  State<Chats> createState() => _ChatsState();
}

class _ChatsState extends State<Chats> {
  @override
  Widget build(BuildContext context) {
    List<Message> reverseMessageList = getMessageList()[widget.chatID] == null
        ? []
        : getMessageList()[widget.chatID]!.reversed.toList();
    return StreamBuilder(
      stream: messageStream,
      builder: (context, snapshot) {
        return ListView.builder(
          reverse: true,
          shrinkWrap: true,
          itemCount: reverseMessageList.length,
          itemBuilder: (context, index) {
            final bool alignRight = reverseMessageList[index].fromSelf;
            return Align(
              alignment:
              alignRight ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 190),
                child: ChatBubble(message: reverseMessageList[index].text),
              ),
            );
          },
        );
      },
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          message,
          textAlign: TextAlign.left,
        ),
      ),
    );
  }
}