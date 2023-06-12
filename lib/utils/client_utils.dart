import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:open_chat/main.dart';
import 'package:open_chat/store/client_data.dart';
import 'package:platform_device_id/platform_device_id.dart';

var logger = Logger(
  printer: PrettyPrinter(),
);

var loggerNoStack = Logger(
  printer: PrettyPrinter(methodCount: 0),
);

// 获取设备的 deviceID
void getDeviceID() async {
  String? deviceId;
  try {
    deviceId = await PlatformDeviceId.getDeviceId;
    deviceId = deviceId!.trim();
    debugPrint('getDeviceId: $deviceId');
  } on PlatformException {
    deviceId = 'Failed To get Device Id';
  }
  clientData.deviceId = deviceId;
  return;
}

// 将Map转换为Json，并转为字符串
String mapToJsonString(Map m) {
  return jsonEncode(m).toString();
}

// 将字符串转换为map
Map<String, dynamic> stringToMap(String str) {
  var json = jsonDecode(str);
  return Map<String, dynamic>.from(json);
}

// 进行md5加密
String md5Encryption(String plainText) {
  var content = const Utf8Encoder().convert(plainText);
  var digest = md5.convert(content);
  return digest.toString();
}

void responsePrinter(String apiName, (int, String) response) {
  logger.i('$apiName:响应结果: ' '${response.$1.toString()}' '${response.$2}');
}

void createFileIfNotExist(String filePath) {
  File file = File(filePath);
  if (file.existsSync()) {
    debugPrint('file$filePath exists');
  } else {
    debugPrint('create $filePath');
    file.createSync(recursive: true);
  }
}

void customDisplayInfoBar(BuildContext? context, String title, String content,
    InfoBarSeverity severity) {
      if (GlobalContent.context != null) {
        context = GlobalContent.context!;
      }
      if (context == null) {
        return;
      }
  displayInfoBar(
    context,
    builder: ((context, close) {
      return InfoBar(
        title: Text(title),
        content: Text(content),
        action: IconButton(
          icon: const Icon(FluentIcons.clear),
          onPressed: close,
        ),
        severity: severity,
      );
    }),
  );
}

/// 如果id是群组id，返回true
bool isGroup(int id) {
  // logger.d('[group] id/100000000=${id / 100000000}');
  return (id ~/ 100000000 == 6);
}
