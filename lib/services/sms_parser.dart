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

class SmsParser {
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
