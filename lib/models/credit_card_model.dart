// lib/models/credit_card_model.dart
import 'package:hive/hive.dart';

part 'credit_card_model.g.dart';

@HiveType(typeId: 2)
class CreditCardModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String monthKey;

  @HiveField(5)
  String? categoryId;

  @HiveField(6)
  String? categoryName;

  CreditCardModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.monthKey,
    this.categoryId,
    this.categoryName,
  });
}
