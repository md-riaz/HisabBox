import 'package:hisabbox/models/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the enabled/disabled state of SMS providers.
///
/// Provider preferences are stored in [SharedPreferences] so they can be
/// accessed from background isolates (for example, when the another_telephony plugin
/// processes messages while the Flutter runtime is killed).
class ProviderSettingsService {
  static const String _providerPrefix = 'provider_enabled_';
  static const String _legacyBankKey = '${_providerPrefix}bank';
  static const Set<Provider> _bankProviders = {
    Provider.dutchBanglaBank,
    Provider.bracBank,
    Provider.cityBank,
    Provider.bankAsia,
    Provider.islamiBank,
  };

  /// Returns whether [provider] is currently enabled.
  ///
  /// Defaults to `true` so newly supported providers begin in an enabled
  /// state without requiring additional migrations.
  static Future<bool> isProviderEnabled(Provider provider) async {
    final prefs = await SharedPreferences.getInstance();
    final legacyBankPreference = prefs.getBool(_legacyBankKey);
    return _readProviderPreference(
          prefs,
          provider,
          legacyBankPreference,
        ) ??
        true;
  }

  /// Persists the enabled/disabled flag for [provider].
  static Future<void> setProviderEnabled(
    Provider provider,
    bool enabled,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFor(provider), enabled);
  }

  /// Loads the full provider preference map.
  static Future<Map<Provider, bool>> getProviderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<Provider, bool> result = {};

    final legacyBankPreference = prefs.getBool(_legacyBankKey);

    for (final provider in Provider.values) {
      result[provider] = _readProviderPreference(
            prefs,
            provider,
            legacyBankPreference,
          ) ??
          true;
    }

    return result;
  }

  /// Convenience helper that returns the subset of enabled providers.
  static Future<List<Provider>> getEnabledProviders() async {
    final settings = await getProviderSettings();
    return settings.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList(growable: false);
  }

  static String _keyFor(Provider provider) =>
      '$_providerPrefix${provider.name}';

  static bool? _readProviderPreference(
    SharedPreferences prefs,
    Provider provider,
    bool? legacyBankPreference,
  ) {
    final storedPreference = prefs.getBool(_keyFor(provider));
    if (storedPreference != null) {
      return storedPreference;
    }

    if (legacyBankPreference != null && _bankProviders.contains(provider)) {
      return legacyBankPreference;
    }

    return null;
  }
}
