import 'package:flutter/material.dart';
import 'package:hisabbox/models/transaction.dart';

extension TransactionTypeUiMetadata on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.sent:
        return 'Sent';
      case TransactionType.received:
        return 'Received';
      case TransactionType.cashout:
        return 'Cash Out';
      case TransactionType.cashin:
        return 'Cash In';
      case TransactionType.payment:
        return 'Payment';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.fee:
        return 'Fee';
      case TransactionType.other:
        return 'Other';
    }
  }

  Color get accentColor {
    switch (this) {
      case TransactionType.sent:
        return Colors.redAccent;
      case TransactionType.received:
        return Colors.green;
      case TransactionType.cashout:
        return Colors.deepOrange;
      case TransactionType.cashin:
        return Colors.blue;
      case TransactionType.payment:
        return Colors.indigo;
      case TransactionType.refund:
        return Colors.teal;
      case TransactionType.fee:
        return Colors.brown;
      case TransactionType.other:
        return Colors.grey;
    }
  }

  IconData get glyph {
    switch (this) {
      case TransactionType.sent:
        return Icons.call_made;
      case TransactionType.received:
        return Icons.call_received;
      case TransactionType.cashout:
        return Icons.arrow_circle_up;
      case TransactionType.cashin:
        return Icons.arrow_circle_down;
      case TransactionType.payment:
        return Icons.payments;
      case TransactionType.refund:
        return Icons.undo;
      case TransactionType.fee:
        return Icons.request_quote;
      case TransactionType.other:
        return Icons.category;
    }
  }
}
