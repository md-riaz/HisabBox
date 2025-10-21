import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/providers/provider_utils.dart';
import 'package:hisabbox/services/providers/sms_provider.dart';

abstract class BankSmsProvider extends SmsProvider {
  BankSmsProvider(
    this._provider,
    Iterable<String> senderIds,
    Iterable<String> fallbackSenderIds,
  ) : _senderIds = normalizeSenderIdSet(senderIds, fallbackSenderIds);

  final Provider _provider;
  final Set<String> _senderIds;

  static final RegExp _debitPattern = RegExp(
    r'(?:Debit|Debited|Withdrawn|Dr).*?(?:BDT|Tk|TK)\s?([\d,]+\.?\d*)',
    caseSensitive: false,
  );

  static final RegExp _creditPattern = RegExp(
    r'(?:Credit|Credited|Deposited|Cr).*?(?:BDT|Tk|TK)\s?([\d,]+\.?\d*)',
    caseSensitive: false,
  );

  @override
  Provider get provider => _provider;

  Set<String> get senderIds => _senderIds;

  List<RegExp> get bodyIdentifiers;

  @override
  bool matches(String address, String message) {
    final normalizedAddress = address.toLowerCase();
    if (senderIds.any(normalizedAddress.contains)) {
      return true;
    }

    final normalizedMessage = message.toLowerCase();
    return bodyIdentifiers.any(
      (pattern) => pattern.hasMatch(normalizedMessage),
    );
  }

  @override
  Transaction? parse(String address, String message, DateTime timestamp) {
    final debitMatch = _debitPattern.firstMatch(message);
    if (debitMatch != null) {
      final entryId = generateInternalId();
      return buildTransaction(
        id: entryId,
        provider: provider,
        type: TransactionType.sent,
        amount: parseAmount(debitMatch.group(1)!),
        transactionId: entryId,
        timestamp: timestamp,
        rawMessage: message,
      );
    }

    final creditMatch = _creditPattern.firstMatch(message);
    if (creditMatch != null) {
      final entryId = generateInternalId();
      return buildTransaction(
        id: entryId,
        provider: provider,
        type: TransactionType.received,
        amount: parseAmount(creditMatch.group(1)!),
        transactionId: entryId,
        timestamp: timestamp,
        rawMessage: message,
      );
    }

    return null;
  }
}
