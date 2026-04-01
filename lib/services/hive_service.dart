// lib/services/hive_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/credit_card_model.dart';
import '../models/month_data_model.dart';

class HiveService {
  static const String categoryBox = 'categories';
  static const String transactionBox = 'transactions';
  static const String creditCardBox = 'credit_cards';
  static const String monthDataBox = 'month_data';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(TransactionModelAdapter());
    Hive.registerAdapter(CreditCardModelAdapter());
    Hive.registerAdapter(MonthDataModelAdapter());
    await Hive.openBox<CategoryModel>(categoryBox);
    await Hive.openBox<TransactionModel>(transactionBox);
    await Hive.openBox<CreditCardModel>(creditCardBox);
    await Hive.openBox<MonthDataModel>(monthDataBox);
  }

  static Box<CategoryModel> get categories => Hive.box<CategoryModel>(categoryBox);
  static Box<TransactionModel> get transactions => Hive.box<TransactionModel>(transactionBox);
  static Box<CreditCardModel> get creditCards => Hive.box<CreditCardModel>(creditCardBox);
  static Box<MonthDataModel> get monthData => Hive.box<MonthDataModel>(monthDataBox);
}
