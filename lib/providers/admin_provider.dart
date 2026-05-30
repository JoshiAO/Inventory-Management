import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/user_model.dart';
import '../data/models/facility_model.dart';
import '../data/repositories/admin_repository.dart';

import 'base_provider.dart';

class AdminProvider extends BaseProvider {
  final AdminRepository _repository = AdminRepository();
  List<UserModel> _users = [];
  List<Facility> _facilities = [];

  List<UserModel> get users => _users;
  List<Facility> get facilities => _facilities;

  Future<List<String>> getCategories() async {
    final snapshot = await _repository.getCategoriesSnapshot();
    return snapshot.docs.map((doc) => doc['name'] as String).toList();
  }

  AdminProvider() {
    _repository.getUsersStream().listen((userList) {
      _users = userList;
      notifyListeners();
    });
    _repository.getFacilitiesStream().listen((facilityList) {
      _facilities = facilityList;
      notifyListeners();
    });
  }

  Future<void> addFacility(String name, String location) async {
    await performTask(() => _repository.addFacility(name, location));
  }

  Future<void> createUser(String email, String password, String name, String role, List<String> categories, String facilityId) async {
    await performTask(() => _repository.createUser(email, password, name, role, categories, facilityId));
  }

  Future<void> updateUserProfile(UserModel user) async {
    await performTask(() => _repository.updateUserProfile(user));
  }

  Future<void> deleteUser(String uid) async {
    await _repository.deleteUserRecord(uid);
  }

  Future<void> clearSystemData({String? facilityId}) async {
    await performTask(() async {
      await _repository.clearCollection('counts', facilityId: facilityId);
      await _repository.clearCollection('ssr_baseline', facilityId: facilityId);
    });
  }

  Future<void> clearItemMaster({String? facilityId}) async {
    await performTask(() async {
      await _repository.clearCollection('items', facilityId: facilityId);
      await _repository.clearCollection('prices', facilityId: facilityId);
    });
  }

  Future<void> uploadInventoryData(String type, List<Map<String, dynamic>> data, {String? facilityId}) async {
    await performTask(() => _repository.uploadInventoryData(type, data, facilityId: facilityId));
  }

  Future<void> sendResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }
}
