import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user.dart';
import '../models/health_record.dart';
import '../models/journal_entry.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();
  
  late Box<User> _usersBox;
  late Box<HealthRecord> _healthRecordsBox;
  late Box<JournalEntry> _journalBox;
  late Box<dynamic> _settingsBox;
  
  Future<void> init() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
    
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(HealthRecordAdapter());
    Hive.registerAdapter(JournalEntryAdapter());
    
    _usersBox = await Hive.openBox<User>('users');
    _healthRecordsBox = await Hive.openBox<HealthRecord>('health_records');
    _journalBox = await Hive.openBox<JournalEntry>('journal_entries');
    _settingsBox = await Hive.openBox('settings');
    
    if (_usersBox.isEmpty) {
      await _createDemoUser();
    }
  }
  
  Future<void> _createDemoUser() async {
    final demoUser = User(
      id: 'demo_user',
      email: 'demo@healthmonitor.com',
      password: _hashPassword('demo123'),
      name: 'Александр Таров',
      age: 25,
      createdAt: DateTime.now(),
    );
    await _usersBox.put(demoUser.id, demoUser);
  }
  
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  Future<User?> getUserByEmail(String email) async {
    for (var user in _usersBox.values) {
      if (user.email == email) {
        return user;
      }
    }
    return null;
  }
  
  Future<User?> authenticateUser(String email, String password) async {
    final user = await getUserByEmail(email);
    if (user != null && user.password == _hashPassword(password)) {
      return user;
    }
    return null;
  }
  
  Future<User> registerUser(String email, String password, String name, int age) async {

    final existingUser = await getUserByEmail(email);
    if (existingUser != null) {
      throw Exception('Пользователь с таким email уже существует');
    }
    
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final newUser = User(
      id: userId,
      email: email,
      password: _hashPassword(password),
      name: name,
      age: age,
      createdAt: DateTime.now(),
    );
    
    await _usersBox.put(userId, newUser);
    return newUser;
  }
  
  Future<String> addHealthRecord(HealthRecord record) async {
    await _healthRecordsBox.put(record.id, record);
    return record.id;
  }
  
  List<HealthRecord> getHealthRecords(String userId, {String? type}) {
    final allRecords = _healthRecordsBox.values.toList();
    var filtered = allRecords.where((record) => record.userId == userId);
    
    if (type != null) {
      filtered = filtered.where((record) => record.type == type);
    }
    
    filtered = filtered.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return filtered.take(100).toList();
  }
  
  List<HealthRecord> getHealthRecordsByPeriod(
    String userId, 
    String type, 
    DateTime start, 
    DateTime end
  ) {
    return _healthRecordsBox.values
        .where((record) => 
          record.userId == userId &&
          record.type == type &&
          record.timestamp.isAfter(start) &&
          record.timestamp.isBefore(end))
        .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }
  
  Future<String> addJournalEntry(JournalEntry entry) async {
    await _journalBox.put(entry.id, entry);
    return entry.id;
  }
  
  List<JournalEntry> getJournalEntries(String userId) {
    return _journalBox.values
        .where((entry) => entry.userId == userId)
        .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp))
        ..take(50);
  }
  
  Future<void> deleteJournalEntry(String id) async {
    await _journalBox.delete(id);
  }
  
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }
  
  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }
  
  Map<String, dynamic> getHealthStatistics(
    String userId, 
    String type, 
    DateTime start, 
    DateTime end
  ) {
    final records = getHealthRecordsByPeriod(userId, type, start, end);
    
    if (records.isEmpty) {
      return {'min': 0, 'max': 0, 'avg': 0, 'count': 0};
    }
    
    final values = records.map((r) => r.value).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    
    return {
      'min': min,
      'max': max,
      'avg': avg,
      'count': values.length,
    };
  }
  
  Future<void> clearAllData() async {
    await _usersBox.clear();
    await _healthRecordsBox.clear();
    await _journalBox.clear();
    await _settingsBox.clear();
    await _createDemoUser();
  }
}