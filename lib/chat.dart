import 'package:chat/message.dart';
import 'package:flutter/material.dart';

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
