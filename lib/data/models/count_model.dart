import 'package:cloud_firestore/cloud_firestore.dart';

class CountModel {
  final String id;
  final DateTime timestamp;
  final String userId;
  final String category;
  final String productCode;
  final String facilityId;
  final CountQuantities quantities;
  final List<String> images; // Remote URLs
  final List<String> localImagePaths; // Local file paths
  final String? profileImageUrl;
  final bool isUploaded;

  CountModel({
    required this.id,
    required this.timestamp,
    required this.userId,
    required this.category,
    required this.productCode,
    required this.facilityId,
    required this.quantities,
    required this.images,
    required this.localImagePaths,
    required this.isUploaded,
    this.profileImageUrl,
  });

  factory CountModel.fromMap(Map<String, dynamic> data, String docId) {
    return CountModel(
      id: docId,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      category: data['category'] ?? '',
      productCode: data['productCode'] ?? '',
      facilityId: data['facilityId'] ?? '',
      quantities: CountQuantities.fromMap(data['quantities'] ?? {}),
      images: List<String>.from(data['images'] ?? []),
      localImagePaths: [],
      profileImageUrl: data['profileImageUrl'],
      isUploaded: data['isUploaded'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'userId': userId,
      'category': category,
      'productCode': productCode,
      'facilityId': facilityId,
      'quantities': quantities.toMap(),
      'images': images,
      'profileImageUrl': profileImageUrl,
      'isUploaded': isUploaded,
    };
  }

  CountModel copyWith({
    String? id,
    DateTime? timestamp,
    String? userId,
    String? category,
    String? productCode,
    String? facilityId,
    CountQuantities? quantities,
    List<String>? images,
    List<String>? localImagePaths,
    String? profileImageUrl,
    bool? isUploaded,
  }) {
    return CountModel(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      productCode: productCode ?? this.productCode,
      facilityId: facilityId ?? this.facilityId,
      quantities: quantities ?? this.quantities,
      images: images ?? this.images,
      localImagePaths: localImagePaths ?? this.localImagePaths,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isUploaded: isUploaded ?? this.isUploaded,
    );
  }
}

class CountQuantities {
  final int countCase;
  final int countSubcase;
  final int countPiece;

  CountQuantities({
    required this.countCase,
    required this.countSubcase,
    required this.countPiece,
  });

  factory CountQuantities.fromMap(Map<String, dynamic> data) {
    return CountQuantities(
      countCase: (data['case'] ?? 0).toInt(),
      countSubcase: (data['subcase'] ?? 0).toInt(),
      countPiece: (data['piece'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'case': countCase,
      'subcase': countSubcase,
      'piece': countPiece,
    };
  }
}
