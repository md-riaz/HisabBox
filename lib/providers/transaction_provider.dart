import 'package:flutter/foundation.dart';
import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/database_service.dart';
import 'package:hisabbox/services/webhook_service.dart';

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  List<Provider> _activeProviders = Provider.values;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  List<Provider> get activeProviders => _activeProviders;

  Future<void> loadTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await DatabaseService.instance.getTransactions(
        providers: _activeProviders,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('Error loading transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      await DatabaseService.instance.insertTransaction(transaction);
      await loadTransactions();
    } catch (e) {
      print('Error adding transaction: $e');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await DatabaseService.instance.deleteTransaction(id);
      await loadTransactions();
    } catch (e) {
      print('Error deleting transaction: $e');
    }
  }

  void setActiveProviders(List<Provider> providers) {
    _activeProviders = providers;
    loadTransactions();
  }

  Future<void> syncWithWebhook() async {
    try {
      await WebhookService.syncTransactions();
      await loadTransactions();
    } catch (e) {
      print('Error syncing with webhook: $e');
    }
  }

  Future<int> getTransactionCount() async {
    return await DatabaseService.instance.getTransactionCount(
      providers: _activeProviders,
    );
  }

  Future<double> getTotalSent() async {
    return await DatabaseService.instance.getTotalAmount(
      providers: _activeProviders,
      type: TransactionType.sent,
    );
  }

  Future<double> getTotalReceived() async {
    return await DatabaseService.instance.getTotalAmount(
      providers: _activeProviders,
      type: TransactionType.received,
    );
  }

  double get totalSent {
    return _transactions
        .where((t) => t.type == TransactionType.sent || t.type == TransactionType.cashout || t.type == TransactionType.payment)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalReceived {
    return _transactions
        .where((t) => t.type == TransactionType.received || t.type == TransactionType.cashin)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get balance {
    return totalReceived - totalSent;
  }
}
