import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/theme/custome_theme.dart';

import '../../main.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage(
      {required this.phoneNumberController,
      required this.passwordController,
      required this.confirmPasswordController,
      super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
  final TextEditingController phoneNumberController,
      passwordController,
      confirmPasswordController;
  void register() {
    debugPrint(phoneNumberController.text);
  }
}

class _CreateUserPageState extends State<CreateUserPage> {
  late TextEditingController phoneNumberController,
      passwordController,
      confirmPasswordController;
  @override
  void initState() {
    phoneNumberController = widget.phoneNumberController;
    passwordController = widget.passwordController;
    confirmPasswordController = widget.confirmPasswordController;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    GlobalContent.context = context;
    return Center(
      child: SizedBox(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Builder(
            builder: (context) {
              return _formBuilder();
            },
          ),
        ),
      ),
    );
  }

  Widget _formBuilder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(
          height: 10,
        ),
        Column(
          children: [
            const Text(
              '欢迎来到',
              style: secondaryTitle,
            ),
            Text(
              'OPenChat',
              style: helloTitle,
            ),
          ],
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
            controller: phoneNumberController,
            unfocusedColor: Colors.white.withOpacity(0),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: PasswordBox(
            placeholder: '密码',
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
            controller: passwordController,
            highlightColor: Colors.white.withOpacity(0),
            unfocusedColor: Colors.white.withOpacity(0),
            textAlign: TextAlign.center,
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: PasswordBox(
            placeholder: '确认密码',
            highlightColor: Colors.white.withOpacity(0),
            textAlign: TextAlign.center,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
            controller: confirmPasswordController,
            unfocusedColor: Colors.white.withOpacity(0),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
      ],
    );
  }
}
