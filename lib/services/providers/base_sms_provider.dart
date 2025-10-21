import 'package:flutter/foundation.dart';
import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/provider_settings_service.dart';
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
    DateTime timestamp, {
    Iterable<Provider>? enabledProviders,
  }) async {
    final trimmedAddress = address.trim();
    final trimmedMessage = message.trim();
    Map<Provider, List<String>> senderIdMap;
    try {
      senderIdMap = await SenderIdSettingsService.getAllSenderIds();
    } catch (error, stackTrace) {
      debugPrint('Failed to load sender IDs: $error');
      debugPrintStack(stackTrace: stackTrace);
      senderIdMap = const <Provider, List<String>>{};
    }
    final Iterable<Provider> activeProviders =
        enabledProviders ?? SenderIdSettingsService.supportedProviders;

    if (activeProviders.isEmpty) {
      return null;
    }

    Map<Provider, bool> providerSettings;
    try {
      providerSettings = await ProviderSettingsService.getProviderSettings();
    } catch (error, stackTrace) {
      debugPrint('Failed to load provider settings: $error');
      debugPrintStack(stackTrace: stackTrace);
      providerSettings = const <Provider, bool>{};
    }
    final providers = _buildProviders(
      senderIdMap,
      activeProviders,
      providerSettings,
    );

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
    Iterable<Provider> enabledProviders,
    Map<Provider, bool> providerSettings,
  ) {
    final Set<Provider> allowed = Set<Provider>.from(enabledProviders);

    if (allowed.isEmpty) {
      return const <SmsProvider>[];
    }

    bool _isAllowed(Provider provider) {
      if (!allowed.contains(provider)) {
        return false;
      }

      return providerSettings[provider] ??
          ProviderSettingsService.isDefaultEnabled(provider);
    }

    final List<SmsProvider> providers = [];

    if (_isAllowed(Provider.bkash)) {
      providers.add(
        BkashProvider(
          senderIds:
              senderIdMap[Provider.bkash] ?? BkashProvider.defaultSenderIds,
        ),
      );
    }

    if (_isAllowed(Provider.nagad)) {
      providers.add(
        NagadProvider(
          senderIds:
              senderIdMap[Provider.nagad] ?? NagadProvider.defaultSenderIds,
        ),
      );
    }

    if (_isAllowed(Provider.rocket)) {
      providers.add(
        RocketProvider(
          senderIds:
              senderIdMap[Provider.rocket] ?? RocketProvider.defaultSenderIds,
        ),
      );
    }

    if (_isAllowed(Provider.bracBank)) {
      providers.add(
        BracBankProvider(
          senderIds:
              senderIdMap[Provider.bracBank] ??
              BracBankProvider.defaultSenderIds,
        ),
      );
    }

    return providers;
  }
}
