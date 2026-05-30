import 'dart:typed_data';
import 'package:excel/excel.dart';

class ExcelService {
  static List<Map<String, dynamic>> _parseRows(Uint8List bytes, Map<String, dynamic> Function(List<Data?> row) mapper) {
    var excel = Excel.decodeBytes(bytes);
    List<Map<String, dynamic>> data = [];
    var sheet = excel.tables.values.first;
    
    for (int i = 1; i < sheet.maxRows; i++) {
      var row = sheet.rows[i];
      if (row.isEmpty || row[0]?.value == null) continue;
      data.add(mapper(row));
    }
    return data;
  }

  /// Parses Item Master XLSX
  static List<Map<String, dynamic>> parseItemMaster(Uint8List bytes) {
    return _parseRows(bytes, (row) => {
      'item_code': row[0]?.value?.toString() ?? '',
      'item_name': row[1]?.value?.toString() ?? '',
      'category': row[2]?.value?.toString() ?? '',
    });
  }

  /// Parses Price List XLSX
  static List<Map<String, dynamic>> parsePriceList(Uint8List bytes) {
    return _parseRows(bytes, (row) => {
      'item_code': row[0]?.value?.toString() ?? '',
      'item_name': row[1]?.value?.toString() ?? '',
      'Case': double.tryParse(row[2]?.value?.toString() ?? '0') ?? 0.0,
      'Subcase': double.tryParse(row[3]?.value?.toString() ?? '0') ?? 0.0,
      'Piece': double.tryParse(row[4]?.value?.toString() ?? '0') ?? 0.0,
    });
  }

  /// Parses SSR Baseline XLSX
  static List<Map<String, dynamic>> parseSSR(Uint8List bytes) {
    return _parseRows(bytes, (row) => {
      'item_code': row[0]?.value?.toString() ?? '',
      'item_name': row[1]?.value?.toString() ?? '',
      'Case': int.tryParse(row[2]?.value?.toString() ?? '0') ?? 0,
      'Subcase': int.tryParse(row[3]?.value?.toString() ?? '0') ?? 0,
      'Piece': int.tryParse(row[4]?.value?.toString() ?? '0') ?? 0,
    });
  }

  /// Parses Category List XLSX
  static List<Map<String, dynamic>> parseCategories(Uint8List bytes) {
    return _parseRows(bytes, (row) => {
      'name': row[0]?.value?.toString() ?? '',
    });
  }
}
