class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'user' | 'superuser'
  final List<String> assignedCategories;
  final String facilityId;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.assignedCategories,
    required this.facilityId,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'user',
      assignedCategories: List<String>.from(data['assignedCategories'] ?? []),
      facilityId: data['facilityId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'assignedCategories': assignedCategories,
      'facilityId': facilityId,
    };
  }
}
