import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AdminRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch all users
  Stream<List<UserModel>> getUsersStream() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc.data())).toList();
    });
  }

  // Create or Update User record
  Future<void> saveUserRecord(UserModel user) async {
    try {
      await _db.collection('users').doc(user.uid).set(user.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  // Delete User record
  Future<void> deleteUserRecord(String uid) async {
    try {
      await _db.collection('users').doc(uid).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Clear all documents in a collection (for reset)
  Future<void> clearCollection(String collectionName) async {
    try {
      final snapshot = await _db.collection(collectionName).get();
      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  // Placeholder for File Upload logic (SSR, Price List, Item Master)
  Future<void> uploadInventoryData(String type, List<Map<String, dynamic>> data) async {
    try {
      final batch = _db.batch();
      String collection = type == 'SSR' ? 'ssr_baseline' : (type == 'PriceList' ? 'prices' : 'items');
      
      for (var item in data) {
        final docRef = _db.collection(collection).doc();
        batch.set(docRef, item);
      }
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }
}
