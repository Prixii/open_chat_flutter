import 'dart:developer';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/component/floating_card.dart';
import 'package:open_chat/network/client/organization.dart';
import 'package:open_chat/store/client_data.dart';
import 'package:open_chat/theme/custome_theme.dart';
import 'package:sqlite3/sqlite3.dart' as sq;

import '../../main.dart';

/// 搜索联系人或群聊
class SearchContactCard extends StatefulWidget {
  const SearchContactCard({required this.closeCard, super.key});
  final Function(bool bl) closeCard;
  @override
  State<SearchContactCard> createState() => _SearchContactCardState();
}

class _SearchContactCardState extends State<SearchContactCard> {
  late TextEditingController _searchTextBoxController;

  late Widget resultWidget;

  /// 搜索失败后，显示这个结果而不是卡片
  Widget getNullResult(String? str) =>
      Expanded(child: Center(child: Text((str == null) ? '没有结果呢' : str)));

  @override
  void initState() {
    _searchTextBoxController = TextEditingController();
    resultWidget = getNullResult('找到你的朋友们...');
    super.initState();
  }

  @override
  void dispose() {
    _searchTextBoxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    GlobalContent.context = context;
    return FloatingCard(
      closeCard: widget.closeCard,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _searchDialogBuilder(),
            const SizedBox(
              height: 18,
            ),
            resultWidget,
          ],
        ),
      ),
    );
  }

  /// 显示结果，不管输入的ID对不对
  /// 对则返回对应的用户
  Widget _resultBuilder(String name, FileImage imageAvatar, int targetId) {
    return SizedBox(
      height: 76,
      child: Card(
        padding: const EdgeInsets.all(0),
        child: ListTile(
          title: Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  foregroundImage: imageAvatar,
                  backgroundColor: OCAPCITY_COLOR,
                  radius: 24,
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: bodyText,
                    ),
                    Text(
                      '#${targetId.toString()}',
                      style: coloredBodyText(Colors.grey[40]),
                    ),
                  ],
                )),
                const Center(
                  child: Icon(
                    FluentIcons.circle_addition,
                    size: 32,
                    color: Color.fromARGB(255, 0, 102, 180),
                    weight: 200,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
              ],
            ),
          ),
          onPressed: () {
            debugPrint('add?');
            showConfirmDeleteDialog(context, targetId);
          },
        ),
      ),
    );
  }

  /// 创建搜索栏
  Widget _searchDialogBuilder() {
    return Row(
      children: [
        Expanded(
          child: TextBox(
            placeholder: '键入ID',
            controller: _searchTextBoxController,
            unfocusedColor: OCAPCITY_COLOR,
            maxLines: 1,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        // RawKeyboardListener(
        //   autofocus: true,
        //   focusNode: FocusNode(),
        //   onKey: (tappedKey) {
        //     if (tappedKey.runtimeType == RawKeyDownEvent) {
        //       if (tappedKey.logicalKey == LogicalKeyboardKey.enter) {
        //         // 按下Shift换行
        //         if (tappedKey.isShiftPressed) {
        //         } else {
        //           // 否则发送信息
        //           _searchContact();
        //         }
        //       }
        //     }
        //   },
        FilledButton(
          child: const Text('搜索'),
          onPressed: () {
            _searchContact();
          },
          // ),
        ),
      ],
    );
  }

  /// 搜索UID对应的用户，有结果则返回对象
  void _searchContact() async {
    // 预判定，看输入的是否为一个ID
    if (int.tryParse(_searchTextBoxController.text) != null &&
        _searchTextBoxController.text.length == 9) {
      int id = int.parse(_searchTextBoxController.text);
      (int, String) getNameResponse = await organizationApi.getNickname(id);
      // ID错误 没有对应的用户
      if (getNameResponse.$1 != 200) {
        if (mounted) {
          setState(() {
            resultWidget = getNullResult(
                _searchTextBoxController.text.length == 9
                    ? '没有结果呢,请确认ID是否正确'
                    : '请输入正确的ID');
          });
        }
        return;
      }
      // ID 正确，有对应的用户
      var contactName = getNameResponse.$2;
      FileImage? contactAvatar = await organizationApi.getAvatar(id);
      if (contactAvatar == null) {
        log(
          'error path',
        );
      } else {
        if (mounted) {
          setState(() {
            resultWidget = _resultBuilder(contactName, contactAvatar, id);
          });
        }
        return;
      }
    }
    if (mounted) {
      setState(() {
        resultWidget = getNullResult(_searchTextBoxController.text.length == 9
            ? '没有结果呢,请确认ID是否正确'
            : '请输入正确的ID');
      });
    }
  }

  // Widget _resultListBuilder(List<String> contactList) {
  //   return ListView.builder(
  //     itemBuilder: (context, index) {
  //       return ListTile(
  //         title: Text(contactList[index]),
  //       );
  //     },
  //     itemCount: contactList.length,
  //   );
  // }

  /// 确认是否要加入群组/添加好友
  void showConfirmDeleteDialog(BuildContext context, int targetId) async {
    await showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
        title: Center(
          child: Column(
            children: [
              const Text(
                '确定发送邀请吗🤔',
                style: primaryTitle,
              ),
              Text(
                '如果对象已经在你的联系列表中了,本操作将不会有任何效果',
                style: bodyText,
              )
            ],
          ),
        ),
        actions: [
          FilledButton(
              child: Text(
                '发送',
                style: coloredBodyText(Colors.white),
              ),
              onPressed: () {
                final db =
                    sq.sqlite3.open('./lib/store/db/${clientData.user!.id}.db');
                db.execute(
                    'UPDATE contact SET contact_status=2 WHERE contact_id=$targetId');
                db.dispose();

                Navigator.pop(context, 'Confirmed');
                organizationApi.join(targetId).then((code) {
                  if (code == 200) {
                    displayInfoBar(
                      context,
                      builder: ((context, close) {
                        return InfoBar(
                          title: const Text('申请:'),
                          content: const Text('申请已经发送了:)'),
                          action: IconButton(
                            icon: const Icon(FluentIcons.clear),
                            onPressed: close,
                          ),
                          severity: InfoBarSeverity.success,
                        );
                      }),
                    );
                  } else {
                    displayInfoBar(
                      context,
                      builder: ((context, close) {
                        return InfoBar(
                          title: const Text('申请:'),
                          content: const Text('申请发送失败:('),
                          action: IconButton(
                            icon: const Icon(FluentIcons.clear),
                            onPressed: close,
                          ),
                          severity: InfoBarSeverity.error,
                        );
                      }),
                    );
                  }
                });
              }),
          Button(
              child: Text(
                '算了',
                style: coloredBodyText(Colors.black),
              ),
              onPressed: () {
                Navigator.pop(context, 'Cancled');
              })
        ],
      ),
    );
    if (mounted) setState(() {});
  }
}
