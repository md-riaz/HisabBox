import 'package:flutter/material.dart';
import 'package:hisabbox/models/transaction.dart';

extension TransactionTypeUiMetadata on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.sent:
        return 'Send Money';
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
        return 'Service Fee';
      case TransactionType.other:
        return 'Other';
    }
  }

  IconData get glyph {
    switch (this) {
      case TransactionType.sent:
        return Icons.arrow_upward;
      case TransactionType.received:
        return Icons.arrow_downward;
      case TransactionType.cashout:
        return Icons.money_off;
      case TransactionType.cashin:
        return Icons.attach_money;
      case TransactionType.payment:
        return Icons.payment;
      case TransactionType.refund:
        return Icons.refresh;
      case TransactionType.fee:
        return Icons.receipt;
      case TransactionType.other:
        return Icons.help_outline;
    }
  }

  Color get accentColor {
    switch (this) {
      case TransactionType.sent:
      case TransactionType.cashout:
      case TransactionType.payment:
      case TransactionType.fee:
        return Colors.red;
      case TransactionType.received:
      case TransactionType.cashin:
      case TransactionType.refund:
        return Colors.green;
      case TransactionType.other:
        return Colors.grey;
    }
  }
}
