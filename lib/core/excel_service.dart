import 'dart:typed_data';
import 'package:excel/excel.dart';

class ExcelService {
  /// Parses an Item Master XLSX file.
  /// Expects columns: SKU, Item Code, Item Name, Category, Price Case, Price Subcase, Price Piece
  static List<Map<String, dynamic>> parseItemMaster(Uint8List bytes) {
    var excel = Excel.decodeBytes(bytes);
    List<Map<String, dynamic>> items = [];

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table]!;
      // Skip header row
      for (int i = 1; i < sheet.maxRows; i++) {
        var row = sheet.rows[i];
        if (row.isEmpty) continue;

        items.add({
          'skuCode': row[0]?.value?.toString() ?? '',
          'itemCode': row[1]?.value?.toString() ?? '',
          'itemName': row[2]?.value?.toString() ?? '',
          'category': row[3]?.value?.toString() ?? '',
          'prices': {
            'case': double.tryParse(row[4]?.value?.toString() ?? '0') ?? 0.0,
            'subcase': double.tryParse(row[5]?.value?.toString() ?? '0') ?? 0.0,
            'piece': double.tryParse(row[6]?.value?.toString() ?? '0') ?? 0.0,
          },
        });
      }
    }
    return items;
  }

  /// Parses an SSR (Stock Status Report) XLSX file.
  /// Expects columns: Item Code, Category, SSR Quantity
  static List<Map<String, dynamic>> parseSSR(Uint8List bytes) {
    var excel = Excel.decodeBytes(bytes);
    List<Map<String, dynamic>> ssrData = [];

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table]!;
      for (int i = 1; i < sheet.maxRows; i++) {
        var row = sheet.rows[i];
        if (row.isEmpty) continue;

        ssrData.add({
          'itemCode': row[0]?.value?.toString() ?? '',
          'category': row[1]?.value?.toString() ?? '',
          'ssrQty': int.tryParse(row[2]?.value?.toString() ?? '0') ?? 0,
        });
      }
    }
    return ssrData;
  }
}
