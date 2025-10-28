import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/providers/bank/bank_sms_provider.dart';
import 'package:hisabbox/services/providers/provider_utils.dart';

class BracBankProvider extends BankSmsProvider {
  BracBankProvider({Iterable<String>? senderIds})
      : super(
            Provider.bracBank, senderIds ?? defaultSenderIds, defaultSenderIds);

  static const List<String> defaultSenderIds = [
    'brac-bank',
    'brac bank',
    'bracbank',
    'brac_bank',
    'brac',
  ];

  static final List<RegExp> _bodyIdentifiers = [
    RegExp(r'brac\s+bank', caseSensitive: false),
    RegExp(r'\bBBL(?:\s*A/?C)?', caseSensitive: false),
  ];

  // Debit patterns for BRAC Bank
  static final RegExp _transferPattern = RegExp(
    r'(?:Tk|TK|BDT)\s?([\d,]+\.?\d*)\s+has been (?:transferred|paid)',
    caseSensitive: false,
  );

  static final RegExp _withdrawalPattern = RegExp(
    r'(?:Tk|TK|BDT)\s?([\d,]+\.?\d*)\s+withdrawn',
    caseSensitive: false,
  );

  static final RegExp _transactedPattern = RegExp(
    r'(?:Tk|TK|BDT|\$)\s?([\d,]+\.?\d*)\s+transacted',
    caseSensitive: false,
  );

  // Credit patterns for BRAC Bank
  static final RegExp _creditedPattern = RegExp(
    r'(?:Tk|TK|BDT)\s?([\d,]+\.?\d*)\s+(?:has been )?credited',
    caseSensitive: false,
  );

  static final RegExp _depositedPattern = RegExp(
    r'(?:Tk|TK|BDT)\s?([\d,]+\.?\d*)\s+(?:has been )?deposited',
    caseSensitive: false,
  );

  @override
  List<RegExp> get bodyIdentifiers => _bodyIdentifiers;

  @override
  Transaction? parse(String address, String message, DateTime timestamp) {
    // Check for debit transactions (transfers, withdrawals, card transactions)
    var match = _transferPattern.firstMatch(message);
    if (match != null) {
      final entryId = generateInternalId();
      return buildTransaction(
        id: entryId,
        provider: provider,
        type: TransactionType.sent,
        amount: parseAmount(match.group(1)!),
        transactionId: entryId,
        timestamp: timestamp,
        rawMessage: message,
      );
    }

    match = _withdrawalPattern.firstMatch(message);
    if (match != null) {
      final entryId = generateInternalId();
      return buildTransaction(
        id: entryId,
        provider: provider,
        type: TransactionType.sent,
        amount: parseAmount(match.group(1)!),
        transactionId: entryId,
        timestamp: timestamp,
        rawMessage: message,
      );
    }

    match = _transactedPattern.firstMatch(message);
    if (match != null) {
      final entryId = generateInternalId();
      return buildTransaction(
        id: entryId,
        provider: provider,
        type: TransactionType.sent,
        amount: parseAmount(match.group(1)!),
        transactionId: entryId,
        timestamp: timestamp,
        rawMessage: message,
      );
    }

    // Check for credit transactions
    match = _creditedPattern.firstMatch(message);
    if (match != null) {
      final entryId = generateInternalId();
      return buildTransaction(
        id: entryId,
        provider: provider,
        type: TransactionType.received,
        amount: parseAmount(match.group(1)!),
        transactionId: entryId,
        timestamp: timestamp,
        rawMessage: message,
      );
    }

    match = _depositedPattern.firstMatch(message);
    if (match != null) {
      final entryId = generateInternalId();
      return buildTransaction(
        id: entryId,
        provider: provider,
        type: TransactionType.received,
        amount: parseAmount(match.group(1)!),
        transactionId: entryId,
        timestamp: timestamp,
        rawMessage: message,
      );
    }

    // Fallback to parent implementation
    return super.parse(address, message, timestamp);
  }
}
