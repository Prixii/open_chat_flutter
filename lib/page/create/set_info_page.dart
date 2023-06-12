import 'package:fluent_ui/fluent_ui.dart';
import 'package:open_chat/store/client_data.dart';
import 'package:open_chat/theme/custome_theme.dart';
import 'package:open_chat/utils/img_utils.dart';

import '../../main.dart';

class SetInfoPage extends StatefulWidget {
  const SetInfoPage({super.key, required this.nicknameController});
  final TextEditingController nicknameController;

  @override
  State<SetInfoPage> createState() => _SetInfoPageState();
}

class _SetInfoPageState extends State<SetInfoPage> {
  late TextEditingController _nicknameController;
  FileImage? avatar;
  @override
  void initState() {
    _nicknameController = widget.nicknameController;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    GlobalContent.context = context;
    return _formBuilder();
  }

  Widget _formBuilder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(
          height: 0,
        ),
        const Text(
          '设置你的信息',
          style: secondaryTitle,
        ),
        GestureDetector(
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.black.withOpacity(0.2),
            foregroundImage: avatar,
            child: const Icon(FluentIcons.add),
          ),
          onTap: () => getLocalImg().then((imageInfo) {
            avatar = imageInfo.$1;
            clientData.fileName = imageInfo.$2;
            clientData.fileExtension =
                imageInfo.$3.replaceFirst(RegExp('.'), '');
            fileImgToByte(imageInfo.$1)
                .then((base64Img) => clientData.user!.u8Avatar = base64Img);
          }),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: TextBox(
            maxLines: 1,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            placeholder: '昵称',
            highlightColor: Colors.white.withOpacity(0),
            textAlign: TextAlign.center,
            controller: _nicknameController,
            unfocusedColor: Colors.white.withOpacity(0),
          ),
        ),
        const SizedBox(
          height: 5,
        ),
      ],
    );
  }
}
