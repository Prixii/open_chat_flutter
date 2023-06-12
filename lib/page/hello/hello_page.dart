import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/models/account.dart';
import 'package:open_chat/models/organization.dart';
import 'package:open_chat/network/client/organization.dart';
import 'package:open_chat/network/client/user.dart';
import 'package:open_chat/page/create/create_user_page.dart';
import 'package:open_chat/page/create/set_info_page.dart';
import 'package:open_chat/page/create/welcome_page.dart';
import 'package:open_chat/page/main/main_page.dart';
import 'package:open_chat/store/client_data.dart';
import 'package:open_chat/utils/client_utils.dart';
import 'package:open_chat/utils/db_utils.dart';
import 'package:open_chat/utils/img_utils.dart';
import 'package:simple_animations/simple_animations.dart';

import '../../main.dart';

enum _ColorTween { color1, color2 }

class HelloPage extends StatefulWidget {
  const HelloPage({super.key});

  @override
  State<HelloPage> createState() => _HelloPageState();
}

class _HelloPageState extends State<HelloPage> with TickerProviderStateMixin {
  bool isLogin = false;
  int _widgetIndex = 0;
  late AnimationController _animationController;
  late Animation animation;
  late TextEditingController _nicknameController, // 用户名控制器
      _phoneNumberController, // 电话控制器
      _passwordController, // 密码控制器
      _confirmPasswordController; // 确认密码控制器
  Timer? _timer;

// 初始化变量
  @override
  void initState() {
    initController();
    super.initState();
  }

// 销毁变量
  @override
  void dispose() {
    _animationController.dispose();
    _nicknameController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    GlobalContent.context = context;
    final tween = MovieTween()
      ..tween(
        _ColorTween.color1,
        ColorTween(begin: const Color(0xffD38312), end: Colors.blue),
        duration: const Duration(seconds: 10),
      )
      ..tween(
        _ColorTween.color2,
        ColorTween(begin: const Color(0xffA83279), end: Colors.green),
        duration: const Duration(seconds: 10),
      );
    return Stack(
      children: [
        MirrorAnimationBuilder<Movie>(
            tween: tween,
            duration: tween.duration,
            builder: (context, value, child) {
              return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        value.get<Color>(_ColorTween.color1),
                        value.get<Color>(_ColorTween.color2),
                      ],
                    ),
                  ),
                  child: _registerPageBuilder());
            }),
        onBottom(const AnimatedWave(
          height: 130,
          speed: 1.0,
        )),
        onBottom(const AnimatedWave(
          height: 120,
          speed: 0.8,
          offset: pi,
        )),
        onBottom(const AnimatedWave(
          height: 190,
          speed: 0.5,
          offset: pi / 2,
        )),
      ],
    );
  }

