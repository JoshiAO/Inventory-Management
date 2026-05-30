import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFile(String path, File file) async {
    final storageRef = _storage.ref().child(path);
    final uploadTask = await storageRef.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<List<String>> uploadMultipleFiles(String basePath, List<String> localPaths) async {
    final List<String> downloadUrls = [];
    for (var localPath in localPaths) {
      final file = File(localPath);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${localPath.split('/').last}';
      final url = await uploadFile('$basePath/$fileName', file);
      downloadUrls.add(url);
    }
    return downloadUrls;
  }
}
