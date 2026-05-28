class UserModel {
  final String uid;
  final String email;
  final String role; // 'user' | 'superuser'
  final String assignedCategory;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.assignedCategory,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      assignedCategory: data['assignedCategory'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'assignedCategory': assignedCategory,
    };
  }
}
