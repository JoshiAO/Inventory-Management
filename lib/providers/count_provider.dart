import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../data/models/item_model.dart';
import '../data/models/count_model.dart';
import '../data/repositories/count_repository.dart';

class CountProvider with ChangeNotifier {
  final CountRepository _repository = CountRepository();
  
  List<ItemMaster> _items = [];
  Map<String, CountModel> _draftCounts = {}; // productCode -> CountModel
  bool _isLoading = false;
  String _searchQuery = "";

  List<ItemMaster> get items => _items.where((item) {
    return item.itemName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
           item.itemCode.toLowerCase().contains(_searchQuery.toLowerCase());
  }).toList();

  bool get isLoading => _isLoading;

  void updateSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadItems(String category) async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await _repository.getItemsByCategory(category);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateDraftCount(String productCode, CountModel count) {
    _draftCounts[productCode] = count;
    notifyListeners();
  }

  CountModel? getDraft(String productCode) => _draftCounts[productCode];

  Future<void> uploadCounts() async {
    _isLoading = true;
    notifyListeners();
    try {
      for (var count in _draftCounts.values) {
        // Upload images if local paths exist
        List<String> uploadedUrls = List.from(count.images);
        for (var localPath in count.localImagePaths) {
          final file = File(localPath);
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('inventory_photos/${count.productCode}/${count.userId}/${DateTime.now().millisecondsSinceEpoch}.jpg');
          
          final task = await storageRef.putFile(file);
          final downloadUrl = await task.ref.getDownloadURL();
          uploadedUrls.add(downloadUrl);
        }

        final finalCount = CountModel(
          id: count.id,
          timestamp: count.timestamp,
          userId: count.userId,
          category: count.category,
          productCode: count.productCode,
          facilityId: count.facilityId,
          quantities: count.quantities,
          images: uploadedUrls,
          localImagePaths: [],
          isUploaded: true,
        );

        await _repository.saveCount(finalCount);
      }
      _draftCounts.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
