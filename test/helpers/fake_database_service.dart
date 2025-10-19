import 'dart:collection';

import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

class FakeDatabaseService implements DatabaseServiceBase {
  FakeDatabaseService();

  final Queue<List<Transaction>> _queuedTransactionResponses = Queue();
  final List<List<TransactionType>?> recordedTransactionTypeFilters = [];
  List<Transaction> fallbackTransactions = const [];

  void enqueueTransactions(List<Transaction> transactions) {
    _queuedTransactionResponses.add(List<Transaction>.from(transactions));
  }

  @override
  Future<Database> get database async => throw UnimplementedError();

  @override
  Future<void> close() async {}

  @override
  Future<int> deleteTransaction(String id) async => throw UnimplementedError();

  @override
  Future<List<Transaction>> getTransactions({
    List<Provider>? providers,
    List<TransactionType>? transactionTypes,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    recordedTransactionTypeFilters.add(transactionTypes);
    if (_queuedTransactionResponses.isNotEmpty) {
      return _queuedTransactionResponses.removeFirst();
    }
    return List<Transaction>.from(fallbackTransactions);
  }

  @override
  Future<int> getTransactionCount({List<Provider>? providers}) async =>
      throw UnimplementedError();

  @override
  Future<double> getTotalAmount({
    List<Provider>? providers,
    TransactionType? type,
  }) async => throw UnimplementedError();

  @override
  Future<Transaction?> getTransactionById(String id) async =>
      throw UnimplementedError();

  @override
  Future<List<Transaction>> getUnsyncedTransactions() async =>
      throw UnimplementedError();

  @override
  Future<String> insertTransaction(Transaction transaction) async =>
      throw UnimplementedError();

  @override
  Future<int> markAsSynced(String id) async => throw UnimplementedError();

  @override
  Future<int> updateTransaction(Transaction transaction) async =>
      throw UnimplementedError();
}
