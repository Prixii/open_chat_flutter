import 'dart:convert';
import 'dart:developer';

import 'package:open_chat/network/api_client.dart';
import 'package:open_chat/utils/client_utils.dart';

final GroupApi groupApi = GroupApi();

class GroupApi {
  /// 创建群聊
  /// 返回 int=200时，第二个数据为新群聊id
  Future<(int, int)> create(String name) async {
    var data = mapToJsonString({
      'name': name,
    });
    return apiClient.httpRequest('/group/create', data).then((response) {
      responsePrinter('createGroup', response);
      if (response.$1 == 200) {
        var json = jsonDecode(response.$2);

        return (response.$1, json['data']['id'] as int);
      }
      return (0, -1);
    }).onError((error, stackTrace) {
      log('createGroup Error');
      return (0, -1);
    });
  }

  /// 解散群聊
  void dismissGroup(int groupId) async {
    var data = mapToJsonString({
      'id': groupId,
    });
    logger.d('[deleteGroup]$data');
    apiClient
        .httpRequest('/group/delete', data)
        .then((response) => responsePrinter('deleteGroup', response))
        .onError((error, stackTrace) => log('deleteGroup Error, id: $groupId'));
  }

  /// 设置群聊的管理员
  void setAdmin(int groupID, int memberId) async {
    var data = mapToJsonString({
      'groupID': groupID,
      'userID': memberId,
    });
    logger.d('setAdmin $data');

    apiClient
        .httpRequest('/group/setAdmin', data)
        .then((response) => responsePrinter('setAdmin', response))
        .onError((error, stackTrace) => log('setAdmin Error'));
  }

  /// 撤销成员管理员身份
  void removeAdmin(int groupID, int memberId) async {
    var data = mapToJsonString({
      'groupID': groupID,
      'userID': memberId,
    });
    logger.d('setAdmin $data');
    apiClient
        .httpRequest('/group/removeAdmin', data)
        .then((response) => responsePrinter('removeAdmin setAdmin', response))
        .onError((error, stackTrace) => log('removeAdmin Error'));
  }

  /// 获取加群请求
  /// 返回申请列表(申请方id, 群组groupID)
  Future<List<(int, int)>?> getGroupRequest() async {
    var data = mapToJsonString({});
    return apiClient.httpRequest('/group/request', data).then((response) {
      responsePrinter('[get requestList]', response);
      if (response.$1 == 200) {
        var json = jsonDecode(response.$2);
        List<(int, int)> requestList = [];
        var responseList = json['data']['request'];
        for (var request in responseList) {
          requestList.add((request['id'], request['groupID']));
        }
        return requestList;
      }
    }).onError((error, stackTrace) {
      logger.e('[get group request]', [error, stackTrace]);
      return null;
    });
  }

  /// 接受加群请求
  void agreeGroupRequest(int groupID, int memberId) async {
    var data = mapToJsonString({
      'groupID': groupID,
      'userID': memberId,
    });
    logger.d('[agree] $data');
    apiClient
        .httpRequest('/group/agree', data)
        .then((response) => responsePrinter('agree', response))
        .onError((error, stackTrace) => log('agree Error'));
  }

  /// 拒绝加群请求
  void disagreeGroupRequest(int groupID, int memberId) async {
    var data = mapToJsonString({
      'groupID': groupID,
      'userID': memberId,
    });

    apiClient
        .httpRequest('/group/disagree', data)
        .then((response) => responsePrinter('disagree', response))
        .onError((error, stackTrace) => log('disagree Error'));
  }

  /// 设置群聊名称
  Future<int> setGroupName(int groupId, String name) async {
    var data = mapToJsonString({
      'groupID': groupId,
      'name': name,
    });
    logger.d('[set group Name] data:$data');
    return apiClient.httpRequest('/group/setName', data).then((response) {
      responsePrinter('[set group Name]', response);
      return response.$1;
    }).onError((error, stackTrace) {
      log('setName Error');
      return 0;
    });
  }

  /// 获取群成员列表并存储到数据库中
  ///
  /// (owner, adminList, memberList)
  ///
  /// 如果返回值为(0,?,?)说明出错了，直接略过
  Future<(int, List<int>?, List<int>?)> getGroupMembers(int groupId) async {
    var data = mapToJsonString({
      'id': groupId,
    });
    // logger.d('[group member] 请求群$groupId 成员');
    (int, String) response = await apiClient
        .httpRequest('/group/member', data)
        .then((value) => value)
        .onError((error, stackTrace) {
      logger.e('[group member] Error', [error, stackTrace]);
      return (0, 'Error');
    });
    // responsePrinter('[group member]', response);
    if (response.$1 == 200) {
      var json = jsonDecode(response.$2)['data'];
      int? owner;

      List<int>? adminList;
      List<int>? memberList;
      try {
        owner = json['owner'];

        if (json['admin'] != null) {
          adminList = [];
          for (int adminId in json['admin']) {
            adminList.add(adminId);
          }
        }

        if (json['member'] != null) {
          memberList = [];
          for (int memberId in json['member']) {
            memberList.add(memberId);
          }
        }
        // logger.d('[parse adminList] ${adminList.toString()}');
        // logger.d('[parse memberList] ${memberList.toString()}');
      } catch (e) {
        logger.e('[group member]parse Error');
        // customDisplayInfoBar(context, '错误', '501', InfoBarSeverity.error);
      }
      return (owner ?? 0, adminList, memberList);
    }
    return (0, null, null);
  }

  void deleteMember(int groupId, int memberId) async {
    var data = mapToJsonString({
      'id': groupId,
      'userID': memberId,
    });
    apiClient
        .httpRequest('/group/t', data)
        .then((response) => responsePrinter('[delete member]', response))
        .onError((error, stackTrace) =>
            logger.e('[delete member]', [error, stackTrace]));
  }
}
