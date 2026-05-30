import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';
import '../models/facility_model.dart';

class AdminRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch all users
  Stream<List<UserModel>> getUsersStream() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    });
  }

  Future<QuerySnapshot> getCategoriesSnapshot() async {
    return await _db.collection('categories').get();
  }

  // Facility management
  Stream<List<Facility>> getFacilitiesStream() {
    return _db.collection('facilities').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Facility.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> addFacility(String name, String location) async {
    await _db.collection('facilities').add({
      'name': name,
      'location': location,
    });
  }

  // Create a New User (Auth + Firestore)
  Future<void> createUser(String email, String password, String name, String role, List<String> categories, String facilityId) async {
    // We use a temporary secondary app instance to create users without logging out the admin
    FirebaseApp tempApp = await Firebase.initializeApp(
      name: 'TempApp',
      options: Firebase.app().options,
    );
    
    try {
      UserCredential creds = await FirebaseAuth.instanceFor(app: tempApp).createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userModel = UserModel(
        uid: creds.user!.uid,
        email: email,
        name: name,
        role: role,
        assignedCategories: categories,
        facilityId: facilityId,
      );

      await _db.collection('users').doc(creds.user!.uid).set(userModel.toMap());
    } finally {
      await tempApp.delete();
    }
  }

  // Update existing Firestore profile
  Future<void> updateUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.uid).update(user.toMap());
  }

  // Delete User record
  Future<void> deleteUserRecord(String uid) async {
    try {
      await _db.collection('users').doc(uid).delete();
      // Note: Full deletion of Auth user usually requires admin SDK or Cloud Function
    } catch (e) {
      rethrow;
    }
  }

  // Clear documents in a collection (optionally scoped to facility)
  Future<void> clearCollection(String collectionName, {String? facilityId}) async {
    try {
      final isGlobal = collectionName == 'items' || collectionName == 'categories';
      Query query;
      
      if (isGlobal) {
        query = _db.collection(collectionName);
      } else {
        if (facilityId == null) throw Exception('Facility ID is required for clearing $collectionName');
        query = _db.collection(collectionName).doc(facilityId).collection('records');
      }
      
      final snapshot = await query.get();
      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  // Upload logic (SSR, Price List, Item Master, Categories)
  Future<void> uploadInventoryData(String type, List<Map<String, dynamic>> data, {String? facilityId}) async {
    try {
      const typeToCollection = {
        'SSR': 'ssr_baseline',
        'Price List': 'prices',
        'Categories': 'categories',
      };
      
      final collection = typeToCollection[type] ?? 'items';
      final isGlobal = collection == 'items' || collection == 'categories';

      if (!isGlobal && facilityId == null) {
        throw Exception('Facility ID is required for $type upload');
      }
      
      final batch = _db.batch();
      final targetRef = isGlobal 
          ? _db.collection(collection) 
          : _db.collection(collection).doc(facilityId).collection('records');

      for (var item in data) {
        // We no longer need to store facilityId inside the document for nested structure
        final docId = item['item_code']?.toString() ?? _db.collection(collection).doc().id;
        final docRef = targetRef.doc(docId);
        batch.set(docRef, item);
      }
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }
}
