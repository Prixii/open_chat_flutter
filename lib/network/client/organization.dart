import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/models/organization.dart';
import 'package:open_chat/network/api_client.dart';
import 'package:open_chat/store/client_data.dart';
import 'package:open_chat/utils/client_utils.dart';
import 'package:open_chat/utils/db_utils.dart';
import 'package:open_chat/utils/img_utils.dart';

final OrganizationApi organizationApi = OrganizationApi();

class OrganizationApi {
  /// 获取头像，返回头像文件
  /// 如果本地存了，就直接返回
  Future<FileImage?> getAvatar(int id) async {
    // 请求头像的md5
    var newMd5AvatarName = await avatarName(id).then((value) {
      // log(value.toString());
      return value.toString();
    });
    // 从数据库中寻找对应的是否存储了
    var oldMd5AvatarName = await findAvatarMd5ById(id).then((value) => value);
    // 校验两个是否相同
    // log('newMd5AvatarName: $newMd5AvatarName');
    // log('oldMd5AvatarName: $oldMd5AvatarName');
    if (oldMd5AvatarName != null && newMd5AvatarName == oldMd5AvatarName) {
      // 两个Md5相同，直接返回本地文件
      return await findAvatarPathById(id).then((avatarPath) async {
        // log('存在本地文件:$avatarPath ');
        if (avatarPath != null) {
          if (File(avatarPath).existsSync()) {
            FileImage avatar = FileImage(File(avatarPath));
            clientData.avatarMap[id] = avatar;
            return avatar;
          }
        }
        return await downloadAvatar(id, newMd5AvatarName);
      });
    } else {
      // 如果两个Md5不同，则下载
      return await downloadAvatar(id, newMd5AvatarName);
    }
  }

  Future<FileImage?> downloadAvatar(int id, String newMd5AvatarName) async {
    log('id ${id.toString()} 的头像不在本地或未更新, 尝试进行下载 ');
    var data = mapToJsonString({
      'id': id,
    });
    return await apiClient
        .httpRequest('/organ/avatar', data)
        .then((response) async {
      // responsePrinter('getAvatar', response);
      if (response.$1 == 200) {
        var json = jsonDecode(response.$2);
        String base64Img = json['data']['file'];
        String ex = json['data']['ex'];
        // 返回头像地址
        var avatarPath = await saveImageWithString(base64Img, 'avatar$id.$ex')
            .then((response) => response);

        var nameResponse = await getNickname(id).then((value) => value);
        var tmpOrganization = Organization(id: id)
          ..avatarPath = avatarPath
          ..ex = ex
          ..md5AvatarName = newMd5AvatarName
          ..name = nameResponse.$2;
        // log(tmpOrganization.toJson().toString());
        // log('获取到了id ${id.toString()} 的头像,尝试进行持久化 ');

        // 更新本地数据库信息
        insertOrReplaceOrganization([tmpOrganization]);
        // log('持久化完成');
        FileImage avatar = FileImage(File(avatarPath));
        clientData.avatarMap[id] = avatar;
        return avatar;
      }
    }).onError((error, stackTrace) {
      log('getAvatarError, id: $id');
      return FileImage(File('./assets/images/genshin_impact_icon.jpg'));
    });
  }

  /// 设置对象的头像，如果设置成功，则返回头像名
  Future<String?> setAvatar(
      int id, String base64Img, String extentionName) async {
    var data = mapToJsonString({
      'id': id,
      'file': base64Img,
      'ex': extentionName,
    });
    logger.d('[setAvatar] $data');
    return await apiClient.httpRequest('/organ/setAvatar', data).then(
        (response) {
      responsePrinter('setAvatar', response);
      return response.$1 == 200
          ? jsonDecode(response.$2)['data']['name']
          : null;
    }).onError(
        (error, stackTrace) => log('setAvatar Error\n ${error.toString()}'));
  }

  Future<(int, String)> getNickname(int id) async {
    // 先从数据库中找

    // 找不到，则从网络获取
    var data = mapToJsonString({'id': id});
    // log('getNickname send: $data');
    return await apiClient.httpRequest('/organ/name', data).then((response) {
      // responsePrinter('getNickname', response);
      var json = jsonDecode(response.$2);
      String? name = json['data']['name'];
      return (response.$1, (name != null) ? name : 'GenshinImpact');
    }).onError((error, stackTrace) {
      log('getNickname Error, id: $id');
      return (0, 'GenshinImpact');
    });
  }

  Future<int> join(int id) async {
    var data = mapToJsonString({'id': id});
    return apiClient.httpRequest('/organ/join', data).then((response) {
      responsePrinter('join', response);
      return response.$1;
    }).onError((error, stackTrace) {
      log('join Error, id: $id');
      return 0;
    });
  }

  void exitOrganization(int contact) async {
    var data = mapToJsonString({'id': contact});
    logger.i('[delete]  $contact');

    apiClient
        .httpRequest('/organ/exit', data)
        .then((response) => responsePrinter('[delete]', response))
        .onError(
          (error, stackTrace) =>
              logger.e('exit Error, id: $contact', [error, stackTrace]),
        );
  }

  ///请求联系人和群组列表
  ///返回 状态码， 联系人列表， 信息
  Future<(int, List<Organization>?, String?)> getContactList() async {
    var data = mapToJsonString({});
    return await apiClient.httpRequest('/organ/list', data).then((response) {
      // responsePrinter('[getContactList]', response);
      var json = jsonDecode(response.$2);
      if (response.$1 == 200) {
        // 解析结果，生成Organization的List
        var resultOrganList = json['data']['result'];
        List<Organization> organList = [];
        for (var organ in resultOrganList) {
          organList.add(organizationFromJson(organ));
        }
        // log('Organization转换完成,目前列表中有${organList.length.toString()}条数据,开始进行持久化');
        // insertOrIgnoreOrganization(organList);
        insertOrUpdateContact(organList);
        insertContactByOrganization(organList);
        // log('持久化完成,尝试返回');
        return (200, organList, null);
      }
      return (response.$1, null, null);
    }).onError((error, stackTrace) {
      log('getContactList Error', stackTrace: stackTrace);
      return (0, null, null);
    });
  }

  Future<String?> avatarName(int id) async {
    var data = mapToJsonString({
      'id': id,
    });
    // log(data.toString());
    return await apiClient
        .httpRequest('/organ/avatarName', data)
        .then((response) => jsonDecode(response.$2)['data']['name'])
        .onError((error, stackTrace) =>
            log('getAvatarName Error\n ${error.toString()}'));
  }
}
