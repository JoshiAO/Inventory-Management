class SsrBaseline {
  final String itemCode;
  final String itemName;
  final int ssrCase;
  final int ssrSubcase;
  final int ssrPiece;
  final String facilityId;

  SsrBaseline({
    required this.itemCode,
    required this.itemName,
    required this.ssrCase,
    required this.ssrSubcase,
    required this.ssrPiece,
    required this.facilityId,
  });

  factory SsrBaseline.fromFirestore(Map<String, dynamic> data) {
    return SsrBaseline(
      itemCode: data['item_code'] ?? '',
      itemName: data['item_name'] ?? '',
      ssrCase: (data['Case'] ?? 0).toInt(),
      ssrSubcase: (data['Subcase'] ?? 0).toInt(),
      ssrPiece: (data['Piece'] ?? 0).toInt(),
      facilityId: data['facilityId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'item_code': itemCode,
      'item_name': itemName,
      'Case': ssrCase,
      'Subcase': ssrSubcase,
      'Piece': ssrPiece,
      'facilityId': facilityId,
    };
  }
}
