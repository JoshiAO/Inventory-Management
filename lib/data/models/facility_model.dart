class Facility {
  final String id;
  final String name;
  final String location;

  Facility({
    required this.id,
    required this.name,
    required this.location,
  });

  factory Facility.fromFirestore(Map<String, dynamic> data, String docId) {
    return Facility(
      id: docId,
      name: data['name'] ?? '',
      location: data['location'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'location': location,
    };
  }
}
