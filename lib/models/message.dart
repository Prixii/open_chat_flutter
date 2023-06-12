import 'package:open_chat/store/client_data.dart';
import 'package:sqlite3/sqlite3.dart';

class Message {
  int messageId = 0;
  int messageSender = 0;
  int messageTarget = 0;
  String messageContent = '';
  int time = 0;

  Message({
    required this.messageId,
    required this.messageSender,
    required this.messageTarget,
    required this.messageContent,
    required this.time,
  });

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'messageSender': messageSender,
      'messageTarget': messageTarget,
      'messageContent': messageContent,
      'time': time,
    };
  }
}

List<Message> messageListFromJsonList(int target, List<dynamic> json) {
  List<Message> messageList = [];
  for (var msg in json) {
    messageList.add(
      Message(
          messageId: msg['id'],
          messageSender: msg['sender'],
          messageTarget: target,
          messageContent: msg['data'],
          time: msg['time']),
    );
  }
  return messageList;
}

Message messageFromResult(Row row) {
  return Message(
      messageId: row['message_id'],
      messageSender: row['message_sender'],
      messageTarget: clientData.currentTargetId,
      messageContent: row['message_content'],
      time: row['time']);
}
