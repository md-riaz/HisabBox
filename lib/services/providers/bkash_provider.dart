import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/providers/provider_utils.dart';
import 'package:hisabbox/services/providers/sms_provider.dart';

class BkashProvider extends SmsProvider {
  static final RegExp _sentPattern = RegExp(
    r'You have sent Tk([\d,]+\.?\d*) to ([\d\s]+).*?Trx[.\s]*ID[:\s]*([\w\d]+)',
    caseSensitive: false,
  );

  static final RegExp _receivedPattern = RegExp(
    r'You have received Tk([\d,]+\.?\d*) from ([\d\s]+).*?Trx[.\s]*ID[:\s]*([\w\d]+)',
    caseSensitive: false,
  );

  static final RegExp _cashoutPattern = RegExp(
    r'Cash Out Tk([\d,]+\.?\d*) .*?from ([\d\s]+).*?Trx[.\s]*ID[:\s]*([\w\d]+)',
    caseSensitive: false,
  );

  static final RegExp _paymentPattern = RegExp(
    r'Payment of Tk([\d,]+\.?\d*) .*?TrxID ([\w\d]+)',
    caseSensitive: false,
  );

  static const Set<String> _senderIds = {'bkash', '16247'};

  @override
  Provider get provider => Provider.bkash;

  @override
  bool matches(String address, String message) {
    final normalizedAddress = address.toLowerCase();
    if (_senderIds.any(normalizedAddress.contains)) {
      return true;
    }
    return message.toLowerCase().contains('bkash');
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
      final recipient = cashoutMatch.group(2)?.trim();
      return buildTransaction(
        provider: provider,
        type: TransactionType.cashout,
        amount: parseAmount(cashoutMatch.group(1)!),
        recipient: recipient,
        transactionId: cashoutMatch.group(3)!,
        timestamp: timestamp,
        rawMessage: message,
      );
    }

    final paymentMatch = _paymentPattern.firstMatch(message);
    if (paymentMatch != null) {
      return buildTransaction(
        provider: provider,
        type: TransactionType.payment,
        amount: parseAmount(paymentMatch.group(1)!),
        transactionId: paymentMatch.group(2)!,
        timestamp: timestamp,
        rawMessage: message,
      );
    }

    return null;
  }
}
