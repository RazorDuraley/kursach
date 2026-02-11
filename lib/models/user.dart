import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String email;
  
  @HiveField(2)
  String password; // В реальном приложении хранить хэш!
  
  @HiveField(3)
  String name;
  
  @HiveField(4)
  int age;
  
  @HiveField(5)
  DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.password,
    required this.name,
    required this.age,
    required this.createdAt,
  });
}