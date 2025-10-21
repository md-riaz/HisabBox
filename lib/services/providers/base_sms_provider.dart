import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/providers/bank/brac_bank_provider.dart';
import 'package:hisabbox/services/providers/bkash_provider.dart';
import 'package:hisabbox/services/providers/nagad_provider.dart';
import 'package:hisabbox/services/providers/rocket_provider.dart';
import 'package:hisabbox/services/providers/sms_provider.dart';
import 'package:hisabbox/services/sender_id_settings_service.dart';

/// Coordinates SMS parsing by delegating to the appropriate [SmsProvider]
/// implementation based on the message sender and body.
abstract final class BaseSmsProvider {
  /// Parses an incoming SMS into a [Transaction] by selecting the matching
  /// provider and delegating the extraction work.
  static Future<Transaction?> parse(
    String address,
    String message,
    DateTime timestamp,
  ) async {
    final trimmedAddress = address.trim();
    final trimmedMessage = message.trim();
    final senderIdMap = await SenderIdSettingsService.getAllSenderIds();
    final providers = _buildProviders(senderIdMap);

    for (final provider in providers) {
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

  static List<SmsProvider> _buildProviders(
    Map<Provider, List<String>> senderIdMap,
  ) {
    return [
      BkashProvider(
        senderIds:
            senderIdMap[Provider.bkash] ?? BkashProvider.defaultSenderIds,
      ),
      NagadProvider(
        senderIds:
            senderIdMap[Provider.nagad] ?? NagadProvider.defaultSenderIds,
      ),
      RocketProvider(
        senderIds:
            senderIdMap[Provider.rocket] ?? RocketProvider.defaultSenderIds,
      ),
      BracBankProvider(
        senderIds:
            senderIdMap[Provider.bracBank] ?? BracBankProvider.defaultSenderIds,
      ),
    ];
  }
}
