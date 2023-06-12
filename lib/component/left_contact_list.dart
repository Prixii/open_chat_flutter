import 'dart:async';
import 'dart:developer';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/store/client_data.dart';
import 'package:open_chat/theme/custome_theme.dart';
import 'package:open_chat/utils/client_utils.dart';
import 'package:open_chat/utils/group_utils.dart';
import 'package:open_chat/utils/message_utils.dart';

import '../network/client/organization.dart';
import '../utils/db_utils.dart';
import '../utils/img_utils.dart';

class LeftContactList extends StatefulWidget {
  const LeftContactList(
      {required this.setUserInfoEditorVisible,
      required this.setAddContactVisible,
      required this.setHaveChatChosen,
      required this.setUserInfoVisible,
      super.key});
  final void Function(bool bl) setUserInfoEditorVisible;
  final void Function(bool bl) setAddContactVisible;
  final void Function(bool bl) setUserInfoVisible;
  final void Function(bool bl) setHaveChatChosen;

  @override
  State<LeftContactList> createState() => _LeftContactListState();
}

class _LeftContactListState extends State<LeftContactList> {
  // 联系人列表四要素
  List<FileImage> avatarList = [];
  List<int> contactList = [];
  List<String> contactNameList = [];
  List<ListTile> contactTile = [];

  // 函数触发计时器
  Timer? fetchContactTimer, fetchMessageTimer;

  @override
  void initState() {
    startTimer();
    super.initState();
  }

  void startTimer() async {
    await updateContactListData().then((value) {
      initMessage();
      return value;
    });

    fetchContactTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      updateContactListData();
    });
    fetchMessageTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchMessage();
    });
  }

  @override
  void dispose() {
    fetchContactTimer?.cancel();
    fetchMessageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
        child: Column(
          children: [
            SizedBox(
              height: 60,
              child: _searchDialogBuilder(),
            ),
            Expanded(child: ListView(children: contactTile)),
          ],
        ),
      ),
    );
  }

// **************** 好友搜索栏 ******************
  Widget _searchDialogBuilder() {
    return Row(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
        child: IconButton(
          icon: const Icon(
            FluentIcons.account_management,
            size: 20,
          ),
          onPressed: () {
            debugPrint('user Info');
            widget.setUserInfoEditorVisible(true);
          },
        ),
      ),
      // SizedBox(
      //   width: 190,
      //   child: AutoSuggestBox<Cat>(
      //     decoration: BoxDecoration(color: Colors.grey[10]),
      //     items: objectCats
      //         .map<AutoSuggestBoxItem<Cat>>(
      //           (cat) => AutoSuggestBoxItem<Cat>(

      //             value: cat,
      //             label: cat.name,
      //             onFocusChange: (focused) {
      //               if (focused) {
      //                 debugPrint('Focused #${cat.id} - ${cat.name}');
      //               }
      //             },
      //           ),
      //         )
      //         .toList(),
      //     onSelected: (item) {
      //       if (mounted) setState(() => selectedObjectCat = item.value);
      //     },
      //     highlightColor: Colors.white.withOpacity(0),
      //     style: bodyText,
      //     unfocusedColor: Colors.white.withOpacity(0),
      //   ),
      // ),
      SizedBox(
        width: 190,
        child: AutoSuggestBox<String>(
          decoration: BoxDecoration(color: Colors.grey[10]),
          items: contactNameList
              .map<AutoSuggestBoxItem<String>>(
                (name) => AutoSuggestBoxItem<String>(
                  value: name,
                  label: name,
                  onFocusChange: (focused) {
                    if (focused) {}
                  },
                ),
              )
              .toList(),
          onSelected: (item) {
            int index = contactNameList.indexOf(item.label);
            try {
              if (contactList[index] != clientData.currentTargetId) {
                clientData.messageList = [];
                clientData.memberList = [];
                clientData.currentMessageList = [];
                setState(() {});
                while (true) {
                  clientData.setCurrentTarget(contactList[index],
                      avatarList[index], contactNameList[index], index);

                  // 如果对象是群组，需要额外做的事情
                  if (isGroup(clientData.currentTargetId)) {
                    processForGroup();
                  }
                  getAllMessageForCurrentChat(contactList[index]);
                  widget.setUserInfoVisible(false);
                  widget.setHaveChatChosen(true);
                  clientData.setNewMessageCount(clientData.currentTargetId, 0);
                  clientData.startMessageTimer();
                  clientData.allowScroolBottom = true;
                  clientData.getEarliestMsgId();
                  if (mounted) setState(() {});
                  break;
                }
              }
            } catch (e) {
              logger.e('[choose chat error]', [e, null]);
            }
          },
          highlightColor: Colors.white.withOpacity(0),
          style: bodyText,
          unfocusedColor: Colors.white.withOpacity(0),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
        child: IconButton(
          icon: const Icon(
            FluentIcons.add_link,
            size: 20,
          ),
          onPressed: () {
            debugPrint('search list');
            widget.setAddContactVisible(true);
          },
        ),
      ),
    ]);
  }

  /// 更新联系人的数据
  /// 这个操作会请求数据库和服务器
  Future<void> updateContactListData() async {
    // 获取联系人
    contactList = await getContacts().then((value) => value);
    contactNameList = [];
    avatarList = [];
    try {
      for (var id in contactList) {
        // log('尝试为 id:$id 获取头像');
        FileImage? avatar = await organizationApi.getAvatar(id);
        // log('尝试为 id: $id 获取姓名');
        var name = await tryFindUserNameByIdFromDb(id);
        if (name == null) {
          log('获取名称失败');
        }
        if (mounted) {
          setState(
            () {
              // log('为 id:$id 获取头像成功');
              contactNameList.add(name ?? 'genshin impact');
              avatarList.add(avatar ?? DEFAULT_AVATAR);
            },
          );
        }
      }
    } catch (e) {
      logger.e('[update contactList error]');
    }
    _contactListBuilder();
  }

