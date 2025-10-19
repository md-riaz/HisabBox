import 'package:hisabbox/models/transaction.dart';
import 'package:uuid/uuid.dart';

final _uuid = Uuid();

String generateInternalId() => _uuid.v4();

double parseAmount(String amountStr) {
  return double.parse(amountStr.replaceAll(',', ''));
}

Transaction buildTransaction({
  String? id,
  required Provider provider,
  required TransactionType type,
  required double amount,
  String? sender,
  String? recipient,
  required String transactionId,
  required DateTime timestamp,
  required String rawMessage,
}) {
  final counterparty = sender ?? recipient;
  return Transaction(
    id: id ?? generateInternalId(),
    provider: provider,
    type: type,
    amount: amount,
    sender: sender,
    recipient: recipient,
    transactionId: transactionId,
    transactionHash: Transaction.generateHash(
      counterparty: counterparty,
      messageBody: rawMessage,
      timestamp: timestamp,
    ),
    timestamp: timestamp,
    rawMessage: rawMessage,
    createdAt: DateTime.now(),
  );
}
