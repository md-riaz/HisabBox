import 'package:flutter_test/flutter_test.dart';
import 'package:hisabbox/services/sms_parser.dart';
import 'package:hisabbox/models/transaction.dart';

void main() {
  group('SmsParser - bKash', () {
    test('parses bKash sent transaction', () {
      const message = 'You have sent Tk1,500.00 to 01712345678 successfully. Fee Tk25.00. TrxID ABC123XYZ at 2024-01-01 12:00:00';
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
      
      final transaction = SmsParser.parse('bKash', message, timestamp);
      
      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.bkash);
      expect(transaction.type, TransactionType.sent);
      expect(transaction.amount, 1500.00);
      expect(transaction.recipient, '01712345678');
      expect(transaction.transactionId, 'ABC123XYZ');
    });

    test('parses bKash received transaction', () {
      const message = 'You have received Tk2,000.00 from 01798765432. TrxID DEF456GHI at 2024-01-02 14:30:00';
      final timestamp = DateTime(2024, 1, 2, 14, 30, 0);
      
      final transaction = SmsParser.parse('bKash', message, timestamp);
      
      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.bkash);
      expect(transaction.type, TransactionType.received);
      expect(transaction.amount, 2000.00);
      expect(transaction.sender, '01798765432');
      expect(transaction.transactionId, 'DEF456GHI');
    });

    test('parses bKash cash out transaction', () {
      const message = 'Cash Out Tk500.00 successful from 01612345678. Fee Tk10.00. TrxID JKL789MNO at 2024-01-03 10:15:00';
      final timestamp = DateTime(2024, 1, 3, 10, 15, 0);
      
      final transaction = SmsParser.parse('bKash', message, timestamp);
      
      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.bkash);
      expect(transaction.type, TransactionType.cashout);
      expect(transaction.amount, 500.00);
      expect(transaction.transactionId, 'JKL789MNO');
    });

    test('parses bKash payment transaction', () {
      const message = 'Payment of Tk750.00 to Merchant successful. TrxID PQR123STU at 2024-01-04 16:45:00';
      final timestamp = DateTime(2024, 1, 4, 16, 45, 0);
      
      final transaction = SmsParser.parse('bKash', message, timestamp);
      
      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.bkash);
      expect(transaction.type, TransactionType.payment);
      expect(transaction.amount, 750.00);
      expect(transaction.transactionId, 'PQR123STU');
    });
  });

  group('SmsParser - Nagad', () {
    test('parses Nagad sent transaction', () {
      const message = 'Send Money Tk 1,200.00 to 01812345678 successful. Trx ID: VWX456YZA';
      final timestamp = DateTime(2024, 1, 5, 9, 0, 0);
      
      final transaction = SmsParser.parse('Nagad', message, timestamp);
      
      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.nagad);
      expect(transaction.type, TransactionType.sent);
      expect(transaction.amount, 1200.00);
      expect(transaction.recipient, '01812345678');
      expect(transaction.transactionId, 'VWX456YZA');
    });

    test('parses Nagad received transaction', () {
      const message = 'Received Tk 3,500.00 from 01998765432. Trx.ID: BCD789EFG';
      final timestamp = DateTime(2024, 1, 6, 11, 30, 0);
      
      final transaction = SmsParser.parse('Nagad', message, timestamp);
      
      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.nagad);
      expect(transaction.type, TransactionType.received);
      expect(transaction.amount, 3500.00);
      expect(transaction.sender, '01998765432');
      expect(transaction.transactionId, 'BCD789EFG');
    });
  });

  group('SmsParser - Rocket', () {
    test('parses Rocket sent transaction', () {
      const message = 'Tk 800.00 sent to 01712345678 successfully. TxnID: HIJ012KLM';
      final timestamp = DateTime(2024, 1, 7, 13, 0, 0);
      
      final transaction = SmsParser.parse('Rocket', message, timestamp);
      
      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.rocket);
      expect(transaction.type, TransactionType.sent);
      expect(transaction.amount, 800.00);
      expect(transaction.recipient, '01712345678');
      expect(transaction.transactionId, 'HIJ012KLM');
    });

    test('parses Rocket received transaction', () {
      const message = 'Tk 2,500.00 received from 01898765432. TxnID: NOP345QRS';
      final timestamp = DateTime(2024, 1, 8, 15, 30, 0);
      
      final transaction = SmsParser.parse('Rocket', message, timestamp);
      
      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.rocket);
      expect(transaction.type, TransactionType.received);
      expect(transaction.amount, 2500.00);
      expect(transaction.sender, '01898765432');
      expect(transaction.transactionId, 'NOP345QRS');
    });
  });

  group('SmsParser - Bank', () {
    test('parses bank debit transaction', () {
      const message = 'Your A/C debited by BDT 5,000.00 on 01-Jan-2024. Balance: 15,000.00';
      final timestamp = DateTime(2024, 1, 9, 10, 0, 0);
      
      final transaction = SmsParser.parse('BankSMS', message, timestamp);
      
      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.bank);
      expect(transaction.type, TransactionType.sent);
      expect(transaction.amount, 5000.00);
    });

    test('parses bank credit transaction', () {
      const message = 'Your A/C credited with Tk 10,000.00 on 02-Jan-2024. Balance: 25,000.00';
      final timestamp = DateTime(2024, 1, 10, 12, 0, 0);
      
      final transaction = SmsParser.parse('BankSMS', message, timestamp);
      
      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.bank);
      expect(transaction.type, TransactionType.received);
      expect(transaction.amount, 10000.00);
    });
  });

  group('SmsParser - Invalid Messages', () {
    test('returns null for non-financial SMS', () {
      const message = 'Hello, how are you?';
      final timestamp = DateTime.now();
      
      final transaction = SmsParser.parse('Unknown', message, timestamp);
      
      expect(transaction, isNull);
    });

    test('returns null for unrecognized format', () {
      const message = 'Some random text with amount 100';
      final timestamp = DateTime.now();
      
      final transaction = SmsParser.parse('RandomSender', message, timestamp);
      
      expect(transaction, isNull);
    });
  });
}
