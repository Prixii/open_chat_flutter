import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/component/floating_card.dart';
import 'package:open_chat/page/group/create_group.dart';
import 'package:open_chat/page/contact/search_contact_card.dart';
import 'package:open_chat/theme/custome_theme.dart';

import '../../main.dart';

class AddContactCard extends StatefulWidget {
  const AddContactCard({required this.closeCard, super.key});
  final Function(bool bl) closeCard;

  @override
  State<AddContactCard> createState() => _AddContactCardState();
}

class _AddContactCardState extends State<AddContactCard> {
  void setSearchContactCardVisible(bool isVisible) {
    if (mounted) {
      setState(() {
        _searchContactCardVisible = isVisible;
      });
    }
  }

  void setCreateGroupCardVisible(bool isVisible) {
    if (mounted) {
      setState(() {
        _createGroupCardVisible = isVisible;
      });
    }
  }

  bool _searchContactCardVisible = false;
  bool _createGroupCardVisible = false;
  @override
  Widget build(BuildContext context) {
    GlobalContent.context = context;
    return Stack(
      children: [
        FloatingCard(
          closeCard: widget.closeCard,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(),
                ),
                Expanded(
                  flex: 3,
                  child: HyperlinkButton(
                      child: Row(
                        children: [
                          const Icon(
                            FluentIcons.add_friend,
                            size: 20,
                            color: Colors.black,
                          ),
                          Text(
                            '添加好友或群组',
                            style: coloredSecondaryTitle(Colors.black),
                          ),
                          Expanded(
                            child: Container(),
                          ),
                          const Icon(
                            FluentIcons.forward,
                            size: 20,
                            color: Colors.black,
                          ),
                        ],
                      ),
                      // 显示卡片
                      onPressed: () => setSearchContactCardVisible(true)),
                ),
                Expanded(
                  child: Container(),
                ),
                Expanded(
                  flex: 3,
                  child: HyperlinkButton(
                      child: Row(
                        children: [
                          const Icon(
                            FluentIcons.o_d_shared_channel,
                            size: 20,
                            color: Colors.black,
                          ),
                          Text(
                            '创建群组',
                            style: coloredSecondaryTitle(Colors.black),
                          ),
                          Expanded(
                            child: Container(),
                          ),
                          const Icon(
                            FluentIcons.forward,
                            size: 20,
                            color: Colors.black,
                          ),
                        ],
                      ),
                      onPressed: () => setCreateGroupCardVisible(true)),
                ),
                Expanded(
                  child: Container(),
                ),
              ],
            ),
          ),
        ),
        Visibility(
          visible: _searchContactCardVisible,
          child: SearchContactCard(
            closeCard: setSearchContactCardVisible,
          ),
        ),
        Visibility(
          visible: _createGroupCardVisible,
          child: CreateGroupCard(
            closeCard: setCreateGroupCardVisible,
          ),
        ),
      ],
    );
  }
}
