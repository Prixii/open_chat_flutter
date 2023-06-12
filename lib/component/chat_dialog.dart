import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/network/client/message.dart';
import 'package:open_chat/store/client_data.dart';
import 'package:open_chat/utils/client_utils.dart';

class ChatDialog extends StatefulWidget {
  const ChatDialog({required this.addMessageToList, super.key});
  final void Function(String msg) addMessageToList;
  @override
  State<ChatDialog> createState() => _ChatDialogState();
}

class _ChatDialogState extends State<ChatDialog> {
  late TextEditingController _messageController;

  @override
  void initState() {
    _messageController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    // debugPrint('sendIt');
    var msg = _messageController.text;
    if (msg.isNotEmpty) {
      widget.addMessageToList(msg);
      Future.delayed(const Duration(milliseconds: 100), () {
        // debugPrint("刷新");
      });
      messageApi.send(clientData.currentTargetId, msg).then((value) {
        if (value != -1) {
          clientData.setLatestMessageIdTemp(clientData.currentTargetId, value);
          _messageController.text = '';
        }
      });
    } else {
      customDisplayInfoBar(context, '提示', '不可以发送空消息哦😥', InfoBarSeverity.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      // child: RawKeyboardListener(
      //   autofocus: true,
      //   focusNode: FocusNode(),
      //   onKey: (tappedKey) {
      //     if (tappedKey.runtimeType == RawKeyDownEvent) {
      //       if (tappedKey.logicalKey == LogicalKeyboardKey.enter) {
      //         // 按下Shift换行
      //         if (tappedKey.isShiftPressed) {
      //         } else {
      //           // 否则发送信息
      //           sendMessage();
      //         }
      //       }
      //     }
      //   },
      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        const SizedBox(
          height: 8,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 180, minHeight: 60),
          child: TextBox(
            controller: _messageController,
            maxLines: null,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[10],
            ),
            placeholder: '输入信息...',
            textAlign: TextAlign.start,
            textAlignVertical: TextAlignVertical.center,
            highlightColor: Colors.grey[10],
            unfocusedColor: Colors.grey[10],
            padding: const EdgeInsets.all(8.0),
          ),
        ),
        SizedBox(
          height: 36,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 发送图片，暂不支持
              // IconButton(
              //   icon: Icon(
              //     FluentIcons.file_image,
              //     size: 20,
              //     color: Colors.grey[200],
              //   ),
              //   onPressed: () {},
              // ),
              // const SizedBox(
              //   width: 8.0,
              // ),
              IconButton(
                icon: Icon(
                  FluentIcons.send,
                  size: 20,
                  color: Colors.blue.dark,
                ),
                onPressed: () => sendMessage().then((value) => null),
              ),
            ],
          ),
        )
      ]),
      // ),
    );
  }
}
