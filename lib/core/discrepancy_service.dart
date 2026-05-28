import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';

import '../data/models/count_model.dart';
import '../data/models/item_model.dart';
import 'file_saver.dart';

class DiscrepancyRecord {
  final String category;
  final String itemCode;
  final String itemName;
  final int ssrQty;
  final String actualQty;
  final int discrepancy;
  final double valueDiff;
  final String status;

  DiscrepancyRecord({
    required this.category,
    required this.itemCode,
    required this.itemName,
    required this.ssrQty,
    required this.actualQty,
    required this.discrepancy,
    required this.valueDiff,
    required this.status,
  });
}

class DiscrepancyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<DiscrepancyRecord>> fetchActualCountRecords() async {
    final countsSnapshot = await _db.collection('counts').get();
    final itemCodes = countsSnapshot.docs
        .map((doc) => (doc.data()['productCode'] ?? '').toString())
        .where((code) => code.isNotEmpty)
        .toSet();

    final ssrMap = await _loadSsrBaseline(itemCodes);
    final itemRecords = await _loadDocumentMap('items', itemCodes);
    final priceRecords = await _loadDocumentMap('prices', itemCodes);

    return countsSnapshot.docs.map((doc) {
      final count = CountModel.fromFirestore(doc.data(), doc.id);
      final itemCode = count.productCode;
      final itemRecord = itemRecords[itemCode];
      final priceRecord = priceRecords[itemCode];
      final itemName = itemRecord != null
          ? (itemRecord['itemName']?.toString() ?? itemCode)
          : itemCode;
      final category = count.category;
      final ssrQty = ssrMap[itemCode] ?? 0;
      final actualQty = '${count.quantities.countCase}/${count.quantities.countSubcase}/${count.quantities.countPiece}';
      final discrepancy = _calculateDiscrepancy(count.quantities, ssrQty);
      final prices = _resolvePrices(itemRecord, priceRecord);
      final valueDiff = _calculateValueDiff(count.quantities, prices, ssrQty);
      final status = _statusFromDiscrepancy(discrepancy);

      return DiscrepancyRecord(
        category: category,
        itemCode: itemCode,
        itemName: itemName,
        ssrQty: ssrQty,
        actualQty: actualQty,
        discrepancy: discrepancy,
        valueDiff: valueDiff,
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
      TextCellValue('SSR Qty'),
      TextCellValue('Actual Qty (C/SC/P)'),
      TextCellValue('Discrepancy'),
      TextCellValue('Value Diff (₱)'),
      TextCellValue('Status'),
    ]);

    for (final row in rows) {
      sheet.appendRow([
        TextCellValue(row.category),
        TextCellValue(row.itemCode),
        TextCellValue(row.itemName),
        IntCellValue(row.ssrQty),
        TextCellValue(row.actualQty),
        IntCellValue(row.discrepancy),
        DoubleCellValue(double.parse(row.valueDiff.toStringAsFixed(2))),
        TextCellValue(row.status),
      ]);
    }

    final encoded = excel.encode();
    return Uint8List.fromList(encoded ?? []);
  }

  Future<Map<String, Map<String, dynamic>>> _loadDocumentMap(
      String collectionName, Set<String> itemCodes) async {
    final records = <String, Map<String, dynamic>>{};
    if (itemCodes.isEmpty) return records;

    final chunks = _chunkList(itemCodes.toList(), 10);
    for (final chunk in chunks) {
      final querySnapshot = await _db
          .collection(collectionName)
          .where('itemCode', whereIn: chunk)
          .get();
      for (final doc in querySnapshot.docs) {
        final code = doc.data()['itemCode']?.toString() ?? '';
        if (code.isNotEmpty) {
          records[code] = doc.data();
        }
      }
    }

    return records;
  }

  Future<Map<String, int>> _loadSsrBaseline(Set<String> itemCodes) async {
    final baseline = <String, int>{};
    if (itemCodes.isEmpty) return baseline;

    final chunks = _chunkList(itemCodes.toList(), 10);
    for (final chunk in chunks) {
      final querySnapshot = await _db
          .collection('ssr_baseline')
          .where('itemCode', whereIn: chunk)
          .get();
      for (final doc in querySnapshot.docs) {
        final code = doc.data()['itemCode']?.toString() ?? '';
        if (code.isNotEmpty) {
          baseline[code] = (doc.data()['ssrQty'] ?? 0).toInt();
        }
      }
    }

    return baseline;
  }

  ItemPrices _resolvePrices(
    Map<String, dynamic>? itemRecord,
    Map<String, dynamic>? priceRecord,
  ) {
    if (itemRecord != null) {
      final prices = itemRecord['prices'];
      if (prices is Map<String, dynamic>) {
        return _buildPricesFromMap(prices);
      }
    }
    if (priceRecord != null) {
      return _buildPricesFromMap(priceRecord);
    }
    return ItemPrices(priceCase: 0.0, priceSubcase: 0.0, pricePiece: 0.0);
  }

  ItemPrices _buildPricesFromMap(Map<String, dynamic> data) {
    double parse(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    return ItemPrices(
      priceCase: parse(data['case'] ?? data['priceCase']),
      priceSubcase: parse(data['subcase'] ?? data['priceSubcase']),
      pricePiece: parse(data['piece'] ?? data['pricePiece']),
    );
  }

  int _calculateDiscrepancy(CountQuantities quantities, int ssrQty) {
    final totalActual = quantities.countCase + quantities.countSubcase + quantities.countPiece;
    return totalActual - ssrQty;
  }

  double _calculateValueDiff(CountQuantities quantities, ItemPrices prices, int ssrQty) {
    final actualValue = quantities.countCase * prices.priceCase +
        quantities.countSubcase * prices.priceSubcase +
        quantities.countPiece * prices.pricePiece;
    final ssrValue = ssrQty * prices.pricePiece;
    return actualValue - ssrValue;
  }

  String _statusFromDiscrepancy(int discrepancy) {
    if (discrepancy > 0) return 'Over';
    if (discrepancy < 0) return 'Short';
    return 'Balanced';
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
