import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/health_record.dart';
import '../models/journal_entry.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'health_monitor.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Таблица пользователей
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Таблица записей здоровья
    await db.execute('''
      CREATE TABLE health_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        value REAL NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    // Таблица журнала
    await db.execute('''
      CREATE TABLE journal_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        severity TEXT
      )
    ''');
  }

  // Методы для пользователей
  Future<int> insertUser(User user) async {
    Database db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserByEmail(String email) async {
    Database db = await database;
    List<Map> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  // Методы для записей здоровья
  Future<int> insertHealthRecord(HealthRecord record) async {
    Database db = await database;
    return await db.insert('health_records', record.toMap());
  }

  Future<List<HealthRecord>> getHealthRecordsByPeriod(
    String userId,
    String type,
    DateTime startDate,
    DateTime endDate,
  ) async {
    Database db = await database;
    List<Map> maps = await db.query(
      'health_records',
      where: 'user_id = ? AND type = ? AND timestamp BETWEEN ? AND ?',
      whereArgs: [
        userId,
        type,
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) {
      return HealthRecord.fromMap(maps[i] as Map<String, dynamic>);
    });
  }

  // Методы для журнала
  Future<int> insertJournalEntry(JournalEntry entry) async {
    Database db = await database;
    return await db.insert('journal_entries', entry.toMap());
  }

  Future<List<JournalEntry>> getJournalEntries(String userId) async {
    Database db = await database;
    List<Map> maps = await db.query(
      'journal_entries',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) {
      return JournalEntry.fromMap(maps[i] as Map<String, dynamic>);
    });
  }

  Future<int> deleteJournalEntry(int id) async {
    Database db = await database;
    return await db.delete(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}