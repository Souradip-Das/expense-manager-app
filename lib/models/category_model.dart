// lib/models/category_model.dart
import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 0)
class CategoryModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double budget;

  @HiveField(3)
  int colorValue;

  @HiveField(4)
  String monthKey; // Format: "MM-YYYY"

  CategoryModel({
    required this.id,
    required this.name,
    required this.budget,
    required this.colorValue,
    required this.monthKey,
  });
}
