import 'dart:convert';
import 'dart:developer';

import 'package:open_chat/models/message.dart';
import 'package:open_chat/network/api_client.dart';
import 'package:open_chat/utils/client_utils.dart';
import 'package:open_chat/utils/db_utils.dart';

final MessageApi messageApi = MessageApi();

class MessageApi {
  Future<int> send(int targetId, String content) async {
    var data = mapToJsonString({
      'id': targetId,
      'data': content,
    });
    // log('[msgSend]申请发送消息,请求:${data.toString()}');
    return apiClient.httpRequest('/msg/send', data).then((response) {
      responsePrinter('msgSend', response);
      if (response.$1 == 200) {
        var json = jsonDecode(response.$2);
        int? msgId = json['data']['id'];
        return msgId ?? -1;
      }
      return -1;
    }).onError((error, stackTrace) {
      log('send Error');
      return -1;
    });
  }

  /// 获取信息
  Future<List<Message>> getEarlyMsg(int contactId, int msgId, int count) async {
    var data = mapToJsonString({
      'id': contactId,
      'msgID': msgId,
      'num': count,
    });
    logger.d('[get history msg] data: $data');
    return apiClient.httpRequest('/msg/up', data).then((response) {
      if (response.$1 == 200) {
        responsePrinter('[get history msg]', response);
        log('[msgUp]获取$contactId历史信息成功,尝试进行持久化');
        List<dynamic> msgList = jsonDecode(response.$2)['data']['message'];
        List<Message> msgDataList = messageListFromJsonList(contactId, msgList);
        // for (var msg in msgDataList) {
        //   var json = msg.toJson();
        //   log('[msgUp]获取到$contactId的信息列表:${json['id']}');
        // }
        insertMessage(msgDataList);
        return msgDataList;
      } else {
        responsePrinter('[msgUp error]id:$contactId', response);
        List<Message> tmp = [];
        return tmp;
      }
    }).onError((error, stackTrace) {
      log('up Error');
      List<Message> tmp = [];
      return tmp;
    });
  }

  Future<int> getLatestMessageId(int contactId) async {
    var data = mapToJsonString({
      'id': contactId,
      'msgID': 0,
      'num': 1,
    });
    // logger.i('[init msg] ${data.toString()}');
    return apiClient.httpRequest('/msg/up', data).then((response) {
      responsePrinter('[init msg] $contactId', response);
      if (response.$1 == 200) {
        final msgList = jsonDecode(response.$2)['data']['message'];
        if (msgList.length > 0) {
          var msgData = msgList[0];
          int msgId = msgData['id'];
          // logger.i('[获取最新消息id] succeed, id: $msgId');
          return msgId;
        }
      }
      return 0;
    }).onError((error, stackTrace) {
      // logger.e('[获取$contactId最新消息id]', [error, stackTrace]);
      return 0;
    });
  }

  /// 获取信息，并自动更新到数据库
  Future<List<Message>?> getLatestMsg(
      int contactId, int msgId, int count) async {
    var data = mapToJsonString({
      'id': contactId,
      'msgID': msgId,
      'num': count,
    });
    // logger.i('[fetch Message] getMsgDown 请求体: $data');
    return apiClient.httpRequest('/msg/down', data).then((response) {
      // responsePrinter('[fetch Message] getMsgDown $msgId', response);
      if (response.$1 == 200) {
        // log('[fetch Message]获取$contactId历史信息成功,尝试进行持久化');
        List<dynamic> msgList = jsonDecode(response.$2)['data']['message'];
        List<Message> msgDataList = messageListFromJsonList(contactId, msgList);
        // for (var msg in msgDataList) {
        // var json = msg.toJson();
        // log('[fetch Message]获取到$contactId的信息列表:${json['messageId']}');
        // }
        insertMessage(msgDataList);
        return msgDataList;
      } else {
        responsePrinter('[msgUp error]id:$contactId', response);
        return null;
      }
    }).onError((error, stackTrace) {
      logger.e('[fetch Message]', [error, stackTrace]);
      return null;
    });
  }
}
