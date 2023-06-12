import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:open_chat/network/client/organization.dart';
import 'package:open_chat/network/client/user.dart';
import 'package:open_chat/page/hello/choose_page.dart';
import 'package:open_chat/page/main/main_page.dart';
import 'package:open_chat/store/client_data.dart';
import 'package:open_chat/theme/custome_theme.dart';
import 'package:open_chat/utils/client_utils.dart';
import 'package:open_chat/utils/db_utils.dart';
import 'package:open_chat/utils/img_utils.dart';

import '../../main.dart';
import '../../models/account.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController _phoneNumberController, _passwordController;

  void initController() {
    _phoneNumberController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void initState() {
    initController();
    super.initState();
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    GlobalContent.context = context;
    var loginCard = Container(
      decoration: BoxDecoration(
        boxShadow: [customBoxShadow],
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Card(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RawKeyboardListener(
              autofocus: true,
              focusNode: FocusNode(),
              child: Container(),
              onKey: (tappedKey) {
                if (tappedKey.runtimeType == RawKeyDownEvent) {
                  if (tappedKey.logicalKey == LogicalKeyboardKey.escape) {
                    Navigator.pushAndRemoveUntil(
                        context,
                        FluentPageRoute(
                            builder: (context) => const ChoosePage()),
                        (route) => false);
                  }
                }
              },
            ),
            Expanded(
              flex: 1,
              child: Container(),
            ),
            const Text(
              '登录',
              textAlign: TextAlign.center,
              style: primaryTitle,
            ),
            Expanded(
              flex: 3,
              child: _loginFormBuilder(),
            ),
            SizedBox(
              height: 60,
              width: 120,
              child: Tooltip(
                message: '开始你的旅程',
                child: IconButton(
                    focusable: false,
                    icon: Icon(
                      FluentIcons.forward,
                      color: Colors.black.withOpacity(0.5),
                      size: 48,
                    ),
                    onPressed: () async {
                      debugPrint('login');
                      _doLogin().then((isLoginSucceed) {
                        if (isLoginSucceed) {
                          customDisplayInfoBar(
                            context,
                            '登录',
                            '登录成功！:>',
                            InfoBarSeverity.success,
                          );
                          Navigator.pushAndRemoveUntil(
                              context,
                              FluentPageRoute(
                                  builder: (context) => const MainPage()),
                              (route) => false);
                        } else {
                          displayInfoBar(
                            context,
                            builder: ((context, close) {
                              return InfoBar(
                                title: const Text('登录:'),
                                content: const Text('用户名或密码有误:<'),
                                action: IconButton(
                                  icon: const Icon(FluentIcons.clear),
                                  onPressed: close,
                                ),
                                severity: InfoBarSeverity.warning,
                              );
                            }),
                          );
                        }
                      });
                    }),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(),
            ),
          ],
        ),
      ),
    );
    return Container(
      color: Colors.grey[40],
      child: Column(
        children: [
          Expanded(
            flex: 1,
            child: Container(),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        flex: 1,
                        child: loginCard,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(),
                ),
              ],
            ),
          ),
          Expanded(flex: 1, child: Container()),
        ],
      ),
    );
  }

  Widget _loginFormBuilder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(
          height: 10,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: TextBox(
            maxLines: 1,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            placeholder: '手机号',
            highlightColor: Colors.white.withOpacity(0),
            textAlign: TextAlign.center,
            controller: _phoneNumberController,
            unfocusedColor: Colors.white.withOpacity(0),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: PasswordBox(
            placeholder: '密码',
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
            controller: _passwordController,
            highlightColor: Colors.white.withOpacity(0),
            unfocusedColor: Colors.white.withOpacity(0),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
      ],
    );
  }

  Future<bool> _doLogin() async {
    String md5Password = md5Encryption(_passwordController.text);
    return await userApi
        .login(_phoneNumberController.text, md5Password)
        .then((value) async {
      debugPrint('value: $value');
      if (value != null) {
        clientData.user = User(
          id: value,
          phoneNumber: _phoneNumberController.text,
          password: _passwordController.text,
        );

        initLocalDb();

        clientData.user!.password = md5Encryption(_passwordController.text);
        userApi.setUser(clientData.user!.id, clientData.user!.password);

        clientData.user!.nickname =
            await organizationApi.getNickname(value).then((value) => value.$2);
        var tmpAvatar = await organizationApi.getAvatar(clientData.user!.id);
        clientData.userAvatar =
            (tmpAvatar != null) ? tmpAvatar : DEFAULT_AVATAR;
        debugPrint(clientData.user.toString());
        return true;
      } else {
        return false;
      }
    });
  }
}
