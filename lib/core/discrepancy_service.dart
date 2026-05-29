import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';

import '../data/models/count_model.dart';
import '../data/models/item_model.dart';
import '../data/models/price_model.dart';
import '../data/models/ssr_baseline_model.dart';
import 'file_saver.dart';

class DiscrepancyRecord {
  final String category;
  final String itemCode;
  final String itemName;
  final String ssrQty;
  final String actualQty;
  final double discrepancyValue;
  final String status;

  DiscrepancyRecord({
    required this.category,
    required this.itemCode,
    required this.itemName,
    required this.ssrQty,
    required this.actualQty,
    required this.discrepancyValue,
    required this.status,
  });
}

class DiscrepancyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<DiscrepancyRecord>> fetchActualCountRecords() async {
    final countsSnapshot = await _db.collection('counts').get();
    
    // Get unique item codes from counts
    final itemCodes = countsSnapshot.docs
        .map((doc) => (doc.data()['productCode'] ?? '').toString())
        .where((code) => code.isNotEmpty)
        .toSet();

    if (itemCodes.isEmpty) return [];

    // Load reference data
    final itemMasters = await _loadItemMasters(itemCodes);
    final prices = await _loadPriceList(itemCodes);
    final baselines = await _loadSsrBaselines(itemCodes);

    return countsSnapshot.docs.map((doc) {
      final count = CountModel.fromFirestore(doc.data(), doc.id);
      final itemCode = count.productCode;
      
      final master = itemMasters[itemCode];
      final price = prices[itemCode];
      final baseline = baselines[itemCode];

      final itemName = master?.itemName ?? itemCode;
      final category = master?.category ?? count.category;
      
      final ssrQtyStr = baseline != null 
          ? '${baseline.ssrCase}/${baseline.ssrSubcase}/${baseline.ssrPiece}'
          : '0/0/0';
          
      final actualQtyStr = '${count.quantities.countCase}/${count.quantities.countSubcase}/${count.quantities.countPiece}';
      
      // Calculate Values
      double ssrValue = 0;
      if (baseline != null && price != null) {
        ssrValue = (baseline.ssrCase * price.priceCase) +
                   (baseline.ssrSubcase * price.priceSubcase) +
                   (baseline.ssrPiece * price.pricePiece);
      }

      double actualValue = 0;
      if (price != null) {
        actualValue = (count.quantities.countCase * price.priceCase) +
                      (count.quantities.countSubcase * price.priceSubcase) +
                      (count.quantities.countPiece * price.pricePiece);
      }

      final diff = actualValue - ssrValue;
      String status = 'Balanced';
      if (diff > 0) status = 'Over';
      if (diff < 0) status = 'Short';

      return DiscrepancyRecord(
        category: category,
        itemCode: itemCode,
        itemName: itemName,
        ssrQty: ssrQtyStr,
        actualQty: actualQtyStr,
        discrepancyValue: diff,
        status: status,
      );
    }).toList();
  }

  Future<String> exportActualCountReport({String fileName = 'actual_count_report.xlsx'}) async {
    final rows = await fetchActualCountRecords();
    final bytes = buildActualCountWorkbook(rows);
    final savedPath = await saveBytes(bytes, fileName);
    return savedPath;
  }

  Uint8List buildActualCountWorkbook(List<DiscrepancyRecord> rows) {
    final excel = Excel.createExcel();
    final sheet = excel['Actual Count'];

    sheet.appendRow([
      TextCellValue('Category'),
      TextCellValue('Item Code'),
      TextCellValue('Item Name'),
      TextCellValue('SSR Qty (C/SC/P)'),
      TextCellValue('Actual Qty (C/SC/P)'),
      TextCellValue('Value Diff (₱)'),
      TextCellValue('Status'),
    ]);

    for (final row in rows) {
      sheet.appendRow([
        TextCellValue(row.category),
        TextCellValue(row.itemCode),
        TextCellValue(row.itemName),
        TextCellValue(row.ssrQty),
        TextCellValue(row.actualQty),
        DoubleCellValue(double.parse(row.discrepancyValue.toStringAsFixed(2))),
        TextCellValue(row.status),
      ]);
    }

    final encoded = excel.encode();
    return Uint8List.fromList(encoded ?? []);
  }

  Future<Map<String, ItemMaster>> _loadItemMasters(Set<String> itemCodes) async {
    final records = <String, ItemMaster>{};
    final chunks = _chunkList(itemCodes.toList(), 10);
    for (final chunk in chunks) {
      final querySnapshot = await _db.collection('items').where('item_code', whereIn: chunk).get();
      for (final doc in querySnapshot.docs) {
        final master = ItemMaster.fromFirestore(doc.data());
        records[master.itemCode] = master;
      }
    }
    return records;
  }

  Future<Map<String, PriceList>> _loadPriceList(Set<String> itemCodes) async {
    final records = <String, PriceList>{};
    final chunks = _chunkList(itemCodes.toList(), 10);
    for (final chunk in chunks) {
      final querySnapshot = await _db.collection('prices').where('item_code', whereIn: chunk).get();
      for (final doc in querySnapshot.docs) {
        final price = PriceList.fromFirestore(doc.data());
        records[price.itemCode] = price;
      }
    }
    return records;
  }

  Future<Map<String, SsrBaseline>> _loadSsrBaselines(Set<String> itemCodes) async {
    final records = <String, SsrBaseline>{};
    final chunks = _chunkList(itemCodes.toList(), 10);
    for (final chunk in chunks) {
      final querySnapshot = await _db.collection('ssr_baseline').where('item_code', whereIn: chunk).get();
      for (final doc in querySnapshot.docs) {
        final ssr = SsrBaseline.fromFirestore(doc.data());
        records[ssr.itemCode] = ssr;
      }
    }
    return records;
  }

  List<List<T>> _chunkList<T>(List<T> items, int size) {
    final chunks = <List<T>>[];
    for (var start = 0; start < items.length; start += size) {
      final end = min(start + size, items.length);
      chunks.add(items.sublist(start, end));
    }
    return chunks;
  }
}
