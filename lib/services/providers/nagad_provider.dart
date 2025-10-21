import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/providers/provider_utils.dart';
import 'package:hisabbox/services/providers/sms_provider.dart';

class NagadProvider extends SmsProvider {
  NagadProvider({Iterable<String>? senderIds})
      : _senderIds = normalizeSenderIdSet(
          senderIds ?? const <String>[],
          defaultSenderIds,
        );

  /// Matches customer transfers such as
  /// "Send Money Tk 1,200.00 to 018XXXXXXXX. Trx ID ABC123".
  static final RegExp _sentPattern = RegExp(
    r'Send Money Tk\s?([\d,]+\.?\d*) to ([\d\s]+).*?Trx[.\s]*ID[:\s]*([\w\d]+)',
    caseSensitive: false,
  );

  /// Captures incoming Nagad transfers from another number.
  /// Matches: "Money Received.\nAmount: Tk 500.00\nSender: 01719404769"
  /// Also handles: "Amt: Tk 810.00\nSender: 01308606031"
  static final RegExp _receivedPattern = RegExp(
    r'Money Received.*?(?:Amount|Amt):\s*Tk\s*([\d,]+\.?\d*).*?Sender:\s*([\d\s]+).*?Txn?ID:\s*([\w\d]+)',
    caseSensitive: false,
    dotAll: true,
  );

  /// Captures payment to merchants like Daraz, Foodpanda, etc.
  /// Matches: "Payment to 'Daraz Bangladesh Limit' is Successful.\nAmount: Tk  494.00"
  static final RegExp _paymentPattern = RegExp(
    r'Payment to .([^\n]+?). is Successful.*?Amount:\s*Tk\s*([\d,]+\.?\d*).*?TxnID:\s*([\w\d]+)',
    caseSensitive: false,
    dotAll: true,
  );

  /// Captures mobile recharge transactions.
  /// Matches: "Mobile Recharge Successful.\nAmount: Tk 20.00\nMobile: 01797810793"
  static final RegExp _mobileRechargePattern = RegExp(
    r'Mobile Recharge Successful.*?Amount:\s*Tk\s*([\d,]+\.?\d*).*?Mobile:\s*([\d\s]+).*?TxnID:\s*([\w\d]+)',
    caseSensitive: false,
    dotAll: true,
  );

  /// Captures bank add money transactions (Cash In).
  /// Matches: "Add Money from Bank is Successful.\nFrom: IBBL\nAmount: Tk 340.0"
  static final RegExp _addMoneyPattern = RegExp(
    r'Add Money from Bank is Successful.*?From:\s*([^\n]+).*?Amount:\s*Tk\s*([\d,]+\.?\d*).*?TxnID:\s*([\w\d]+)',
    caseSensitive: false,
    dotAll: true,
  );

  /// Captures refund transactions.
  /// Matches: "Refund from Daraz BD\nAmount: Tk 239\nTrnxID: 72HDK2ZV"
  static final RegExp _refundPattern = RegExp(
    r'Refund from\s+([^\n]+).*?Amount:\s*Tk\s*([\d,]+\.?\d*).*?Tr[nx]+ID:\s*([\w\d]+)',
    caseSensitive: false,
    dotAll: true,
  );

  /// Captures cashback and gift transactions.
  /// Matches multiple formats:
  /// - "Congrats! You've received Cashback 20.00 Tk for Mobile Recharge"
  /// - "Congrats! You've received Cash back/Gift 49.40 Tk for Payment"
  /// - "Congrats! You have won cashback Tk 79.00 for payment"
  /// - "Congrats! You have received BDT 25 for Nagad Registration"
  static final RegExp _cashbackPattern = RegExp(
    r'Congrats!.*?(?:received|won).*?(?:Cashback|Cash back/Gift|cashback)\s+([\d,]+\.?\d*)\s*Tk',
    caseSensitive: false,
    dotAll: true,
  );

  /// Alternative cashback pattern for "won cashback Tk 79.00" format
  static final RegExp _cashbackWonPattern = RegExp(
    r'Congrats!.*?won.*?cashback\s+Tk\s+([\d,]+\.?\d*)',
    caseSensitive: false,
    dotAll: true,
  );

  /// Alternative cashback pattern for messages that don't use specific keywords
  static final RegExp _cashbackAltPattern = RegExp(
    r'Congrats!.*?received.*?BDT\s*([\d,]+\.?\d*)',
    caseSensitive: false,
    dotAll: true,
  );

  /// Captures registration bonus with TxnID.
  /// Matches: "Congrats! You have received BDT 25...TxnID: 70KOMZZJ"
  static final RegExp _bonusWithTxnPattern = RegExp(
    r'Congrats!.*?received.*?BDT\s+([\d,]+\.?\d*).*?TxnID:\s*([\w\d]+)',
    caseSensitive: false,
    dotAll: true,
  );

  /// Identifies cash-out confirmations where the agent number is optional.
  static final RegExp _cashoutPattern = RegExp(
    r'Cash Out Tk\s?([\d,]+\.?\d*) .*?Trx[.\s]?ID[:\s]?([\w\d]+)',
    caseSensitive: false,
  );

