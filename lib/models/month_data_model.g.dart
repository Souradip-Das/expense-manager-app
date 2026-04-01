part of 'month_data_model.dart';

class MonthDataModelAdapter extends TypeAdapter<MonthDataModel> {
  @override
  final int typeId = 3;

  @override
  MonthDataModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MonthDataModel(
      monthKey: fields[0] as String,
      openingBalance: fields[1] as double,
      manualCurrentBalance: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, MonthDataModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.monthKey)
      ..writeByte(1)
      ..write(obj.openingBalance)
      ..writeByte(2)
      ..write(obj.manualCurrentBalance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthDataModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
