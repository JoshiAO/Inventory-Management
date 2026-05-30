class ItemMaster {
  final String itemCode;
  final String itemName;
  final String category;
  final String? imageUrl;

  ItemMaster({
    required this.itemCode,
    required this.itemName,
    required this.category,
    this.imageUrl,
  });

  factory ItemMaster.fromMap(Map<String, dynamic> data) {
    return ItemMaster(
      itemCode: data['item_code'] ?? '',
      itemName: data['item_name'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item_code': itemCode,
      'item_name': itemName,
      'category': category,
      'imageUrl': imageUrl,
    };
  }
}
