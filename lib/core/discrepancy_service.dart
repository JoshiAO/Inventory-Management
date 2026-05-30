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

  Future<List<DiscrepancyRecord>> fetchActualCountRecords(String facilityId) async {
    final countsSnapshot = await _db.collection('counts').doc(facilityId).collection('records').get();
    
    final itemCodes = countsSnapshot.docs
        .map((doc) => (doc.data()['productCode'] ?? '').toString())
        .where((code) => code.isNotEmpty)
        .toSet();

    if (itemCodes.isEmpty) return [];

    final itemMasters = await _loadCollectionAsMap<ItemMaster>(
      'items', 
      itemCodes, 
      'item_code', 
      (data) => ItemMaster.fromMap(data)
    );
    final prices = await _loadCollectionAsMap<PriceList>(
      'prices', 
      itemCodes, 
      'item_code', 
      (data) => PriceList.fromMap(data),
      facilityId: facilityId,
    );
    final baselines = await _loadCollectionAsMap<SsrBaseline>(
      'ssr_baseline', 
      itemCodes, 
      'item_code', 
      (data) => SsrBaseline.fromMap(data),
      facilityId: facilityId,
    );

    return countsSnapshot.docs.map((doc) {
      final count = CountModel.fromMap(doc.data(), doc.id);
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
      
      final double ssrValue = _calculateValue(
        baseline?.ssrCase ?? 0, 
        baseline?.ssrSubcase ?? 0, 
        baseline?.ssrPiece ?? 0, 
        price
      );

      final double actualValue = _calculateValue(
        count.quantities.countCase, 
        count.quantities.countSubcase, 
        count.quantities.countPiece, 
        price
      );

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

  double _calculateValue(int c, int sc, int p, PriceList? price) {
    if (price == null) return 0;
    return (c * price.priceCase) + (sc * price.priceSubcase) + (p * price.pricePiece);
  }

  Future<Map<String, T>> _loadCollectionAsMap<T>(
    String collection, 
    Set<String> itemCodes, 
    String queryField,
    T Function(Map<String, dynamic>) mapper, {
    String? facilityId,
  }) async {
    final records = <String, T>{};
    final chunks = _chunkList(itemCodes.toList(), 10);
    for (final chunk in chunks) {
      final targetRef = facilityId == null 
          ? _db.collection(collection) 
          : _db.collection(collection).doc(facilityId).collection('records');
          
      final querySnapshot = await targetRef.where(queryField, whereIn: chunk).get();
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final itemCode = data[queryField] as String;
        records[itemCode] = mapper(data);
      }
    }
    return records;
  }

  Future<String> exportActualCountReport(String facilityId, {String fileName = 'actual_count_report.xlsx'}) async {
    final rows = await fetchActualCountRecords(facilityId);
    final bytes = buildActualCountWorkbook(rows);
    return await saveBytes(bytes, fileName);
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

  List<List<T>> _chunkList<T>(List<T> items, int size) {
    final chunks = <List<T>>[];
    for (var start = 0; start < items.length; start += size) {
      final end = min(start + size, items.length);
      chunks.add(items.sublist(start, end));
    }
    return chunks;
  }
}
