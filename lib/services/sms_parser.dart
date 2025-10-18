import 'package:hisabbox/models/transaction.dart';

class SmsParser {
  // bKash patterns
  static final RegExp _bkashSentPattern = RegExp(
    r'You have sent Tk([\d,]+\.?\d*) to ([\d\s]+) .*?TrxID ([\w\d]+)',
    caseSensitive: false,
  );

  static final RegExp _bkashReceivedPattern = RegExp(
    r'You have received Tk([\d,]+\.?\d*) from ([\d\s]+) .*?TrxID ([\w\d]+)',
    caseSensitive: false,
  );

  static final RegExp _bkashCashoutPattern = RegExp(
    r'Cash Out Tk([\d,]+\.?\d*) .*?from ([\d\s]+) .*?TrxID ([\w\d]+)',
    caseSensitive: false,
  );

  static final RegExp _bkashPaymentPattern = RegExp(
    r'Payment of Tk([\d,]+\.?\d*) .*?TrxID ([\w\d]+)',
    caseSensitive: false,
  );

  // Nagad patterns
  static final RegExp _nagadSentPattern = RegExp(
    r'Send Money Tk\s?([\d,]+\.?\d*) to ([\d\s]+) .*?Trx[.\s]?ID[:\s]?([\w\d]+)',
    caseSensitive: false,
  );

  static final RegExp _nagadReceivedPattern = RegExp(
    r'Received Tk\s?([\d,]+\.?\d*) from ([\d\s]+) .*?Trx[.\s]?ID[:\s]?([\w\d]+)',
    caseSensitive: false,
  );

  static final RegExp _nagadCashoutPattern = RegExp(
    r'Cash Out Tk\s?([\d,]+\.?\d*) .*?Trx[.\s]?ID[:\s]?([\w\d]+)',
    caseSensitive: false,
  );

  // Rocket patterns
  static final RegExp _rocketSentPattern = RegExp(
    r'Tk\s?([\d,]+\.?\d*) sent to ([\d\s]+) .*?TxnID[:\s]?([\w\d]+)',
    caseSensitive: false,
  );

  static final RegExp _rocketReceivedPattern = RegExp(
    r'Tk\s?([\d,]+\.?\d*) received from ([\d\s]+) .*?TxnID[:\s]?([\w\d]+)',
    caseSensitive: false,
  );

  static final RegExp _rocketCashoutPattern = RegExp(
    r'Cash Out Tk\s?([\d,]+\.?\d*) .*?TxnID[:\s]?([\w\d]+)',
    caseSensitive: false,
  );

  // Bank patterns (generic for various banks)
  static final RegExp _bankDebitPattern = RegExp(
    r'(?:Debit|Debited|Withdrawn|Dr).*?(?:BDT|Tk|TK)\s?([\d,]+\.?\d*)',
    caseSensitive: false,
  );

  static final RegExp _bankCreditPattern = RegExp(
    r'(?:Credit|Credited|Deposited|Cr).*?(?:BDT|Tk|TK)\s?([\d,]+\.?\d*)',
    caseSensitive: false,
  );

  static Transaction? parse(String address, String message, DateTime timestamp) {
    final lowercaseMsg = message.toLowerCase();
    final lowercaseAddress = address.toLowerCase();

    // Check for bKash
    if (_isBkashMessage(lowercaseAddress, lowercaseMsg)) {
      return _parseBkash(message, timestamp);
    }

    // Check for Nagad
    if (_isNagadMessage(lowercaseAddress, lowercaseMsg)) {
      return _parseNagad(message, timestamp);
    }

    // Check for Rocket
    if (_isRocketMessage(lowercaseAddress, lowercaseMsg)) {
      return _parseRocket(message, timestamp);
    }

    // Check for Bank
    if (_isBankMessage(lowercaseAddress, lowercaseMsg)) {
      return _parseBank(message, timestamp);
    }

    return null;
  }

  static bool _isBkashMessage(String address, String message) {
    return address.contains('bkash') || 
           message.contains('bkash') ||
           address.contains('16247');
  }

  static bool _isNagadMessage(String address, String message) {
    return address.contains('nagad') || 
           message.contains('nagad') ||
           address.contains('16167');
  }

  static bool _isRocketMessage(String address, String message) {
    return address.contains('rocket') || 
           message.contains('rocket') ||
           address.contains('16216');
  }

  static bool _isBankMessage(String address, String message) {
    final bankKeywords = ['bank', 'debit', 'credit', 'a/c', 'account', 'balance'];
    return bankKeywords.any((keyword) => 
      address.contains(keyword) || message.contains(keyword)
    );
  }

  static Transaction? _parseBkash(String message, DateTime timestamp) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    // Try sent pattern
    var match = _bkashSentPattern.firstMatch(message);
    if (match != null) {
      return Transaction(
        id: id,
        provider: Provider.bkash,
        type: TransactionType.sent,
        amount: _parseAmount(match.group(1)!),
        recipient: match.group(2)?.trim(),
        transactionId: match.group(3)!,
        timestamp: timestamp,
        rawMessage: message,
        createdAt: DateTime.now(),
      );
    }

