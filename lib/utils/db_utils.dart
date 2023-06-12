import 'dart:developer';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' as ui;
import 'package:open_chat/models/message.dart';
import 'package:open_chat/models/organization.dart';
import 'package:open_chat/network/client/organization.dart';
import 'package:open_chat/store/client_data.dart';
import 'package:open_chat/utils/client_utils.dart';
import 'package:sqlite3/sqlite3.dart';

bool createFileIfNotExist(String filePath) {
  File file = File(filePath);
  if (file.existsSync()) {
    return false;
  } else {
    file.createSync(recursive: true);
    ui.debugPrint('$filePath created');
    return true;
  }
}

void initGeneralDb() async {
  final db = sqlite3.open('./lib/store/db/general.db');
  db.execute(
    '''
      CREATE TABLE IF NOT EXISTS organization(
        id INTEGER NOT NULL PRIMARY KEY,
        name TEXT,
        md5_avatar TEXT,
        avatar_path TEXT,
        ex TEXT

      );
    ''',
  );
  db.dispose();
}

void initUserDb(int userId) {
  final db = sqlite3.open('./lib/store/db/$userId.db');
  db.execute(
    '''
      CREATE TABLE IF NOT EXISTS message(
        message_id INTEGER NOT NULL PRIMARY KEY,
        message_sender INTEGER NOT NULL,
        message_target INTEGER NOT NULL,
        message_content TEXT,
        time INTEGER
      );
    ''',
  );
  db.execute(
    '''
      CREATE TABLE IF NOT EXISTS contact(
        contact_id INTEGER NOT NULL PRIMARY KEY,
        last_message_id INTEGER DEFAULT 0,
        contact_status INTEGER DEFAULT 0
      );
    ''',
  );
  db.execute(
    '''
      CREATE TABLE IF NOT EXISTS groups(
        group_id INTEGER NOT NULL ,
        member_id INTEGER NOT NULL,
        member_identify INTEGER DEFAULT 0,
        PRIMARY KEY (group_id, member_id)
      );
    ''',
  );
  db.dispose();
}

// 检测全局数据库
void checkGeneralDb() {
  if (createFileIfNotExist('./lib/store/db/general.db')) {
    log('本地通用数据库不存在，尝试重新创建');
    initGeneralDb();
    log('本地通用数据库创建成功');
  }
}

// 检测用户数据库
void checkUserDb() {
  int userId = clientData.user!.id;
  if (createFileIfNotExist('./lib/store/db/$userId.db')) {
    initUserDb(userId);
  } else {
    final db = sqlite3.open('./lib/store/db/$userId.db');
    db.execute('DELETE FROM contact WHERE contact_status=1');
    db.dispose();
  }
}

// ******* 可用接口 ***********
// 检查sqlite文件
/// 初始化数据库
void initLocalDb() {
  checkGeneralDb();
  checkUserDb();
}
// *************************** 联系人 ******************************

/// 通过联系人插入联系人到数据库
void insertContactByOrganization(List<Organization> organArray) async {
  // int userId = clientData.user!.id;
  int userId = clientData.user!.id;

  final db = sqlite3.open('./lib/store/db/$userId.db');
  final stmt =
      db.prepare('INSERT OR IGNORE INTO contact (contact_id) VALUES (?)');
  final stmt2 = db.prepare(
      'UPDATE contact SET contact_status=0 WHERE contact_id=(?) AND contact_status=2 ');

  for (var organ in organArray) {
    // log('尝试保存数据库 [${organ.id.toString()}]');
    stmt.execute([organ.id.toString()]);
    stmt2.execute([organ.id.toString()]);
  }

  stmt.dispose();
  db.dispose();
}

/// 插入组织对象到数据库
void insertOrReplaceOrganization(List<Organization> organArray) {
  // log('尝试插入Organization到本地,目前列表中有${organizationArray.length.toString()}条数据,开始进行持久化(包含头像，破坏性)');
  checkGeneralDb();
  final db = sqlite3.open('./lib/store/db/general.db');
  final stmt = db.prepare(
      'INSERT OR REPLACE INTO organization (id, name, md5_avatar, avatar_path, ex) VALUES (?,?,?,?,?);');

  for (var organ in organArray) {
    var json = organ.toJson();
    stmt.execute([
      json['id'],
      json['name'],
      json['md5Avatar'],
      json['avatarPath'],
      json['ex'],
    ]);
  }

  stmt.dispose();
  db.dispose();
  log('共${organArray.length.toString()}条数据持久化成功');
}

