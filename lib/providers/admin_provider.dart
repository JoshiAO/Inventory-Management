import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/repositories/admin_repository.dart';

class AdminProvider with ChangeNotifier {
  final AdminRepository _repository = AdminRepository();
  List<UserModel> _users = [];
  bool _isLoading = false;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;

  AdminProvider() {
    _repository.getUsersStream().listen((userList) {
      _users = userList;
      notifyListeners();
    });
  }

  Future<void> saveUser(UserModel user) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.saveUserRecord(user);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(String uid) async {
    await _repository.deleteUserRecord(uid);
  }

  Future<void> clearSystemData() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Clear all transaction data to start a new cycle
      await _repository.clearCollection('counts');
      await _repository.clearCollection('ssr_baseline');
      // Note: We usually keep 'users' and 'items' (Item Master) unless specifically requested
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearItemMaster() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.clearCollection('items');
      await _repository.clearCollection('prices');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadInventoryData(String type, List<Map<String, dynamic>> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.uploadInventoryData(type, data);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
