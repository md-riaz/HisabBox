import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hisabbox/models/provider_extensions.dart';
import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/models/transaction_type_extensions.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const TransactionCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    final currencyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 2);
    final typeColor = transaction.type.accentColor;
    final providerColor = transaction.provider.accentColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: typeColor.withValues(alpha: 0.1),
          child: Icon(transaction.type.glyph, color: typeColor),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    currencyFormat.format(transaction.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: providerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    transaction.provider.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: providerColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              transaction.type.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: typeColor,
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
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (transaction.synced)
              Row(
                children: [
                  Icon(
                    Icons.cloud_done,
                    size: 14,
                    color: Colors.green.shade600,
                  ),
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
