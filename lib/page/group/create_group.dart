import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/network/client/group.dart';
import 'package:open_chat/network/client/organization.dart';

import '../../component/floating_card.dart';
import '../../main.dart';
import '../../models/organization.dart';
import '../../store/client_data.dart';
import '../../utils/client_utils.dart';
import '../../utils/db_utils.dart';
import '../../utils/img_utils.dart';

class CreateGroupCard extends StatefulWidget {
  const CreateGroupCard({required this.closeCard, super.key});
  final Function(bool bl) closeCard;

  @override
  State<CreateGroupCard> createState() => _CreateGroupCardState();
}

class _CreateGroupCardState extends State<CreateGroupCard> {
  late TextEditingController _groupNameController;
  FileImage? avatar;
  @override
  void initState() {
    _groupNameController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    GlobalContent.context = context;
    return FloatingCard(
      closeCard: widget.closeCard,
      follow: _createButtonBuilder(),
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

  Widget _circleAvatarBuilder() {
    return GestureDetector(
      child: CircleAvatar(
        radius: 60,
        backgroundColor: Colors.black.withOpacity(0.2),
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
          }
        });
      },
    );
  }

  /// 构建用户名输入框
  Widget _nicknameFormBuilder() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: TextBox(
          maxLines: 1,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          placeholder: '群名称',
          highlightColor: Colors.white.withOpacity(0),
          textAlign: TextAlign.center,
          controller: _groupNameController,
          unfocusedColor: Colors.white.withOpacity(0),
        ),
      ),
    );
  }

  Widget _createButtonBuilder() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Container(),
        ),
        Expanded(child: Container()),
        Expanded(
          flex: 2,
          child: Card(
            child: Tooltip(
              message: '创建群组: ${_groupNameController.text}',
              child: IconButton(
                icon: const Icon(
                  FluentIcons.forward,
                  size: 24,
                ),
                onPressed: () => createGroup(),
              ),
            ),
          ),
        ),
        Expanded(child: Container()),
        Expanded(
          flex: 2,
          child: Container(),
        ),
      ],
    );
  }

  void createGroup() {
    if (_groupNameController.text.length > 18) {
      customDisplayInfoBar(
          context, '你有点太极端了😨', '群名称不能大于18字符哦:/', InfoBarSeverity.error);
    } else if (_groupNameController.text.isEmpty) {
      customDisplayInfoBar(
          context, '非法的群名称', '群名称不能为空哦:/', InfoBarSeverity.error);
    } else {
      groupApi.create(_groupNameController.text).then((response) async {
        int groupId = response.$2;
        if (response.$1 == 200) {
          // 返回200 群聊创建成功
          // 更新头像
          logger.d('[create group] 群聊创建成功,id:$groupId');
          String base64Avatar = await fileImgToBase64String(avatar);
          organizationApi
              .setAvatar(
                  response.$2, base64Avatar, clientData.fileExtension ?? '')
              .then((newMd5AvatarName) {
            // 如果返回值不等于空，则更改成功
            if (newMd5AvatarName == null) {
              customDisplayInfoBar(
                context,
                '错误',
                '头像设置失败',
                InfoBarSeverity.warning,
              );
            } else {
              var ex = clientData.fileExtension;
              var tmpOrganization = Organization(id: groupId)
                ..avatarPath = './lib/store/avatars/avatar$groupId.$ex'
                ..ex = ex
                ..md5AvatarName = newMd5AvatarName
                ..name = _groupNameController.text;
              insertOrReplaceOrganization([tmpOrganization]);
              widget.closeCard(false);
              customDisplayInfoBar(
                  context, '创建群聊', '创建群聊成功🎉', InfoBarSeverity.success);
            }
          });
        } else {
          //  群聊创建失败
          customDisplayInfoBar(
              context, '创建群聊', '创建群聊失败, code=$response', InfoBarSeverity.error);
        }
      });
    }
  }
}
