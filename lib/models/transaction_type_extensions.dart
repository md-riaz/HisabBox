import 'package:flutter/material.dart';
import 'package:hisabbox/models/transaction.dart';

extension TransactionTypeDisplay on TransactionType {
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

  IconData get icon {
    switch (this) {
      case TransactionType.sent:
        return Icons.call_made;
      case TransactionType.received:
        return Icons.call_received;
      case TransactionType.cashout:
        return Icons.account_balance_wallet_outlined;
      case TransactionType.cashin:
        return Icons.account_balance_wallet;
      case TransactionType.payment:
        return Icons.shopping_bag_outlined;
      case TransactionType.refund:
        return Icons.undo;
      case TransactionType.fee:
        return Icons.money_off;
      case TransactionType.other:
        return Icons.swap_horiz;
    }
  }
}
