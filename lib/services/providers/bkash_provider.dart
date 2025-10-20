import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/providers/provider_utils.dart';
import 'package:hisabbox/services/providers/sms_provider.dart';

class BkashProvider extends SmsProvider {
  /// Matches customer-to-customer transfers such as
  /// "You have sent Tk 1,500.00 to 017XXXXXXXX. TrxID ABC123".
  static final RegExp _sentPattern = RegExp(
    r'You have sent Tk\s*([\d,]+(?:\.\d+)?) to ([\d\s]+).*?Trx[.\s]*ID[:\s]*([\w\d]+)',
    caseSensitive: false,
    dotAll: true,
  );

  /// Captures standard incoming transfers like
  /// "You have received Tk 2,000.00 from 017XXXXXXXX. TrxID DEF456".
  static final RegExp _receivedPattern = RegExp(
    r'You have received(?: .*?)? Tk\s*([\d,]+(?:\.\d+)?) from ([^\.]+).*?Trx[.\s]*ID[:\s]*([\w\d]+)',
    caseSensitive: false,
    dotAll: true,
  );

  /// Identifies bank-to-bKash transfers that mention "received deposit".
  static final RegExp _receivedDepositPattern = RegExp(
    r'You have received deposit from [^\.]+ of Tk\s*([\d,]+(?:\.\d+)?) from ([^\.]+).*?Trx[.\s]*ID[:\s]*([\w\d]+)',
    caseSensitive: false,
    dotAll: true,
  );

  /// Matches agent cash-out confirmations listing the agent MSISDN.
  static final RegExp _cashoutPattern = RegExp(
    r'Cash Out Tk\s*([\d,]+(?:\.\d+)?) .*?from ([\d\s]+).*?Trx[.\s]*ID[:\s]*([\w\d]+)',
    caseSensitive: false,
    dotAll: true,
  );

  /// Handles merchant payments where only the amount and transaction ID are guaranteed.
  static final RegExp _paymentPattern = RegExp(
    r'Payment of Tk\s*([\d,]+(?:\.\d+)?).*?Trx[.\s]*ID[:\s]*([\w\d]+)',
    caseSensitive: false,
    dotAll: true,
  );

  /// Extracts the optional merchant name from payment confirmations.
  static final RegExp _paymentRecipientPattern = RegExp(
    r'Payment of Tk\s*[\d,]+(?:\.\d+)? to ([^\.]+)',
    caseSensitive: false,
  );

  /// Covers multiline bill payment receipts that explicitly list the biller.
  static final RegExp _billPaymentPattern = RegExp(
    r'Bill successfully paid.*?Biller[:\s]*([^\n]+).*?Amount[:\s]*Tk\s*([\d,]+(?:\.\d+)?).*?Trx[.:\s]*ID[:\s]*([\w\d]+)',
    caseSensitive: false,
    dotAll: true,
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

    final receivedDepositMatch = _receivedDepositPattern.firstMatch(message);
    if (receivedDepositMatch != null) {
      final sender = receivedDepositMatch.group(2)?.trim();
      return buildTransaction(
        provider: provider,
        type: TransactionType.received,
        amount: parseAmount(receivedDepositMatch.group(1)!),
        sender: sender,
        transactionId: receivedDepositMatch.group(3)!,
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
      final recipientMatch = _paymentRecipientPattern.firstMatch(message);
      final rawRecipient = recipientMatch?.group(1)?.trim();
      final recipient = rawRecipient
          ?.replaceAll(
            RegExp(r'\sis successful$', caseSensitive: false),
            '',
          )
          .replaceAll(
            RegExp(r'\swas successful$', caseSensitive: false),
            '',
          )
          .replaceAll(
            RegExp(r'\ssuccessfully$', caseSensitive: false),
            '',
          )
          .replaceAll(
            RegExp(r'\ssuccessful$', caseSensitive: false),
            '',
          )
          .trim();
      return buildTransaction(
        provider: provider,
        type: TransactionType.payment,
        amount: parseAmount(paymentMatch.group(1)!),
        recipient: recipient?.isEmpty ?? true ? null : recipient,
        transactionId: paymentMatch.group(2)!,
        timestamp: timestamp,
        rawMessage: message,
      );
    }

    final billPaymentMatch = _billPaymentPattern.firstMatch(message);
    if (billPaymentMatch != null) {
      final recipient = billPaymentMatch.group(1)?.trim();
      return buildTransaction(
        provider: provider,
        type: TransactionType.payment,
        amount: parseAmount(billPaymentMatch.group(2)!),
        recipient: recipient,
        transactionId: billPaymentMatch.group(3)!,
        timestamp: timestamp,
        rawMessage: message,
      );
    }

    return null;
  }
}
