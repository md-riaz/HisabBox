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
      case Provider.other:
        return Icons.help_outline;
    }
  }

  String get matchingDescription {
    switch (this) {
      case Provider.bkash:
        return 'Matches SMS from the configured bKash sender IDs (defaults include bKash and 16247).';
      case Provider.nagad:
        return 'Matches SMS from the configured Nagad sender IDs (defaults include Nagad and 16167).';
      case Provider.rocket:
        return 'Matches SMS from the configured Rocket sender IDs (defaults include Rocket and 16216).';
      case Provider.other:
        return 'Fallback for providers without a dedicated matcher.';
    }
  }
}
