import 'dart:convert';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/component/floating_card.dart';
import 'package:open_chat/models/organization.dart';
import 'package:open_chat/network/client/organization.dart';
import 'package:open_chat/network/client/user.dart';
import 'package:open_chat/page/account/contact_application_manager.dart';
import 'package:open_chat/page/account/update_password_card.dart';
import 'package:open_chat/store/client_data.dart';
import 'package:open_chat/theme/custome_theme.dart';
import 'package:open_chat/utils/client_utils.dart';
import 'package:open_chat/utils/db_utils.dart';
import 'package:open_chat/utils/img_utils.dart';

import '../../main.dart';
import '../../network/api_client.dart';
import '../hello/choose_page.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({required this.closeCard, super.key});
  final Function(bool bl) closeCard;

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  late TextEditingController _nicknameController;
  FileImage? avatar;
  bool _contactApplicationVisible = false;
  bool _updatePasswordVisible = false;

  void initListener() {
    _nicknameController = TextEditingController();
    _nicknameController.text = clientData.user!.nickname;
  }

  void initComponents() {
    avatar = clientData.userAvatar;
  }

  void setContactApplicationVisible(bool isVisible) {
    if (mounted) {
      setState(() {
        _contactApplicationVisible = isVisible;
      });
    }
  }

  void setUpdatePasswordVisible(bool isVisible) {
    if (mounted) {
      setState(() {
        _updatePasswordVisible = isVisible;
      });
    }
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
    return Stack(
      children: [
        _infoEditorBuilder(),
        // 联系人或群组申请管理
        Visibility(
          visible: _contactApplicationVisible,
          child: ContactApplicationManager(
            closeCard: setContactApplicationVisible,
          ),
        ),
        Visibility(
          visible: _updatePasswordVisible,
          child: UpdatePasswordCard(closeCard: setUpdatePasswordVisible),
        ),
      ],
    );
  }

  Widget _infoEditorBuilder() {
    return FloatingCard(
      closeCard: widget.closeCard,
      follow: _functionButtonListBuilder(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(
            height: 0,
          ),
          _circleAvatarBuilder(),
          Text(
            '#${clientData.user!.id}',
            style: coloredBodyText(Colors.grey[100]),
          ),
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
                clientData.userAvatar = imageInfo.$1!;
              });
            }
            clientData.fileName = imageInfo.$2;
            clientData.fileExtension =
                imageInfo.$3.replaceFirst(RegExp(r'.'), '');
            clientData.user!.u8Avatar =
                await fileImgToByte(imageInfo.$1).then((u8Img) {
              saveImageWithU8(u8Img!,
                  'avatar${clientData.user!.id}.${clientData.fileExtension}');
              return u8Img;
            });
            organizationApi
                .setAvatar(
                    clientData.user!.id,
                    base64Encode(clientData.user!.u8Avatar!),
                    clientData.fileExtension!)
                .then((newMd5AvatarName) {
              if (newMd5AvatarName == null) {
                customDisplayInfoBar(
                  context,
                  '错误',
                  '更新失败',
                  InfoBarSeverity.warning,
                );
              } else {
                var id = clientData.user!.id;
                var ex = clientData.fileExtension;
                var tmpOrganization = Organization(id: id)
                  ..avatarPath = './lib/store/avatars/avatar$id.$ex'
                  ..ex = ex
                  ..md5AvatarName = newMd5AvatarName
                  ..name = clientData.user!.nickname;
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
              placeholder:
                  (clientData.user != null) ? clientData.user!.nickname : '昵称',
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
                customDisplayInfoBar(
                    context, '更新名称错误', '昵称不能大于18字符哦:/', InfoBarSeverity.error);
              } else if (_nicknameController.text.isEmpty) {
                customDisplayInfoBar(
                    context, '更新名称错误', '昵称不能为空哦:/', InfoBarSeverity.error);
              } else {
                userApi.setName(_nicknameController.text).then((code) {
                  if (code == 200) {
                    // 返回200 在服务器上更新昵称成功
                    clientData.user!.nickname = _nicknameController.text;
                    updateUserName(
                        clientData.user!.id, _nicknameController.text);
                    customDisplayInfoBar(
                        context, '更新', '更新昵称成功X>', InfoBarSeverity.success);
                  } else {
                    //  更新昵称失败
                    customDisplayInfoBar(context, '更新', '更新昵称失败X<, code=$code',
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

  /// 构建功能按键表单
  Widget _functionButtonListBuilder() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Card(
            child: Tooltip(
              message: '联系人或群组申请管理',
              child: IconButton(
                icon: const Icon(
                  FluentIcons.apps_content,
                  size: 24,
                ),
                onPressed: () {
                  setContactApplicationVisible(true);
                },
              ),
            ),
          ),
        ),
        Expanded(child: Container()),
        Expanded(
          flex: 2,
          child: Card(
            child: Tooltip(
              message: '密码修改',
              child: IconButton(
                icon: const Icon(
                  FluentIcons.lock,
                  size: 24,
                ),
                onPressed: () {
                  setUpdatePasswordVisible(true);
                },
              ),
            ),
          ),
        ),
        Expanded(child: Container()),
        Expanded(
          flex: 2,
          child: Card(
            child: Tooltip(
              message: '登出',
              child: IconButton(
                icon: Icon(
                  FluentIcons.sign_out,
                  size: 24,
                  color: Colors.red,
                  weight: 500,
                ),
                onPressed: () {
                  apiClient.cleanUser();
                  Future.delayed(
                    const Duration(milliseconds: 200),
                    () {
                      Navigator.pushAndRemoveUntil(
                          context,
                          FluentPageRoute(
                              builder: (context) => const ChoosePage()),
                          (route) => false);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
