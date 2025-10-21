import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/providers/provider_utils.dart';
import 'package:hisabbox/services/providers/sms_provider.dart';

abstract class BankSmsProvider extends SmsProvider {
  BankSmsProvider(
    this._provider,
    Iterable<String> senderIds,
    Iterable<String> fallbackSenderIds,
  ) : _senderIds = _normaliseSenderIds(senderIds, fallbackSenderIds);

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

Set<String> _normaliseSenderIds(
  Iterable<String> values,
  Iterable<String> fallback,
) {
  final normalised = _sanitize(values);
  if (normalised.isNotEmpty) {
    return normalised;
  }
  return _sanitize(fallback);
}

Set<String> _sanitize(Iterable<String> values) {
  final result = <String>{};
  for (final value in values) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) {
      continue;
    }
    result.add(trimmed);
  }
  return result;
}
