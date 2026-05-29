import 'package:cloud_firestore/cloud_firestore.dart';

class MigrationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> migrateToFacility(String facilityId) async {
    final collections = ['counts', 'prices', 'ssr_baseline'];
    
    for (final collection in collections) {
      final snapshot = await _db.collection(collection).get();
      final batch = _db.batch();
      
      for (final doc in snapshot.docs) {
        // Only update if facilityId is missing
        if (!doc.data().containsKey('facilityId')) {
          batch.update(doc.reference, {'facilityId': facilityId});
        }
      }
      await batch.commit();
    }
  }
}
