import 'package:flutter_test/flutter_test.dart';
import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/providers/bkash_provider.dart';
import 'package:hisabbox/services/providers/nagad_provider.dart';
import 'package:hisabbox/services/providers/rocket_provider.dart';

void main() {
  group('BkashProvider', () {
    final provider = BkashProvider();

    test('produces a sent transaction for matching SMS', () {
      const message =
          'You have sent Tk 1,500.00 to 01712345678 successfully. TrxID ABC123XYZ';
      final timestamp = DateTime(2024, 1, 1, 12, 0);

      final transaction = provider.parse('bKash', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.bkash);
      expect(transaction.type, TransactionType.sent);
      expect(transaction.amount, 1500.00);
      expect(transaction.recipient, '01712345678');
      expect(transaction.transactionId, 'ABC123XYZ');
    });

    test('produces a received transaction for matching SMS', () {
      const message =
          'You have received Tk 2,000.00 from 01798765432. TrxID DEF456GHI';
      final timestamp = DateTime(2024, 1, 2, 14, 30);

      final transaction = provider.parse('bKash', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.bkash);
      expect(transaction.type, TransactionType.received);
      expect(transaction.amount, 2000.00);
      expect(transaction.sender, '01798765432');
      expect(transaction.transactionId, 'DEF456GHI');
    });
  });

  group('NagadProvider', () {
    final provider = NagadProvider();

    test('produces a sent transaction for matching SMS', () {
      const message =
          'Send Money Tk 1,200.00 to 01812345678 successful. Trx ID: VWX456YZA';
      final timestamp = DateTime(2024, 1, 5, 9, 0);

      final transaction = provider.parse('Nagad', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.nagad);
      expect(transaction.type, TransactionType.sent);
      expect(transaction.amount, 1200.00);
      expect(transaction.recipient, '01812345678');
      expect(transaction.transactionId, 'VWX456YZA');
    });

    test('produces a received transaction for matching SMS', () {
      const message =
          'Received Tk 3,500.00 from 01998765432. Trx.ID: BCD789EFG';
      final timestamp = DateTime(2024, 1, 6, 11, 30);

      final transaction = provider.parse('Nagad', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.nagad);
      expect(transaction.type, TransactionType.received);
      expect(transaction.amount, 3500.00);
      expect(transaction.sender, '01998765432');
      expect(transaction.transactionId, 'BCD789EFG');
    });
  });

  group('RocketProvider', () {
    final provider = RocketProvider();

    test('produces a sent transaction for matching SMS', () {
      const message =
          'Tk 800.00 sent to 01712345678 successfully. TxnID: HIJ012KLM';
      final timestamp = DateTime(2024, 1, 7, 13, 0);

      final transaction = provider.parse('Rocket', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.rocket);
      expect(transaction.type, TransactionType.sent);
      expect(transaction.amount, 800.00);
      expect(transaction.recipient, '01712345678');
      expect(transaction.transactionId, 'HIJ012KLM');
    });

    test('produces a received transaction for matching SMS', () {
      const message =
          'Tk 2,500.00 received from 01898765432. TxnID: NOP345QRS';
      final timestamp = DateTime(2024, 1, 8, 15, 30);

      final transaction = provider.parse('Rocket', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.rocket);
      expect(transaction.type, TransactionType.received);
      expect(transaction.amount, 2500.00);
      expect(transaction.sender, '01898765432');
      expect(transaction.transactionId, 'NOP345QRS');
    });
  });
}
