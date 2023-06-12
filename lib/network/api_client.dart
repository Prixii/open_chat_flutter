import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/utils/client_utils.dart';

final ApiClient apiClient = ApiClient();

class ApiClient {
  final httpClient =
      Dio(BaseOptions(connectTimeout: const Duration(seconds: 3)));
  final _versionKey =
      "516^*ydj0DCZZ&EHjAEav^bw7Xt6_9MozZOIqA5RoklyJBU#q1yctzBONH&C1Ybh";
  // TODO: you need our ip here
  final _basePath = "";

  var _userID = 0;
  var _password = "";
  var _deviceID = "";

  void setUser(int userID, String password, String deviceID) {
    _userID = userID;
    _password = password;
    _deviceID = deviceID;
  }

  void cleanUser() {
    _userID = 0;
    _password = "";
    _deviceID = "";
  }

  Future<(int, String)> httpRequest(String path, String data) async {
    final key = _getKey();
    final byteBody = _encrypt(utf8.encode(data), key);
    final userAgent =
        base64.encode(_encrypt(md5.convert(utf8.encode(path)).bytes, key));
    Response<dynamic> response = Response(requestOptions: RequestOptions());
    try {
      response = await httpClient.post(_basePath + path,
          data: Stream.fromIterable(byteBody.map((e) => [e])),
          options: Options(headers: {
            HttpHeaders.userAgentHeader: userAgent,
            HttpHeaders.contentLengthHeader: byteBody.length,
            "id": _userID
          }, responseType: ResponseType.bytes));
    } on DioError catch (e) {
      if (e.response == null) {
        customDisplayInfoBar(null, "发生错误", "网络连接已断开", InfoBarSeverity.error);
        throw (0, "");
      }
      if (e.response!.statusCode == 500) {
        customDisplayInfoBar(null, "发生错误", "服务器错误", InfoBarSeverity.error);
        throw (500, "");
      }
      if (e.response!.statusCode == 502) {
        customDisplayInfoBar(
            null, "发生错误", "安全性检测已失败，请重新启动", InfoBarSeverity.error);
        cleanUser();
        throw (502, "");
      }
      response.statusCode = e.response!.statusCode!;
      response.data = e.response!.data;
      customDisplayInfoBar(null, "发生错误",
          utf8.decode(_encrypt(response.data, key)), InfoBarSeverity.error);
    }
    return (response.statusCode!, utf8.decode(_encrypt(response.data, key)));
  }

  List<int> _encrypt(List<int> data, List<int> key) {
    if (data.isEmpty || key.isEmpty) {
      return data;
    }
    final res = List<int>.empty(growable: true);
    final md5Key = md5.convert(key).bytes;
    for (var i = 0; i < data.length; i++) {
      res.add(data[i] ^ md5Key[i % 16]);
    }
    return res;
  }

  List<int> _getKey() {
    var key = "";
    final time = (DateTime.now().millisecondsSinceEpoch ~/ 100000).toString();
    if (_userID == 0) {
      key = _versionKey + time;
    } else {
      key = _versionKey + _password + _userID.toString() + _deviceID + time;
      // debugPrint('key: $key');
    }
    return utf8.encode(key);
  }
}
