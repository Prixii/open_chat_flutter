import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/page/hello/hello_page.dart';
import 'package:open_chat/page/hello/login_page.dart';
import 'package:open_chat/theme/custome_theme.dart';

class ChoosePage extends StatelessWidget {
  const ChoosePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Timer.periodic(const Duration(seconds: 2), (timer) {
    //   logger.d('nothing');
    // });
    var registerCard = Container(
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
            Expanded(
              flex: 1,
              child: Container(),
            ),
            const Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      '注册',
                      textAlign: TextAlign.center,
                      style: primaryTitle,
                    ),
                    Text(
                      'Register\n登録する',
                      textAlign: TextAlign.center,
                      style: secondaryTitle,
                    ),
                  ],
                )),
            SizedBox(
              height: 90,
              child: HyperlinkButton(
                child: Icon(
                  FluentIcons.forward,
                  size: 48,
                  color: Colors.grey[100],
                ),
                onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    FluentPageRoute(builder: (context) => const HelloPage()),
                    (route) => false),
              ),
            ),
          ],
        ),
      ),
    );

    // **************登录操作**********
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
            Expanded(
              flex: 1,
              child: Container(),
            ),
            const Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(
                    '登录',
                    textAlign: TextAlign.center,
                    style: primaryTitle,
                  ),
                  Text(
                    'Login\nログインします',
                    textAlign: TextAlign.center,
                    style: secondaryTitle,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 90,
              child: HyperlinkButton(
                child: Icon(
                  FluentIcons.forward,
                  size: 48,
                  color: Colors.grey[100],
                ),
                onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    FluentPageRoute(builder: (context) => const LoginPage()),
                    (route) => false),
              ),
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
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'OPenChat',
                  style: TextStyle(fontSize: 128, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 60,
                  child: Text(
                    '  @Bee',
                    style: TextStyle(fontSize: 32, color: Colors.grey),
                    textAlign: TextAlign.end,
                  ),
                ),
                SizedBox(
                  height: 64,
                  child: Image.asset('./assets/images/colored_bee.png'),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 18,
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
                        child: registerCard,
                      ),
                      const SizedBox(
                        width: 80,
                      ),
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
}
