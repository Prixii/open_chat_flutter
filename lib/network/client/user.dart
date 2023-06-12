import 'dart:convert';
import 'dart:developer';

import 'package:open_chat/models/account.dart';
import 'package:open_chat/network/api_client.dart';
import 'package:open_chat/network/client/organization.dart';
import 'package:open_chat/store/client_data.dart';
import 'package:open_chat/utils/client_utils.dart';

import '../../utils/img_utils.dart';

final UserApi userApi = UserApi();

class UserApi {
  Future<(int, String, int?)> create(
      String phoneNumber, String password) async {
    var data = mapToJsonString({
      'phoneNumber': phoneNumber,
      'password': password,
      'deviceID': clientData.deviceId,
    });
    // log(data.toString());
    return apiClient.httpRequest('/user/create', data).then((response) {
      var json = jsonDecode(response.$2);
      int code = json['code'];
      String message = json['message'];
      int? id = json['data']['id'];
      return (
        code,
        message,
        id,
      );
    }).onError((error, stackTrace) => (0, '网络错误', null));
  }

  void setUser(int userId, String password) {
    apiClient.setUser(userId, password, clientData.deviceId);
  }

  void setPassword(String oldPassword, String newPassword) async {
    var data = mapToJsonString({
      'oldPassword': oldPassword,
      'password': newPassword,
    });
    apiClient
        .httpRequest('/user/setPassword', data)
        .then((response) => responsePrinter('setPassword', response))
        .onError((error, stackTrace) => log('setPassword Error'));
  }

  Future<int> setName(String newNickname) async {
    var data = mapToJsonString({'name': newNickname});
    return apiClient.httpRequest('/user/setName', data).then((response) {
      responsePrinter('setName', response);
      return response.$1;
    }).onError((error, stackTrace) {
      log('setName Error');
      return 0;
    });
  }

  Future<int?> login(String phoneNumber, String md5Password) async {
    log('device Id :${clientData.deviceId}');
    var data = mapToJsonString({
      'phoneNumber': phoneNumber,
      'deviceID': clientData.deviceId,
      'password': md5Password,
    });
    log(data);
    var newUserId =
        await apiClient.httpRequest('/user/login', data).then((response) {
      responsePrinter('login', response);
      var responseJson = jsonDecode(response.$2);
      return responseJson['data']['id'];
    });

    return newUserId;
  }

  void initCurrentUserInfo() async {
    clientData.user = User(
        id: 100000001,
        phoneNumber: '12305251757',
        password: '25d55ad283aa400af464c76d713c07ad');
    clientData.deviceId = '31444335-3232-4D38-5142-489EBD26ECE0';
    apiClient.setUser(100000001, '25d55ad283aa400af464c76d713c07ad',
        '31444335-3232-4D38-5142-489EBD26ECE0');
    initCurrentUserNameFromNet();
    apiClient.setUser(
        clientData.user!.id, clientData.user!.password, clientData.deviceId);
    clientData.showCurrentUserInfo();
    clientData.userAvatar =
        await organizationApi.getAvatar(clientData.user!.id) ?? DEFAULT_AVATAR;
    // var tmpAvatar = await organizationApi.getAvatar(clientData.user!.id);
    // clientData.userAvatar = (tmpAvatar != null) ? tmpAvatar : DEFAULT_AVATAR;
  }

  void initCurrentUserNameFromNet() {
    organizationApi.getNickname(clientData.user!.id).then((response) {
      if (response.$1 == 200) {
        clientData.user!.nickname = response.$2;
      }
    });
  }
}
