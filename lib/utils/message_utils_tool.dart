import 'package:open_chat/network/client/message.dart';
import 'package:open_chat/store/client_data.dart';
import 'package:open_chat/utils/client_utils.dart';
import 'package:open_chat/utils/db_utils.dart';
import 'package:sqlite3/sqlite3.dart';

/// 更新某个contact的 last_message_id
void updateLastMessageId(int contactId, Database db) async {
  var lastMessageId = await messageApi.getLatestMessageId(contactId);
  await updateLastMessageIdToDb(contactId, lastMessageId);
}

/// 更新某个contact的 last_message_id
/// 这个函数会更改数据库
Future<void> updateLastMessageIdToDb(int contactId, int lastMessageId) async {
  int userId = clientData.user!.id;
  // logger.d('[init msg] contact:$contactId last id:$lastMessageId 持久化 start ');
  final db = sqlite3.open('./lib/store/db/$userId.db');
  db.execute(
      'UPDATE contact SET last_message_id=$lastMessageId WHERE contact_id=$contactId');
  db.dispose();
  // logger.d('[update lastMessageid ] 持久化 end ');
}

Future<int> getLastMessageIdByContactId(int contactId) async {
  int userId = clientData.user!.id;
  if (await getContactStatus(contactId) == 1) {
    logger.d('[get lastMessageID]  获取受阻,对象已删除 ');
    return -1;
  }
  // logger.d('[get lastMessageID] 获取lastMessageId start ');
  final db = sqlite3.open('./lib/store/db/$userId.db');
  var result = db.select(
      'SELECT last_message_id from contact WHERE contact_id=$contactId');
  if (result.isNotEmpty) {
    return result[0]['last_message_id'];
  }
  return 0;
}
