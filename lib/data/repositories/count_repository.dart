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
          .map((doc) => ItemMaster.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Fetch all PriceList for a facility
  Future<List<PriceList>> getPricesByFacility(String facilityId) async {
    final snapshot = await _db.collection('prices').doc(facilityId).collection('records').get();
    return snapshot.docs.map((doc) => PriceList.fromMap(doc.data())).toList();
  }

  // Fetch all SSR Baseline for a facility
  Future<List<SsrBaseline>> getSsrBaselinesByFacility(String facilityId) async {
    final snapshot = await _db.collection('ssr_baseline').doc(facilityId).collection('records').get();
    return snapshot.docs.map((doc) => SsrBaseline.fromMap(doc.data())).toList();
  }

  // Fetch all recent Counts for a facility
  Future<List<CountModel>> getRecentCountsByFacility(String facilityId) async {
    final snapshot = await _db.collection('counts')
        .doc(facilityId)
        .collection('records')
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs.map((doc) => CountModel.fromMap(doc.data(), doc.id)).toList();
  }

  // Save/Upload a count record
  Future<void> saveCount(CountModel count) async {
    try {
      await _db.collection('counts')
          .doc(count.facilityId)
          .collection('records')
          .add(count.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Update Global Item Master Profile Image
  Future<void> updateItemProfileImage(String productCode, String imageUrl) async {
    try {
      await _db.collection('items').doc(productCode).update({'imageUrl': imageUrl});
    } catch (e) {
      rethrow;
    }
  }
}
