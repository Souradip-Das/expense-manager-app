import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import '../models/category_model.dart';
import '../models/credit_card_model.dart';
import '../models/month_data_model.dart';
import '../models/transaction_model.dart';
import '../services/sync_service.dart';

const _uuid = Uuid();

class SelectedMonthNotifier extends StateNotifier<DateTime> {
  SelectedMonthNotifier() : super(DateTime.now());

  void setMonth(DateTime date) => state = date;
  void nextMonth() => state = DateTime(state.year, state.month + 1);
  void prevMonth() => state = DateTime(state.year, state.month - 1);

  String get monthKey {
    final m = state.month.toString().padLeft(2, '0');
    return '$m-${state.year}';
  }
}

final selectedMonthProvider =
    StateNotifierProvider<SelectedMonthNotifier, DateTime>(
        (_) => SelectedMonthNotifier());

class MonthDataNotifier extends StateNotifier<MonthDataModel?> {
  MonthDataNotifier() : super(null);

  Future<void> loadMonth(String monthKey) async {
    final data = await SyncService.loadMonthData(monthKey);
    state = null;
    state = data;
  }

  Future<void> setOpeningBalance(String monthKey, double amount) async {
    MonthDataModel existing = state ??
        MonthDataModel(monthKey: monthKey, openingBalance: 0);
    existing.openingBalance = amount;
    await SyncService.saveMonthData(existing);
    state = null;
    state = existing;
  }

  Future<void> setCurrentBalance(String monthKey, double amount) async {
    if (state == null) return;
    state!.manualCurrentBalance = amount;
    await SyncService.saveMonthData(state!);
    state = null;
    state = state;
  }
}

final monthDataProvider =
    StateNotifierProvider<MonthDataNotifier, MonthDataModel?>(
        (_) => MonthDataNotifier());

class CategoriesNotifier extends StateNotifier<List<CategoryModel>> {
  CategoriesNotifier() : super([]);

  Future<void> loadCategories(String monthKey) async {
    final data = await SyncService.loadCategories(monthKey);
    state = data;
  }

  Future<void> addCategory({
    required String name,
    required double budget,
    required int colorValue,
    required String monthKey,
  }) async {
    final cat = CategoryModel(
      id: _uuid.v4(),
      name: name,
      budget: budget,
      colorValue: colorValue,
      monthKey: monthKey,
    );
    await SyncService.saveCategory(cat);
    state = [...state, cat];
  }

  Future<void> updateCategory(CategoryModel cat) async {
    await SyncService.saveCategory(cat);
    state = [
      for (final c in state)
        if (c.id == cat.id) cat else c
    ];
  }

  Future<void> deleteCategory(String id) async {
    await SyncService.deleteCategory(id);
    state = state.where((c) => c.id != id).toList();
  }
}

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<CategoryModel>>(
        (_) => CategoriesNotifier());

class TransactionsNotifier extends StateNotifier<List<TransactionModel>> {
  TransactionsNotifier() : super([]);

  Future<void> loadTransactions(String monthKey) async {
    final data = await SyncService.loadTransactions(monthKey);
    state = data;
  }

  Future<void> addTransaction({
    required String categoryId,
    required String categoryName,
    required double amount,
    required String description,
    required DateTime date,
    required String monthKey,
  }) async {
    final tx = TransactionModel(
      id: _uuid.v4(),
      categoryId: categoryId,
      categoryName: categoryName,
      amount: amount,
      description: description,
      date: date,
      monthKey: monthKey,
    );
    await SyncService.saveTransaction(tx);
    state = [tx, ...state];
  }

  Future<void> deleteTransaction(String id) async {
    await SyncService.deleteTransaction(id);
    state = state.where((t) => t.id != id).toList();
  }

  double totalSpentForCategory(
      String categoryId, List<CreditCardModel> creditCards) {
    final txSpent = state
        .where((t) => t.categoryId == categoryId)
        .fold(0.0, (sum, t) => sum + t.amount);
    final ccSpent = creditCards
        .where((c) => c.categoryId == categoryId)
        .fold(0.0, (sum, c) => sum + c.amount);
    return txSpent + ccSpent;
  }

  double totalSpent() => state.fold(0.0, (sum, t) => sum + t.amount);
}

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<TransactionModel>>(
        (_) => TransactionsNotifier());

class CreditCardsNotifier extends StateNotifier<List<CreditCardModel>> {
  CreditCardsNotifier() : super([]);

  Future<void> loadCreditCards(String monthKey) async {
    final data = await SyncService.loadCreditCards(monthKey);
    state = data;
  }

  Future<void> addCreditCard({
    required String title,
    required double amount,
    required DateTime date,
    required String monthKey,
    String? categoryId,
    String? categoryName,
  }) async {
    final cc = CreditCardModel(
      id: _uuid.v4(),
      title: title,
      amount: amount,
      date: date,
      monthKey: monthKey,
      categoryId: categoryId,
      categoryName: categoryName,
    );
    await SyncService.saveCreditCard(cc);
    state = [cc, ...state];
  }

  Future<void> deleteCreditCard(String id) async {
    await SyncService.deleteCreditCard(id);
    state = state.where((c) => c.id != id).toList();
  }

  double totalSpent() => state.fold(0.0, (sum, c) => sum + c.amount);
}

final creditCardsProvider =
    StateNotifierProvider<CreditCardsNotifier, List<CreditCardModel>>(
        (_) => CreditCardsNotifier());

final currentBalanceProvider = Provider<double>((ref) {
  final monthData = ref.watch(monthDataProvider);
  final transactions = ref.watch(transactionsProvider);
  final creditCards = ref.watch(creditCardsProvider);
  if (monthData == null) return 0.0;
  final totalTx = transactions.fold<double>(0, (s, t) => s + t.amount);
  final totalCC = creditCards.fold<double>(0, (s, c) => s + c.amount);
  return monthData.openingBalance - totalTx - totalCC;
});

final totalBudgetProvider = Provider<double>((ref) {
  final categories = ref.watch(categoriesProvider);
  return categories.fold(0.0, (sum, cat) => sum + cat.budget);
});