// 控制器初始化
  void initController() {
    _animationController = AnimationController(
      vsync: this,
      value: 1.0,
      duration: const Duration(seconds: 1),
    );
    animation = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
    _nicknameController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

// ****** 注册页面 *****************
  Widget _registerPageBuilder() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(),
        ),
        Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(),
                ),
                Expanded(
                  flex: 3,
                  child: Card(
                    padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
                    borderRadius: BorderRadius.circular(15),
                    borderColor: null,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 320,
                        ),
                        child: IndexedStack(
                          index: _widgetIndex,
                          children: [
                            CreateUserPage(
                              phoneNumberController: _phoneNumberController,
                              passwordController: _passwordController,
                              confirmPasswordController:
                                  _confirmPasswordController,
                            ),
                            const Center(
                              child: ProgressRing(),
                            ),
                            SetInfoPage(
                              nicknameController: _nicknameController,
                            ),
                            const Center(
                              child: ProgressRing(),
                            ),
                            Center(
                              child: WelcomePage(
                                  nickname: _nicknameController.text),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 96,
                  width: 96,
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
                      child: _createButtonBuilder()),
                ),
                Expanded(
                  flex: 1,
                  child: Container(),
                ),
              ],
            )),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Expanded(child: SizedBox(height: 36)),
                  Expanded(
                    child: Container(),
                  )
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  onBottom(Widget child) => Positioned.fill(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      );
  // 跳转到下一个页面，如果 isLogin = true，跳转到主页面
  void toNextPage() {
    if (isLogin) {
      Navigator.push(
        context,
        FluentPageRoute(builder: (context) => const MainPage()),
      );
    }
    if (_widgetIndex < 4) {
      if (mounted) {
        setState(() {
          _widgetIndex += 1;
        });
      }
      if (_widgetIndex == 1 || _widgetIndex == 3) {
        _startTimer();
      }
      if (_widgetIndex == 4) {
        isLogin = true;
      }
    }
  }

  Widget _createButtonBuilder() {
    return Card(
      padding: const EdgeInsets.all(0),
      borderRadius: BorderRadius.circular(300),
      borderColor: null,
      child: Tooltip(
        message: '开始你的旅程',
        child: IconButton(
            focusable: false,
            icon: Icon(
              FluentIcons.chevron_right_small,
              color: Colors.black.withOpacity(0.5),
              size: 24,
            ),
            onPressed: () {
              if (_widgetIndex == 0) {
                _doRegister();
              } else if (_widgetIndex == 2) {
                _doSetInfo();
              } else if (_widgetIndex == 4) {
                toNextPage();
              }
            }),
      ),
    );
  }

// 注册操作
  void _doRegister() async {
    if (_checkForm()) {
      var md5Password = md5Encryption(_passwordController.text);
      userApi.create(_phoneNumberController.text, md5Password).then((response) {
        if (response.$1 == 200) {
          debugPrint('response $response');
          saveUser(response.$3!);
          userApi.setUser(clientData.user!.id, clientData.user!.password);
          initLocalDb();
          toNextPage();
        } else {
          customDisplayInfoBar(
              context,
              '注册',
              '出现问题 错误码:${response.$1} message:${response.$2}',
              InfoBarSeverity.error);
        }
      });
    }
  }

// 保存用户注册的信息到全局变量
  void saveUser(int id) {
    clientData.user = User(
      id: id,
      phoneNumber: _phoneNumberController.text,
      password: md5Encryption(_passwordController.text),
    );
    debugPrint(clientData.user.toString());
    userApi.setUser(clientData.user!.id, clientData.user!.password);
  }

// 检查输入的手机号、密码是否符合要求
  bool _checkForm() {
    bool isPhoneLegal = false;
    bool isPasswordLegal = false;
    isPhoneLegal = _checkPhoneNumber();
    isPasswordLegal = _checkPassword();
    if (!(isPhoneLegal && isPasswordLegal)) {
      displayInfoBar(
        context,
        builder: ((context, close) {
          String errorMsg = '';
          if (!isPhoneLegal) {
            errorMsg += ' 电话号码不合法 ';
          }
          if (!isPasswordLegal) {
            errorMsg += ' 不合适的密码,长度需要在8~16位之间 ';
          }
          errorMsg += ':(';
          return InfoBar(
            title: const Text('信息有误'),
            content: Text(errorMsg),
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: close,
            ),
            severity: InfoBarSeverity.warning,
          );
        }),
      );
    }
    return (isPhoneLegal && isPasswordLegal);
  }

  bool _checkPhoneNumber() {
    String phoneNumber = _phoneNumberController.text;
    bool isAllNumber = (double.tryParse(phoneNumber) == null) ? false : true;
    if (!isAllNumber || phoneNumber.length != 11 || phoneNumber[0] != "1") {
      // debugPrint('Illegal phoneNumber');
      return false;
    }
    // debugPrint('Good phone');
    return true;
  }

  bool _checkPassword() {
    if (_passwordController.text.length > 18 ||
        _passwordController.text.length < 8) {
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      // debugPrint('Please confirm your password');
      return false;
    }
    debugPrint('Good pwd');
    return true;
  }

