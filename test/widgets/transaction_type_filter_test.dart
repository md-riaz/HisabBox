import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hisabbox/controllers/transaction_controller.dart';
import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/database_service.dart';
import 'package:hisabbox/widgets/transaction_type_filter.dart';

import '../helpers/fake_database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    Get.testMode = true;
    originalDatabaseService = DatabaseService.instance;
    fakeDatabaseService = FakeDatabaseService();
    DatabaseService.instance = fakeDatabaseService;
  });

  tearDown(() {
    DatabaseService.instance = originalDatabaseService;
    Get.reset();
  });

  testWidgets('toggling chips updates controller filters and transactions', (
    tester,
  ) async {
    final initialTransaction = buildTransaction('1', TransactionType.received);
    final filteredTransaction = buildTransaction('2', TransactionType.sent);
    fakeDatabaseService
      ..enqueueTransactions([initialTransaction])
      ..enqueueTransactions([filteredTransaction]);

    final controller = TransactionController();
    Get.put(controller);

    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: TransactionTypeFilter())),
    );
    await tester.pumpAndSettle();

    expect(controller.transactions.toList(), [initialTransaction]);

    final receivedFinder = find.text('Received');
    expect(receivedFinder, findsOneWidget);

    await tester.tap(receivedFinder);
    await tester.pumpAndSettle();

    final expectedTypes = TransactionType.values.where(
      (t) => t != TransactionType.received,
    );
    expect(
      controller.activeTransactionTypes.contains(TransactionType.received),
      isFalse,
    );
    expect(controller.activeTransactionTypes, containsAll(expectedTypes));
    expect(
      fakeDatabaseService.recordedTransactionTypeFilters.last,
      expectedTypes.toList(),
    );
    expect(controller.transactions.toList(), [filteredTransaction]);
  });
}
