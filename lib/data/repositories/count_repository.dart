import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';
import '../models/count_model.dart';

class CountRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch items by category
  Future<List<ItemModel>> getItemsByCategory(String category) async {
    try {
      final querySnapshot = await _db
          .collection('items')
          .where('category', isEqualTo: category)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ItemModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
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
