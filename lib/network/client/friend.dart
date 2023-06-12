import 'dart:convert';
import 'dart:developer';

import 'package:open_chat/network/api_client.dart';
import 'package:open_chat/utils/client_utils.dart';

final FriendApi friendApi = FriendApi();

class FriendApi {
  void agree(int id) {
    var data = mapToJsonString({
      'id': id,
    });
    apiClient
        .httpRequest('/friend/agree', data)
        .then((value) => responsePrinter('agree', value))
        .onError((error, stackTrace) => log('friendAgree Error'));
  }

  void disagree(int id) {
    var data = mapToJsonString({
      'id': id,
    });
    apiClient
        .httpRequest('/friend/agree', data)
        .then((value) => responsePrinter('disagree', value))
        .onError((error, stackTrace) => log('disagree Error'));
  }

  Future<List<int>?> getRequestList() async {
    var data = mapToJsonString({});
    return await apiClient.httpRequest('/friend/request', data).then(
      (response) {
        var json = jsonDecode(response.$2);
        if (response.$1 == 200) {
          responsePrinter('get requestList', response);
          List<int> tmpList = [];
          for (var e in json['data']['id']) {
            tmpList.add(e);
          }

          return (tmpList);
        } else {
          return (null);
        }
      },
    ).onError((error, stackTrace) {
      return (null);
    });
  }
}
