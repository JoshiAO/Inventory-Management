import 'dart:typed_data';
import 'package:excel/excel.dart';

class ExcelService {
  /// Parses Item Master XLSX
  /// Expects: item_code, item_name, category
  static List<Map<String, dynamic>> parseItemMaster(Uint8List bytes) {
    var excel = Excel.decodeBytes(bytes);
    List<Map<String, dynamic>> data = [];
    var sheet = excel.tables.values.first;
    
    for (int i = 1; i < sheet.maxRows; i++) {
      var row = sheet.rows[i];
      if (row.isEmpty || row[0]?.value == null) continue;
      data.add({
        'item_code': row[0]?.value?.toString() ?? '',
        'item_name': row[1]?.value?.toString() ?? '',
        'category': row[2]?.value?.toString() ?? '',
      });
    }
    return data;
  }

  /// Parses Price List XLSX
  /// Expects: item_code, item_name, Case, Subcase, Piece
  static List<Map<String, dynamic>> parsePriceList(Uint8List bytes) {
    var excel = Excel.decodeBytes(bytes);
    List<Map<String, dynamic>> data = [];
    var sheet = excel.tables.values.first;
    
    for (int i = 1; i < sheet.maxRows; i++) {
      var row = sheet.rows[i];
      if (row.isEmpty || row[0]?.value == null) continue;
      data.add({
        'item_code': row[0]?.value?.toString() ?? '',
        'item_name': row[1]?.value?.toString() ?? '',
        'Case': double.tryParse(row[2]?.value?.toString() ?? '0') ?? 0.0,
        'Subcase': double.tryParse(row[3]?.value?.toString() ?? '0') ?? 0.0,
        'Piece': double.tryParse(row[4]?.value?.toString() ?? '0') ?? 0.0,
      });
    }
    return data;
  }

  /// Parses SSR Baseline XLSX
  /// Expects: item_code, item_name, Case, Subcase, Piece
  static List<Map<String, dynamic>> parseSSR(Uint8List bytes) {
    var excel = Excel.decodeBytes(bytes);
    List<Map<String, dynamic>> data = [];
    var sheet = excel.tables.values.first;
    
    for (int i = 1; i < sheet.maxRows; i++) {
      var row = sheet.rows[i];
      if (row.isEmpty || row[0]?.value == null) continue;
      data.add({
        'item_code': row[0]?.value?.toString() ?? '',
        'item_name': row[1]?.value?.toString() ?? '',
        'Case': int.tryParse(row[2]?.value?.toString() ?? '0') ?? 0,
        'Subcase': int.tryParse(row[3]?.value?.toString() ?? '0') ?? 0,
        'Piece': int.tryParse(row[4]?.value?.toString() ?? '0') ?? 0,
      });
    }
    return data;
  }

  /// Parses Category List XLSX
  /// Expects: category_name in first column
  static List<Map<String, dynamic>> parseCategories(Uint8List bytes) {
    var excel = Excel.decodeBytes(bytes);
    List<Map<String, dynamic>> data = [];
    var sheet = excel.tables.values.first;
    
    for (int i = 1; i < sheet.maxRows; i++) {
      var row = sheet.rows[i];
      if (row.isEmpty || row[0]?.value == null) continue;
      data.add({
        'name': row[0]?.value?.toString() ?? '',
      });
    }
    return data;
  }
}
