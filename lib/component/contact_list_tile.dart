import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/network/client/organization.dart';
import 'package:open_chat/utils/client_utils.dart';

import '../theme/custome_theme.dart';
import '../utils/img_utils.dart';

class ContactListTile extends StatefulWidget {
  const ContactListTile({required this.id, required this.identify, super.key});
  final int id;
  final int identify;
  @override
  State<ContactListTile> createState() => _ContactListTileState();
}

class _ContactListTileState extends State<ContactListTile> {
  String name = 'Loading';
  FileImage? avatar;

  @override
  void initState() {
    organizationApi.getAvatar(widget.id).then((value) {
      logger.d('[refresh Tile]');
      if (mounted) {
        setState(() {
          avatar = value ?? DEFAULT_AVATAR;
        });
      }
    });
    organizationApi.getNickname(widget.id).then((value) {
      if (mounted) {
        setState(() {
          name = value.$1 != 0 ? value.$2 : 'Loading...';
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
        leading: CircleAvatar(
          backgroundImage: avatar,
          backgroundColor: OCAPCITY_COLOR,
          radius: 12,
        ),
        title: Text(
          name,
          style: bodyText,
        ),
        subtitle: Text(
          getIdentify(widget.identify),
          style: secondaryBodyText,
        ),
        onPressed: () {});
  }

  String getIdentify(int identify) {
    switch (identify) {
      case 0:
        return '群成员';
      case 1:
        return '管理员';
      case 2:
        return '所有者';
      default:
        return '群成员';
    }
  }
}
