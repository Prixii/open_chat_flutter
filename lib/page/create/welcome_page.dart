import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/theme/custome_theme.dart';

import '../../main.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key, required this.nickname});

  final String nickname;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    GlobalContent.context = context;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(
          height: 20,
        ),
        Column(children: [
          const Text(
            '欢迎',
            style: primaryTitle,
          ),
          Text(
            widget.nickname,
            style: const TextStyle(
              fontFamily: 'OPenChatFonts',
              fontSize: 64,
              fontWeight: FontWeight.normal,
            ),
          ),
        ]),
        // const Text('开始你的旅程', style: secondaryTitle),
        // const SizedBox(
        //   height: 5,
        // ),
        const SizedBox(
          height: 20,
        ),
      ],
    );
  }
}
