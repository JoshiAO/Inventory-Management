import '../data/models/item_model.dart';
import '../data/models/count_model.dart';
import '../data/models/ssr_baseline_model.dart';
import '../data/repositories/count_repository.dart';
import '../data/repositories/storage_repository.dart';
import 'base_provider.dart';

class CountProvider extends BaseProvider {
  final CountRepository _repository = CountRepository();
  final StorageRepository _storageRepository = StorageRepository();
  
  List<ItemMaster> _items = [];
  List<SsrBaseline> _baselines = [];
  final Map<String, CountModel> _draftCounts = {}; 
  String _searchQuery = "";
  bool _showOnlyWithSSR = false;

  List<ItemMaster> get items {
    final query = _searchQuery.toLowerCase();
    return _items.where((item) {
      final matchesSearch = item.itemName.toLowerCase().contains(query) ||
                            item.itemCode.toLowerCase().contains(query);
      
      final baseline = _baselines.firstWhere((b) => b.itemCode == item.itemCode, orElse: () => SsrBaseline(itemCode: item.itemCode, itemName: '', ssrCase: 0, ssrSubcase: 0, ssrPiece: 0, facilityId: ''));
      final hasSSR = baseline.ssrCase > 0 || baseline.ssrSubcase > 0 || baseline.ssrPiece > 0;
      final matchesSSRFilter = !_showOnlyWithSSR || hasSSR;

      return matchesSearch && matchesSSRFilter;
    }).toList();
  }

  bool get showOnlyWithSSR => _showOnlyWithSSR;

  void toggleSSRFilter(bool value) {
    _showOnlyWithSSR = value;
    notifyListeners();
  }

  void updateSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadItems(List<String> categories, String facilityId) async {
    await performTask(() async {
      List<ItemMaster> allItems = [];
      for (var cat in categories) {
        final catItems = await _repository.getItemsByCategory(cat);
        allItems.addAll(catItems);
      }
      _items = allItems;
      _baselines = await _repository.getSsrBaselinesByFacility(facilityId);
    });
  }

  void updateDraftCount(String productCode, CountModel count) {
    _draftCounts[productCode] = count;
    notifyListeners();
  }

  CountModel? getDraft(String productCode) => _draftCounts[productCode];

  Future<void> uploadCounts() async {
    await performTask(() async {
      for (var productCode in _draftCounts.keys) {
        final count = _draftCounts[productCode]!;
        if (count.isUploaded) continue; // Skip already uploaded

        final uploadedUrls = await _storageRepository.uploadMultipleFiles(
          'inventory_photos/${count.productCode}/${count.userId}', 
          count.localImagePaths
        );

        String? finalProfileUrl = count.profileImageUrl;
        
        // If profile image was a local path, find its new URL
        if (count.profileImageUrl != null && !count.profileImageUrl!.startsWith('http')) {
          final index = count.localImagePaths.indexOf(count.profileImageUrl!);
          if (index != -1 && index < uploadedUrls.length) {
            finalProfileUrl = uploadedUrls[index];
          }
        }

        final finalCount = count.copyWith(
          images: [...count.images, ...uploadedUrls],
          localImagePaths: [],
          profileImageUrl: finalProfileUrl,
          isUploaded: true,
        );

        await _repository.saveCount(finalCount);

        // Update Item Master Profile if set
        if (finalProfileUrl != null) {
          await _repository.updateItemProfileImage(count.productCode, finalProfileUrl);
        }

        // Update the draft in memory instead of clearing it
        _draftCounts[productCode] = finalCount;
      }
    });
  }
}
