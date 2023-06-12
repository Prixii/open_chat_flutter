import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/network/client/user.dart';
import 'package:open_chat/page/hello/choose_page.dart';
import 'package:open_chat/theme/custome_theme.dart';
import 'package:open_chat/utils/client_utils.dart';
import 'package:open_chat/utils/db_utils.dart';

// ignore: unused_import
import 'network/client/organization.dart';

void main(List<String> args) async {
  runApp(FluentApp(
    home: const MyApp(),
    theme: customTheme,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    // startDebugMode();
    getDeviceID();
    return const ScaffoldPage(
      padding: EdgeInsets.zero,
      // content: MainPage(),
      content: ChoosePage(),
    );
  }
}

void startDebugMode() async {
  userApi.initCurrentUserInfo();
  initLocalDb();
  // await organizationApi.getContactList().then((value) {
  //   return value;
  // });
}

class GlobalContent {
  static BuildContext? context;
}
