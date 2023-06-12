import 'dart:developer';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:open_chat/utils/client_utils.dart';

@JsonSerializable()
class Account {}

@JsonSerializable()
class User {
  int id;
  String nickname = "";
  Uint8List? u8Avatar; // 将头像储存为img
  String phoneNumber;
  String password;

  User({
    required this.id,
    required this.phoneNumber,
    required this.password,
  });

  @override
  String toString() {
    log('id: $id');
    log('nickname: $nickname');
    log('u8Avatar: $u8Avatar');
    log('phoneNumber: $phoneNumber');
    log('password: $password');

    return mapToJsonString({
      'id': id,
      'nickname': nickname,
      'u8Avatar': u8Avatar,
      'phoneNumber': phoneNumber,
      'password': password
    });
  }
}
