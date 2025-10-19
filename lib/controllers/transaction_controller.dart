import 'package:get/get.dart';
import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/capture_settings_service.dart';
import 'package:hisabbox/services/database_service.dart';
import 'package:hisabbox/services/webhook_service.dart';

class TransactionController extends GetxController {
  final RxList<Transaction> transactions = <Transaction>[].obs;
  final RxBool isLoading = false.obs;
  final RxList<Provider> activeProviders = Provider.values.obs;
  final RxList<TransactionType> selectedTransactionTypes =
      List<TransactionType>.from(TransactionType.values).obs;
  int? _currentLimit = 30;

  @override
  void onInit() {
    super.onInit();
    _initialiseFilters();
  }

  Future<void> _initialiseFilters() async {
    try {
      final enabledTypes =
          await CaptureSettingsService.getEnabledTransactionTypes();
      selectedTransactionTypes.assignAll(enabledTypes);
    } catch (_) {
      selectedTransactionTypes.assignAll(TransactionType.values);
    }
    await loadTransactions();
  }

  Future<void> loadTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    bool updateLimit = false,
  }) async {
    isLoading.value = true;

    final effectiveLimit = updateLimit ? limit : (limit ?? _currentLimit);
    if (updateLimit) {
      _currentLimit = effectiveLimit;
    }

    try {
      final result = await DatabaseService.instance.getTransactions(
        providers: activeProviders.toList(growable: false),
        types: selectedTransactionTypes.toList(growable: false),
        startDate: startDate,
        endDate: endDate,
        limit: effectiveLimit,
      );
      transactions.assignAll(result);
    } catch (e) {
      // ignore: avoid_print
      print('Error loading transactions: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      await DatabaseService.instance.insertTransaction(transaction);
      await WebhookService.processNewTransaction(transaction);
      await loadTransactions();
    } catch (e) {
      // ignore: avoid_print
      print('Error adding transaction: $e');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await DatabaseService.instance.deleteTransaction(id);
      await loadTransactions();
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting transaction: $e');
    }
  }

  Future<void> setActiveProviders(List<Provider> providers) async {
    activeProviders.assignAll(providers);
    await loadTransactions();
  }

  Future<void> setSelectedTransactionTypes(
    List<TransactionType> transactionTypes,
  ) async {
    selectedTransactionTypes.assignAll(transactionTypes);
    await loadTransactions();
  }

  Future<void> syncWithWebhook() async {
    try {
      await WebhookService.syncTransactionsManually();
      await loadTransactions();
    } catch (e) {
      // ignore: avoid_print
      print('Error syncing with webhook: $e');
    }
  }

  Future<int> getTransactionCount() async {
    return DatabaseService.instance.getTransactionCount(
      providers: activeProviders.toList(growable: false),
    );
  }

  Future<double> getTotalSent() async {
    return DatabaseService.instance.getTotalAmount(
      providers: activeProviders.toList(growable: false),
      type: TransactionType.sent,
    );
  }

  Future<double> getTotalReceived() async {
    return DatabaseService.instance.getTotalAmount(
      providers: activeProviders.toList(growable: false),
      type: TransactionType.received,
    );
  }

  double get totalSent {
    return transactions
        .where(
          (t) =>
              t.type == TransactionType.sent ||
              t.type == TransactionType.cashout ||
              t.type == TransactionType.payment,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalReceived {
    return transactions
        .where(
          (t) =>
              t.type == TransactionType.received ||
              t.type == TransactionType.cashin,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get balance => totalReceived - totalSent;
}
