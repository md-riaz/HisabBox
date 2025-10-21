import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/providers/provider_utils.dart';
import 'package:hisabbox/services/providers/sms_provider.dart';

class NagadProvider extends SmsProvider {
  NagadProvider({Iterable<String>? senderIds})
    : _senderIds = _normaliseSenderIds(senderIds ?? defaultSenderIds);

  /// Matches customer transfers such as
  /// "Send Money Tk 1,200.00 to 018XXXXXXXX. Trx ID ABC123".
  static final RegExp _sentPattern = RegExp(
    r'Send Money Tk\s?([\d,]+\.?\d*) to ([\d\s]+).*?Trx[.\s]*ID[:\s]*([\w\d]+)',
    caseSensitive: false,
  );

  /// Captures incoming Nagad transfers from another number.
  static final RegExp _receivedPattern = RegExp(
    r'Received Tk\s?([\d,]+\.?\d*) from ([\d\s]+).*?Trx[.\s]*ID[:\s]*([\w\d]+)',
    caseSensitive: false,
  );

  /// Identifies cash-out confirmations where the agent number is optional.
  static final RegExp _cashoutPattern = RegExp(
    r'Cash Out Tk\s?([\d,]+\.?\d*) .*?Trx[.\s]?ID[:\s]?([\w\d]+)',
    caseSensitive: false,
  );

  static const List<String> defaultSenderIds = ['nagad', '16167'];
  final Set<String> _senderIds;

  static Set<String> _normaliseSenderIds(Iterable<String> values) {
    final result = <String>{};
    for (final value in values) {
      final trimmed = value.trim().toLowerCase();
      if (trimmed.isEmpty) {
        continue;
      }
      result.add(trimmed);
    }
    if (result.isEmpty) {
      return defaultSenderIds.toSet();
    }
    return result;
  }

  @override
  Provider get provider => Provider.nagad;

  @override
  bool matches(String address, String message) {
    final normalizedAddress = address.toLowerCase();
    if (_senderIds.any(normalizedAddress.contains)) {
      return true;
    }
    return message.toLowerCase().contains('nagad');
  }

  @override
  Transaction? parse(String address, String message, DateTime timestamp) {
    final sentMatch = _sentPattern.firstMatch(message);
    if (sentMatch != null) {
      final recipient = sentMatch.group(2)?.trim();
      return buildTransaction(
        provider: provider,
        type: TransactionType.sent,
        amount: parseAmount(sentMatch.group(1)!),
        recipient: recipient,
        transactionId: sentMatch.group(3)!,
        timestamp: timestamp,
        rawMessage: message,
      );
    }

    final receivedMatch = _receivedPattern.firstMatch(message);
    if (receivedMatch != null) {
      final sender = receivedMatch.group(2)?.trim();
      return buildTransaction(
        provider: provider,
        type: TransactionType.received,
        amount: parseAmount(receivedMatch.group(1)!),
        sender: sender,
        transactionId: receivedMatch.group(3)!,
        timestamp: timestamp,
        rawMessage: message,
      );
    }

    final cashoutMatch = _cashoutPattern.firstMatch(message);
    if (cashoutMatch != null) {
      return buildTransaction(
        provider: provider,
        type: TransactionType.cashout,
        amount: parseAmount(cashoutMatch.group(1)!),
        transactionId: cashoutMatch.group(2)!,
        timestamp: timestamp,
        rawMessage: message,
      );
    }

    return null;
  }
}
