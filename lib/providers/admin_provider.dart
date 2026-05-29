import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/user_model.dart';
import '../data/models/facility_model.dart';
import '../data/repositories/admin_repository.dart';

class AdminProvider with ChangeNotifier {
  final AdminRepository _repository = AdminRepository();
  List<UserModel> _users = [];
  List<Facility> _facilities = [];
  bool _isLoading = false;

  List<UserModel> get users => _users;
  List<Facility> get facilities => _facilities;
  bool get isLoading => _isLoading;

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
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.addFacility(name, location);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createUser(String email, String password, String name, String role, List<String> categories, String facilityId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.createUser(email, password, name, role, categories, facilityId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.updateUserProfile(user);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(String uid) async {
    await _repository.deleteUserRecord(uid);
  }

  Future<void> clearSystemData({String? facilityId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Clear all transaction data to start a new cycle, optionally scoped
      await _repository.clearCollection('counts', facilityId: facilityId);
      await _repository.clearCollection('ssr_baseline', facilityId: facilityId);
      // Note: We usually keep 'users' and 'items' (Item Master) unless specifically requested
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearItemMaster({String? facilityId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.clearCollection('items', facilityId: facilityId);
      await _repository.clearCollection('prices', facilityId: facilityId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadInventoryData(String type, List<Map<String, dynamic>> data, {String? facilityId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.uploadInventoryData(type, data, facilityId: facilityId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }
}
