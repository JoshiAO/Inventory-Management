import 'dart:typed_data';
import 'dart:io';

Future<String> saveBytesImpl(Uint8List bytes, String fileName) async {
  final tempDir = Directory.systemTemp.createTempSync('inventory_count_app_');
  final file = File('${tempDir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes);
  return file.path;
}
