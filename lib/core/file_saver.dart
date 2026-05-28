import 'dart:typed_data';
import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart';

Future<String> saveBytes(Uint8List bytes, String fileName) => saveBytesImpl(bytes, fileName);
