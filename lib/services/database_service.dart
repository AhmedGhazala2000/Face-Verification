import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('face_recognition.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        face_id TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // Create a new user
  Future<UserModel> createUser(UserModel user) async {
    final db = await database;
    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  // Get user by ID
  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);

    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  // Get user by face ID
  Future<UserModel?> getUserByFaceId(String faceId) async {
    final db = await database;
    final maps = await db.query('users', where: 'face_id = ?', whereArgs: [faceId]);

    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  // Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query('users', where: 'email = ?', whereArgs: [email]);

    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  // Get all users
  Future<List<UserModel>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users', orderBy: 'created_at DESC');
    return maps.map((map) => UserModel.fromMap(map)).toList();
  }

  // Update user
  Future<int> updateUser(UserModel user) async {
    final db = await database;
    return await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  // Delete user
  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // Delete user by face ID
  Future<int> deleteUserByFaceId(String faceId) async {
    final db = await database;
    return await db.delete('users', where: 'face_id = ?', whereArgs: [faceId]);
  }

  // Check if email exists
  Future<bool> emailExists(String email) async {
    final user = await getUserByEmail(email);
    return user != null;
  }

  // Get user count
  Future<int> getUserCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
