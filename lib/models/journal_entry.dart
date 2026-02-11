import 'package:hive/hive.dart';

part 'journal_entry.g.dart';

@HiveType(typeId: 2)
class JournalEntry {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String userId;
  
  @HiveField(2)
  String type;
  
  @HiveField(3)
  String title;
  
  @HiveField(4)
  String description;
  
  @HiveField(5)
  DateTime timestamp;
  
  @HiveField(6)
  String? severity;

  JournalEntry({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.severity,
  });
}