  /// Patterns to explicitly ignore (OTP, authorization, etc.)
  static final List<RegExp> _ignorePatterns = [
    RegExp(r'One Time Password|OTP|verification code', caseSensitive: false),
    RegExp(r'Device registration request', caseSensitive: false),
    RegExp(r'PIN setup|set your.*digit PIN', caseSensitive: false),
    RegExp(r'authorized.*for payment', caseSensitive: false),
    RegExp(r'authorization.*has been cancelled', caseSensitive: false),
    RegExp(r'payment.*has been cancelled', caseSensitive: false),
    RegExp(r'Welcome to Nagad', caseSensitive: false),
    RegExp(r'Virtual Card Number', caseSensitive: false),
    RegExp(r'account opening form has been rejected', caseSensitive: false),
    RegExp(r'Your request for.*is accepted', caseSensitive: false),
    RegExp(r'Customer No:.*Meter No:', caseSensitive: false),
  ];

  static const List<String> defaultSenderIds = ['nagad', '16167'];
  final Set<String> _senderIds;

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
    // Check if message should be ignored
    for (final pattern in _ignorePatterns) {
      if (pattern.hasMatch(message)) {
        return null;
      }
    }

    // Check for sent money
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

    // Check for received money
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

    // Check for payment to merchant
    final paymentMatch = _paymentPattern.firstMatch(message);
    if (paymentMatch != null) {
      final recipient = paymentMatch.group(1)?.trim();
      return buildTransaction(
        provider: provider,
        type: TransactionType.payment,
        amount: parseAmount(paymentMatch.group(2)!),
        recipient: recipient,
        transactionId: paymentMatch.group(3)!,
        timestamp: timestamp,
        rawMessage: message,
      );
    }

    // Check for mobile recharge
    final mobileRechargeMatch = _mobileRechargePattern.firstMatch(message);
    if (mobileRechargeMatch != null) {
      final recipient = mobileRechargeMatch.group(2)?.trim();
      return buildTransaction(
        provider: provider,
        type: TransactionType.payment,
        amount: parseAmount(mobileRechargeMatch.group(1)!),
        recipient: recipient,
        transactionId: mobileRechargeMatch.group(3)!,
        timestamp: timestamp,
        rawMessage: message,
      );
    }

    // Check for add money from bank
    final addMoneyMatch = _addMoneyPattern.firstMatch(message);
    if (addMoneyMatch != null) {
      final sender = addMoneyMatch.group(1)?.trim();
      return buildTransaction(
        provider: provider,
        type: TransactionType.cashin,
        amount: parseAmount(addMoneyMatch.group(2)!),
        sender: sender,
        transactionId: addMoneyMatch.group(3)!,
        timestamp: timestamp,
        rawMessage: message,
      );
    }

    // Check for refund
    final refundMatch = _refundPattern.firstMatch(message);
    if (refundMatch != null) {
      final sender = refundMatch.group(1)?.trim();
      return buildTransaction(
        provider: provider,
        type: TransactionType.received,
        amount: parseAmount(refundMatch.group(2)!),
        sender: sender,
        transactionId: refundMatch.group(3)!,
        timestamp: timestamp,
        rawMessage: message,
      );
    }

    // Check for bonus with TxnID (registration bonus)
    final bonusMatch = _bonusWithTxnPattern.firstMatch(message);
    if (bonusMatch != null) {
      return buildTransaction(
        provider: provider,
        type: TransactionType.received,
        amount: parseAmount(bonusMatch.group(1)!),
        transactionId: bonusMatch.group(2)!,
        timestamp: timestamp,
        rawMessage: message,
      );
    }

    // Check for cashback/gift
    final cashbackMatch = _cashbackPattern.firstMatch(message);
    if (cashbackMatch != null) {
      return buildTransaction(
        provider: provider,
        type: TransactionType.received,
        amount: parseAmount(cashbackMatch.group(1)!),
        transactionId: 'CASHBACK',
        timestamp: timestamp,
        rawMessage: message,
      );
    }

    // Check for won cashback format (Tk after cashback keyword)
    final cashbackWonMatch = _cashbackWonPattern.firstMatch(message);
    if (cashbackWonMatch != null) {
      return buildTransaction(
        provider: provider,
        type: TransactionType.received,
        amount: parseAmount(cashbackWonMatch.group(1)!),
        transactionId: 'CASHBACK',
        timestamp: timestamp,
        rawMessage: message,
      );
    }

    // Check for alternative cashback format (BDT without Cashback keyword)
    final cashbackAltMatch = _cashbackAltPattern.firstMatch(message);
    if (cashbackAltMatch != null) {
      return buildTransaction(
        provider: provider,
        type: TransactionType.received,
        amount: parseAmount(cashbackAltMatch.group(1)!),
        transactionId: 'CASHBACK',
        timestamp: timestamp,
        rawMessage: message,
      );
    }

    // Check for cash out
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
