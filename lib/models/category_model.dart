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
  String monthKey;

  CategoryModel({
    required this.id,
    required this.name,
    required this.budget,
    required this.colorValue,
    required this.monthKey,
  });
}
