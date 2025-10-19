import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:hisabbox/models/transaction.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hisabbox.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        provider TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        recipient TEXT,
        sender TEXT,
        transactionId TEXT NOT NULL,
        transactionHash TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        note TEXT,
        rawMessage TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_provider ON transactions(provider)
    ''');

    await db.execute('''
      CREATE INDEX idx_timestamp ON transactions(timestamp)
    ''');

    await db.execute('''
      CREATE INDEX idx_synced ON transactions(synced)
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_transaction_hash ON transactions(transactionHash)
    ''');
  }

  Future<String> insertTransaction(Transaction transaction) async {
    final db = await instance.database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return transaction.id;
  }

  @visibleForTesting
  Future<void> resetForTesting() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'hisabbox.db');
    await deleteDatabase(path);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          "ALTER TABLE transactions ADD COLUMN transactionHash TEXT");

      final existing = await db.query('transactions');
      final batch = db.batch();
      for (final row in existing) {
        final timestamp = DateTime.parse(row['timestamp'] as String);
        final hash = Transaction.generateHash(
          sender: row['sender'] as String?,
          messageBody: row['rawMessage'] as String,
          timestamp: timestamp,
        );
        batch.update(
          'transactions',
          {'transactionHash': hash},
          where: 'id = ?',
          whereArgs: [row['id'] as String],
        );
      }
      await batch.commit(noResult: true);

      final rows = await db.query(
        'transactions',
        columns: ['id', 'transactionHash'],
        orderBy: 'createdAt ASC',
      );
      final seen = <String>{};
      for (final row in rows) {
        final hash = row['transactionHash'] as String?;
        final id = row['id'] as String;
        if (hash == null || hash.isEmpty) {
          continue;
        }
        if (seen.contains(hash)) {
          await db.delete(
            'transactions',
            where: 'id = ?',
            whereArgs: [id],
          );
        } else {
          seen.add(hash);
        }
      }

      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_transaction_hash
        ON transactions(transactionHash)
      ''');
    }
  }

  Future<List<Transaction>> getTransactions({
    List<Provider>? providers,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    final db = await instance.database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (providers != null && providers.isNotEmpty) {
      final providerNames = providers.map((p) => "'${p.name}'").join(',');
      whereClause += ' AND provider IN ($providerNames)';
    }

    if (startDate != null) {
      whereClause += ' AND timestamp >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClause += ' AND timestamp <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final result = await db.query(
      'transactions',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return result.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<Transaction?> getTransactionById(String id) async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return Transaction.fromMap(result.first);
  }

  Future<List<Transaction>> getUnsyncedTransactions() async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'createdAt ASC',
    );

    return result.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> markAsSynced(String id) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTransaction(String id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getTransactionCount({List<Provider>? providers}) async {
    final db = await instance.database;
    
    String whereClause = '1=1';
    if (providers != null && providers.isNotEmpty) {
      final providerNames = providers.map((p) => "'${p.name}'").join(',');
      whereClause += ' AND provider IN ($providerNames)';
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions WHERE $whereClause',
    );
    
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<double> getTotalAmount({
    List<Provider>? providers,
    TransactionType? type,
  }) async {
    final db = await instance.database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (providers != null && providers.isNotEmpty) {
      final providerNames = providers.map((p) => "'${p.name}'").join(',');
      whereClause += ' AND provider IN ($providerNames)';
    }

    if (type != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(type.name);
    }

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE $whereClause',
      whereArgs.isEmpty ? null : whereArgs,
    );
    
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
