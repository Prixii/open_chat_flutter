import 'dart:async';
import 'dart:developer';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/component/chat_dialog.dart';
import 'package:open_chat/component/contact_info.dart';
import 'package:open_chat/component/contact_top_bar.dart';
import 'package:open_chat/component/left_contact_list.dart';
import 'package:open_chat/component/message_bubble.dart';
import 'package:open_chat/store/client_data.dart';
import 'package:open_chat/utils/client_utils.dart';

import '../models/message.dart';
import '../network/client/message.dart';

class ChatBody extends StatefulWidget {
  const ChatBody(
      {required this.setUserInfoEditorVisible,
      required this.setAddContactVisible,
      required this.setGroupInfoEditorVisible,
      super.key});
  final void Function(bool bl) setUserInfoEditorVisible;
  final void Function(bool bl) setAddContactVisible;
  final void Function(bool bl) setGroupInfoEditorVisible;

  @override
  State<ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends State<ChatBody> {
  List<Widget> _historyMessageList = [];
  Icon paneClose = Icon(
    FluentIcons.open_pane,
    size: 20,
    color: Colors.grey[200],
  );
  Icon paneOpen = Icon(
    FluentIcons.close_pane,
    size: 20,
    color: Colors.blue,
  );
  int userId = clientData.user!.id;
  late Icon paneButtonIcon;
  bool contactInfoVisible = false;
  int messageCount = 0;
  late ScrollController messageScrollController;
  bool haveChatChosen = false;
  List<String> localMessageListTemp = [];
  Timer? reflushTimer;
  bool isHistroyAvailable = true;

  // 添加消息到消息列表
  List<Message> messageList = [];
  Future<void> addMessage(String msg) async {
    clientData.messageList.add(
      Message(
        messageId: -1,
        messageSender: userId,
        messageTarget: clientData.currentTargetId,
        messageContent: msg,
        time: 0,
      ),
    );
    if (mounted) setState(() {});
    Future.delayed(const Duration(milliseconds: 100), () {
      // debugPrint("刷新");
      messageScrollController
          .jumpTo(messageScrollController.position.maxScrollExtent);
    });
  }

  /// 列表滚动事件检测

  @override
  void initState() {
    messageScrollController = ScrollController();
    paneButtonIcon = paneOpen;
    reflushTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (haveChatChosen) {
        if (mounted) {
          setState(() {
            messageList = clientData.messageList;
            // logger.d('[flush message] 滑动到底部');
            try {
              clientData.allowScroolBottom =
                  (messageScrollController.position.pixels ==
                      messageScrollController.position.maxScrollExtent);
            } catch (e) {
              logger.e('[scroll list error]', [e]);
            }
            if (clientData.allowScroolBottom) {
              Future.delayed(const Duration(milliseconds: 100), () {
                // debugPrint("刷新");
                messageScrollController
                    .jumpTo(messageScrollController.position.maxScrollExtent);
              });
            } else {
              logger.d(
                  '[flush message] distance:${(messageScrollController.position.pixels - messageScrollController.position.maxScrollExtent).toString()}');
            }
          });
        }
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    messageScrollController.dispose();
    reflushTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
// ********************** 左侧列表 ********************************
        Container(
          color: Colors.grey[10],
          child: LeftContactList(
            setUserInfoEditorVisible: widget.setUserInfoEditorVisible,
            setAddContactVisible: widget.setAddContactVisible,
            setHaveChatChosen: setHaveChatChosen,
            setUserInfoVisible: setContactInfoVisible,
          ),
        ),
// ********************** 中部聊天窗 ********************************
        Expanded(
          child: Stack(
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: const Center(
                        child: Text('select a chat'),
                      ),
                    ),
                  ),
                ],
              ),
              Visibility(
                visible: haveChatChosen,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          ContactTopBar(
                            paneButtonIcon: paneButtonIcon,
                            setIsInfoVisible: setContactInfoVisible,
                          ),
                          Container(
                            color: Colors.grey[20],
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Center(
                                child: Tooltip(
                                  message: '获取历史消息',
                                  child: HyperlinkButton(
                                    child: Icon(
                                      FluentIcons.history,
                                      color: isHistroyAvailable
                                          ? Colors.blue.dark
                                          : Colors.grey[100],
                                    ),
                                    onPressed: () {
                                      if (isHistroyAvailable) {
                                        _getHistoryMessage();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),

// ***********聊天记录***********
                          Expanded(
                            flex: 6,
                            child: Container(
                              color: Colors.grey[20],
                              child: ListView.builder(
                                itemCount: messageList.length,
                                controller: messageScrollController,
                                itemBuilder: (context, index) {
                                  Message tmpMsg = messageList[index];
                                  if (tmpMsg.messageSender == userId) {
                                    return MyMessageBubble(
                                      message: tmpMsg,
                                      strMessage: null,
                                      // clientData.currentMessageList[index],
                                    );
                                  } else {
                                    return OthersMessageBubble(
                                      message: tmpMsg,
                                      strMessage: null,
                                    );
                                  }
                                },
                                // itemCount: clientData.currentMessageList.length,
                              ),
                            ),
                          ),
// ***********输入框***********
                          Container(
                            color: Colors.grey[10],
                            child: ChatDialog(addMessageToList: addMessage),
                          ),
                        ],
                      ),
                    ),
// ********************** 右侧信息栏 ********************************
                    Visibility(
                      visible: contactInfoVisible,
                      child: ContactInfo(
                        setHaveChatChosen: setHaveChatChosen,
                        setGroupInfoEditorVisible:
                            widget.setGroupInfoEditorVisible,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void setContactInfoVisible(bool? bl) {
    if (mounted) {
      setState(() {
        if (bl != null) {
          contactInfoVisible = bl;
          paneButtonIcon = bl ? paneOpen : paneClose;
        } else {
          contactInfoVisible = !contactInfoVisible;
          if (paneButtonIcon == paneOpen) {
            paneButtonIcon = paneClose;
          } else {
            paneButtonIcon = paneOpen;
          }
        }
      });
    }
  }

  void _getHistoryMessage() async {
    if (mounted) {
      setState(() {
        isHistroyAvailable = false;
      });
    }
    int contactId = clientData.currentTargetId;
    messageApi
        .getEarlyMsg(
            contactId, clientData.earliestMessageId[contactId] ?? 0, 10)
        .then((historyMsgList) {
      // updateHistoryMsgBubble();
      try {
        if (historyMsgList.isNotEmpty) {
          clientData.setEarliestMsgId(
              contactId, historyMsgList[historyMsgList.length - 1].messageId);
          for (Message tmpMsg in historyMsgList) {
            clientData.messageList.insert(0, tmpMsg);
          }
        }
        if (mounted) {
          setState(() {
            isHistroyAvailable = true;
          });
        }
        return;
      } catch (e) {
        logger.e('[get message error]', [e]);
      }
      logger
          .d('[get history] 现在的历史消息${clientData.earliestMessageId[contactId]}');
      if (mounted) {
        setState(() {
          isHistroyAvailable = true;
        });
      }
      return;
    });
    if (mounted) {
      setState(() {
        isHistroyAvailable = true;
      });
    }
  }

  void setHaveChatChosen(bool bl) {
    if (mounted) {
      setState(() {
        haveChatChosen = bl;
      });
    }
  }

  Future<List<Widget>> _listTileBuilder() async {
    List<Widget> tmpBubbleList = [];
    for (var msg in clientData.currentMessageList) {
      tmpBubbleList.add(MyMessageBubble(
        message: null,
        strMessage: msg,
      ));
      clientData.currentMessageList = [];
    }
    return tmpBubbleList;
  }

  void updateHistoryMsgBubble() async {
    await _listTileBuilder().then((value) {
      log('[msg list] 信息量1: ${_historyMessageList.length}');
      if (mounted) {
        setState(() {
          _historyMessageList = value;
          // log('[msg list] 信息量2: ${_historyMessageList.length}');
        });
      }
    });
  }
}
