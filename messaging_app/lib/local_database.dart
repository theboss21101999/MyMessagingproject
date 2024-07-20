import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();

  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('messages.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
CREATE TABLE messages (
  id $idType,
  sender $textType,
  receiver $textType,
  content $textType,
  timestamp $textType
  )
''');
  }

  Future<void> createMessage(Map<String, dynamic> message) async {
    final db = await instance.database;
    await db.insert('messages', message);
  }

  Future<List<Map<String, dynamic>>> readAllMessages() async {
    final db = await instance.database;
    return await db.query('messages');
  }

  Future<void> deleteOldMessages() async {
    final db = await instance.database;
    await db.delete('messages', where: 'timestamp < ?', whereArgs: [DateTime.now().subtract(Duration(days: 30)).toIso8601String()]);
  }
}
