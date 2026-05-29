import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/discrepancy_service.dart';

class DashboardProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DiscrepancyService _discrepancyService = DiscrepancyService();

  int _totalItems = 0;
  int _discrepanciesCount = 0;
  int _activeCounts = 0;
  bool _isLoading = false;

  int get totalItems => _totalItems;
  int get discrepanciesCount => _discrepanciesCount;
  int get activeCounts => _activeCounts;
  bool get isLoading => _isLoading;

  DashboardProvider() {
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    _isLoading = true;
    notifyListeners();

    try {
      final itemsSnapshot = await _db.collection('items').get();
      _totalItems = itemsSnapshot.size;

      final countsSnapshot = await _db.collection('counts').get();
      _activeCounts = countsSnapshot.size;

      final records = await _discrepancyService.fetchActualCountRecords();
      _discrepanciesCount = records.where((r) => r.status != 'Balanced').length;
    } catch (e) {
      debugPrint('Error loading dashboard metrics: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
