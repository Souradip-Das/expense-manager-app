// lib/models/month_data_model.dart
import 'package:hive/hive.dart';

part 'month_data_model.g.dart';

@HiveType(typeId: 3)
class MonthDataModel extends HiveObject {
  @HiveField(0)
  String monthKey; // Format: "MM-YYYY"

  @HiveField(1)
  double openingBalance;

  @HiveField(2)
  double manualCurrentBalance; // optional override, -1 means auto

  MonthDataModel({
    required this.monthKey,
    required this.openingBalance,
    this.manualCurrentBalance = -1,
  });
}
