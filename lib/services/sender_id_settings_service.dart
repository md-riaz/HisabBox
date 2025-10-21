import 'package:hisabbox/models/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hisabbox/services/sms_preferences_cache.dart';

/// Stores and retrieves the SMS sender identifiers used by each provider.
///
/// The sender IDs are persisted in [SharedPreferences] so they can be
/// refreshed by background isolates before parsing an incoming SMS.
class SenderIdSettingsService {
  SenderIdSettingsService._();

  static const String _senderIdPrefix = 'sender_ids_';

  /// Providers that allow configurable sender IDs from the settings screen.
  static const List<Provider> supportedProviders = <Provider>[
    Provider.bkash,
    Provider.nagad,
    Provider.rocket,
    Provider.bracBank,
  ];

  static const Map<Provider, List<String>> _defaultSenderIds = {
    Provider.bkash: ['bkash', '16247'],
    Provider.nagad: ['nagad', '16167'],
    Provider.rocket: ['rocket', '16216'],
    Provider.bracBank: ['bracbank', 'brac-bank', 'brac'],
  };

  /// Returns the currently configured sender IDs for [provider].
  static Future<List<String>> getSenderIds(Provider provider) async {
    final prefs = await SharedPreferences.getInstance();
    return _loadSenderIds(prefs, provider);
  }

  /// Persists the [senderIds] for [provider] and returns the sanitized list.
  static Future<List<String>> setSenderIds(
    Provider provider,
    List<String> senderIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = _normalize(senderIds);

    await prefs.setStringList(_keyFor(provider), normalized);
    invalidateSmsPreferencesCache();
    return normalized;
  }

  /// Restores the default sender IDs for [provider].
  static Future<List<String>> resetToDefault(Provider provider) async {
    return setSenderIds(
      provider,
      _defaultSenderIds[provider] ?? const <String>[],
    );
  }

  /// Loads the sender IDs for all supported providers.
  static Future<Map<Provider, List<String>>> getAllSenderIds() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<Provider, List<String>> result = {};

    for (final provider in supportedProviders) {
      result[provider] = _loadSenderIds(prefs, provider);
    }

    return result;
  }

  /// Returns the immutable default sender IDs for [provider].
  static List<String> defaultSenderIdsFor(Provider provider) =>
      List<String>.unmodifiable(
        _defaultSenderIds[provider] ?? const <String>[],
      );

  static List<String> _normalize(List<String>? values) {
    if (values == null) {
      return const <String>[];
    }

    final normalized = <String>{};
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      normalized.add(trimmed.toLowerCase());
    }
    return normalized.toList();
  }

  static List<String> _loadSenderIds(
    SharedPreferences prefs,
    Provider provider,
  ) {
    final stored = prefs.getStringList(_keyFor(provider));
    if (stored == null) {
      return List<String>.from(_defaultSenderIds[provider] ?? const <String>[]);
    }

    return _normalize(stored);
  }

  static String _keyFor(Provider provider) =>
      '$_senderIdPrefix${provider.name}';
}
