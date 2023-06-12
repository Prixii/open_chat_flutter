import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/store/client_data.dart';
import 'package:open_chat/theme/custome_theme.dart';

class ContactTopBar extends StatefulWidget {
  const ContactTopBar(
      {required this.paneButtonIcon,
      required this.setIsInfoVisible,
      super.key});
  final void Function(bool? bl) setIsInfoVisible;
  final Icon paneButtonIcon;

  @override
  State<ContactTopBar> createState() => _ContactTopBarState();
}

class _ContactTopBarState extends State<ContactTopBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[10],
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            const SizedBox(
              width: 16,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clientData.currentTargetName,
                    style: bodyText,
                  ),
                  Text(
                    '#${clientData.currentTargetId}',
                    style: secondaryBodyText,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      FluentIcons.collapse_menu,
                      size: 20,
                      color: Colors.grey[200],
                    ),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: widget.paneButtonIcon,
                    onPressed: () => widget.setIsInfoVisible(null),
                  ),
                  const SizedBox(
                    width: 8,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
