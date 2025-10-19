import 'package:flutter_test/flutter_test.dart';
import 'package:hisabbox/controllers/transaction_controller.dart';
import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/database_service.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqflite_ffi.sqfliteFfiInit();
    sqflite.databaseFactory = sqflite_ffi.databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseService.instance.resetForTesting();
  });

  test('loadTransactions respects selected transaction types', () async {
    final baseTimestamp = DateTime(2024, 1, 1);
    final transactions = [
      _buildTransaction(
        id: 'sent',
        type: TransactionType.sent,
        timestamp: baseTimestamp,
      ),
      _buildTransaction(
        id: 'received',
        type: TransactionType.received,
        timestamp: baseTimestamp.add(const Duration(minutes: 1)),
      ),
      _buildTransaction(
        id: 'cashout',
        type: TransactionType.cashout,
        timestamp: baseTimestamp.add(const Duration(minutes: 2)),
      ),
    ];

    for (final transaction in transactions) {
      await DatabaseService.instance.insertTransaction(transaction);
    }

    final controller = TransactionController();
    addTearDown(controller.dispose);

    await controller.loadTransactions(limit: 10);
    expect(controller.transactions.length, transactions.length);

    await controller.setSelectedTransactionTypes([TransactionType.received]);
    expect(controller.selectedTransactionTypes.toList(), [
      TransactionType.received,
    ]);
    expect(controller.transactions.length, 1);
    expect(controller.transactions.first.type, TransactionType.received);

    await controller.setSelectedTransactionTypes([
      TransactionType.sent,
      TransactionType.cashout,
    ]);
    expect(controller.selectedTransactionTypes.toList(), [
      TransactionType.sent,
      TransactionType.cashout,
    ]);
    expect(controller.transactions.length, 2);
    expect(
      controller.transactions.every(
        (transaction) =>
            transaction.type == TransactionType.sent ||
            transaction.type == TransactionType.cashout,
      ),
      isTrue,
    );
  });
}

Transaction _buildTransaction({
  required String id,
  required TransactionType type,
  required DateTime timestamp,
}) {
  return Transaction(
    id: id,
    provider: Provider.bkash,
    type: type,
    amount: 100.0,
    recipient: 'recipient',
    sender: 'sender',
    transactionId: 'trx_$id',
    transactionHash: 'hash_$id',
    timestamp: timestamp,
    note: 'note',
    rawMessage: 'raw message',
    synced: false,
    createdAt: timestamp,
  );
}
