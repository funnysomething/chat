import 'package:web_socket_channel/io.dart';

Map<String, List<Message>> messageList = {};

final channel = IOWebSocketChannel.connect('ws://192.168.2.126:8764/');
final messageStream = channel.stream.asBroadcastStream();

Map<String, List<Message>> getMessageList() {
  return messageList;
}

void addMessage(String chatID, Message message) {
  if (messageList[chatID.toString()] == null) {
    messageList[chatID.toString()] = [message];
  } else {
    messageList[chatID.toString()]!.add(message);
  }
}

class Message {
  final String text;
  final String sender;
  final DateTime sendTime;
  final bool fromSelf;

  Message(this.text, this.sender, this.sendTime, this.fromSelf);

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'sender': sender,
      'fromSelf': fromSelf,
    };
  }
}