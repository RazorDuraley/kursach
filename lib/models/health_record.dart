import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'health_record.g.dart';

@HiveType(typeId: 1)
class HealthRecord {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String userId;
  
  @HiveField(2)
  String type;
  
  @HiveField(3)
  double value;
  
  @HiveField(4)
  DateTime timestamp;
  
  @HiveField(5)
  String? notes;

  HealthRecord({
    required this.id,
    required this.userId,
    required this.type,
    required this.value,
    required this.timestamp,
    this.notes,
  });
  
  String get formattedTime => DateFormat('HH:mm').format(timestamp);
  String get formattedDate => DateFormat('dd.MM.yyyy').format(timestamp);
}