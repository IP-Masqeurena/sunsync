import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressor {
  static Future<File?> compress(File file) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      '${file.path}_compressed.jpg',
      quality: 90,
      minWidth: 300,
      minHeight: 300,
      autoCorrectionAngle: true,
      keepExif: false,
    );
    return result != null ? File(result.path) : null;
  }
}