import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    return _database ??= await _initDB();
  }

  Future<Database> _initDB() async {
    final path = join((await getApplicationDocumentsDirectory()).path, 'aqi_history.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT UNIQUE, 
            AQI REAL,
            Temperature REAL,
            Humidity REAL,
            timestamp INTEGER,
            isRandom INTEGER DEFAULT 0
          )
        ''');
        await _insertSixDaysRandomPastData(db);
      },
    );
  }

  Future<void> _insertSixDaysRandomPastData(Database db) async {
    final random = Random();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
    print('Initializing with 6 days of past sample data...');
    
    for (int i = 1; i <= 6; i++) {
      final date = yesterday.subtract(Duration(days: i - 1));
      await db.insert(
        'history',
        {
          'date': date.toIso8601String().split('T')[0],
          'AQI': 30.0 + random.nextDouble() * 200,
          'Temperature': 20.0 + random.nextDouble() * 15,
          'Humidity': 40.0 + random.nextDouble() * 40,
          'timestamp': date.millisecondsSinceEpoch,
          'isRandom': 1
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> upsertDailyData(double aqi, double temp, double humidity) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    await db.insert(
      'history',
      {
        'date': today,
        'AQI': aqi,
        'Temperature': temp,
        'Humidity': humidity,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isRandom': 0
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getHistoricalData() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    final history = await db.query(
      'history',
      orderBy: 'date DESC',
      limit: 7
    );
    
    if (history.isEmpty || history.first['date'] != today) {
      return [
        {'date': today, 'AQI': null, 'Temperature': null, 'Humidity': null},
        ...history.take(6)
      ];
    }
    return history;
  }

  Future<List<Map<String, dynamic>>> getLastSevenDaysExcludingToday() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    return await db.query(
      'history',  
      where: 'date != ?',
      whereArgs: [today],
      orderBy: 'date DESC',
      limit: 6
    );
  }

  Future<void> clearOldData() async {
    final db = await database;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    await db.delete(
      'history',
      where: 'date < ?',
      whereArgs: [sevenDaysAgo.toIso8601String().split('T')[0]]
    );
  }
}