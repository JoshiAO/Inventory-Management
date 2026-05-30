import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../core/discrepancy_service.dart';

import 'base_provider.dart';

class DashboardProvider extends BaseProvider {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DiscrepancyService _discrepancyService = DiscrepancyService();

  int _totalItems = 0;
  int _discrepanciesCount = 0;
  int _activeCounts = 0;
  
  // Chart Data
  Map<String, double> _categoryDiscrepancies = {};
  Map<String, int> _statusCounts = {'Balanced': 0, 'Over': 0, 'Short': 0};
  int _itemsCounted = 0;
  int _itemsPending = 0;

  int get totalItems => _totalItems;
  int get discrepanciesCount => _discrepanciesCount;
  int get activeCounts => _activeCounts;
  
  Map<String, double> get categoryDiscrepancies => _categoryDiscrepancies;
  Map<String, int> get statusCounts => _statusCounts;
  int get itemsCounted => _itemsCounted;
  int get itemsPending => _itemsPending;

  Future<void> loadMetrics(String facilityId) async {
    await performTask(() async {
      // 1. Global Item Master count
      final itemsSnapshot = await _db.collection('items').get();
      _totalItems = itemsSnapshot.size;

      // 2. Facility-specific counts
      final countsSnapshot = await _db.collection('counts').doc(facilityId).collection('records').get();
      _activeCounts = countsSnapshot.size;

      // 3. Discrepancy Records (Already filtered by facilityId in service)
      final records = await _discrepancyService.fetchActualCountRecords(facilityId);
      
      // 4. Calculations & Aggregations
      _discrepanciesCount = records.where((r) => r.status != 'Balanced').length;
      
      _categoryDiscrepancies = {};
      _statusCounts = {'Balanced': 0, 'Over': 0, 'Short': 0};
      
      for (var r in records) {
        // We sum the absolute value of discrepancy per category for the bar chart
        _categoryDiscrepancies[r.category] = (_categoryDiscrepancies[r.category] ?? 0) + r.discrepancyValue.abs();
        _statusCounts[r.status] = (_statusCounts[r.status] ?? 0) + 1;
      }

      _itemsCounted = records.length;
      _itemsPending = max(0, _totalItems - _itemsCounted);
    });
  }
}
