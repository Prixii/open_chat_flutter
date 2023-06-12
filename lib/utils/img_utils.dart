import 'dart:convert';

import 'dart:io';
import 'dart:typed_data';
import 'package:open_chat/store/client_data.dart';
import 'package:open_chat/utils/client_utils.dart';
import 'package:path/path.dart' as p;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image_compression_flutter/image_compression_flutter.dart';

const Configuration config =
    Configuration(outputType: ImageOutputType.webpThenJpg, quality: 40);
const XTypeGroup typeGroup = XTypeGroup(
  label: 'images',
  extensions: <String>['jpg', 'png'],
);
// ignore: non_constant_identifier_names
final DEFAULT_AVATAR =
    FileImage(File('./assets/images/genshin_impact_icon.jpg'));

/// 获取本地的图片，如果成功，则返回
/// 图片，图片名称，图片扩展名
Future<(FileImage?, String, String)> getLocalImg() async {
  debugPrint('try get img');
  final XFile? file =
      await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
  if (file == null) return (null, '', '');
  var path = file.path;
  // debugPrint(bytes.toString());
  return (
    FileImage(File(path)),
    p.basenameWithoutExtension(path),
    p.extension(path),
  );
}

Future<FileImage?> openLocalImg(String path) async {
  return FileImage(File(path));
}

// 将图片文件转换为base64编码的字符串
Future<String> fileImgToBase64String(FileImage? fileImg) async {
  if (fileImg != null) {
    return fileImgToByte(fileImg).then((bytes) {
      String base64String = base64Encode(bytes!);
      return base64String;
    });
  }
  return "";
}

// 将图片文件转换为byte数组
Future<Uint8List?> fileImgToByte(FileImage? fileImg) async {
  if (fileImg != null) {
    String filePath = fileImg.file.path;
    Uint8List bytes = await File(filePath).readAsBytes();
    return bytes;
  }
  return null;
}

Future<Image> fileImgToImg(FileImage fileImage) async {
  String base64String = "";
  fileImgToBase64String(fileImage).then((result) => base64String = result);
  Uint8List bytes = base64Decode(base64String);
  return Image.memory(bytes);
}

// 将字节流保存为图片文件
Future<String> saveImageWithString(String base64Img, String fileName) async {
  Uint8List bytes = base64Decode(base64Img);
  String filePath = './lib/store/avatars/$fileName';
  // debugPrint('filePath: $filePath');
  createFileIfNotExist(filePath);
  File file = File(filePath);
  await file.writeAsBytes(bytes);
  return filePath;
}

Future<String> saveImageWithU8(Uint8List u8Img, String fileName) async {
  String filePath = './lib/store/avatars/$fileName';
  // debugPrint('filePath: $filePath');
  createFileIfNotExist(filePath);
  File file = File(filePath);
  await file.writeAsBytes(u8Img);
  return filePath;
}

Future<FileImage> base64ToFileImage(
  String base64Img,
  String path,
) async {
  Uint8List bytes = base64.decode(base64Img);
  clientData.user!.u8Avatar = bytes;
  // var fileImg = FileImage(File.fromRawPath(bytes));
  File savedImg = File(path);
  await savedImg.writeAsBytes(bytes);
  return FileImage(savedImg);
}



// Future<FileImage> findAvatarById(int id) async{}



// Future<FileImage> imageCompressor(FileImage imgInput) async {
//   imgInput.file.readAsBytes().then((bytes){
//     var imageFile = ImageFile(filePath: imgInput.file.path, rawBytes: bytes);
//     final param = ImageFileConfiguration(input: imageFile, config: config);
//     final imgOutput = compressor.compress(param);
//   });
// }
