import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/component/group_member_tile.dart';
import 'package:open_chat/network/client/group.dart';
import 'package:open_chat/store/client_data.dart';
import 'package:open_chat/theme/custome_theme.dart';
import 'package:open_chat/utils/client_utils.dart';
import 'package:open_chat/utils/db_utils.dart';
import 'package:open_chat/utils/group_utils.dart';

import '../models/group.dart';
import '../network/client/organization.dart';

class ContactInfo extends StatefulWidget {
  const ContactInfo({
    required this.setHaveChatChosen,
    required this.setGroupInfoEditorVisible,
    super.key,
  });
  final void Function(bool bl) setHaveChatChosen;
  final void Function(bool bl) setGroupInfoEditorVisible;
  @override
  State<ContactInfo> createState() => _ContactInfoState();
}

class _ContactInfoState extends State<ContactInfo> {
  List<Member> memberList = [];
  Timer? refreshMemberTimer;
  int _identify = 0;
  @override
  void initState() {
    strartTimer();
    _identify = getIdentify(clientData.currentTargetId, clientData.user!.id);
    super.initState();
  }

  @override
  void dispose() {
    refreshMemberTimer?.cancel();
    super.dispose();
  }

  void strartTimer() {
    refreshMemberTimer?.cancel();
    if (isGroup(clientData.currentTargetId)) {
      refreshMemberTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (mounted) {
          setState(() {
            memberList = clientData.memberList;
            logger.d('[member list] listSize:${memberList.length}');
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
      child: Container(
        color: Colors.grey[10],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 48,
                child: Text(
                  isGroup(clientData.currentTargetId) ? '群组' : '好友',
                  style: secondaryTitle,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              // 头像与名称
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    foregroundImage: clientData.currentTargetAvatar,
                    backgroundColor: OCAPCITY_COLOR,
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientData.currentTargetName,
                        style: secondaryTitle,
                      ),
                      Text(
                        '#${clientData.currentTargetId}',
                        style: coloredBodyText(
                          Colors.grey[80],
                        ),
                      )
                    ],
                  )
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              const Divider(),

              const SizedBox(
                height: 20,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: memberList.length,
                  itemBuilder: (context, index) {
                    if (isGroup(clientData.currentTargetId)) {
                      return GroupMemberTile(
                          member: memberList[index], userIdentify: _identify);
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              const Divider(),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Visibility(
                    visible: adminVisible(),
                    child: HyperlinkButton(
                      child: const SizedBox(
                        width: 240,
                        height: 36,
                        child: Center(
                          child: Text('管理群聊'),
                        ),
                      ),
                      onPressed: () => {widget.setGroupInfoEditorVisible(true)},
                    ),
                  ),
                  HyperlinkButton(
                    child: SizedBox(
                      width: 240,
                      height: 36,
                      child: Center(
                        child: Text(
                          isGroup(clientData.currentTargetId)
                              ? deleteWord()
                              : '删除好友',
                          style: coloredBodyText(Colors.red),
                        ),
                      ),
                    ),
                    onPressed: () => {
                      showConfirmDeleteDialog(context),
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  /// 确认是否要删除与该用户/该群聊的关系
  void showConfirmDeleteDialog(BuildContext context) async {
    String infoMessage = isGroup(clientData.currentTargetId)
        ? '如果你是这个群的群主,这个群会直接解散！'
        : '他会在你的列表中消失，很久很久（真的很久）';
    await showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Center(
          child: Text(
            '确定要删除吗？',
            style: primaryTitle,
          ),
        ),
        content: Text(infoMessage),
        actions: [
          Button(
              child: Text(
                '删！',
                style: coloredBodyText(Colors.red),
              ),
              onPressed: () {
                if (_identify == 2) {
                  groupApi.dismissGroup(clientData.currentTargetId);
                } else {
                  deleteFriend();
                }
                Navigator.pop(context, 'Delete');
                customDisplayInfoBar(
                    context, '删除', '你删除了ta', InfoBarSeverity.info);
              }),
          FilledButton(
            child: Text(
              '算了',
              style: coloredBodyText(Colors.white),
            ),
            onPressed: () {
              Navigator.pop(context, 'Cancled');
            },
          ),
        ],
      ),
    );
    if (mounted) setState(() {});
  }

  void deleteFriend() async {
    widget.setHaveChatChosen(false);
    var contactId = clientData.currentTargetId;
    clientData.contactIdList.remove(contactId);
    await deleteContact(contactId);
    organizationApi.exitOrganization(clientData.currentTargetId);
  }

  String deleteWord() {
    if (checkIsOwner(clientData.currentTargetId)) {
      return '解散群聊';
    }
    return '退出群聊';
  }

  bool adminVisible() {
    int groupId = clientData.currentTargetId;
    if (isGroup(groupId)) {
      int userId = clientData.user!.id;
      return checkIsAdmin(groupId, userId) || checkIsOwner(groupId);
    } else {
      return false;
    }
  }

  bool ownerVisible() {
    if (isGroup(clientData.currentTargetId)) {
      return checkIsOwner(clientData.user!.id);
    }
    return false;
  }
}
