import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:hisabbox/models/transaction.dart';

abstract class DatabaseServiceBase {
  Future<Database> get database;

  Future<String> insertTransaction(Transaction transaction);

  Future<List<Transaction>> getTransactions({
    List<Provider>? providers,
    List<TransactionType>? transactionTypes,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  });

  Future<Transaction?> getTransactionById(String id);

  Future<List<Transaction>> getUnsyncedTransactions();

  Future<int> updateTransaction(Transaction transaction);

  Future<int> markAsSynced(String id);

  Future<int> deleteTransaction(String id);

  Future<int> getTransactionCount({List<Provider>? providers});

  Future<double> getTotalAmount({
    List<Provider>? providers,
    TransactionType? type,
  });

  Future<void> close();
}

class DatabaseService implements DatabaseServiceBase {
  static DatabaseServiceBase instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  @override
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hisabbox.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
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
  }

  @override
  Future<String> insertTransaction(Transaction transaction) async {
    final db = await instance.database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return transaction.id;
  }

  @override
  Future<List<Transaction>> getTransactions({
    List<Provider>? providers,
    List<TransactionType>? transactionTypes,
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

    if (transactionTypes != null && transactionTypes.isNotEmpty) {
      final typeNames = transactionTypes.map((t) => "'${t.name}'").join(',');
      whereClause += ' AND type IN ($typeNames)';
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

  @override
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

  @override
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

  @override
  Future<int> updateTransaction(Transaction transaction) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  @override
  Future<int> markAsSynced(String id) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> deleteTransaction(String id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  @override
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

  @override
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

  @override
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
