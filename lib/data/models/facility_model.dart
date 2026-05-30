class Facility {
  final String id;
  final String name;
  final String location;

  Facility({
    required this.id,
    required this.name,
    required this.location,
  });

  factory Facility.fromMap(Map<String, dynamic> data, String docId) {
    return Facility(
      id: docId,
      name: data['name'] ?? '',
      location: data['location'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
    };
  }
}
