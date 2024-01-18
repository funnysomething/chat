
import 'dart:convert';
import 'dart:io';
import 'package:chat/models/message.dart';
import 'package:path_provider/path_provider.dart';

Future<void> writeToFile(Map<String, List<Message>> messageList) async {
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

Future<void> readFromFile(Map<String, List<Message>> messageList) async {
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
              ?.add(Message(message['text'], message['sender'], message['sendTime'], message['fromSelf']));
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