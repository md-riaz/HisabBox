import 'package:flutter/material.dart';
import 'package:hisabbox/models/transaction.dart';

extension ProviderUiMetadata on Provider {
  String get displayName {
    switch (this) {
      case Provider.bkash:
        return 'bKash';
      case Provider.nagad:
        return 'Nagad';
      case Provider.rocket:
        return 'Rocket';
      case Provider.bank:
        return 'Bank';
      case Provider.other:
        return 'Other';
    }
  }

  Color get accentColor {
    switch (this) {
      case Provider.bkash:
        return Colors.pink;
      case Provider.nagad:
        return Colors.orange;
      case Provider.rocket:
        return Colors.purple;
      case Provider.bank:
        return Colors.blue;
      case Provider.other:
        return Colors.grey;
    }
  }

  IconData get glyph {
    switch (this) {
      case Provider.bkash:
        return Icons.mobile_friendly;
      case Provider.nagad:
        return Icons.smartphone;
      case Provider.rocket:
        return Icons.rocket_launch;
      case Provider.bank:
        return Icons.account_balance;
      case Provider.other:
        return Icons.help_outline;
    }
  }
}
