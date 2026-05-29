class ItemMaster {
  final String itemCode;
  final String itemName;
  final String category;

  ItemMaster({
    required this.itemCode,
    required this.itemName,
    required this.category,
  });

  factory ItemMaster.fromFirestore(Map<String, dynamic> data) {
    return ItemMaster(
      itemCode: data['item_code'] ?? '',
      itemName: data['item_name'] ?? '',
      category: data['category'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'item_code': itemCode,
      'item_name': itemName,
      'category': category,
    };
  }
}
