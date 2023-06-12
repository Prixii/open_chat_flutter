import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/network/client/friend.dart';
import 'package:open_chat/network/client/group.dart';
import 'package:open_chat/network/client/organization.dart';
import 'package:open_chat/utils/client_utils.dart';
import 'package:open_chat/utils/img_utils.dart';
import 'package:sqlite3/sqlite3.dart' as sq;

import '../store/client_data.dart';
import '../theme/custome_theme.dart';

class PersonalApplicationTile extends StatefulWidget {
  const PersonalApplicationTile(
      {required this.avatar, required this.name, required this.id, super.key});
  final FileImage avatar;
  final String name;
  final int id;
  @override
  State<PersonalApplicationTile> createState() =>
      _PersonalApplicationTileState();
}

class _PersonalApplicationTileState extends State<PersonalApplicationTile> {
  bool visible = true;
  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      child: ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              foregroundImage: widget.avatar,
              backgroundColor: OCAPCITY_COLOR,
              radius: 24,
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.name,
                      style: bodyText,
                    ),
                    Text(
                      '申请加你为好友',
                      style: coloredBodyText(Colors.grey[120]),
                    ),
                  ],
                ),
                Text(
                  '#${widget.id.toString()}',
                  style: coloredBodyText(Colors.grey[100]),
                ),
              ],
            )),
            Center(
              child: IconButton(
                icon: const Icon(
                  FluentIcons.completed12,
                  size: 32,
                  color: Color.fromARGB(255, 0, 102, 180),
                  weight: 200,
                ),
                onPressed: () {
                  agreeApplication();
                  if (mounted) {
                    setState(() {
                      visible = false;
                    });
                  }
                },
              ),
            ),
            Center(
              child: IconButton(
                icon: Icon(
                  FluentIcons.error_badge12,
                  size: 32,
                  color: Colors.red.dark,
                  weight: 200,
                ),
                onPressed: () {
                  showConfirmRefuseDialog(context);
                },
              ),
            ),
            const SizedBox(
              width: 10,
            ),
          ],
        ),
      ),
    );
  }

// 接受之后直接变成好友
  void agreeApplication() {
    friendApi.agree(widget.id);
    customDisplayInfoBar(context, '添加好友', '已经同意该请求', InfoBarSeverity.success);
    final db = sq.sqlite3.open('./lib/store/db/${clientData.user!.id}.db');
    db.execute(
        'UPDATE contact SET contact_status=0 WHERE contact_id=${widget.id}');
    db.dispose();
  }

  void showConfirmRefuseDialog(BuildContext context) async {
    await showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Center(
          child: Text(
            '确定要拒绝吗？',
            style: primaryTitle,
          ),
        ),
        content: const Text('这个操作无法撤销!'),
        actions: [
          Button(
              child: Text(
                '确定',
                style: coloredBodyText(Colors.red),
              ),
              onPressed: () {
                friendApi.disagree(widget.id);
                if (mounted) {
                  setState(() {
                    visible = false;
                  });
                }
                Navigator.pop(context, 'Delete');
                customDisplayInfoBar(
                    context, '添加好友', '已经拒绝该请求', InfoBarSeverity.info);
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

class GroupApplicationTile extends StatefulWidget {
  const GroupApplicationTile(
      {required this.id, required this.groupId, super.key});

  final int id;
  final int groupId;
  @override
  State<GroupApplicationTile> createState() => _GroupApplicationTileState();
}

class _GroupApplicationTileState extends State<GroupApplicationTile> {
  bool visible = true;

  FileImage? avatar;
  String name = 'Loading...';
  String groupName = 'Loading...';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    organizationApi.getAvatar(widget.id).then((value) {
      if (mounted) {
        setState(() {
          avatar = value ?? DEFAULT_AVATAR;
        });
      }
    });
    organizationApi.getNickname(widget.id).then((value) {
      if (mounted) {
        setState(() {
          name = value.$1 != 0 ? value.$2 : 'Loading...';
        });
      }
    });
    organizationApi.getNickname(widget.groupId).then((value) {
      if (mounted) {
        setState(() {
          groupName = value.$1 != 0 ? value.$2 : 'Loading...';
        });
      }
    });
    return Visibility(
      visible: visible,
      child: ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              foregroundImage: avatar,
              backgroundColor: OCAPCITY_COLOR,
              radius: 24,
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 76),
                      child: Text(
                        name,
                        style: bodyText,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      ' 申请加入群聊 ',
                      style: coloredBodyText(Colors.grey[120]),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 76),
                      child: Text(
                        groupName,
                        style: bodyText,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  '#${widget.id.toString()}',
                  style: coloredBodyText(Colors.grey[100]),
                ),
              ],
            )),
            Center(
              child: IconButton(
                icon: const Icon(
                  FluentIcons.completed12,
                  size: 32,
                  color: Color.fromARGB(255, 0, 102, 180),
                  weight: 200,
                ),
                onPressed: () {
                  agreeApplication();
                  if (mounted) {
                    setState(() {
                      visible = false;
                    });
                  }
                },
              ),
            ),
            Center(
              child: IconButton(
                icon: Icon(
                  FluentIcons.error_badge12,
                  size: 32,
                  color: Colors.red.dark,
                  weight: 200,
                ),
                onPressed: () {
                  showConfirmRefuseDialog(context);
                },
              ),
            ),
            const SizedBox(
              width: 10,
            ),
          ],
        ),
      ),
    );
  }

// 接受之后直接变成好友
  void agreeApplication() {
    groupApi.agreeGroupRequest(widget.groupId, widget.id);
    customDisplayInfoBar(context, '添加群成员', '已经同意该请求', InfoBarSeverity.success);
    final db = sq.sqlite3.open('./lib/store/db/${clientData.user!.id}.db');
    db.execute(
        'UPDATE contact SET contact_status=0 WHERE contact_id=${widget.id}');
    db.dispose();
  }

  void showConfirmRefuseDialog(BuildContext context) async {
    await showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Center(
          child: Text(
            '确定要拒绝吗？',
            style: primaryTitle,
          ),
        ),
        content: const Text('这个操作无法撤销!'),
        actions: [
          Button(
              child: Text(
                '确定',
                style: coloredBodyText(Colors.red),
              ),
              onPressed: () {
                groupApi.disagreeGroupRequest(widget.groupId, widget.id);
                if (mounted) {
                  setState(() {
                    visible = false;
                  });
                }
                Navigator.pop(context, 'Delete');
                customDisplayInfoBar(
                    context, '添加群成员', '已经拒绝该请求', InfoBarSeverity.info);
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
