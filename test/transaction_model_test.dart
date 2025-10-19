import 'package:flutter_test/flutter_test.dart';
import 'package:hisabbox/models/transaction.dart';

void main() {
  group('Transaction Model', () {
    test('creates transaction with all required fields', () {
      final transaction = Transaction(
        id: '123',
        provider: Provider.bkash,
        type: TransactionType.sent,
        amount: 1000.0,
        transactionId: 'TRX123',
        transactionHash: Transaction.generateHash(
          sender: null,
          messageBody: 'Test message',
          timestamp: DateTime(2024, 1, 1),
        ),
        timestamp: DateTime(2024, 1, 1),
        rawMessage: 'Test message',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(transaction.id, '123');
      expect(transaction.provider, Provider.bkash);
      expect(transaction.type, TransactionType.sent);
      expect(transaction.amount, 1000.0);
      expect(transaction.transactionId, 'TRX123');
      expect(transaction.synced, false);
    });

    test('converts transaction to map', () {
      final transaction = Transaction(
        id: '123',
        provider: Provider.nagad,
        type: TransactionType.received,
        amount: 500.0,
        recipient: '01712345678',
        transactionId: 'TRX456',
        transactionHash: Transaction.generateHash(
          sender: '01712345678',
          messageBody: 'Test message',
          timestamp: DateTime(2024, 1, 1),
        ),
        timestamp: DateTime(2024, 1, 1),
        rawMessage: 'Test message',
        createdAt: DateTime(2024, 1, 1),
      );

      final map = transaction.toMap();

      expect(map['id'], '123');
      expect(map['provider'], 'nagad');
      expect(map['type'], 'received');
      expect(map['amount'], 500.0);
      expect(map['recipient'], '01712345678');
      expect(map['synced'], 0);
    });

    test('creates transaction from map', () {
      final map = {
        'id': '789',
        'provider': 'rocket',
        'type': 'cashout',
        'amount': 300.0,
        'transactionId': 'TRX789',
        'transactionHash': Transaction.generateHash(
          sender: null,
          messageBody: 'Test message',
          timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        ),
        'timestamp': '2024-01-01T12:00:00.000',
        'rawMessage': 'Test message',
        'synced': 1,
        'createdAt': '2024-01-01T12:00:00.000',
      };

      final transaction = Transaction.fromMap(map);

      expect(transaction.id, '789');
      expect(transaction.provider, Provider.rocket);
      expect(transaction.type, TransactionType.cashout);
      expect(transaction.amount, 300.0);
      expect(transaction.transactionId, 'TRX789');
      expect(transaction.synced, true);
    });

    test('copyWith creates new transaction with updated fields', () {
      final original = Transaction(
        id: '123',
        provider: Provider.bkash,
        type: TransactionType.sent,
        amount: 1000.0,
        transactionId: 'TRX123',
        transactionHash: Transaction.generateHash(
          sender: null,
          messageBody: 'Test message',
          timestamp: DateTime(2024, 1, 1),
        ),
        timestamp: DateTime(2024, 1, 1),
        rawMessage: 'Test message',
        synced: false,
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = original.copyWith(synced: true);

      expect(updated.id, '123');
      expect(updated.synced, true);
      expect(original.synced, false); // Original unchanged
    });

    test('toJson serializes correctly', () {
      final transaction = Transaction(
        id: '123',
        provider: Provider.bank,
        type: TransactionType.payment,
        amount: 750.0,
        transactionId: 'TRX999',
        transactionHash: Transaction.generateHash(
          sender: null,
          messageBody: 'Test message',
          timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        ),
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        rawMessage: 'Test message',
        createdAt: DateTime(2024, 1, 1, 12, 0, 0),
      );

      final json = transaction.toJson();

      expect(json['id'], '123');
      expect(json['provider'], 'bank');
      expect(json['type'], 'payment');
      expect(json['amount'], 750.0);
    });
  });
}
