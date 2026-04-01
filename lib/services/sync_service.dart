import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/credit_card_model.dart';
import '../models/month_data_model.dart';
import '../models/transaction_model.dart';
import 'firebase_service.dart';
import 'hive_service.dart';

class SyncService {
  // ─── Month Data ────────────────────────────────────────────────────────────
  static Future<MonthDataModel?> loadMonthData(String monthKey) async {
    try {
      final remote = await FirebaseService.fetchMonthData(monthKey);
      if (remote != null) {
        await HiveService.monthData.put(monthKey, remote); // update cache
        return remote;
      }
    } catch (e) {
      debugPrint('Firestore offline, using Hive for month: $e');
    }
    return HiveService.monthData.get(monthKey);
  }

  static Future<void> saveMonthData(MonthDataModel model) async {
    await HiveService.monthData.put(model.monthKey, model);
    _pushAsync(() => FirebaseService.saveMonthData(model));
  }

  // ─── Categories ────────────────────────────────────────────────────────────
  static Future<List<CategoryModel>> loadCategories(String monthKey) async {
    try {
      final remote = await FirebaseService.fetchCategories(monthKey);
      for (final c in remote) {
        await HiveService.categories.put(c.id, c);
      }
      return remote;
    } catch (e) {
      debugPrint('Firestore offline, using Hive for categories: $e');
    }
    return HiveService.categories.values
        .where((c) => c.monthKey == monthKey)
        .toList();
  }

  static Future<void> saveCategory(CategoryModel cat) async {
    await HiveService.categories.put(cat.id, cat);
    _pushAsync(() => FirebaseService.saveCategory(cat));
  }

  static Future<void> deleteCategory(String id) async {
    await HiveService.categories.delete(id);
    _pushAsync(() => FirebaseService.deleteCategory(id));
  }

  // ─── Transactions ──────────────────────────────────────────────────────────
  static Future<List<TransactionModel>> loadTransactions(
    String monthKey,
  ) async {
    try {
      final remote = await FirebaseService.fetchTransactions(monthKey);
      // Always sync Firestore → Hive regardless of count
      for (final t in remote) {
        await HiveService.transactions.put(t.id, t);
      }
      // Return sorted list
      return remote..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('Firestore offline, using Hive for transactions: $e');
    }
    // Offline fallback
    return HiveService.transactions.values
        .where((t) => t.monthKey == monthKey)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> saveTransaction(TransactionModel tx) async {
    await HiveService.transactions.put(tx.id, tx);
    _pushAsync(() => FirebaseService.saveTransaction(tx));
  }

  static Future<void> deleteTransaction(String id) async {
    await HiveService.transactions.delete(id);
    _pushAsync(() => FirebaseService.deleteTransaction(id));
  }

  // ─── Credit Cards ──────────────────────────────────────────────────────────
  static Future<List<CreditCardModel>> loadCreditCards(String monthKey) async {
    try {
      final remote = await FirebaseService.fetchCreditCards(monthKey);
      for (final c in remote) {
        await HiveService.creditCards.put(c.id, c);
      }
      return remote..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('Firestore offline, using Hive for credit cards: $e');
    }
    return HiveService.creditCards.values
        .where((c) => c.monthKey == monthKey)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> saveCreditCard(CreditCardModel cc) async {
    await HiveService.creditCards.put(cc.id, cc);
    _pushAsync(() => FirebaseService.saveCreditCard(cc));
  }

  static Future<void> deleteCreditCard(String id) async {
    await HiveService.creditCards.delete(id);
    _pushAsync(() => FirebaseService.deleteCreditCard(id));
  }

  // ─── Fire-and-forget async push ────────────────────────────────────────────
  // Writes to Firestore in background without blocking UI
  static void _pushAsync(Future<void> Function() fn) {
    fn().catchError((e) => debugPrint('Firestore sync error: $e'));
  }
}
