import 'dart:developer';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/component/floating_card.dart';
import 'package:open_chat/main.dart';
import 'package:open_chat/network/client/friend.dart';
import 'package:open_chat/network/client/group.dart';
import 'package:open_chat/network/client/organization.dart';
import 'package:open_chat/component/application_tile.dart';
import 'package:open_chat/utils/db_utils.dart';
import 'package:open_chat/utils/img_utils.dart';

import '../../utils/client_utils.dart';

class ContactApplicationManager extends StatefulWidget {
  const ContactApplicationManager({required this.closeCard, super.key});
  final void Function(bool) closeCard;
  @override
  State<ContactApplicationManager> createState() =>
      _ContactApplicationManagerState();
}

class _ContactApplicationManagerState extends State<ContactApplicationManager> {
  List<FileImage> avatarList = [];
  List<int> contactList = [];
  List<String> contactNameList = [];
  bool getApplicationAvailable = true;
  List<(int, int)> groupApplicationList = [];
  List<Widget> list = [];
  List<Widget> applicationList = [];

  void updatePersonalList() {
    for (int index = 0; index < contactList.length; index++) {
      list.add(PersonalApplicationTile(
          avatar: avatarList[index],
          name: contactNameList[index].toString(),
          id: contactList[index]));
      if (mounted) {
        setState(() {
          applicationList = list;
        });
      }
    }
  }

  void updateGroupList() async {
    for ((int, int) groupApplication in groupApplicationList) {
      logger.d('[requestList] try insert${groupApplication.toString()}');
      list.add(GroupApplicationTile(
          id: groupApplication.$1, groupId: groupApplication.$2));
      logger.d('[requestList] list length: ${list.length}');
      if (mounted) {
        setState(() {
          applicationList = list;
        });
      }
    }
  }

  @override
  void initState() {
    _getApplication();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    GlobalContent.context = context;
    return FloatingCard(
      closeCard: widget.closeCard,
      child: ListView(
        children: applicationList,
      ),
    );
  }

  void _getPersonalApplication() async {
    await friendApi.getRequestList().then(
      (response) async {
        log('get request list response:${response.toString()}');
        if (response != null) {
          try {
            log('try get list succeed ${contactList.toString()}');
            // 获取id列表
            if (mounted) {
              setState(() {
                contactList = response;
              });
            }
            log('get list succeed ${contactList.toString()}');
            // 向avatar列表中插入图片
            for (var id in contactList) {
              log('尝试将id :${id.toString()}的联系人加入到列表 尝试获取name');
              var name = await tryFindUserNameByIdFromDb(id);
              // log('id $id 的联系人姓名为: $name');
              // log('尝试为 id:$id 的人获取头像');
              var avatar =
                  await organizationApi.getAvatar(id).then((avatar) => avatar);
              if (mounted) {
                setState(() {
                  // log('获取:$id 的头像成功');
                  contactNameList.add(name ?? 'default name');
                  avatarList.add(avatar ?? DEFAULT_AVATAR);
                });
              }
            }
          } catch (e) {
            logger.e('[get avatar error]', [e]);
          }
        } else {
          log('get list failed');
        }
      },
    );
    try {
      log('there is ${contactList.length} applications');
      updatePersonalList();
      if (mounted) setState(() {});
    } catch (e) {
      logger.e('[get application error]', [e]);
    }
  }

  void _getGroupApplication() async {
    await groupApi.getGroupRequest().then(
      (response) async {
        if (response != null) {
          try {
            // 获取id列表
            if (mounted) {
              setState(() {
                groupApplicationList = response;
              });
            }
          } catch (e) {
            logger.e('[get application error]', [e]);
          }
        } else {
          log('[get requestList] get list failed');
        }
      },
    );

    log('[get requestList]there is ${groupApplicationList.length} applications');
    updateGroupList();
    if (mounted) setState(() {});
  }

  void _getApplication() async {
    if (getApplicationAvailable) {
      getApplicationAvailable = false;
      // 获取个人申请信息
      _getPersonalApplication();
      // 获取群聊申请信息
      _getGroupApplication();
      getApplicationAvailable = true;
    }
  }
}
