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

    test('parses real Cash In message', () {
      const message =
          'Cash In Tk 400.00 from 01700000001 successful. Fee Tk 0.00. Balance Tk 485.00. TrxID ABC1234XYZ at 13/11/2018 12:33. Mobile Recharge bKash korun.';
      final timestamp = DateTime(2018, 11, 13, 12, 33);

      final transaction = provider.parse('bKash', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.bkash);
      expect(transaction.type, TransactionType.cashin);
      expect(transaction.amount, 400.00);
      expect(transaction.sender, '01700000001');
      expect(transaction.transactionId, 'ABC1234XYZ');
    });

    test('parses real Send Money message', () {
      const message =
          'Send Money Tk 105.00 to 01700000002 successful. Ref . Fee Tk 0.00. Balance Tk 440.00. TrxID DEF5678ABC at 15/11/2018 10:05';
      final timestamp = DateTime(2018, 11, 15, 10, 5);

      final transaction = provider.parse('bKash', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.bkash);
      expect(transaction.type, TransactionType.sent);
      expect(transaction.amount, 105.00);
      expect(transaction.recipient, '01700000002');
      expect(transaction.transactionId, 'DEF5678ABC');
    });

    test('parses real Mobile Recharge confirmation message', () {
      const message =
          'Received Recharge request of Tk 50.00 for 01700000003. Fee Tk 0.00. Balance Tk 534.00. TrxID GHI9012DEF at 08/10/2018 19:53. Wait for confirmation.';
      final timestamp = DateTime(2018, 10, 8, 19, 53);

      final transaction = provider.parse('bKash', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.bkash);
      expect(transaction.type, TransactionType.payment);
      expect(transaction.amount, 50.00);
      expect(transaction.recipient, '01700000003');
      expect(transaction.transactionId, 'GHI9012DEF');
    });

    test('parses real Payment message', () {
      const message =
          'Payment of Tk 1.00 to TESTMERCHANT is successful. Balance Tk 122.01. TrxID JKL3456GHI at 16/10/2025 15:05';
      final timestamp = DateTime(2025, 10, 16, 15, 5);

      final transaction = provider.parse('bKash', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.bkash);
      expect(transaction.type, TransactionType.payment);
      expect(transaction.amount, 1.00);
      expect(transaction.recipient, 'TESTMERCHANT');
      expect(transaction.transactionId, 'JKL3456GHI');
    });

    test('parses received with Ref message', () {
      const message =
          'You have received Tk 400.00 from 01700000004. Ref TESTUSER. Fee Tk 0.00. Balance Tk 423.00. TrxID MNO7890JKL at 03/11/2018 11:30';
      final timestamp = DateTime(2018, 11, 3, 11, 30);

      final transaction = provider.parse('bKash', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.bkash);
      expect(transaction.type, TransactionType.received);
      expect(transaction.amount, 400.00);
      expect(transaction.sender, '01700000004');
      expect(transaction.transactionId, 'MNO7890JKL');
    });

    test('parses received message with no Ref', () {
      const message =
          'You have received Tk 100.00 from 01700000005.Ref . Fee Tk 0.00. Balance Tk 585.00. TrxID PQR1234MNO at 14/11/2018 08:10';
      final timestamp = DateTime(2018, 11, 14, 8, 10);

      final transaction = provider.parse('bKash', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.bkash);
      expect(transaction.type, TransactionType.received);
      expect(transaction.amount, 100.00);
      expect(transaction.sender, '01700000005');
      expect(transaction.transactionId, 'PQR1234MNO');
    });

    test('ignores verification code messages', () {
      const message =
          '<#> Your bKash verification code is 603872. It expires in 2 minutes. Please do NOT share this code and PIN with anyone. UID: wgBmYWuOA+X';
      final timestamp = DateTime(2018, 10, 8, 16, 23);

      final transaction = provider.parse('bKash', message, timestamp);

      expect(transaction, isNull);
    });

    test('ignores recharge success confirmation without TrxID', () {
      const message =
          'Your bKash Mobile Recharge request of Tk 50.00 for 01700000006 was successful. bKash App diye Mobile Recharge ekdom simple! Get App: http://android.bka.sh';
      final timestamp = DateTime(2018, 10, 8, 20, 10);

      final transaction = provider.parse('bKash', message, timestamp);

      expect(transaction, isNull);
    });

    test('ignores promotional messages', () {
      const message =
          'bKash Amazing Deals is here! Pay with bKash and get up to 20% Instant Cashback at 3500+ outlets of 350+ brands.For details, visit https://www.bkash.com/payment/';
      final timestamp = DateTime(2018, 11, 22, 19, 22);

      final transaction = provider.parse('bKash', message, timestamp);

      expect(transaction, isNull);
    });

    test('ignores bill check request messages', () {
      const message =
          'Your check bill request has been received. Please wait for confirmation.';
      final timestamp = DateTime(2018, 10, 25, 9, 32);

      final transaction = provider.parse('bKash', message, timestamp);

      expect(transaction, isNull);
    });

    test('ignores bill information messages', () {
      const message =
          'Biller: TESTBILLER\nAccount: 12345678\nAmount: 570.00\nMonth/Year: 09/2018\nPayment Status: UNPAID as on 25-OCT-2018 09:32:17 AM.';
      final timestamp = DateTime(2018, 10, 25, 9, 32);

      final transaction = provider.parse('bKash', message, timestamp);

      expect(transaction, isNull);
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
      const message = 'Tk 2,500.00 received from 01898765432. TxnID: NOP345QRS';
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
