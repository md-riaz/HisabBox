import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hisabbox/models/transaction.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const TransactionCard({
    super.key,
    required this.transaction,
  });

  IconData _getIcon() {
    switch (transaction.type) {
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
      default:
        return Icons.help_outline;
    }
  }

  Color _getColor() {
    switch (transaction.type) {
      case TransactionType.sent:
      case TransactionType.cashout:
      case TransactionType.payment:
      case TransactionType.fee:
        return Colors.red;
      case TransactionType.received:
      case TransactionType.cashin:
      case TransactionType.refund:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getProviderName() {
    switch (transaction.provider) {
      case Provider.bkash:
        return 'bKash';
      case Provider.nagad:
        return 'Nagad';
      case Provider.rocket:
        return 'Rocket';
      case Provider.bank:
        return 'Bank';
      default:
        return 'Other';
    }
  }

  Color _getProviderColor() {
    switch (transaction.provider) {
      case Provider.bkash:
        return Colors.pink;
      case Provider.nagad:
        return Colors.orange;
      case Provider.rocket:
        return Colors.purple;
      case Provider.bank:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    final currencyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 2);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColor().withValues(alpha: 0.1),
          child: Icon(_getIcon(), color: _getColor()),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                currencyFormat.format(transaction.amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getColor(),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getProviderColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getProviderName(),
                style: TextStyle(
                  fontSize: 12,
                  color: _getProviderColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (transaction.recipient != null)
              Text('To: ${transaction.recipient}'),
            if (transaction.sender != null) Text('From: ${transaction.sender}'),
            Text('TrxID: ${transaction.transactionId}'),
            Text(
              dateFormat.format(transaction.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            if (transaction.synced)
              Row(
                children: [
                  Icon(Icons.cloud_done,
                      size: 14, color: Colors.green.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Synced',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
