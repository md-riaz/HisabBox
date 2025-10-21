import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/database_service.dart';
import 'package:hisabbox/services/provider_settings_service.dart';
import 'package:hisabbox/services/providers/base_sms_provider.dart';
import 'package:hisabbox/services/webhook_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqflite_ffi.sqfliteFfiInit();
    sqflite.databaseFactory = sqflite_ffi.databaseFactoryFfi;
  });

  Future<void> enableSupportedProviders() async {
    await ProviderSettingsService.setProviderEnabled(Provider.bkash, true);
    await ProviderSettingsService.setProviderEnabled(Provider.nagad, true);
    await ProviderSettingsService.setProviderEnabled(Provider.rocket, true);
    await ProviderSettingsService.setProviderEnabled(Provider.bracBank, true);
  }

  setUp(() async {
    await DatabaseService.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    WebhookService.setHttpClientForTesting(
      Dio(
        BaseOptions(
          headers: const {'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      ),
    );
    await enableSupportedProviders();
  });

  group('BaseSmsProvider - bKash', () {
    test('parses bKash sent transaction', () async {
      const message =
          'You have sent Tk1,500.00 to 01712345678 successfully. Fee Tk25.00. TrxID ABC123XYZ at 2024-01-01 12:00:00';
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);

      final transaction = await BaseSmsProvider.parse(
        'bKash',
        message,
        timestamp,
      );

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.bkash);
      expect(transaction.type, TransactionType.sent);
      expect(transaction.amount, 1500.00);
      expect(transaction.recipient, '01712345678');
      expect(transaction.transactionId, 'ABC123XYZ');
    });

    test('parses bKash received transaction', () async {
      const message =
          'You have received Tk2,000.00 from 01798765432. TrxID DEF456GHI at 2024-01-02 14:30:00';
      final timestamp = DateTime(2024, 1, 2, 14, 30, 0);

      final transaction = await BaseSmsProvider.parse(
        'bKash',
        message,
        timestamp,
      );

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.bkash);
      expect(transaction.type, TransactionType.received);
      expect(transaction.amount, 2000.00);
      expect(transaction.sender, '01798765432');
      expect(transaction.transactionId, 'DEF456GHI');
    });

    test('parses bKash cash out transaction', () async {
      const message =
          'Cash Out Tk500.00 successful from 01612345678. Fee Tk10.00. TrxID JKL789MNO at 2024-01-03 10:15:00';
      final timestamp = DateTime(2024, 1, 3, 10, 15, 0);

      final transaction = await BaseSmsProvider.parse(
        'bKash',
        message,
        timestamp,
      );

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.bkash);
      expect(transaction.type, TransactionType.cashout);
      expect(transaction.amount, 500.00);
      expect(transaction.transactionId, 'JKL789MNO');
    });

    test('parses bKash payment transaction', () async {
      const message =
          'Payment of Tk750.00 to Merchant successful. TrxID PQR123STU at 2024-01-04 16:45:00';
      final timestamp = DateTime(2024, 1, 4, 16, 45, 0);

      final transaction = await BaseSmsProvider.parse(
        'bKash',
        message,
        timestamp,
      );

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.bkash);
      expect(transaction.type, TransactionType.payment);
      expect(transaction.amount, 750.00);
      expect(transaction.transactionId, 'PQR123STU');
    });

    test('parses bKash merchant payment with recipient name', () async {
      const message =
          'Payment of Tk 54.00 to Grameenphone Ltd-MyGP Direct Charge-RM50518 is successful. Balance Tk 13.91. TrxID CH428D66W2 at 04/08/2025 04:41';
      final timestamp = DateTime(2025, 8, 4, 4, 41);

      final transaction = await BaseSmsProvider.parse(
        'bKash',
        message,
        timestamp,
      );

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.bkash);
      expect(transaction.type, TransactionType.payment);
      expect(transaction.amount, 54.00);
      expect(
        transaction.recipient,
        'Grameenphone Ltd-MyGP Direct Charge-RM50518',
      );
      expect(transaction.transactionId, 'CH428D66W2');
    });

    test('parses bKash merchant payment with uppercase recipient', () async {
      const message =
          'Payment of Tk 1.00 to ALPHANET is successful. Balance Tk 122.01. TrxID CJG1C2P5R5 at 16/10/2025 15:05';
      final timestamp = DateTime(2025, 10, 16, 15, 5);

      final transaction = await BaseSmsProvider.parse(
        'bKash',
        message,
        timestamp,
      );

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.bkash);
      expect(transaction.type, TransactionType.payment);
      expect(transaction.amount, 1.00);
      expect(transaction.recipient, 'ALPHANET');
      expect(transaction.transactionId, 'CJG1C2P5R5');
    });

    test('parses bKash received deposit message', () async {
      const message =
          'You have received deposit from iBanking of Tk 1,500.00 from BRAC Bank Internet Banking. Fee Tk 0.00. Balance Tk 1,643.01. TrxID CJA161O7R1 at 10/10/2025 15:29';
      final timestamp = DateTime(2025, 10, 10, 15, 29);

      final transaction = await BaseSmsProvider.parse(
        'bKash',
        message,
        timestamp,
      );

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.bkash);
      expect(transaction.type, TransactionType.received);
      expect(transaction.amount, 1500.00);
      expect(transaction.sender, 'BRAC Bank Internet Banking');
      expect(transaction.transactionId, 'CJA161O7R1');
    });

    test('parses bKash bill payment summary', () async {
      const message =
          'Bill successfully paid.\nBiller: BrothersIT \nMMYYYY/Contact: 072025\nA/C: 1052 \nAmount: Tk 500.00 \nFee: Tk 0.00 \nTrxID: CHA0EEADZY at 10/08/2025 15:29';
      final timestamp = DateTime(2025, 8, 10, 15, 29);

      final transaction = await BaseSmsProvider.parse(
        'bKash',
        message,
        timestamp,
      );

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.bkash);
      expect(transaction.type, TransactionType.payment);
      expect(transaction.amount, 500.00);
      expect(transaction.recipient, 'BrothersIT');
      expect(transaction.transactionId, 'CHA0EEADZY');
    });
  });

  group('BaseSmsProvider - Nagad', () {
    test('parses Nagad sent transaction', () async {
      const message =
          'Send Money Tk 1,200.00 to 01812345678 successful. Trx ID: VWX456YZA';
      final timestamp = DateTime(2024, 1, 5, 9, 0, 0);

      final transaction = await BaseSmsProvider.parse(
        'Nagad',
        message,
        timestamp,
      );

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.nagad);
      expect(transaction.type, TransactionType.sent);
      expect(transaction.amount, 1200.00);
      expect(transaction.recipient, '01812345678');
      expect(transaction.transactionId, 'VWX456YZA');
    });

    test('parses Nagad received transaction', () async {
      const message =
          'Received Tk 3,500.00 from 01998765432. Trx.ID: BCD789EFG';
      final timestamp = DateTime(2024, 1, 6, 11, 30, 0);

      final transaction = await BaseSmsProvider.parse(
        'Nagad',
        message,
        timestamp,
      );

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.nagad);
      expect(transaction.type, TransactionType.received);
      expect(transaction.amount, 3500.00);
      expect(transaction.sender, '01998765432');
      expect(transaction.transactionId, 'BCD789EFG');
    });
  });

  group('BaseSmsProvider - Rocket', () {
    test('parses Rocket sent transaction', () async {
      const message =
          'Tk 800.00 sent to 01712345678 successfully. TxnID: HIJ012KLM';
      final timestamp = DateTime(2024, 1, 7, 13, 0, 0);

      final transaction = await BaseSmsProvider.parse(
        'Rocket',
        message,
        timestamp,
      );

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.rocket);
      expect(transaction.type, TransactionType.sent);
      expect(transaction.amount, 800.00);
      expect(transaction.recipient, '01712345678');
      expect(transaction.transactionId, 'HIJ012KLM');
    });

    test('parses Rocket received transaction', () async {
      const message = 'Tk 2,500.00 received from 01898765432. TxnID: NOP345QRS';
      final timestamp = DateTime(2024, 1, 8, 15, 30, 0);

      final transaction = await BaseSmsProvider.parse(
        'Rocket',
        message,
        timestamp,
      );

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.rocket);
      expect(transaction.type, TransactionType.received);
      expect(transaction.amount, 2500.00);
      expect(transaction.sender, '01898765432');
      expect(transaction.transactionId, 'NOP345QRS');
    });

    test('returns null when Rocket provider is disabled', () async {
      await ProviderSettingsService.setProviderEnabled(Provider.rocket, false);

      const message =
          'Tk 800.00 sent to 01712345678 successfully. TxnID: HIJ012KLM';
      final timestamp = DateTime(2024, 1, 7, 13, 0, 0);

      final transaction = await BaseSmsProvider.parse(
        'Rocket',
        message,
        timestamp,
      );

      expect(transaction, isNull);
    });
  });

  group('BaseSmsProvider - Bank', () {
    test('parses BRAC Bank debit transaction', () async {
      const message =
          'BRAC Bank: Your A/C debited by BDT 5,000.00 on 01-Jan-2024.';
      final timestamp = DateTime(2024, 1, 9, 10, 0, 0);

      final transaction = await BaseSmsProvider.parse(
        'BRACBANK',
        message,
        timestamp,
      );

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.bracBank);
      expect(transaction.type, TransactionType.sent);
      expect(transaction.amount, 5000.00);
    });
  });

  group('BaseSmsProvider - Invalid Messages', () {
    test('returns null for non-financial SMS', () async {
      const message = 'Hello, how are you?';
      final timestamp = DateTime.now();

      final transaction = await BaseSmsProvider.parse(
        'Unknown',
        message,
        timestamp,
      );

      expect(transaction, isNull);
    });

    test('returns null for unrecognized format', () async {
      const message = 'Some random text with amount 100';
      final timestamp = DateTime.now();

      final transaction = await BaseSmsProvider.parse(
        'RandomSender',
        message,
        timestamp,
      );

      expect(transaction, isNull);
    });

    test('does not parse known template from unverified sender', () async {
      const message =
          'You have sent Tk1,500.00 to 01712345678 successfully. Fee Tk25.00. TrxID ABC123XYZ at 2024-01-01 12:00:00';
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);

      final transaction = await BaseSmsProvider.parse(
        '01700000000',
        message,
        timestamp,
      );

      expect(transaction, isNull);
    });
  });

  group('BaseSmsProvider - Hashing and deduplication', () {
    test('generates identical hashes for duplicate messages', () async {
      const message =
          'You have sent Tk1,500.00 to 01712345678 successfully. Fee Tk25.00. TrxID ABC123XYZ at 2024-01-01 12:00:00';
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);

      final first = await BaseSmsProvider.parse('bKash', message, timestamp);
      final second = await BaseSmsProvider.parse('bKash', message, timestamp);

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(first!.transactionHash, second!.transactionHash);
    });

    test('ignores duplicate SMS and emits a single webhook call', () async {
      SharedPreferences.setMockInitialValues({
        'webhook_enabled': true,
        'webhook_url': 'https://example.com/webhook',
      });
      await enableSupportedProviders();

      const message =
          'You have received Tk2,000.00 from 01798765432. TrxID DEF456GHI at 2024-01-02 14:30:00';
      final timestamp = DateTime(2024, 1, 2, 14, 30, 0);

      final first = (await BaseSmsProvider.parse('bKash', message, timestamp))!;
      final duplicate = (await BaseSmsProvider.parse(
        'bKash',
        message,
        timestamp,
      ))!;

      await DatabaseService.instance.insertTransaction(first);
      await DatabaseService.instance.insertTransaction(duplicate);

      final db = await DatabaseService.instance.database;
      final rows = await db.query('transactions');
      expect(rows.length, 1);

      int callCount = 0;
      WebhookService.setHttpClientForTesting(
        Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                callCount++;
                handler.resolve(
                  Response(requestOptions: options, statusCode: 200, data: {}),
                );
              },
            ),
          ),
      );

      final success = await WebhookService.syncTransactions();
      expect(success, isTrue);
      expect(callCount, 1);

      // Subsequent syncs with the duplicate should not trigger new calls.
      final secondSync = await WebhookService.syncTransactions();
      expect(secondSync, isTrue);
      expect(callCount, 1);
    });
  });

  group('Sender ID overrides', () {
    test('uses updated sender IDs from preferences', () async {
      SharedPreferences.setMockInitialValues({
        'sender_ids_bkash': ['custombkash'],
      });
      await enableSupportedProviders();

      const message =
          'You have sent Tk1,500.00 to 01712345678 successfully. Fee Tk25.00. TrxID ABC123XYZ at 2024-01-01 12:00:00';
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);

      final transaction = await BaseSmsProvider.parse(
        'CustomBkash Alerts',
        message,
        timestamp,
      );

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.bkash);
    });

    test('falls back to defaults when overrides are empty', () async {
      SharedPreferences.setMockInitialValues({'sender_ids_rocket': <String>[]});
      await enableSupportedProviders();

      const message =
          'Tk 800.00 sent to 01712345678 successfully. TxnID: HIJ012KLM';
      final timestamp = DateTime(2024, 1, 7, 13, 0, 0);

      final transaction = await BaseSmsProvider.parse(
        'Rocket',
        message,
        timestamp,
      );

      expect(transaction, isNotNull);
      expect(transaction!.provider, Provider.rocket);
    });
  });
}
