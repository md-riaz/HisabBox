import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/providers/bank/bank_asia_provider.dart';
import 'package:hisabbox/services/providers/bank/brac_bank_provider.dart';
import 'package:hisabbox/services/providers/bank/city_bank_provider.dart';
import 'package:hisabbox/services/providers/bank/dutch_bangla_bank_provider.dart';
import 'package:hisabbox/services/providers/bank/islami_bank_provider.dart';
import 'package:hisabbox/services/providers/bkash_provider.dart';
import 'package:hisabbox/services/providers/nagad_provider.dart';
import 'package:hisabbox/services/providers/rocket_provider.dart';
import 'package:hisabbox/services/providers/sms_provider.dart';

/// Coordinates SMS parsing by delegating to the appropriate [SmsProvider]
/// implementation based on the message sender and body.
class BaseSmsProvider {
  BaseSmsProvider._();

  static final List<SmsProvider> _providers = [
    BkashProvider(),
    NagadProvider(),
    RocketProvider(),
    DutchBanglaBankProvider(),
    BracBankProvider(),
    CityBankProvider(),
    BankAsiaProvider(),
    IslamiBankProvider(),
  ];

  /// Parses an incoming SMS into a [Transaction] by selecting the matching
  /// provider and delegating the extraction work.
  static Transaction? parse(
    String address,
    String message,
    DateTime timestamp,
  ) {
    final trimmedAddress = address.trim();
    final trimmedMessage = message.trim();

    for (final provider in _providers) {
      if (!provider.matches(trimmedAddress, trimmedMessage)) {
        continue;
      }

      final transaction = provider.parse(
        trimmedAddress,
        trimmedMessage,
        timestamp,
      );

      if (transaction != null) {
        return transaction;
      }
    }

    return null;
  }
}
