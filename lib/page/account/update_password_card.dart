import 'package:open_chat/component/floating_card.dart';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/network/api_client.dart';
import 'package:open_chat/network/client/user.dart';
import 'package:open_chat/page/hello/choose_page.dart';
import 'package:open_chat/store/client_data.dart';

import '../../main.dart';
import '../../theme/custome_theme.dart';
import '../../utils/client_utils.dart';

class UpdatePasswordCard extends StatefulWidget {
  const UpdatePasswordCard({required this.closeCard, super.key});
  final void Function(bool bl) closeCard;
  @override
  State<UpdatePasswordCard> createState() => _UpdatePasswordCardState();
}

class _UpdatePasswordCardState extends State<UpdatePasswordCard> {
  late TextEditingController _oldPasswordController,
      _newPasswordController,
      _confirmPasswordController;

  @override
  void initState() {
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    GlobalContent.context = context;
    Widget oldPasswordForm = TextBox(
      maxLines: 1,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      placeholder: '旧密码',
      highlightColor: Colors.white.withOpacity(0),
      textAlign: TextAlign.center,
      controller: _oldPasswordController,
      unfocusedColor: Colors.white.withOpacity(0),
    );
    Widget newPasswordForm = TextBox(
      maxLines: 1,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      placeholder: '新密码',
      highlightColor: Colors.white.withOpacity(0),
      textAlign: TextAlign.center,
      controller: _newPasswordController,
      unfocusedColor: Colors.white.withOpacity(0),
    );
    Widget confirmNewPasswordForm = TextBox(
      maxLines: 1,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      placeholder: '确认新密码',
      highlightColor: Colors.white.withOpacity(0),
      textAlign: TextAlign.center,
      controller: _confirmPasswordController,
      unfocusedColor: Colors.white.withOpacity(0),
    );

    return FloatingCard(
        closeCard: widget.closeCard,
        child: Column(
          children: [
            const SizedBox(
              height: 18,
            ),
            Expanded(
              child: oldPasswordForm,
            ),
            const SizedBox(
              height: 18,
            ),
            Expanded(
              child: newPasswordForm,
            ),
            const SizedBox(
              height: 18,
            ),
            Expanded(
              child: confirmNewPasswordForm,
            ),
            const SizedBox(
              height: 18,
            ),
            HyperlinkButton(
                child: const Icon(
                  FluentIcons.completed12,
                  size: 36,
                ),
                onPressed: () => tryUpdatePassword()),
            const SizedBox(
              height: 18,
            ),
          ],
        ));
  }

  void tryUpdatePassword() {
    var oldPassword = _oldPasswordController.text;
    var newPassword = _newPasswordController.text;
    var confirmPassword = _confirmPasswordController.text;
    if (newPassword.length > 18 || newPassword.length < 8) {
      customDisplayInfoBar(
          context, '错误', '密码长度需要大于8小于16', InfoBarSeverity.info);
      return;
    }
    if (confirmPassword != newPassword) {
      customDisplayInfoBar(context, '错误', '新密码和确认的密码不相同', InfoBarSeverity.info);
      return;
    }
    if (md5Encryption(oldPassword) != clientData.user!.password) {
      customDisplayInfoBar(context, '错误', '旧密码错误', InfoBarSeverity.info);
      return;
    }
    oldPassword = md5Encryption(oldPassword);
    newPassword = md5Encryption(newPassword);
    showConfirmChangeDialog(context, oldPassword, newPassword);
  }

  void showConfirmChangeDialog(
      BuildContext context, String oldMd5Pwd, newMd5Pwd) async {
    await showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Center(
          child: Text(
            '确定要更改密码吗？',
            style: primaryTitle,
          ),
        ),
        content: const Text('如果确认要修改密码, 在这之后, 你需要重新登录'),
        actions: [
          Button(
            child: Text(
              '是的, 我要修改密码',
              style: coloredBodyText(Colors.red),
            ),
            onPressed: () {
              Navigator.pop(context, 'Delete');
              userApi.setPassword(oldMd5Pwd, newMd5Pwd);
              customDisplayInfoBar(
                  context, '修改密码', '修改成功', InfoBarSeverity.success);
              apiClient.cleanUser();
              Future.delayed(
                const Duration(milliseconds: 200),
                () {
                  Navigator.pushAndRemoveUntil(
                      context,
                      FluentPageRoute(builder: (context) => const ChoosePage()),
                      (route) => false);
                },
              );
            },
          ),
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
