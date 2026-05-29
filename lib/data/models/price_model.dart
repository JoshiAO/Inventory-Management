class PriceList {
  final String itemCode;
  final String itemName;
  final double priceCase;
  final double priceSubcase;
  final double pricePiece;
  final String facilityId;

  PriceList({
    required this.itemCode,
    required this.itemName,
    required this.priceCase,
    required this.priceSubcase,
    required this.pricePiece,
    required this.facilityId,
  });

  factory PriceList.fromFirestore(Map<String, dynamic> data) {
    return PriceList(
      itemCode: data['item_code'] ?? '',
      itemName: data['item_name'] ?? '',
      priceCase: (data['Case'] ?? 0.0).toDouble(),
      priceSubcase: (data['Subcase'] ?? 0.0).toDouble(),
      pricePiece: (data['Piece'] ?? 0.0).toDouble(),
      facilityId: data['facilityId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'item_code': itemCode,
      'item_name': itemName,
      'Case': priceCase,
      'Subcase': priceSubcase,
      'Piece': pricePiece,
      'facilityId': facilityId,
    };
  }
}
