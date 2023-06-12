import 'package:open_chat/models/group.dart';
import 'package:open_chat/network/client/group.dart';
import 'package:open_chat/utils/client_utils.dart';
import 'package:open_chat/utils/db_utils.dart';
import 'package:sqlite3/sqlite3.dart';

import '../store/client_data.dart';

/// 初始化群组信息
///
/// 1、获取群成员信息并存储到数据库（仅有id和身份）
void refreshGroupMember(int groupId) async {
  // 获取信息
  (int, List<int>?, List<int>?) memberList =
      await groupApi.getGroupMembers(groupId);
  // 返回值不为0,成功
  if (memberList.$1 != 0) {
    storeGroupMemberToDb(groupId, memberList.$1, memberList.$2, memberList.$3);
  }
}

// 存储群组的成员信息
void storeGroupMemberToDb(
  int groupId,
  int? owner,
  List<int>? adminList,
  List<int>? memberList,
) {
  // 更新数据库

  if (adminList != null && adminList.isNotEmpty) {
    insertMember(groupId, adminList, 1);
  }
  if (memberList != null && memberList.isNotEmpty) {
    insertMember(groupId, memberList, 0);
  }
  if (owner != null) {
    insertMember(groupId, [owner], 2);

    // 在数据库中删除已经被移出群组的用户
    List<int> allMemberList = [owner];
    if (memberList != null && memberList.isNotEmpty) {
      allMemberList.addAll(memberList);
    }
    if (adminList != null && adminList.isNotEmpty) {
      allMemberList.addAll(adminList);
    }
    if (allMemberList.length > 1) {
      checkMemberDeleted(allMemberList, groupId);
    }
  }
}

bool checkIsOwner(int groupId) {
  int userId = clientData.user!.id;
  final db = sqlite3.open('./lib/store/db/$userId.db');
  ResultSet resultSet = db.select(
      'SELECT member_identify from groups WHERE group_id=$groupId AND member_id=$userId;');
  if (resultSet.isNotEmpty && resultSet[0]['member_identify'] == 2) {
    return true;
  }
  return false;
}

bool checkIsAdmin(int groupId, int memberId) {
  int userId = clientData.user!.id;
  final db = sqlite3.open('./lib/store/db/$userId.db');
  ResultSet resultSet = db.select(
      'SELECT member_identify from groups WHERE group_id=$groupId AND member_id=$memberId;');
  if (resultSet.isNotEmpty && resultSet[0]['member_identify'] == 2) {
    return true;
  }
  return false;
}

int getIdentify(int groupId, int memberId) {
  int userId = clientData.user!.id;
  final db = sqlite3.open('./lib/store/db/$userId.db');
  ResultSet resultSet = db.select(
      'SELECT member_identify from groups WHERE group_id=$groupId AND member_id=$memberId;');
  if (resultSet.isNotEmpty) {
    return resultSet[0]['member_identify'];
  }
  return 0;
}

/// 从数据库中加载
void loadMemberListFromDb(int groupId) async {
  final ResultSet resultSet = await loadGroupMemberFromDb(groupId);
  if (resultSet.isNotEmpty) {
    List<Member> tmpList = [];
    for (final Row row in resultSet) {
      tmpList.add(Member(
          id: row['member_id'],
          groupId: groupId,
          identify: row['member_identify']));
      logger.d('[group member identify] ${row.toString()}');
    }
    clientData.memberList = tmpList;
  }
}

// Future<(int, List<int>, List<int>)> loadGroupMember(int groupId) async {}
