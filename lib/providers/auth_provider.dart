import 'package:firebase_auth/firebase_auth.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/user_model.dart';

import 'base_provider.dart';

class AuthProvider extends BaseProvider {
  final AuthRepository _authRepository = AuthRepository();
  UserModel? _userModel;

  UserModel? get userModel => _userModel;

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
    await performTask(() => _authRepository.signIn(email, password));
  }

  Future<void> register(String email, String password, String name, String role, List<String> categories, String facilityId) async {
    await performTask(() => _authRepository.signUp(email, password, name, role, categories, facilityId));
  }

  Future<void> setupAdmin(String email, String password, String facilityId) async {
    await performTask(() async {
      try {
        await _authRepository.signUp(email, password, 'Administrator', 'superuser', ['ALL'], facilityId);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          final creds = await _authRepository.signIn(email, password);
          await _authRepository.createFirestoreUser(creds.user!.uid, email, 'Administrator', 'superuser', ['ALL'], facilityId);

          _userModel = await _authRepository.getUserData(creds.user!.uid);
          notifyListeners();
        } else {
          rethrow;
        }
      }
    });
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
