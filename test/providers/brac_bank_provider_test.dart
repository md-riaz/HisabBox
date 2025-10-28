import 'package:flutter_test/flutter_test.dart';
import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/providers/bank/brac_bank_provider.dart';

void main() {
  late BracBankProvider provider;

  setUp(() {
    provider = BracBankProvider();
  });

  group('BracBankProvider - Sender ID Matching', () {
    test('matches BRAC-BANK sender', () {
      expect(provider.matches('BRAC-BANK', ''), true);
    });

    test('matches bracbank sender', () {
      expect(provider.matches('bracbank', ''), true);
    });

    test('matches brac sender', () {
      expect(provider.matches('brac', ''), true);
    });

    test('matches case insensitive', () {
      expect(provider.matches('BrAc-BaNk', ''), true);
    });

    test('rejects non-matching sender without body match', () {
      expect(provider.matches('random', 'some message'), false);
    });

    test('matches by body content when sender unknown', () {
      expect(provider.matches('unknown', 'Your BRAC Bank account'), true);
    });
  });

  group('BracBankProvider - Fund Transfer (Debit)', () {
    test('parses within bank transfer', () {
      const message =
          'Tk 700.00 has been transferred from your BBL A/C: 07011**001 to A/C: 07011**002. Available balance is Tk5,720.88. Queries: call 16221.';
      final timestamp = DateTime(2024, 8, 24, 11, 45, 47);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.type, TransactionType.sent);
      expect(transaction.amount, 700.00);
      expect(transaction.provider, Provider.bracBank);
    });

    test('parses bKash transfer', () {
      const message =
          'Tk 500.00 has been transferred from your BBL A/C: 07011**001 to BKASH wallet: 017XXXXXXXX. Available balance is Tk 39,623.96. Queries: call 16221.';
      final timestamp = DateTime(2024, 9, 4, 14, 36, 25);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.type, TransactionType.sent);
      expect(transaction.amount, 500.00);
    });

    test('parses Rocket transfer', () {
      const message =
          'Tk 5,000.00 has been transferred from your BBL A/C: 07011**001 to Rocket wallet: 017XXXXXXXX. Available balance is Tk 34,623.96. Queries: call 16221.';
      final timestamp = DateTime(2024, 9, 6, 9, 5, 49);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.type, TransactionType.sent);
      expect(transaction.amount, 5000.00);
    });

    test('parses local transfer (other bank)', () {
      const message =
          'Tk 14,000.00 has been transferred from your BBL A/C: 07011**001 to A/C: 04934**450. Available balance is Tk. 12,083.96. Queries: call 16221.';
      final timestamp = DateTime(2024, 9, 23, 10, 25, 27);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.type, TransactionType.sent);
      expect(transaction.amount, 14000.00);
    });

    test('parses NPSB payment transfer', () {
      const message =
          'Tk 7,000.00 has been transferred from your BBL A/C: 07011**001 to A/C: 20501**900. Available balance is Tk. 201.27. Queries: call 16221.';
      final timestamp = DateTime(2024, 11, 9, 11, 32, 56);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.type, TransactionType.sent);
      expect(transaction.amount, 7000.00);
    });

    test('parses mobile topup recharge', () {
      const message =
          'BDT 100.00 has been paid from your BBL A/C: 07011**001 to mobile no. 015XXXXXXXX. Available balance is BDT 24,338.30. Queries: call 16221.';
      final timestamp = DateTime(2025, 2, 11, 8, 56, 44);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.type, TransactionType.sent);
      expect(transaction.amount, 100.00);
    });

    test('parses transfer with masked account number', () {
      const message =
          'Tk 4,000.00 has been transferred from your BBL A/C: 07011**001 to A/C: 07011**001. Available balance is Tk16,410.39. Queries: call 16221.';
      final timestamp = DateTime(2025, 1, 15, 10, 20, 7);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.type, TransactionType.sent);
      expect(transaction.amount, 4000.00);
    });

    test('parses transfer to one-off beneficiary', () {
      const message =
          'Tk 150.00 has been transferred from your BBL A/C: 07011**001 to BKASH wallet: 016XXXXXXXX. Available balance is Tk 2,313.53. Queries: call 16221.';
      final timestamp = DateTime(2024, 12, 26, 12, 40, 40);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.type, TransactionType.sent);
      expect(transaction.amount, 150.00);
    });

    test('parses small amount transfer with decimals', () {
      const message =
          'Tk 316.00 has been transferred from your BBL A/C: 07011**001 to BKASH wallet: 017XXXXXXXX. Available balance is Tk 0.39. Queries: call 16221.';
      final timestamp = DateTime(2025, 1, 3, 20, 3, 39);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.type, TransactionType.sent);
      expect(transaction.amount, 316.00);
    });
  });

  group('BracBankProvider - Fund Receipt (Credit)', () {
    test('parses direct credit to account', () {
      const message =
          'TK 35,000.00 has been credited to your A/C# 07011**6001 on 03-09-24. Your A/C balance is TK 40,123.96. For Enquiry call: 16221';
      final timestamp = DateTime(2024, 9, 3, 22, 21, 19);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.type, TransactionType.received);
      expect(transaction.amount, 35000.00);
    });

    test('parses EFT credit from other bank', () {
      const message =
          'Your BRAC Bank A/C#070110**6001 has been credited by TK 14,000.00 by EFT from other bank. A/C balance is TK 26,083.96.';
      final timestamp = DateTime(2024, 9, 22, 18, 56, 39);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.type, TransactionType.received);
      expect(transaction.amount, 14000.00);
    });

    test('parses credit from other bank via ATM network', () {
      const message =
          'TK 10,000.00 credited to A/C#07011**6001 on 07-04-25 @06:52 PM from OTHER BANK. Balance TK 10,508.96. BRAC Bank.';
      final timestamp = DateTime(2025, 4, 7, 18, 52, 15);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.type, TransactionType.received);
      expect(transaction.amount, 10000.00);
    });

    test('parses cash deposit at branch', () {
      const message =
          'TK 20,000.00 has been deposited to BRAC Bank A/C#07011**6001 on 24-04-25, 02:58 PM at BEGUM ROKEYA SHARANI BR. Balance TK 24,203.96. Query: 16221';
      final timestamp = DateTime(2025, 4, 24, 14, 58, 10);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.type, TransactionType.received);
      expect(transaction.amount, 20000.00);
    });

    test('parses small credit amount', () {
      const message =
          'TK 225.00 has been credited to your A/C# 07011**6001 on 22-11-24. Your A/C balance is TK 6,056.27. For Enquiry call: 16221';
      final timestamp = DateTime(2024, 11, 22, 10, 45, 53);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.type, TransactionType.received);
      expect(transaction.amount, 225.00);
    });

    test('parses large credit amount', () {
      const message =
          'TK 33,000.00 has been credited to your A/C# 07011**6001 on 11-04-25. Your A/C balance is TK 52,408.96. For Enquiry call: 16221';
      final timestamp = DateTime(2025, 4, 11, 12, 59, 22);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.type, TransactionType.received);
      expect(transaction.amount, 33000.00);
    });
  });

  group('BracBankProvider - ATM Withdrawals (Debit)', () {
    test('parses ATM withdrawal from BRAC Bank ATM', () {
      const message =
          'TK 5,000.00 withdrawn from A/C#07011**6001 on 12-09-24 @07:03 PM from BOGRA AS ATM BOGRA BD. Balance TK 23,383.96. BRAC Bank.';
      final timestamp = DateTime(2024, 9, 12, 19, 3, 32);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.type, TransactionType.cashout);
      expect(transaction.amount, 5000.00);
    });

    test('parses ATM withdrawal from other bank ATM', () {
      const message =
          'TK 3,500.00 withdrawn from A/C#07011**6001 on 04-02-25 @09:50 PM from OTHER BANK ATM. Balance TK 298.30. BRAC Bank.';
      final timestamp = DateTime(2025, 2, 4, 21, 51, 5);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.type, TransactionType.cashout);
      expect(transaction.amount, 3500.00);
    });

    test('parses ATM withdrawal from branch ATM', () {
      const message =
          'TK 20,000.00 withdrawn from A/C#07011**6001 on 07-11-24 @07:08 PM from BOGRA BRANCH 2ND ATM BOGRA BD. Balance TK 201.27. BRAC Bank.';
      final timestamp = DateTime(2024, 11, 7, 19, 8, 54);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.type, TransactionType.cashout);
      expect(transaction.amount, 20000.00);
    });

    test('parses ATM withdrawal from BRTC ATM', () {
      const message =
          'TK 5,000.00 withdrawn from A/C#07011**6001 on 31-10-24 @06:58 PM from BOGRA BRTC 2ND ATM BOGRA BD. Balance TK 698.16. BRAC Bank.';
      final timestamp = DateTime(2024, 10, 31, 18, 58, 27);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.type, TransactionType.cashout);
      expect(transaction.amount, 5000.00);
    });

    test('parses small ATM withdrawal', () {
      const message =
          'TK 500.00 withdrawn from A/C#07011**6001 on 04-11-24 @06:51 PM from BOGRA AS ATM BOGRA BD. Balance TK 201.27. BRAC Bank.';
      final timestamp = DateTime(2024, 11, 4, 18, 51, 38);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.type, TransactionType.cashout);
      expect(transaction.amount, 500.00);
    });
  });

  group('BracBankProvider - Card Transactions (Debit)', () {
    test('parses bKash card transaction', () {
      const message =
          'TK 230.00 transacted at BKASH LIMITED 01 BD on 13-10-24 @01:57 PM using card#***9246. Balance TK 12,058.62. BRAC Bank.';
      final timestamp = DateTime(2024, 10, 13, 13, 57, 49);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.type, TransactionType.sent);
      expect(transaction.amount, 230.00);
    });

    test('parses foreign currency card transaction', () {
      const message =
          r'$ 6.67 transacted at NAME-CHEAP.COM* SKRIPF on 14-10-24 @02:15 PM using card#***9246. Balance TK 10,818.22. BRAC Bank.';
      final timestamp = DateTime(2024, 10, 14, 14, 15, 34);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.type, TransactionType.sent);
      expect(transaction.amount, 6.67);
    });

    test('parses e-commerce card transaction', () {
      const message =
          'TK 1,268.00 transacted at OTHOBA.COM DHAKA BD on 01-06-25 @05:02 PM using card#***9246. Balance TK 19,735.42. BRAC Bank.';
      final timestamp = DateTime(2025, 6, 1, 17, 2, 45);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.type, TransactionType.sent);
      expect(transaction.amount, 1268.00);
    });
  });

  group('BracBankProvider - Non-Transaction Messages', () {
    test('ignores OTP messages', () {
      const message =
          'Use OTP: 133299 to proceed with Within Bank Transfer-Beneficiary. This OTP will be valid for 3 minutes. Please do not share it with anyone.';
      final timestamp = DateTime(2024, 8, 24, 11, 45, 12);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNull);
    });

    test('ignores password change notifications', () {
      const message =
          'Your BRAC Bank Astha password has been changed. Queries: call 16221 (local), 0255668056 (overseas).';
      final timestamp = DateTime(2025, 7, 7, 16, 40, 23);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNull);
    });

    test('ignores login notifications', () {
      const message =
          'We noticed a log-in to your BRAC Bank account from a new device. If this was not you, please report to our 24/7 call center at 16221 immediately.';
      final timestamp = DateTime(2024, 10, 14, 14, 17, 27);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNull);
    });

    test('ignores promotional messages', () {
      const message = '৫০% পর্যন্ত ডিসকাউন্টে পূজার শপিং! tinyurl.com/BBPJYQ';
      final timestamp = DateTime(2024, 9, 19, 19, 16, 1);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNull);
    });

    test('ignores beneficiary deletion notifications', () {
      const message =
          'Dear Customer: Your beneficairy Account Number: 10554**001 has been deleted. Queries: call 16221 (local), 0255668055 (overseas).';
      final timestamp = DateTime(2024, 11, 28, 10, 19, 0);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNull);
    });

    test('ignores service announcement messages', () {
      const message =
          'Debit card services (ATM, POS, QR, e-commerce, NPSB) will be unavailable from 12:30 AM to 3:30 PM (15 hours) on July 4, 2025, for system upgrade.';
      final timestamp = DateTime(2025, 7, 2, 16, 31, 16);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNull);
    });

    test('ignores password expiry warnings', () {
      const message =
          'Dear Customer: Your BRAC Bank Astha password will expire in 15 days. To reset your password log into BRAC Bank Astha.';
      final timestamp = DateTime(2025, 6, 18, 13, 50, 13);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNull);
    });

    test('ignores statement access messages', () {
      const message =
          'Please visit https://s.bracbank.com/48bXMB to access half-yearly account statement & Certificate. After OTP, use A/C Number to open pdf. For details, call 16221';
      final timestamp = DateTime(2024, 8, 28, 17, 6, 1);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNull);
    });

    test('ignores maintenance notifications', () {
      const message =
          'Dear Customer: Astha app is under maintenance to enhance your user experience. We\'ll notify you once it\'s back. Sorry for the inconvenience.';
      final timestamp = DateTime(2025, 7, 7, 21, 5, 27);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNull);
    });
  });

  group('BracBankProvider - Edge Cases', () {
    test('handles amount without thousands separator', () {
      const message =
          'Tk 100.00 has been transferred from your BBL A/C: 07011**001 to A/C: 07011**001. Available balance is Tk100.19. Queries: call 16221.';
      final timestamp = DateTime(2025, 5, 29, 10, 48, 26);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.amount, 100.00);
    });

    test('handles balance with inconsistent formatting', () {
      const message =
          'Tk 700.00 has been transferred from your BBL A/C: 07011**001 to A/C: 07011**001. Available balance is Tk200.19. Queries: call 16221.';
      final timestamp = DateTime(2025, 5, 29, 10, 46, 10);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.amount, 700.00);
    });

    test('handles very small decimal amounts', () {
      const message =
          'Tk 191.00 has been transferred from your BBL A/C: 07011**001 to BKASH wallet: 017XXXXXXXX. Available balance is Tk 0.19. Queries: call 16221.';
      final timestamp = DateTime(2025, 5, 3, 13, 9, 26);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.amount, 191.00);
    });

    test('handles duplicate SMS (should still parse)', () {
      // This is a duplicate in the data
      const message =
          'Tk 1,000.00 has been transferred from your BBL A/C: 07011**001 to Rocket wallet: 017XXXXXXXX. Available balance is Tk 13,520.00. Queries: call 16221.';
      final timestamp = DateTime(2025, 7, 10, 13, 56, 14);

      final transaction = provider.parse('BRAC-BANK', message, timestamp);

      expect(transaction, isNotNull);
      expect(transaction!.amount, 1000.00);
    });
  });
}
