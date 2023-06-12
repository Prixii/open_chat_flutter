import 'package:fluent_ui/fluent_ui.dart';

// ignore: non_constant_identifier_names
final Color OCAPCITY_COLOR = Colors.black.withOpacity(0);
// ignore: non_constant_identifier_names, constant_identifier_names
const Color SYSTEM_BLUE = Color.fromARGB(255, 0, 102, 180);
TextStyle helloTitle = TextStyle(
  fontSize: 48,
  fontFamily: 'OPenChatFonts',
  fontWeight: FontWeight.normal,
  foreground: Paint()
    ..shader = const LinearGradient(colors: [
      Color.fromRGBO(173, 21, 0, 1),
      Color.fromRGBO(255, 157, 5, 1),
    ]).createShader(const Rect.fromLTWH(550, 250, 100, 150)),
);

const TextStyle primaryTitle = TextStyle(
  fontFamily: 'OPenChatFonts',
  fontSize: 24,
  fontWeight: FontWeight.normal,
);

const TextStyle secondaryTitle = TextStyle(
  fontFamily: 'OPenChatFonts',
  fontSize: 20,
  fontWeight: FontWeight.normal,
);

TextStyle coloredSecondaryTitle(Color color) => TextStyle(
      fontFamily: 'OPenChatFonts',
      fontSize: 20,
      fontWeight: FontWeight.normal,
      color: color,
    );

TextStyle bodyText = TextStyle(
  fontFamily: 'OPenChatFonts',
  fontSize: 16,
  fontWeight: FontWeight.normal,
  color: Colors.grey[200],
);
TextStyle coloredBodyText(Color color) {
  return TextStyle(
    fontFamily: 'OPenChatFonts',
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: color,
  );
}

TextStyle timeText = TextStyle(
  fontFamily: 'OPenChatFonts',
  fontSize: 8,
  fontWeight: FontWeight.w100,
  color: Colors.grey[100],
);

TextStyle secondaryBodyText = TextStyle(
  fontFamily: 'OPenChatFonts',
  fontSize: 12,
  fontWeight: FontWeight.normal,
  color: Colors.grey[100],
);

BoxShadow customBoxShadow = BoxShadow(
  color: Colors.black.withOpacity(0.3),
  offset: const Offset(0, 0), // 阴影与容器的距离
  blurRadius: 15.0, // 高斯的标准偏差与盒子的形状卷积。
  spreadRadius: 0.0, // 在应用模糊之前，框应该膨胀的量。
);

FluentThemeData customTheme = FluentThemeData(
  activeColor: Colors.white,
  scaffoldBackgroundColor: Colors.red,
);
