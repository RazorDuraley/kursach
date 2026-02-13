// GENERATED CODE - manually created to satisfy build without running build_runner
part of 'health_record.dart';

class HealthRecordAdapter extends TypeAdapter<HealthRecord> {
  @override
  final int typeId = 1;

  @override
  HealthRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return HealthRecord(
      id: fields[0] as String,
      userId: fields[1] as String,
      type: fields[2] as String,
      value: fields[3] as double,
      timestamp: fields[4] as DateTime,
      notes: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HealthRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.value)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is HealthRecordAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