Future<void> insertOrIgnoreOrganization(
    List<Organization> organizationArray) async {
  // log('尝试插入Organization到本地,目前列表中有${organizationArray.length.toString()}条数据,开始进行持久化(非破坏性，包含头像)');
  checkGeneralDb();
  final db = sqlite3.open('./lib/store/db/general.db');
  final stmt = db.prepare(
      'INSERT OR IGNORE INTO organization (id, name, md5_avatar, avatar_path, ex) VALUES (?,?,?,?,?);');

  for (var organ in organizationArray) {
    var json = organ.toJson();
    stmt.execute([
      json['id'],
      json['name'],
      json['md5Avatar'],
      json['avatarPath'],
      json['ex'],
    ]);
  }

  stmt.dispose();
  db.dispose();
  // log('共${organizationArray.length.toString()}条数据持久化成功');
}

// *************************** 消息 ******************************
/// 插入消息到数据库
Future<void> insertMessage(List<Message> messageArray) async {
  int userId = clientData.user!.id;

  final db = sqlite3.open('./lib/store/db/$userId.db');
  final stmt = db.prepare(
      'INSERT OR IGNORE INTO message (message_id, message_sender,message_target, message_content,time) VALUES (?,?,?,?,?)');

  // log('[insert Msg] 尝试加入信息到本地数据库');
  for (var msg in messageArray) {
    var json = msg.toJson();
    stmt.execute([
      json['messageId'],
      json['messageSender'],
      json['messageTarget'],
      json['messageContent'],
      json['time'],
    ]);
  }
  // log('[insert Msg] ${messageArray.length} 条持久化成功');

  stmt.dispose();
  db.dispose();
}

/// 获取数据库中的全部对应聊天的消息到 MessageCache
/// 包括自己的和别人的
/// 因为数据库只会记录本次打开之后收到的所有信息，所以放心加载没问题
Future<List<Message>> getAllMessageForCurrentChat(int targetId) async {
  int userId = clientData.user!.id;

  final db = sqlite3.open('./lib/store/db/$userId.db');

  var resultSet = db.select(
      'SELECT * FROM message WHERE message_target=$targetId ORDER BY message_id ');
  List<Message> messageList = [];
  if (resultSet.isNotEmpty) {
    // logger.d('[flush message] 从数据库中获取了 ${resultSet.length} 条信息');
    // logger.d('[flush message: 获取到的信息${resultSet[0].toString()}]');
    for (final Row row in resultSet) {
      messageList.add(messageFromResult(row));
    }
  }
  return messageList;
}

/// 返回最新的消息记录
/// 只包括别人的！！！
Future<List<Message>> getNewMessageForCurrentChat(
  int targetId,
  int latestMessageId,
) async {
  int userId = clientData.user!.id;

  final db = sqlite3.open('./lib/store/db/$userId.db');
  // logger.d('[history]: 尝试获取大于$latestMessageId');

  var resultSet = db.select(
      'SELECT * FROM message WHERE message_target=$targetId AND message_id>$latestMessageId AND message_sender IS NOT $userId ORDER BY message_id ');
  List<Message> messageList = [];
  if (resultSet.isNotEmpty) {
    logger.d('[flush message: 获取到的信息${resultSet.toString()}]');
    for (final Row row in resultSet) {
      messageList.add(messageFromResult(row));
    }
  } else {
    // logger.d('[flush message]: 没有最新消息,本地消息数量${clientData.messageList.length}');
  }
  return messageList;
}

/// 在数据库中更新联系人
Future<void> insertOrUpdateContact(List<Organization> organArray) async {
  // checkGeneralDb();
  final db = sqlite3.open('./lib/store/db/general.db');

  final stmtInsert =
      db.prepare('INSERT OR IGNORE INTO organization (id, name) VALUES (?,?);');
  final stmtUpdate =
      db.prepare('UPDATE organization SET name=(?) WHERE id=(?);');
  for (var organ in organArray) {
    var json = organ.toJson();
    stmtInsert.execute([
      json['id'],
      json['name'],
    ]);
    stmtUpdate.execute([json['name'], json['id']]);
  }
  deleteContacts(organArray);
  stmtUpdate.dispose();
  stmtInsert.dispose();
  db.dispose();
}

Future<void> deleteContacts(List<Organization> organArray) async {
  int userId = clientData.user!.id;
  final db = sqlite3.open('./lib/store/db/$userId.db');
  String currentContacts = '';
  for (var organ in organArray) {
    var json = organ.toJson();
    currentContacts = '$currentContacts${json['id']},';
  }
  currentContacts = currentContacts.substring(0, currentContacts.length - 1);
  db.execute('DELETE FROM contact WHERE contact_id NOT IN ($currentContacts);');
  db.dispose();
}

Future<void> deleteContact(int contactId) async {
  logger.i('[delete]remove $contactId');
  final db = sqlite3.open('./lib/store/db/${clientData.user!.id}.db');
  db.execute('UPDATE contact SET contact_status=1 WHERE contact_id=$contactId');
  db.dispose();
}

