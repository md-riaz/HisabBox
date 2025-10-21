import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/providers/provider_utils.dart';
import 'package:hisabbox/services/providers/sms_provider.dart';

class RocketProvider extends SmsProvider {
  RocketProvider({Iterable<String>? senderIds})
    : _senderIds = _normaliseSenderIds(senderIds ?? defaultSenderIds);

  /// Matches outgoing Rocket transfers like
  /// "Tk 800.00 sent to 017XXXXXXXX. TxnID ABC123".
  static final RegExp _sentPattern = RegExp(
    r'Tk\s?([\d,]+\.?\d*) sent to ([\d\s]+).*?TxnID[:\s]*([\w\d]+)',
    caseSensitive: false,
  );

  /// Captures incoming Rocket transfers indicating the sender number.
  static final RegExp _receivedPattern = RegExp(
    r'Tk\s?([\d,]+\.?\d*) received from ([\d\s]+).*?TxnID[:\s]*([\w\d]+)',
    caseSensitive: false,
  );

  /// Identifies cash-out confirmations where only amount and transaction ID are reliable.
  static final RegExp _cashoutPattern = RegExp(
    r'Cash Out Tk\s?([\d,]+\.?\d*) .*?TxnID[:\s]?([\w\d]+)',
    caseSensitive: false,
  );

  static const List<String> defaultSenderIds = ['rocket', '16216'];
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
  Provider get provider => Provider.rocket;

  @override
  bool matches(String address, String message) {
    final normalizedAddress = address.toLowerCase();
    if (_senderIds.any(normalizedAddress.contains)) {
      return true;
    }
    return message.toLowerCase().contains('rocket');
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
