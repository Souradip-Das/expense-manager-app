// lib/services/export_import_service.dart
//
// Dependencies to add to pubspec.yaml:
//   excel: ^4.0.2
//   file_picker: ^8.0.0+1
//   share_plus: ^10.0.0
//   path_provider: ^2.1.2
//   permission_handler: ^11.3.0

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/category_model.dart';
import '../models/credit_card_model.dart';
import '../models/month_data_model.dart';
import '../models/transaction_model.dart';
import 'hive_service.dart';

class ExportImportService {
  // ─── Sheet names ────────────────────────────────────────────────────────────
  static const String _sheetSummary = 'Monthly Summary';
  static const String _sheetCategories = 'Categories';
  static const String _sheetTransactions = 'Transactions';
  static const String _sheetCreditCards = 'Credit Card Spends';
  static const String _metaTag = 'BudgetTrackerExport_v1';

  // ─── Export ─────────────────────────────────────────────────────────────────
  static Future<String> exportToExcel({String? specificMonthKey}) async {
    final excel = Excel.createExcel();

    // Collect all months or just one
    final allMonthKeys = specificMonthKey != null
        ? [specificMonthKey]
        : _getAllMonthKeys();

    // Remove default sheet
    excel.delete('Sheet1');

    // ── Summary Sheet ──────────────────────────────────────────────────────────
    final summarySheet = excel[_sheetSummary];
    _writeSummarySheet(summarySheet, allMonthKeys);

    // ── Categories Sheet ───────────────────────────────────────────────────────
    final catSheet = excel[_sheetCategories];
    _writeCategoriesSheet(catSheet, allMonthKeys);

    // ── Transactions Sheet ─────────────────────────────────────────────────────
    final txSheet = excel[_sheetTransactions];
    _writeTransactionsSheet(txSheet, allMonthKeys);

    // ── Credit Card Sheet ──────────────────────────────────────────────────────
    final ccSheet = excel[_sheetCreditCards];
    _writeCreditCardSheet(ccSheet, allMonthKeys);

    // ── Save & Share ───────────────────────────────────────────────────────────
    final bytes = excel.encode()!;
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'budget_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    // Share via share_plus
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      subject: 'Expense Tracker Export',
      text: 'My budget history export from Expense Tracker app.',
    );