// *************************** 群组 ******************************
/// 插入群组成员信息到数据库
///
Future<void> insertMember(
  int groupId,
  List<int> memberIdList,
  int memberidentify,
) async {
  final db = sqlite3.open('./lib/store/db/${clientData.user!.id}.db');
  final stmt = db.prepare(
      'INSERT OR REPLACE INTO groups (group_id, member_id, member_identify) VALUES ($groupId,?,$memberidentify)');
  for (int memberId in memberIdList) {
    // logger.i('[group insert member] 插入$memberId');
    stmt.execute([memberId]);
  }
  stmt.dispose();
  db.dispose();
}

/// 检查有没有被移出群聊的用户
void checkMemberDeleted(List<int> memberIdList, int groupId) {
  final db = sqlite3.open('./lib/store/db/${clientData.user!.id}.db');
  String members = memberIdList.toString();
  members = members.substring(1, members.length - 1);
  // logger.d('[check member] members:$members');
  db.execute(
      'DELETE FROM groups WHERE group_id=$groupId AND member_id NOT IN ($members);');
  db.dispose();
}

/// 获取对应群组的成员们
///
/// 降序排列，仅有id和对应的identify
Future<ResultSet> loadGroupMemberFromDb(int groupId) async {
  final db = sqlite3.open('./lib/store/db/${clientData.user!.id}.db');
  final ResultSet resultSet = db.select(
      'SELECT member_id, member_identify FROM groups WHERE group_id=$groupId ORDER BY member_identify DESC');

  return resultSet;
}

// SELECT
/// 通过ID返回对应的头像
Future<String?> findAvatarPathById(int id) async {
  final db = sqlite3.open('./lib/store/db/general.db');
  String? avatarPath;
  var resultSet = db.select(
      '''SELECT avatar_path FROM organization WHERE id=${id.toString()}''');
  // ui.debugPrint(resultSet.toString());
  // ui.debugPrint(resultSet.length.toString());
  if (resultSet.isNotEmpty) {
    avatarPath = resultSet[0]['avatar_path'];
  }
  return avatarPath;
}

/// 通过ID返回对应的头像
Future<String?> findAvatarMd5ById(int id) async {
  final db = sqlite3.open('./lib/store/db/general.db');
  String? md5AvatarName;
  var resultSet = db.select(
      '''SELECT md5_avatar FROM organization WHERE id=${id.toString()}''');
  // ui.debugPrint(resultSet.toString());
  if (resultSet.isNotEmpty) {
    md5AvatarName = resultSet[0]['md5_avatar'];
  }
  return md5AvatarName;
}

/// 更新对应id的名字
void updateUserName(int id, String newName) async {
  final db = sqlite3.open('./lib/store/db/general.db');
  final stmt = db.prepare('UPDATE organization SET name=? WHERE id=?;');
  stmt.execute([newName, id]);
  stmt.dispose();
  db.dispose();
}

/// 从本地数据库中获取联系人
/// 这个操作会重新拉取数据并更新数据库
Future<List<int>> getContacts() async {
  // int userId = clientData.user!.id;
  int userId = clientData.user!.id;
  return await organizationApi.getContactList().then((value) {
    // log('成功同步云端数据,现在开始拉取本地数据库');

    final db = sqlite3.open('./lib/store/db/$userId.db');
    final ResultSet resultSet =
        db.select('SELECT * FROM contact WHERE contact_status=0;');

    List<int> contactIdList = [];
    for (Row row in resultSet) {
      // log('[get contact]尝试加入数据${row['contact_id']}');
      contactIdList.add(row['contact_id']);
    }
    db.dispose();
    clientData.contactIdList = contactIdList;
    return contactIdList;
  });
}

/// 从数据库寻找姓名，此操作不会向服务器请求!
Future<String?> tryFindUserNameByIdFromDb(int id) async {
  final db = sqlite3.open('./lib/store/db/general.db');
  var resultSet =
      db.select('''SELECT name FROM organization WHERE id=${id.toString()}''');
  if (resultSet.rows.isNotEmpty) {
    // log('在数据库中找到了对应的名称${resultSet[0]['name']}');
    return resultSet[0]['name'];
  } else {
    log('本地没有对应的姓名,尝试从云端获取');
    return await organizationApi.getNickname(id).then((value) {
      log('从云端获取姓名: ${value.$2}');
      clientData.addName(id, value.$2);
      return value.$2;
    });
  }
}

void insertOrIgnoreMessages(List<Message> messageList) {}

Future<int> getContactStatus(int contactId) async {
  int userId = clientData.user!.id;

  final db = sqlite3.open('./lib/store/db/$userId.db');
  final ResultSet resultSet = db
      .select('SELECT contact_status FROM contact WHERE contact_id=$contactId');
  if (resultSet.isNotEmpty) {
    return resultSet[0]['contact_status'];
  } else {
    return 1;
  }
}
