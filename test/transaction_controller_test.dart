import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hisabbox/controllers/transaction_controller.dart';
import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/database_service.dart';

import 'helpers/fake_database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Get.testMode = true;

  late DatabaseServiceBase originalDatabaseService;
  late FakeDatabaseService fakeDatabaseService;

  Transaction buildTransaction(String id, TransactionType type) {
    return Transaction(
      id: id,
      provider: Provider.bkash,
      type: type,
      amount: 100.0,
      recipient: 'recipient',
      sender: 'sender',
      transactionId: 'trx$id',
      timestamp: DateTime.now(),
      note: null,
      rawMessage: 'message',
      synced: false,
      createdAt: DateTime.now(),
    );
  }

  setUp(() {
    originalDatabaseService = DatabaseService.instance;
    fakeDatabaseService = FakeDatabaseService();
    DatabaseService.instance = fakeDatabaseService;
  });

  tearDown(() {
    DatabaseService.instance = originalDatabaseService;
    Get.reset();
  });

  test('loadTransactions requests all transaction types by default', () async {
    fakeDatabaseService.enqueueTransactions(const []);
    final controller = TransactionController();

    await controller.loadTransactions();

    expect(
      fakeDatabaseService.recordedTransactionTypeFilters.single,
      TransactionType.values,
    );
  });

  test(
    'setActiveTransactionTypes updates selections and reloads transactions',
    () async {
      final initialTransaction = buildTransaction('1', TransactionType.sent);
      final filteredTransaction = buildTransaction(
        '2',
        TransactionType.received,
      );
      fakeDatabaseService
        ..enqueueTransactions([initialTransaction])
        ..enqueueTransactions([filteredTransaction]);

      final controller = TransactionController();

      await controller.loadTransactions();
      expect(controller.transactions.toList(), [initialTransaction]);

      final selectedTypes = [TransactionType.received, TransactionType.refund];
      await controller.setActiveTransactionTypes(selectedTypes);

      expect(controller.activeTransactionTypes.toList(), selectedTypes);
      expect(
        fakeDatabaseService.recordedTransactionTypeFilters.last,
        selectedTypes,
      );
      expect(controller.transactions.toList(), [filteredTransaction]);
    },
  );
}
