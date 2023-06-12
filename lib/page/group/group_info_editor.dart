import 'dart:convert';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/network/client/group.dart';
import 'package:open_chat/utils/img_utils.dart';

import '../../component/floating_card.dart';
import '../../main.dart';
import '../../models/organization.dart';
import '../../network/client/organization.dart';
import '../../store/client_data.dart';
import '../../theme/custome_theme.dart';
import '../../utils/client_utils.dart';
import '../../utils/db_utils.dart';

class GroupInfoEditor extends StatefulWidget {
  const GroupInfoEditor({required this.closeCard, super.key});
  final Function(bool bl) closeCard;

  @override
  State<GroupInfoEditor> createState() => _GroupInfoEditorState();
}

class _GroupInfoEditorState extends State<GroupInfoEditor> {
  int groupId = clientData.currentTargetId;
  late TextEditingController _nicknameController;
  FileImage? avatar;
  String groupName = 'Loading...';
  void initListener() {
    _nicknameController = TextEditingController();
    _nicknameController.text = groupName;
  }

  void initComponents() {
    avatar = clientData.loadAvatar(groupId);
  }

  @override
  void initState() {
    initListener();
    initComponents();
    super.initState();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    GlobalContent.context = context;
    return FloatingCard(
      closeCard: widget.closeCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(
            height: 0,
          ),
          _circleAvatarBuilder(),
          _nicknameFormBuilder(),
          const SizedBox(
            height: 5,
          ),
        ],
      ),
    );
  }

  /// 构建头像
  Widget _circleAvatarBuilder() {
    organizationApi.getNickname(groupId).then(
      (value) {
        if (value.$1 == 200) {
          groupName = value.$2;
          _nicknameController.text = value.$2;
        }
      },
    );
    return GestureDetector(
      child: CircleAvatar(
        radius: 60,
        backgroundColor: OCAPCITY_COLOR,
        foregroundImage: avatar,
        child: const Icon(FluentIcons.add),
      ),
      onTap: () {
        getLocalImg().then((imageInfo) async {
          // 如果没返回图片，直接结束
          if (imageInfo.$1 != null) {
            if (mounted) {
              setState(() {
                avatar = imageInfo.$1;
              });
            }
            clientData.fileName = imageInfo.$2;
            clientData.fileExtension =
                imageInfo.$3.replaceFirst(RegExp(r'.'), '');
            var u8Avatar = await fileImgToByte(imageInfo.$1).then((u8Img) {
              saveImageWithU8(
                  u8Img!, 'avatar$groupId.${clientData.fileExtension}');
              return u8Img;
            });
            organizationApi
                .setAvatar(
                    groupId, base64Encode(u8Avatar), clientData.fileExtension!)
                .then((newMd5AvatarName) {
              if (newMd5AvatarName == null) {
                customDisplayInfoBar(
                  context,
                  '错误',
                  '更新失败',
                  InfoBarSeverity.warning,
                );
              } else {
                var ex = clientData.fileExtension;
                var tmpOrganization = Organization(id: groupId)
                  ..avatarPath = './lib/store/avatars/avatar$groupId.$ex'
                  ..ex = ex
                  ..md5AvatarName = newMd5AvatarName
                  ..name = clientData.loadName(groupId);
                insertOrReplaceOrganization([tmpOrganization]);
                customDisplayInfoBar(
                  context,
                  '更新',
                  '更新成功',
                  InfoBarSeverity.success,
                );
              }
            });
          }
        });
      },
    );
  }

  /// 构建用户名输入框
  Widget _nicknameFormBuilder() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: [
          Expanded(
            child: TextBox(
              maxLines: 1,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              placeholder: clientData.loadName(groupId),
              highlightColor: Colors.white.withOpacity(0),
              textAlign: TextAlign.center,
              controller: _nicknameController,
              unfocusedColor: Colors.white.withOpacity(0),
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          FilledButton(
            child: const Text(
              '确定',
            ),
            onPressed: () {
              if (_nicknameController.text.length > 18) {
                customDisplayInfoBar(context, '更新群名称错误', '群名称不能大于18字符哦:/',
                    InfoBarSeverity.error);
              } else if (_nicknameController.text.isEmpty) {
                customDisplayInfoBar(
                    context, '更新群名称错误', '群名称不能为空哦:/', InfoBarSeverity.error);
              } else {
                groupApi
                    .setGroupName(groupId, _nicknameController.text)
                    .then((code) {
                  if (code == 200) {
                    // 返回200 在服务器上更新昵称成功
                    clientData.user!.nickname = _nicknameController.text;
                    updateUserName(groupId, _nicknameController.text);
                    customDisplayInfoBar(
                        context, '更新', '更新群名称成功X>', InfoBarSeverity.success);
                  } else {
                    //  更新昵称失败
                    customDisplayInfoBar(context, '更新', '更新群名称失败X<, code=$code',
                        InfoBarSeverity.error);
                  }
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
