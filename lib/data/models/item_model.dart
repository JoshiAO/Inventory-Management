class ItemModel {
  final String skuCode;
  final String itemCode;
  final String itemName;
  final String category;
  final String imageUrl;
  final ItemPrices prices;

  ItemModel({
    required this.skuCode,
    required this.itemCode,
    required this.itemName,
    required this.category,
    required this.imageUrl,
    required this.prices,
  });

  factory ItemModel.fromFirestore(Map<String, dynamic> data) {
    return ItemModel(
      skuCode: data['skuCode'] ?? '',
      itemCode: data['itemCode'] ?? '',
      itemName: data['itemName'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      prices: ItemPrices.fromMap(data['prices'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'skuCode': skuCode,
      'itemCode': itemCode,
      'itemName': itemName,
      'category': category,
      'imageUrl': imageUrl,
      'prices': prices.toMap(),
    };
  }
}

class ItemPrices {
  final double priceCase;
  final double priceSubcase;
  final double pricePiece;

  ItemPrices({
    required this.priceCase,
    required this.priceSubcase,
    required this.pricePiece,
  });

  factory ItemPrices.fromMap(Map<String, dynamic> data) {
    return ItemPrices(
      priceCase: (data['case'] ?? 0.0).toDouble(),
      priceSubcase: (data['subcase'] ?? 0.0).toDouble(),
      pricePiece: (data['piece'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'case': priceCase,
      'subcase': priceSubcase,
      'piece': pricePiece,
    };
  }
}