// 上传初始化信息
  void _doSetInfo() async {
    if (_checkAvatarAndNickname()) {
      debugPrint('To nextPage');
      _saveCurrentUserInfo();

      userApi.setName(_nicknameController.text);
      toNextPage();
    }
  }

// 保存当前的用户信息到数据库
  void _saveCurrentUserInfo() async {
    initLocalDb();
// 上传头像到服务器
    var md5Avatar = await organizationApi.setAvatar(
      clientData.user!.id,
      base64Encode(clientData.user!.u8Avatar!),
      clientData.fileExtension!,
    );
    // debugPrint('md5Avatar $md5Avatar');
// 保存头像到本地
    saveImageWithString(base64Encode(clientData.user!.u8Avatar!),
            'avatar${clientData.user!.phoneNumber}.${clientData.fileExtension}')
        .then((filePath) {
      var organization = Organization(id: clientData.user!.id)
        ..avatarPath = filePath
        ..ex = clientData.fileExtension
        ..md5AvatarName = md5Avatar
        ..name = clientData.user!.nickname;
      insertOrReplaceOrganization([organization]);
    });
  }

// 检查头像与昵称
  bool _checkAvatarAndNickname() {
    bool isAvatarLegal = _checkAvatar();
    bool isNicknameLegal = _checkNickname();

    if (isAvatarLegal && isNicknameLegal) {
      clientData.user!.nickname = _nicknameController.text;
      // debugPrint('Good info');
      return true;
    }
    // if (!isNicknameLegal) debugPrint("Please set nickname");
    // if (!isAvatarLegal) debugPrint("Please set avatar");

    return false;
  }

  bool _checkAvatar() {
    // debugPrint(clientData.user!.avatar.toString());
    if (clientData.user!.u8Avatar != null) {
      return true;
    } else {
      customDisplayInfoBar(context, '头像错误', '请你设置头像', InfoBarSeverity.error);
      return false;
    }
  }

  bool _checkNickname() {
    if (_nicknameController.text.length > 18) {
      customDisplayInfoBar(
          context, '昵称错误', '昵称不能大于18字符哦:/', InfoBarSeverity.error);
    } else if (_nicknameController.text.isEmpty) {
      customDisplayInfoBar(context, '昵称错误', '昵称不能为空哦:/', InfoBarSeverity.error);
    }
    return (_nicknameController.text.isNotEmpty);
  }

// 计时器
  void _startTimer() {
    const duration = Duration(seconds: 1);

    _timer = Timer.periodic(duration, (timer) {
      // debugPrint('CountValue');
      cancelTimer();
    });
  }

  void cancelTimer() {
    if (_timer != null) {
      toNextPage();
      _timer!.cancel();
    }
  }
}

// 实现波浪动效
class AnimatedWave extends StatelessWidget {
  final double? height;
  final double? speed;
  final double offset;

  const AnimatedWave({super.key, this.height, this.speed, this.offset = 0.0});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SizedBox(
        height: height,
        width: constraints.biggest.width,
        child: LoopAnimationBuilder<double>(
            duration: Duration(milliseconds: (5000 / speed!).round()),
            tween: Tween(begin: 0.0, end: 2 * pi),
            builder: (context, value, child) {
              return CustomPaint(
                foregroundPainter: CurvePainter(value + offset),
              );
            }),
      );
    });
  }
}

// 实现背景颜色变换
class CurvePainter extends CustomPainter {
  final double value;

  CurvePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final white = Paint()..color = Colors.white.withAlpha(60);
    final path = Path();
    final y1 = sin(value);
    final y2 = sin(value + pi / 2);
    final y3 = sin(value + pi);
    final startPointY = size.height * (0.5 + 0.4 * y1);
    final controlPointY = size.height * (0.5 + 0.4 * y2);
    final endPointY = size.height * (0.5 + 0.4 * y3);

    path.moveTo(size.width * 0, startPointY);
    path.quadraticBezierTo(
        size.width * 0.5, controlPointY, size.width, endPointY);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, white);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
