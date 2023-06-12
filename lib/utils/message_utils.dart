import 'package:open_chat/models/message.dart';
import 'package:open_chat/network/client/message.dart';
import 'package:open_chat/utils/client_utils.dart';
import 'package:open_chat/utils/db_utils.dart';
import 'package:open_chat/utils/message_utils_tool.dart';
import 'package:sqlite3/sqlite3.dart';

import '../store/client_data.dart';

/// 初始化聊天记录,请在获取完contact之后执行
///
/// 1、重置用户的message数据库
///
/// 2、检查所有联系人的 last_message_id，如果为0，则执行一次获取最新信息的请求，请求大小为1
///
/// 3、对于所有好友或加入的群组，分别拉取100条信息，并将id与last_message_id比对
///
///    如果全部大于last_message，则直接置为99+，如果有小于last_message_id，则置对应的数
///
/// 4、直到点击后，更新last_message_id到数据库。只有大于last_message_id的才会被计数
void initMessage() async {
  int userId = clientData.user!.id;
  final db = sqlite3.open('./lib/store/db/$userId.db');
  await resetMessage(db);
  final ResultSet resultSet = await checkLastMessageId(db);
  for (int contactId in clientData.contactIdList) {
    clientData.setLatestMessageIdTemp(
        contactId, await getLastMessageIdByContactId(contactId));
  }
  await checkNotReadMessageCount(resultSet);

  db.dispose();
}

/// 全局下每秒都拉取一次信息
/// 操作会更新最新消息的id缓存（不修改数据库）
/// 会更新最新消息的数量（除非对象已经打开了聊天窗口）
void fetchMessage() async {
  // logger.d('[fetch Message] 获取${clientData.contactIdList.toString()}的新消息');
  // logger.d('[fetch Message] 目前状态${clientData.lastMessageId.toString()}');
  for (final int contactId in clientData.contactIdList) {
    if (await getContactStatus(contactId) == 1) continue;
    // 如果对象已经删除了，直接跳过
    var lastMsgId = clientData.lastMessageId[contactId];
    if (lastMsgId != null) {
      // 获取信息,
      List<Message>? msgList =
          await messageApi.getLatestMsg(contactId, lastMsgId, 20);

      if (msgList != null && msgList.isNotEmpty) {
        int latestId = msgList[msgList.length - 1].messageId;
        // 更新最近消息游标
        clientData.setLatestMessageIdTemp(contactId, latestId);

        // 更新未读消息数量
        int tmpCount = clientData.notReadMessageCount[contactId] ?? 0;
        clientData.setNewMessageCount(contactId, tmpCount + msgList.length);
      }
    }
  }
  // logger.d('[unread count]${clientData.notReadMessageCount.toString()}');
}

// *******************************************************
/// 1、重置用户的message表
Future<void> resetMessage(Database db) async {
  // logger.d('[重置message表] start');
  db.execute('DELETE FROM message');
  // logger.d('[init msg]重置message表 succeed');
}

/// 2、检查所有联系人的 last_message_id，如果为0，则执行一次获取最新信息的请求，请求大小为1
Future<ResultSet> checkLastMessageId(Database db) async {
  // logger.d('[获取联系人last_message_id] start');

  final ResultSet resultSet = db.select('SELECT * FROM contact;');
  for (final Row row in resultSet) {
    // logger.i('[history] ${row.toString()}');
    if (row['last_message_id'] == 0) {
      updateLastMessageId(row['contact_id'], db);
    }
  }

  // logger.d('[获取联系人last_message_id] succeed');
  return resultSet;
}

/// 3、对于所有好友或加入的群组，分别拉取100条信息，并将id与last_message_id比对
///    如果全部大于last_message，则直接置为99+，如果有小于last_message_id，则置对应的数
Future<void> checkNotReadMessageCount(ResultSet resultSet) async {
  for (Row row in resultSet) {
    // 如果最后的数量不为0，说明可能有最新消息
    if (row['last_message_id'] != 0) {
      int contactId = row['contact_id'];

      List<Message>? msgList = await messageApi.getLatestMsg(
          row['contact_id'], row['last_message_id'], 100);
      if (msgList != null) {
        final int lastMessageId = await getLastMessageIdByContactId(contactId);
        if (lastMessageId == -1) return;
        if (msgList.isNotEmpty && msgList[0].messageId > lastMessageId) {
          logger.d(
              '[checkLastMessageId] lastMessageId $contactId: ${msgList.length}');
          clientData.setLatestMessageIdTemp(contactId, msgList[0].messageId);
          clientData.setNewMessageCount(contactId, msgList.length);
        } else {
          for (int i = 0; i < msgList.length; i++) {
            if (msgList[i].messageId > lastMessageId) {
              logger
                  .d('[checkLastMessageId] lastMessageId$contactId: ${i + 1}');
              clientData.setLatestMessageIdTemp(
                  contactId, msgList[i].messageId);
              clientData.setNewMessageCount(contactId, i + 1);
              break;
            }
          }
        }
      }
    }
    // logger.d(
    // '[fetch Message] newMessageCount: ${clientData.notReadMessageCount.toString()}');
  }
}

void fetchMessageDebug() async {
  // logger.d('[fetch Message] 获取${clientData.contactIdList.toString()}的新消息');
  // logger.d('[fetch Message] 目前状态${clientData.lastMessageId.toString()}');
  int contactId = 100000013;
  if (await getContactStatus(contactId) == 1) return;
  var lastMsgId = clientData.lastMessageId[contactId];
  if (lastMsgId != null) {
    // 获取信息,
    List<Message>? msgList =
        await messageApi.getLatestMsg(contactId, lastMsgId, 20);
    if (msgList != null && msgList.isNotEmpty) {
      int latestId = msgList[msgList.length - 1].messageId;
      // 更新最近消息游标
      clientData.setLatestMessageIdTemp(contactId, latestId);

      // 更新未读消息数量
      clientData.setNewMessageCount(contactId, msgList.length);
    }
  }
}
