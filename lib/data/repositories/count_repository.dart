import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';
import '../models/price_model.dart';
import '../models/ssr_baseline_model.dart';
import '../models/count_model.dart';

class CountRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch items by category (Item Master)
  Future<List<ItemMaster>> getItemsByCategory(String category) async {
    try {
      Query query = _db.collection('items');
      if (category != 'ALL') {
        query = query.where('category', isEqualTo: category);
      }
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => ItemMaster.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Fetch all PriceList for a facility
  Future<List<PriceList>> getPricesByFacility(String facilityId) async {
    final snapshot = await _db.collection('prices').where('facilityId', isEqualTo: facilityId).get();
    return snapshot.docs.map((doc) => PriceList.fromFirestore(doc.data())).toList();
  }

  // Fetch all SSR Baseline for a facility
  Future<List<SsrBaseline>> getSsrBaselinesByFacility(String facilityId) async {
    final snapshot = await _db.collection('ssr_baseline').where('facilityId', isEqualTo: facilityId).get();
    return snapshot.docs.map((doc) => SsrBaseline.fromFirestore(doc.data())).toList();
  }

  // Fetch all recent Counts for a facility
  Future<List<CountModel>> getRecentCountsByFacility(String facilityId) async {
    final snapshot = await _db.collection('counts').where('facilityId', isEqualTo: facilityId).orderBy('timestamp', descending: true).get();
    return snapshot.docs.map((doc) => CountModel.fromFirestore(doc.data(), doc.id)).toList();
  }

  // Save/Upload a count record
  Future<void> saveCount(CountModel count) async {
    try {
      await _db.collection('counts').add(count.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
}
