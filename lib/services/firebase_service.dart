import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/credit_card_model.dart';
import '../models/month_data_model.dart';
import 'auth_service.dart';

class FirebaseService {
  static final _db = FirebaseFirestore.instance;

  // ─── Base user collection ──────────────────────────────────────────────────
  static CollectionReference _userCol(String sub) {
    final uid = AuthService.currentUid!;
    return _db.collection('users').doc(uid).collection(sub);
  }

  // ─── Month Data ────────────────────────────────────────────────────────────
  static Future<void> saveMonthData(MonthDataModel model) async {
    await _userCol('months').doc(model.monthKey).set({
      'monthKey': model.monthKey,
      'openingBalance': model.openingBalance,
      'manualCurrentBalance': model.manualCurrentBalance,
    });
  }

  static Future<MonthDataModel?> fetchMonthData(String monthKey) async {
    final doc = await _userCol('months').doc(monthKey).get();
    if (!doc.exists) return null;
    final d = doc.data() as Map<String, dynamic>;
    return MonthDataModel(
      monthKey: d['monthKey'] ?? monthKey,
      openingBalance: (d['openingBalance'] ?? 0).toDouble(),
      manualCurrentBalance: (d['manualCurrentBalance'] ?? -1).toDouble(),
    );
  }

  // ─── Categories ────────────────────────────────────────────────────────────
  static Future<void> saveCategory(CategoryModel cat) async {
    await _userCol('categories').doc(cat.id).set({
      'id': cat.id,
      'name': cat.name,
      'budget': cat.budget,
      'colorValue': cat.colorValue,
      'monthKey': cat.monthKey,
    });
  }

  static Future<void> deleteCategory(String id) async {
    await _userCol('categories').doc(id).delete();
  }

  static Future<List<CategoryModel>> fetchCategories(String monthKey) async {
    final snap = await _userCol(
      'categories',
    ).where('monthKey', isEqualTo: monthKey).get();
    return snap.docs.map((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return CategoryModel(
        id: d['id'],
        name: d['name'],
        budget: (d['budget'] ?? 0).toDouble(),
        colorValue: d['colorValue'] ?? 0xFFB71C1C,
        monthKey: d['monthKey'],
      );
    }).toList();
  }

  // ─── Transactions ──────────────────────────────────────────────────────────
  static Future<void> saveTransaction(TransactionModel tx) async {
    await _userCol('transactions').doc(tx.id).set({
      'id': tx.id,
      'categoryId': tx.categoryId,
      'categoryName': tx.categoryName,
      'amount': tx.amount,
      'description': tx.description,
      'date': Timestamp.fromDate(tx.date),
      'monthKey': tx.monthKey,
    });
  }

  static Future<void> deleteTransaction(String id) async {
    await _userCol('transactions').doc(id).delete();
  }

  static Future<List<TransactionModel>> fetchTransactions(
    String monthKey,
  ) async {
    final snap = await _userCol(
      'transactions',
    ).where('monthKey', isEqualTo: monthKey).get();
    return snap.docs.map((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return TransactionModel(
        id: d['id'],
        categoryId: d['categoryId'],
        categoryName: d['categoryName'],
        amount: (d['amount'] ?? 0).toDouble(),
        description: d['description'] ?? '',
        date: (d['date'] as Timestamp).toDate(),
        monthKey: d['monthKey'],
      );
    }).toList();
  }

  // ─── Credit Cards ──────────────────────────────────────────────────────────
  static Future<void> saveCreditCard(CreditCardModel cc) async {
    await _userCol('creditCards').doc(cc.id).set({
      'id': cc.id,
      'title': cc.title,
      'amount': cc.amount,
      'date': Timestamp.fromDate(cc.date),
      'monthKey': cc.monthKey,
      'categoryId': cc.categoryId,
      'categoryName': cc.categoryName,
    });
  }

  static Future<void> deleteCreditCard(String id) async {
    await _userCol('creditCards').doc(id).delete();
  }

  static Future<List<CreditCardModel>> fetchCreditCards(String monthKey) async {
    final snap = await _userCol(
      'creditCards',
    ).where('monthKey', isEqualTo: monthKey).get();
    return snap.docs.map((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return CreditCardModel(
        id: d['id'],
        title: d['title'],
        amount: (d['amount'] ?? 0).toDouble(),
        date: (d['date'] as Timestamp).toDate(),
        monthKey: d['monthKey'],
        categoryId: d['categoryId'],
        categoryName: d['categoryName'],
      );
    }).toList();
  }

  // ─── Fetch all month keys for export ──────────────────────────────────────
  static Future<List<String>> fetchAllMonthKeys() async {
    final snap = await _userCol('months').get();
    return snap.docs.map((d) => d.id).toList();
  }
}
