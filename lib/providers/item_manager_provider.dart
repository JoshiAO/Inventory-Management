import '../data/models/item_model.dart';
import '../data/models/price_model.dart';
import '../data/models/ssr_baseline_model.dart';
import '../data/models/count_model.dart';
import '../data/models/merged_item_model.dart';
import '../data/repositories/count_repository.dart';
import 'base_provider.dart';

class ItemManagerProvider extends BaseProvider {
  final CountRepository _repository = CountRepository();

  List<MergedItem> _mergedItems = [];
  List<String> _categories = ['ALL'];
  String _selectedCategory = 'ALL';
  String _searchQuery = "";
  bool _showOnlyWithSSR = false;

  List<MergedItem> get items {
    final query = _searchQuery.toLowerCase();
    return _mergedItems.where((item) {
      final matchesCategory = _selectedCategory == 'ALL' || item.master.category == _selectedCategory;
      final matchesSearch = item.master.itemName.toLowerCase().contains(query) ||
                            item.master.itemCode.toLowerCase().contains(query);
      final hasSSR = item.ssr != null && (item.ssr!.ssrCase > 0 || item.ssr!.ssrSubcase > 0 || item.ssr!.ssrPiece > 0);
      final matchesSSRFilter = !_showOnlyWithSSR || hasSSR;

      return matchesCategory && matchesSearch && matchesSSRFilter;
    }).toList();
  }

  bool get showOnlyWithSSR => _showOnlyWithSSR;

  void toggleSSRFilter(bool value) {
    _showOnlyWithSSR = value;
    notifyListeners();
  }

  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;

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
    await performTask(() async {
      final masters = await _repository.getItemsByCategory('ALL');
      final prices = await _repository.getPricesByFacility(facilityId);
      final baselines = await _repository.getSsrBaselinesByFacility(facilityId);
      final counts = await _repository.getRecentCountsByFacility(facilityId);

      // Collect all unique item codes across Master, Prices, and SSR
      final allCodes = {
        ...masters.map((m) => m.itemCode),
        ...prices.map((p) => p.itemCode),
        ...baselines.map((b) => b.itemCode),
      };

      if (allCodes.isEmpty) {
        _mergedItems = [];
        _categories = ['ALL'];
        return;
      }

      // Extract categories from masters
      _categories = ['ALL', ...masters.map((m) => m.category).where((c) => c.isNotEmpty).toSet().toList()];

      // Merge data
      _mergedItems = allCodes.map((code) {
        final m = masters.firstWhere(
          (m) => m.itemCode == code, 
          orElse: () => ItemMaster(itemCode: code, itemName: code, category: 'Uncategorized')
        );
        
        final price = prices.firstWhere(
          (p) => p.itemCode == code, 
          orElse: () => PriceList(itemCode: code, itemName: m.itemName, priceCase: 0, priceSubcase: 0, pricePiece: 0, facilityId: facilityId)
        );
        
        final ssr = baselines.firstWhere(
          (b) => b.itemCode == code, 
          orElse: () => SsrBaseline(itemCode: code, itemName: m.itemName, ssrCase: 0, ssrSubcase: 0, ssrPiece: 0, facilityId: facilityId)
        );
        
        CountModel? latestCount;
        try {
          latestCount = counts.firstWhere((c) => c.productCode == code);
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
    });
  }
}
