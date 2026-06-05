import 'dart:developer';

import 'package:dukunsaldo_fe/models/model_users.dart';
import 'package:dukunsaldo_fe/models/transactions_model.dart';
import 'package:dukunsaldo_fe/models/log_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dukunSaldo.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path, 
      version: 2, 
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          date TEXT NOT NULL,
          type TEXT NOT NULL
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    // 1. BUAT TABEL USERS (Untuk Login/Register)
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL, 
        password TEXT NOT NULL
      )
    ''');

    // 2. BUAT TABEL TRANSAKSI (Untuk nanti)
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        merchantName TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // 3. BUAT TABEL LOGS (Untuk Notifikasi)
    await db.execute('''
      CREATE TABLE logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');
  }

  // fungsi buat cek email
  Future<bool> checkEmailExist(String email) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }

  // fungsi buat register
  Future<bool> registerUser(UserModelSql user) async {
    final db = await instance.database;
    try {
      await db.insert("users", user.toMap());
      return true;
    } catch (e) {
      log(e.toString());
      return false;
    }
  }

  // untuk login
  Future<UserModelSql?> loginUser(UserModelSql user) async {
    final db = await instance.database;

    final List<Map<String, dynamic>> results = await db.query(
      "users",
      where: 'email = ? AND password = ?',
      whereArgs: [user.email, user.password],
    );
    log(results.toString());

    if (results.isNotEmpty) {
      return UserModelSql.fromMap(results.first);
    }
    return null;
  }

  // mengambil semua data user
  Future<List<UserModelSql>> getAllUsers() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> results = await db.query("users");

    return results.map((map) => UserModelSql.fromMap(map)).toList();
  }

  // Fungsi untuk menghapus user berdasarkan ID
  Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // update data user
  Future<bool> updateUser(UserModelSql user) async {
    final db = await instance.database;
    try {
      int count = await db.update(
        "users",
        user.toMap(),
        where: "id = ?",
        whereArgs: [user.id],
      );

      return count > 0;
    } catch (e) {
      return false;
    }
  }

  // Fungsi untuk mengecek isi tabel users di terminal
  Future<void> checkUsersData() async {
    final db = await instance.database;
    final result = await db.query('users');

    print("=== ISI TABEL USERS ===");
    for (var user in result) {
      print(user);
    }
    print("=======================");
  }

  Future<bool> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    try {
      await db.insert('transactions', transaction.toMap());
      return true;
    } catch (e) {
      log("Error insert transaction: ${e.toString()}");
      return false;
    }
  }

  // 2. Fungsi Ambil Semua Transaksi (Urut dari yang paling baru)
  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'transactions',
      orderBy: 'id DESC',
    );

    return results.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByUserId(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      "transactions",
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return results.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // delete transaksi
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // update transaksi
  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // ===================== LOGS =====================
  Future<bool> insertLog(LogModel logData) async {
    final db = await database;
    try {
      await db.insert('logs', logData.toMap());
      return true;
    } catch (e) {
      log("Error insert log: ${e.toString()}");
      return false;
    }
  }

  Future<List<LogModel>> getLogsByUserId(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'logs',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'id DESC', // Urutkan dari yang terbaru
    );

    return results.map((map) => LogModel.fromMap(map)).toList();
  }
}