// **************** 好友列表 ********************
  void _contactListBuilder() {
    List<ListTile> tmpList = [];
    for (int index = 0; index < contactNameList.length; index++) {
      int tmpId = contactList[index];
      tmpList.add(
        ListTile(
          leading: CircleAvatar(
            backgroundImage: avatarList[index],
            backgroundColor: OCAPCITY_COLOR,
            radius: 24,
          ),
          title: Text(
            contactNameList[index],
            style: bodyText,
          ),
          subtitle: Text(
            '',
            style: secondaryBodyText,
          ),
          trailing: Visibility(
            visible: clientData.notReadMessageCount[tmpId] != null &&
                clientData.notReadMessageCount[tmpId] != 0 &&
                clientData.currentTargetId != tmpId,
            child: Center(
              child: CircleAvatar(
                backgroundColor: Colors.red,
                radius: 11,
                child: Text(
                  clientData.notReadMessageCount[tmpId] != null
                      ? (clientData.notReadMessageCount[tmpId]! > 99
                          ? '99+'
                          : clientData.notReadMessageCount[tmpId].toString())
                      : '',
                  style: const TextStyle(
                    fontFamily: 'OPenChatFonts',
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          onPressed: () {
            // debugPrint(contactList[index].toString());
            try {
              if (contactList[index] != clientData.currentTargetId) {
                clientData.messageList = [];
                clientData.memberList = [];
                clientData.currentMessageList = [];
                setState(() {});
                while (true) {
                  clientData.setCurrentTarget(contactList[index],
                      avatarList[index], contactNameList[index], index);

                  // 如果对象是群组，需要额外做的事情
                  if (isGroup(clientData.currentTargetId)) {
                    processForGroup();
                  }
                  getAllMessageForCurrentChat(contactList[index]);
                  widget.setUserInfoVisible(false);
                  widget.setHaveChatChosen(true);
                  clientData.setNewMessageCount(clientData.currentTargetId, 0);
                  clientData.startMessageTimer();
                  clientData.allowScroolBottom = true;
                  clientData.getEarliestMsgId();
                  if (mounted) setState(() {});
                  break;
                }
              }
            } catch (e) {
              logger.e('[choose chat error]', [e, null]);
            }
          },
        ),
      );
      // log('新增了一个联系人');
    }
    // log('联系人新增完成,目前共:${tmpList.length.toString()}个联系人');
    if (mounted) {
      setState(() {
        contactTile = tmpList;
        tmpList = [];
      });
    }
  }

  /// 对于群组，需要额外完成的
  ///
  /// 1、初始化群组信息
  ///
  /// 2、启动每3s刷新群组成员
  void processForGroup() {
    refreshGroupMember(clientData.currentTargetId);
    clientData.startGroupMemberTimer();
  }
}
