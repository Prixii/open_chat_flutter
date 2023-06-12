import 'dart:async';
import 'dart:developer';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/models/account.dart';
import 'package:open_chat/models/group.dart';
import 'package:open_chat/models/message.dart';
import 'package:open_chat/network/client/organization.dart';
import 'package:open_chat/utils/client_utils.dart';
import 'package:open_chat/utils/db_utils.dart';
import 'package:open_chat/utils/group_utils.dart';
import 'package:open_chat/utils/img_utils.dart';
import 'package:sqlite3/sqlite3.dart';

import '../utils/message_utils_tool.dart';

final ClientData clientData = ClientData();

class ClientData {
  String deviceId = "";
  User? user;
  String? fileName;
  String? fileExtension;
  List<int> contactIdList = [];
  FileImage userAvatar = DEFAULT_AVATAR;
  // 一旦进行对象的切换,就要更新这三个
  String currentTargetName = '';
  int currentTargetId = 0;
  int currentTargetIndex = -1;
  FileImage currentTargetAvatar = DEFAULT_AVATAR;
  bool contactChanged = false;
  bool allowScroolBottom = true;
  // 信息收发使用
  int currentLastMessageId = 0;
  List<Message> currentMessageCache = [];
  // 当前消息列表
  List<String> currentMessageList = [];

  /// 用于暂存 last_message_id
  /// $1 contactId，$2 new_last_message_id
  Map<int, int> lastMessageId = {};

  Map<int, int> notReadMessageCount = {};

  // 消息列表
  List<Message> messageList = [];
  Timer? messageUpdateTimer;
  // 定时刷新消息
  bool messageLock = false;

  Map<int, FileImage> avatarMap = {};
  Map<int, String> nameMap = {};
  // 群成员列表
  Timer? groupMemberUpdateTimer;
  List<Member> memberList = [];
  Map<int, int> earliestMessageId = {};

  /// 初始化使用，从数据库中获取对应的消息记录，这个操作不会产生数据更新
  Future<void> initMessageList() async {
    clientData.messageList =
        await getAllMessageForCurrentChat(clientData.currentTargetId);
  }

  void startMessageTimer() async {
    messageUpdateTimer?.cancel();
    await initMessageList();

    messageUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!messageLock) {
        getNewMessageFromDb();
      }
    });
  }

  /// 启动刷新群组成员的计时器
  void startGroupMemberTimer() {
    groupMemberUpdateTimer?.cancel();

    groupMemberUpdateTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) {
      if (isGroup(currentTargetId)) {
        int groupId = currentTargetId;
        refreshGroupMember(groupId);
        loadMemberListFromDb(groupId);
      }
    });
  }

  /// 每秒从数据库获取一次最新消息
  Future<void> getNewMessageFromDb() async {
    messageLock = true;
    int lastMsgId = 0;
    for (int i = messageList.length - 1; i > 0; i--) {
      if (messageList[i].messageSender != user!.id) {
        lastMsgId = messageList[i].messageId;
        break;
      }
    }
    List<Message> newMessageList =
        await getNewMessageForCurrentChat(currentTargetId, lastMsgId);
    if (newMessageList.isNotEmpty) {
      if (newMessageList.length >= 2 &&
          newMessageList[0].messageId == newMessageList[1].messageId) {
        newMessageList.removeAt(0);
      }
      if (messageList.isNotEmpty &&
          newMessageList[0].messageId == messageList[0].messageId) {
        newMessageList.removeAt(0);
      }
      if (newMessageList.isNotEmpty) {
        clientData.messageList.addAll(newMessageList);
      }
    }
    messageLock = false;
  }

  // ********************
  void setCurrentTarget(
      int id, FileImage? avatar, String? name, int index) async {
    currentTargetId = id;
    if (avatar == null) {
      currentTargetAvatar =
          await organizationApi.getAvatar(id) ?? DEFAULT_AVATAR;
    } else {
      currentTargetAvatar = avatar;
    }
    if (name == null) {
      currentTargetName =
          await tryFindUserNameByIdFromDb(id) ?? 'Genshin Impact';
    } else {
      currentTargetName = name;
    }
    currentTargetIndex = index;
  }

  void initUser(int id, String phoneNumber, String md5Password) {
    user = User(
      id: id,
      phoneNumber: phoneNumber,
      password: md5Password,
    );
  }

  void showCurrentUserInfo() {
    log(mapToJsonString({
      'deviceId': deviceId,
      'user': user != null ? user.toString() : '',
      'fileName': fileName ?? '',
      'fileExtension': fileExtension ?? '',
    }));
  }

  Future<int> updateContactList() async {
    return organizationApi.getContactList().then((response) async {
      if (response.$1 == 200) {
        // 状态码为200
        contactIdList = await getContacts();
        log('get contactIdList from loaclDB: ${contactIdList.toString()}');
        return 200;
      } else {
        return 0;
      }
    }).onError((error, stackTrace) => 0);
  }

  /// 设置最新未读消息id缓存
  void setLatestMessageIdTemp(int contactId, int newMessageId) {
    lastMessageId[contactId] = newMessageId;
    // 如果和数据库相同，直接更新到数据库中
    if (currentTargetId == contactId) {
      clientData.updateMessageIdTodb(clientData.currentTargetId);
    }
    // logger.d('[updateMessageId] $contactId: $newMessageId');
  }

  /// 设置最新未读消息数量
  void setNewMessageCount(int contactId, int newMessageCount) {
    if (contactId != currentTargetId) {
      notReadMessageCount[contactId] = newMessageCount;
    } else {
      notReadMessageCount[contactId] = 0;
    }
    // logger.d('[updateMessageId] $contactId: $newMessageCount');
  }

  void updateMessageIdTodb(int contactId) {
    int userId = clientData.user!.id;
    final db = sqlite3.open('./lib/store/db/$userId.db');
    db.execute(
        'UPDATE contact SET last_message_id=${lastMessageId[contactId]} WHERE contact_id=$contactId');
    // logger.d('[updateMessageId] $contactId 的最新消息Id持久化成功');
    db.dispose();
  }

  /// 从本地加载头像，如果不成功，则先返回默认头像，再请求
  FileImage loadAvatar(int id) {
    FileImage? avatar = avatarMap[id];
    if (avatar == null) {
      organizationApi.getAvatar(id);
      return DEFAULT_AVATAR;
    } else {
      return avatar;
    }
  }

  void addAvatar(int id, FileImage avatar) {
    avatarMap[id] = avatar;
  }

  String loadName(int id) {
    if (id == user!.id) return user!.nickname;
    String? name = nameMap[id];
    if (name == null) {
      tryGetName(id);
      return 'Loading';
    }
    return name;
  }

  void addName(int id, String name) {
    try {
      nameMap[id] = name;
    } catch (e) {
      logger.e('[add name error]', [e]);
    }
  }

  void tryGetName(int id) async {
    tryFindUserNameByIdFromDb(id);
  }

  /// 获取最旧的信息id
  void getEarliestMsgId() async {
    int contactId = currentTargetId;
    if (messageList.isEmpty) {
      earliestMessageId[contactId] =
          await getLastMessageIdByContactId(contactId);
    } else {
      for (int i = 0; i < messageList.length; i++) {
        if (messageList[i].messageId < 0) {
          continue;
        } else {
          earliestMessageId[contactId] = messageList[i].messageId;
          break;
        }
      }
    }
  }

  void setEarliestMsgId(int contactId, int earliestMgsId) {
    earliestMessageId[contactId] = earliestMgsId;
  }
}