    // Try received pattern
    match = _bkashReceivedPattern.firstMatch(message);
    if (match != null) {
      return Transaction(
        id: id,
        provider: Provider.bkash,
        type: TransactionType.received,
        amount: _parseAmount(match.group(1)!),
        sender: match.group(2)?.trim(),
        transactionId: match.group(3)!,
        timestamp: timestamp,
        rawMessage: message,
        createdAt: DateTime.now(),
      );
    }

    // Try cashout pattern
    match = _bkashCashoutPattern.firstMatch(message);
    if (match != null) {
      return Transaction(
        id: id,
        provider: Provider.bkash,
        type: TransactionType.cashout,
        amount: _parseAmount(match.group(1)!),
        recipient: match.group(2)?.trim(),
        transactionId: match.group(3)!,
        timestamp: timestamp,
        rawMessage: message,
        createdAt: DateTime.now(),
      );
    }

    // Try payment pattern
    match = _bkashPaymentPattern.firstMatch(message);
    if (match != null) {
      return Transaction(
        id: id,
        provider: Provider.bkash,
        type: TransactionType.payment,
        amount: _parseAmount(match.group(1)!),
        transactionId: match.group(2)!,
        timestamp: timestamp,
        rawMessage: message,
        createdAt: DateTime.now(),
      );
    }

    return null;
  }

  static Transaction? _parseNagad(String message, DateTime timestamp) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    // Try sent pattern
    var match = _nagadSentPattern.firstMatch(message);
    if (match != null) {
      return Transaction(
        id: id,
        provider: Provider.nagad,
        type: TransactionType.sent,
        amount: _parseAmount(match.group(1)!),
        recipient: match.group(2)?.trim(),
        transactionId: match.group(3)!,
        timestamp: timestamp,
        rawMessage: message,
        createdAt: DateTime.now(),
      );
    }

    // Try received pattern
    match = _nagadReceivedPattern.firstMatch(message);
    if (match != null) {
      return Transaction(
        id: id,
        provider: Provider.nagad,
        type: TransactionType.received,
        amount: _parseAmount(match.group(1)!),
        sender: match.group(2)?.trim(),
        transactionId: match.group(3)!,
        timestamp: timestamp,
        rawMessage: message,
        createdAt: DateTime.now(),
      );
    }

    // Try cashout pattern
    match = _nagadCashoutPattern.firstMatch(message);
    if (match != null) {
      return Transaction(
        id: id,
        provider: Provider.nagad,
        type: TransactionType.cashout,
        amount: _parseAmount(match.group(1)!),
        transactionId: match.group(2)!,
        timestamp: timestamp,
        rawMessage: message,
        createdAt: DateTime.now(),
      );
    }

    return null;
  }

  static Transaction? _parseRocket(String message, DateTime timestamp) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    // Try sent pattern
    var match = _rocketSentPattern.firstMatch(message);
    if (match != null) {
      return Transaction(
        id: id,
        provider: Provider.rocket,
        type: TransactionType.sent,
        amount: _parseAmount(match.group(1)!),
        recipient: match.group(2)?.trim(),
        transactionId: match.group(3)!,
        timestamp: timestamp,
        rawMessage: message,
        createdAt: DateTime.now(),
      );
    }

    // Try received pattern
    match = _rocketReceivedPattern.firstMatch(message);
    if (match != null) {
      return Transaction(
        id: id,
        provider: Provider.rocket,
        type: TransactionType.received,
        amount: _parseAmount(match.group(1)!),
        sender: match.group(2)?.trim(),
        transactionId: match.group(3)!,
        timestamp: timestamp,
        rawMessage: message,
        createdAt: DateTime.now(),
      );
    }

    // Try cashout pattern
    match = _rocketCashoutPattern.firstMatch(message);
    if (match != null) {
      return Transaction(
        id: id,
        provider: Provider.rocket,
        type: TransactionType.cashout,
        amount: _parseAmount(match.group(1)!),
        transactionId: match.group(2)!,
        timestamp: timestamp,
        rawMessage: message,
        createdAt: DateTime.now(),
      );
    }

    return null;
  }

  static Transaction? _parseBank(String message, DateTime timestamp) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    // Try debit pattern
    var match = _bankDebitPattern.firstMatch(message);
    if (match != null) {
      return Transaction(
        id: id,
        provider: Provider.bank,
        type: TransactionType.sent,
        amount: _parseAmount(match.group(1)!),
        transactionId: id,
        timestamp: timestamp,
        rawMessage: message,
        createdAt: DateTime.now(),
      );
    }

    // Try credit pattern
    match = _bankCreditPattern.firstMatch(message);
    if (match != null) {
      return Transaction(
        id: id,
        provider: Provider.bank,
        type: TransactionType.received,
        amount: _parseAmount(match.group(1)!),
        transactionId: id,
        timestamp: timestamp,
        rawMessage: message,
        createdAt: DateTime.now(),
      );
    }

    return null;
  }

  static double _parseAmount(String amountStr) {
    // Remove commas and parse to double
    return double.parse(amountStr.replaceAll(',', ''));
  }
}