    return file.path;
  }

  // ─── Import ─────────────────────────────────────────────────────────────────
  static Future<ImportResult> importFromExcel() async {
    // Pick file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return ImportResult(success: false, message: 'No file selected.');
    }

    final bytes = result.files.first.bytes;
    if (bytes == null) {
      return ImportResult(success: false, message: 'Could not read file.');
    }

    try {
      final excel = Excel.decodeBytes(bytes);

      // Validate it's our export
      final summarySheet = excel[_sheetSummary];
      if (summarySheet.rows.isEmpty ||
          summarySheet.rows[0][0]?.value.toString() != _metaTag) {
        return ImportResult(
            success: false,
            message: 'Invalid file. Please use a file exported from this app.');
      }

      int monthsImported = 0;
      int categoriesImported = 0;
      int transactionsImported = 0;
      int ccImported = 0;

      // ── Import Month Data ────────────────────────────────────────────────────
      for (int r = 3; r < summarySheet.rows.length; r++) {
        final row = summarySheet.rows[r];
        if (row.isEmpty || row[0]?.value == null) continue;
        final monthKey = row[0]!.value.toString();
        final opening = double.tryParse(row[1]?.value.toString() ?? '0') ?? 0;
        if (!HiveService.monthData.containsKey(monthKey)) {
          await HiveService.monthData
              .put(monthKey, MonthDataModel(monthKey: monthKey, openingBalance: opening));
          monthsImported++;
        }
      }

      // ── Import Categories ────────────────────────────────────────────────────
      final catSheet = excel[_sheetCategories];
      for (int r = 1; r < catSheet.rows.length; r++) {
        final row = catSheet.rows[r];
        if (row.isEmpty || row[0]?.value == null) continue;
        final id = row[0]!.value.toString();
        if (!HiveService.categories.containsKey(id)) {
          final cat = CategoryModel(
            id: id,
            monthKey: row[1]?.value.toString() ?? '',
            name: row[2]?.value.toString() ?? '',
            budget: double.tryParse(row[3]?.value.toString() ?? '0') ?? 0,
            colorValue:
                int.tryParse(row[4]?.value.toString() ?? '0') ?? 0xFFB71C1C,
          );
          await HiveService.categories.put(id, cat);
          categoriesImported++;
        }
      }

      // ── Import Transactions ──────────────────────────────────────────────────
      final txSheet = excel[_sheetTransactions];
      for (int r = 1; r < txSheet.rows.length; r++) {
        final row = txSheet.rows[r];
        if (row.isEmpty || row[0]?.value == null) continue;
        final id = row[0]!.value.toString();
        if (!HiveService.transactions.containsKey(id)) {
          DateTime date;
          try {
            date = DateFormat('dd-MM-yyyy').parse(row[5]?.value.toString() ?? '');
          } catch (_) {
            date = DateTime.now();
          }
          final tx = TransactionModel(
            id: id,
            monthKey: row[1]?.value.toString() ?? '',
            categoryId: row[2]?.value.toString() ?? '',
            categoryName: row[3]?.value.toString() ?? '',
            amount: double.tryParse(row[4]?.value.toString() ?? '0') ?? 0,
            date: date,
            description: row[6]?.value.toString() ?? '',
          );
          await HiveService.transactions.put(id, tx);
          transactionsImported++;
        }
      }

      // ── Import Credit Cards ──────────────────────────────────────────────────
      final ccSheet = excel[_sheetCreditCards];
      for (int r = 1; r < ccSheet.rows.length; r++) {
        final row = ccSheet.rows[r];
        if (row.isEmpty || row[0]?.value == null) continue;
        final id = row[0]!.value.toString();
        if (!HiveService.creditCards.containsKey(id)) {
          DateTime date;
          try {
            date = DateFormat('dd-MM-yyyy').parse(row[2]?.value.toString() ?? '');
          } catch (_) {
            date = DateTime.now();
          }
          final cc = CreditCardModel(
            id: id,
            monthKey: row[1]?.value.toString() ?? '',  // fixed: was missing monthKey
            title: row[3]?.value.toString() ?? '',
            amount: double.tryParse(row[4]?.value.toString() ?? '0') ?? 0,
            date: date,
          );
          await HiveService.creditCards.put(id, cc);
          ccImported++;
        }
      }

      return ImportResult(
        success: true,
        message:
            'Import complete!\n• $monthsImported month(s)\n• $categoriesImported categories\n• $transactionsImported transactions\n• $ccImported credit card entries',
        monthsImported: monthsImported,
        categoriesImported: categoriesImported,
        transactionsImported: transactionsImported,
        ccImported: ccImported,
      );
    } catch (e) {
      debugPrint('Import error: $e');
      return ImportResult(
          success: false, message: 'Failed to import: ${e.toString()}');
    }
  }

  // ─── Sheet Writers ───────────────────────────────────────────────────────────

  /// Helper: assign a CellValue to a cell — only TextCellValue & DoubleCellValue
  /// are used because excel v4 removed IntCellValue.
  static void _setCell(Sheet sheet, int col, int row, dynamic val) {
    final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    if (val is double || val is int) {
      cell.value = DoubleCellValue((val as num).toDouble());
    } else {
      cell.value = TextCellValue(val?.toString() ?? '');
    }
  }

  static void _setHeaderRow(Sheet sheet, List<String> headers, int rowIndex) {
    for (int c = 0; c < headers.length; c++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIndex));
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = CellStyle(bold: true);
    }
  }

  static void _writeSummarySheet(Sheet sheet, List<String> monthKeys) {
    // Row 0: meta tag (used for import validation)
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = TextCellValue(_metaTag);

    // Row 1: empty spacer
    // Row 2: column headers
    _setHeaderRow(sheet,
        ['Month', 'Opening Balance', 'Total Spent', 'CC Spent', 'Net Balance'],
        2);

    // Rows 3+: data
    int r = 3;
    for (final mk in monthKeys) {
      final md = HiveService.monthData.get(mk);
      if (md == null) continue;

      final txTotal = HiveService.transactions.values
          .where((t) => t.monthKey == mk)
          .fold(0.0, (s, t) => s + t.amount);
      final ccTotal = HiveService.creditCards.values
          .where((c) => c.monthKey == mk)
          .fold(0.0, (s, c) => s + c.amount);
      final net = md.openingBalance - txTotal - ccTotal;

      _setCell(sheet, 0, r, mk);
      _setCell(sheet, 1, r, md.openingBalance);
      _setCell(sheet, 2, r, txTotal);
      _setCell(sheet, 3, r, ccTotal);
      _setCell(sheet, 4, r, net);
      r++;
    }

    sheet.setColumnWidth(0, 14);
    sheet.setColumnWidth(1, 18);
    sheet.setColumnWidth(2, 16);
    sheet.setColumnWidth(3, 16);
    sheet.setColumnWidth(4, 16);
  }

  static void _writeCategoriesSheet(Sheet sheet, List<String> monthKeys) {
    _setHeaderRow(sheet,
        ['ID', 'Month', 'Name', 'Budget', 'Color Value', 'Amount Spent', 'Remaining'],
        0);

    int r = 1;
    for (final mk in monthKeys) {
      for (final cat
          in HiveService.categories.values.where((c) => c.monthKey == mk)) {
        final spent = HiveService.transactions.values
            .where((t) => t.categoryId == cat.id)
            .fold(0.0, (s, t) => s + t.amount);

        _setCell(sheet, 0, r, cat.id);
        _setCell(sheet, 1, r, mk);
        _setCell(sheet, 2, r, cat.name);
        _setCell(sheet, 3, r, cat.budget);
        _setCell(sheet, 4, r, cat.colorValue.toDouble());
        _setCell(sheet, 5, r, spent);
        _setCell(sheet, 6, r, cat.budget - spent);
        r++;
      }
    }

    sheet.setColumnWidth(0, 38);
    sheet.setColumnWidth(1, 12);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 14);
    sheet.setColumnWidth(4, 14);
    sheet.setColumnWidth(5, 14);
    sheet.setColumnWidth(6, 14);
  }

  static void _writeTransactionsSheet(Sheet sheet, List<String> monthKeys) {
    _setHeaderRow(sheet,
        ['ID', 'Month', 'Category ID', 'Category', 'Amount', 'Date', 'Description'],
        0);

    int r = 1;
    for (final mk in monthKeys) {
      final txs = HiveService.transactions.values
          .where((t) => t.monthKey == mk)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      for (final tx in txs) {
        _setCell(sheet, 0, r, tx.id);
        _setCell(sheet, 1, r, mk);
        _setCell(sheet, 2, r, tx.categoryId);
        _setCell(sheet, 3, r, tx.categoryName);
        _setCell(sheet, 4, r, tx.amount);
        _setCell(sheet, 5, r, DateFormat('dd-MM-yyyy').format(tx.date));
        _setCell(sheet, 6, r, tx.description);
        r++;
      }
    }

    sheet.setColumnWidth(0, 38);
    sheet.setColumnWidth(1, 12);
    sheet.setColumnWidth(2, 38);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 12);
    sheet.setColumnWidth(5, 14);
    sheet.setColumnWidth(6, 30);
  }

  static void _writeCreditCardSheet(Sheet sheet, List<String> monthKeys) {
    _setHeaderRow(sheet, ['ID', 'Month', 'Date', 'Title', 'Amount'], 0);

    int r = 1;
    for (final mk in monthKeys) {
      final ccs = HiveService.creditCards.values
          .where((c) => c.monthKey == mk)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      for (final cc in ccs) {
        _setCell(sheet, 0, r, cc.id);
        _setCell(sheet, 1, r, mk);
        _setCell(sheet, 2, r, DateFormat('dd-MM-yyyy').format(cc.date));
        _setCell(sheet, 3, r, cc.title);
        _setCell(sheet, 4, r, cc.amount);
        r++;
      }
    }

    sheet.setColumnWidth(0, 38);
    sheet.setColumnWidth(1, 12);
    sheet.setColumnWidth(2, 14);
    sheet.setColumnWidth(3, 30);
    sheet.setColumnWidth(4, 12);
  }

  static List<String> _getAllMonthKeys() {
    final keys = <String>{};
    keys.addAll(HiveService.monthData.keys.cast<String>());
    for (final c in HiveService.categories.values) keys.add(c.monthKey);
    for (final t in HiveService.transactions.values) keys.add(t.monthKey);
    for (final cc in HiveService.creditCards.values) keys.add(cc.monthKey);
    final sorted = keys.toList()
      ..sort((a, b) {
        final pa = _parseMonthKey(a);
        final pb = _parseMonthKey(b);
        return pa.compareTo(pb);
      });
    return sorted;
  }

  static DateTime _parseMonthKey(String key) {
    try {
      final parts = key.split('-');
      return DateTime(int.parse(parts[1]), int.parse(parts[0]));
    } catch (_) {
      return DateTime(2000);
    }
  }
}

class ImportResult {
  final bool success;
  final String message;
  final int monthsImported;
  final int categoriesImported;
  final int transactionsImported;
  final int ccImported;

  ImportResult({
    required this.success,
    required this.message,
    this.monthsImported = 0,
    this.categoriesImported = 0,
    this.transactionsImported = 0,
    this.ccImported = 0,
  });
}