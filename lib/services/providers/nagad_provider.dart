import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/providers/provider_utils.dart';
import 'package:hisabbox/services/providers/sms_provider.dart';

class NagadProvider extends SmsProvider {
  static final RegExp _sentPattern = RegExp(
    r'Send Money Tk\s?([\d,]+\.?\d*) to ([\d\s]+).*?Trx[.\s]*ID[:\s]*([\w\d]+)',
    caseSensitive: false,
  );

  static final RegExp _receivedPattern = RegExp(
    r'Received Tk\s?([\d,]+\.?\d*) from ([\d\s]+).*?Trx[.\s]*ID[:\s]*([\w\d]+)',
    caseSensitive: false,
  );

  static final RegExp _cashoutPattern = RegExp(
    r'Cash Out Tk\s?([\d,]+\.?\d*) .*?Trx[.\s]?ID[:\s]?([\w\d]+)',
    caseSensitive: false,
  );

  static const Set<String> _senderIds = {'nagad', '16167'};

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
