import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/component/message_bubble_tail.dart';
import 'package:open_chat/models/message.dart';
import 'package:open_chat/store/client_data.dart';
import 'package:open_chat/theme/custome_theme.dart';
import 'package:open_chat/utils/client_utils.dart';

class MyMessageBubble extends StatelessWidget {
  const MyMessageBubble(
      {required this.message, required this.strMessage, super.key});
  final Message? message;
  final String? strMessage;
  @override
  Widget build(BuildContext context) {
    final messageTextGroup = Flexible(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18)),
              ),
              child: SelectableText(
                // message.messageContent,
                message != null ? message!.messageContent : strMessage ?? '',
                style: coloredBodyText(Colors.grey[10]),
              ),
            ),
          ),
          CustomPaint(painter: BubbleTailShape(Colors.blue)),
          const SizedBox(
            width: 10,
          ),
          //
          CircleAvatar(
            radius: 20,
            backgroundColor: OCAPCITY_COLOR,
            foregroundImage: clientData.userAvatar,
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(right: 18, left: 50, top: 15, bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(
            height: 30,
          ),
          messageTextGroup
        ],
      ),
    );
  }
}

class OthersMessageBubble extends StatelessWidget {
  const OthersMessageBubble(
      {required this.message, required this.strMessage, super.key});
  final Message? message;
  final String? strMessage;

  @override
  Widget build(BuildContext context) {
    final messageTextGroup = Flexible(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: OCAPCITY_COLOR,
            foregroundImage: isGroup(clientData.currentTargetId)
                ? clientData.loadAvatar(message!.messageSender)
                : clientData.currentTargetAvatar,
          ),
          const SizedBox(
            width: 10,
          ),
          CustomPaint(painter: BubbleTailShape(Colors.grey[10])),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[10],
                borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18)),
              ),
              child: SelectableText(
                message != null ? message!.messageContent : strMessage ?? '',
                style: bodyText,
              ),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(right: 50, left: 18, top: 15, bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(
            height: 30,
          ),
          messageTextGroup
        ],
      ),
    );
  }
}
