import 'package:flutter/material.dart';
import '../data/models/item_model.dart';
import '../data/models/price_model.dart';
import '../data/models/ssr_baseline_model.dart';
import '../data/models/count_model.dart';
import '../data/models/merged_item_model.dart';
import '../data/repositories/count_repository.dart';

class ItemManagerProvider with ChangeNotifier {
  final CountRepository _repository = CountRepository();

  List<MergedItem> _mergedItems = [];
  List<String> _categories = ['ALL'];
  String _selectedCategory = 'ALL';
  String _searchQuery = "";
  bool _isLoading = false;

  List<MergedItem> get items {
    return _mergedItems.where((item) {
      final matchesCategory = _selectedCategory == 'ALL' || item.master.category == _selectedCategory;
      final matchesSearch = item.master.itemName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            item.master.itemCode.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;

  void updateSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void updateCategory(String? category) {
    if (category != null) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  Future<void> loadData(String facilityId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final masters = await _repository.getItemsByCategory('ALL');
      final prices = await _repository.getPricesByFacility(facilityId);
      final baselines = await _repository.getSsrBaselinesByFacility(facilityId);
      final counts = await _repository.getRecentCountsByFacility(facilityId);

      // Extract unique categories
      _categories = ['ALL', ...masters.map((m) => m.category).toSet().toList()];

      // Merge data
      _mergedItems = masters.map((m) {
        final price = prices.firstWhere((p) => p.itemCode == m.itemCode, orElse: () => PriceList(itemCode: m.itemCode, itemName: m.itemName, priceCase: 0, priceSubcase: 0, pricePiece: 0, facilityId: facilityId));
        final ssr = baselines.firstWhere((b) => b.itemCode == m.itemCode, orElse: () => SsrBaseline(itemCode: m.itemCode, itemName: m.itemName, ssrCase: 0, ssrSubcase: 0, ssrPiece: 0, facilityId: facilityId));
        
        // Find most recent count for this item
        CountModel? latestCount;
        try {
          latestCount = counts.firstWhere((c) => c.productCode == m.itemCode);
        } catch (_) {
          latestCount = null;
        }

        return MergedItem(
          master: m,
          price: price,
          ssr: ssr,
          count: latestCount,
        );
      }).toList();

    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
