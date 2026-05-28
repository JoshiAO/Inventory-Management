import 'package:flutter/material.dart';
import '../data/models/item_model.dart';
import '../data/models/count_model.dart';
import '../data/repositories/count_repository.dart';

class CountProvider with ChangeNotifier {
  final CountRepository _repository = CountRepository();
  
  List<ItemModel> _items = [];
  Map<String, CountModel> _draftCounts = {}; // productCode -> CountModel
  bool _isLoading = false;
  String _searchQuery = "";

  List<ItemModel> get items => _items.where((item) {
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
        await _repository.saveCount(count);
      }
      _draftCounts.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
