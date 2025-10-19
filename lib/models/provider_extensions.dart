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
      case Provider.dutchBanglaBank:
        return 'Dutch-Bangla Bank';
      case Provider.bracBank:
        return 'BRAC Bank';
      case Provider.cityBank:
        return 'City Bank';
      case Provider.bankAsia:
        return 'Bank Asia';
      case Provider.islamiBank:
        return 'Islami Bank';
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
      case Provider.dutchBanglaBank:
        return Colors.blue;
      case Provider.bracBank:
        return Colors.teal;
      case Provider.cityBank:
        return Colors.indigo;
      case Provider.bankAsia:
        return Colors.cyan;
      case Provider.islamiBank:
        return Colors.green;
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
      case Provider.dutchBanglaBank:
      case Provider.bracBank:
      case Provider.cityBank:
      case Provider.bankAsia:
      case Provider.islamiBank:
        return Icons.account_balance;
      case Provider.other:
        return Icons.help_outline;
    }
  }

  String get matchingDescription {
    switch (this) {
      case Provider.bkash:
        return 'Matches SMS from sender IDs like bKash, bKashAlert, and 16247.';
      case Provider.nagad:
        return 'Matches SMS from sender IDs like Nagad, NagadAlert, and 16167.';
      case Provider.rocket:
        return 'Matches SMS from sender IDs like Rocket, RocketAlert, and 16216.';
      case Provider.dutchBanglaBank:
        return 'Matches SMS containing Dutch-Bangla or DBBL account notifications.';
      case Provider.bracBank:
        return 'Matches SMS mentioning BRAC Bank account activity.';
      case Provider.cityBank:
        return 'Matches SMS referencing City Bank or CBL account alerts.';
      case Provider.bankAsia:
        return 'Matches SMS that include Bank Asia account updates.';
      case Provider.islamiBank:
        return 'Matches SMS mentioning Islami Bank or IBBL account activity.';
      case Provider.other:
        return 'Fallback for providers without a dedicated matcher.';
    }
  }
}
