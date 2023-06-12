import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/models/group.dart';
import 'package:open_chat/network/client/group.dart';
import 'package:open_chat/network/client/organization.dart';
import 'package:open_chat/utils/client_utils.dart';

import '../store/client_data.dart';
import '../theme/custome_theme.dart';
import '../utils/img_utils.dart';

class GroupMemberTile extends StatefulWidget {
  const GroupMemberTile(
      {required this.member, required this.userIdentify, super.key});
  final Member member;
  final int userIdentify;
  @override
  State<GroupMemberTile> createState() => _GroupMemberTileState();
}

class _GroupMemberTileState extends State<GroupMemberTile> {
  int identify = 0;
  String name = 'Loading';
  FileImage? avatar;
  bool isDeleted = false;
  late int memberId = 0;

  @override
  void initState() {
    final memberId = widget.member.id;
    identify = widget.member.identify;
    organizationApi.getAvatar(widget.member.id).then((value) {
      logger.d('[refresh Tile]');
      if (mounted) {
        setState(() {
          avatar = value ?? DEFAULT_AVATAR;
        });
      }
    });
    organizationApi.getNickname(memberId).then((value) {
      if (mounted) {
        setState(() {
          name = value.$1 != 0 ? value.$2 : 'Loading...';
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: !isDeleted,
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: avatar,
          backgroundColor: OCAPCITY_COLOR,
          radius: 20,
        ),
        title: Text(
          name,
          style: bodyText,
        ),
        subtitle: Text(
          getIdentify(identify),
          style: secondaryBodyText,
        ),
        trailing: Expanded(
          child: functionButtons(widget.member.id),
        ),
      ),
    );
  }

  String getIdentify(int identify) {
    switch (identify) {
      case 0:
        return '群成员';
      case 1:
        return '管理员';
      case 2:
        return '所有者';
      default:
        return '群成员';
    }
  }

  Widget functionButtons(int memberId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Visibility(
          visible: identify == 0 && widget.userIdentify == 2,
          child: Tooltip(
            message: '设置为管理员',
            child: RotatedBox(
              quarterTurns: 2,
              child: IconButton(
                icon: Icon(
                  FluentIcons.drill_down,
                  size: 22,
                  color: Colors.green.darker,
                ),
                onPressed: () {
                  groupApi.setAdmin(clientData.currentTargetId, memberId);
                  identify = 1;
                },
              ),
            ),
          ),
        ),
        Visibility(
          visible: identify == 1 && widget.userIdentify == 2,
          child: Tooltip(
            message: '降为普通群成员',
            child: IconButton(
              icon: Icon(
                FluentIcons.drill_down,
                size: 22,
                color: Colors.orange.darker,
              ),
              onPressed: () {
                groupApi.removeAdmin(clientData.currentTargetId, memberId);
                setState(() {
                  identify = 0;
                });
              },
            ),
          ),
        ),
        Visibility(
            visible: widget.userIdentify > identify,
            // visible: false,
            child: Tooltip(
              message: '踢出群聊',
              child: IconButton(
                icon: const Icon(
                  FluentIcons.error_badge12,
                  size: 22,
                  color: Colors.errorPrimaryColor,
                ),
                onPressed: () {
                  showConfirmDeleteDialog(context, memberId);
                },
              ),
            )),
      ],
    );
  }

  void showConfirmDeleteDialog(BuildContext context, int memberId) async {
    await showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Center(
          child: Text(
            '确定要删除吗？',
            style: primaryTitle,
          ),
        ),
        content: const Text('确定要将ta提出群聊吗'),
        actions: [
          Button(
              child: Text(
                '踢！',
                style: coloredBodyText(Colors.red),
              ),
              onPressed: () {
                isDeleted = true;
                groupApi.deleteMember(clientData.currentTargetId, memberId);
                Navigator.pop(context, 'Delete');
                customDisplayInfoBar(
                    context, '删除', '你将ta踢出了群聊', InfoBarSeverity.info);
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
}
