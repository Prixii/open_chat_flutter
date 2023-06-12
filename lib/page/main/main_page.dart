import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/component/chat_body.dart';
import 'package:open_chat/page/contact/add_contact_card.dart';
import 'package:open_chat/page/account/user_profile.dart';
import 'package:open_chat/page/group/group_info_editor.dart';

import '../../main.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool _userInfoEditorVisible = false;
  bool _addContactVisible = false;
  bool _groupInfoEditorVisible = false;
  void setHaveChatChosen(bool haveChatChosen) {
    haveChatChosen = true;
  }

  void setUserInfoEditorVisible(bool visible) {
    if (mounted) {
      setState(() {
        _userInfoEditorVisible = visible;
      });
    }
  }

  void setAddContactVisible(bool visible) {
    if (mounted) {
      setState(() {
        _addContactVisible = visible;
      });
    }
  }

  void setGroupInfoEditorVisible(bool visible) {
    if (mounted) {
      setState(() {
        _groupInfoEditorVisible = visible;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    GlobalContent.context = context;
    return Container(
      color: Colors.grey[20],
      child: Center(
        child: Stack(
          children: [
            ChatBody(
              setUserInfoEditorVisible: setUserInfoEditorVisible,
              setAddContactVisible: setAddContactVisible,
              setGroupInfoEditorVisible: setGroupInfoEditorVisible,
            ),
            Visibility(
              visible: _userInfoEditorVisible,
              // visible: _userInfoEditorVisible,
              child: UserProfile(
                closeCard: setUserInfoEditorVisible,
              ),
            ),
            Visibility(
              visible: _addContactVisible,
              // visible: _userInfoEditorVisible,
              child: AddContactCard(
                closeCard: setAddContactVisible,
              ),
            ),
            Visibility(
              visible: _groupInfoEditorVisible,
              // visible: _userInfoEditorVisible,
              child: GroupInfoEditor(
                closeCard: setGroupInfoEditorVisible,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
