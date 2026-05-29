import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  UserModel? _userModel;
  bool _isLoading = false;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _authRepository.userStream.listen((User? user) async {
      if (user != null) {
        _userModel = await _authRepository.getUserData(user.uid);
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authRepository.signIn(email, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password, String name, String role, List<String> categories, String facilityId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authRepository.signUp(email, password, name, role, categories, facilityId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setupAdmin(String email, String password, String facilityId) async {
    _isLoading = true;
    notifyListeners();
    try {
      try {
        await _authRepository.signUp(email, password, 'Administrator', 'superuser', ['ALL'], facilityId);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // If already exists in Auth, try to sign in and force create Firestore doc
          final creds = await _authRepository.signIn(email, password);
          await _authRepository.createFirestoreUser(creds.user!.uid, email, 'Administrator', 'superuser', ['ALL'], facilityId);

          // Manually trigger a data reload if sign-in succeeded
          _userModel = await _authRepository.getUserData(creds.user!.uid);
          notifyListeners();
        } else {
          rethrow;
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authRepository.signOut();
  }

  Future<void> changePassword(String newPassword) async {
    await _authRepository.updatePassword(newPassword);
  }

  Future<void> resetPassword(String email) async {
    await _authRepository.sendPasswordResetEmail(email);
  }
}
