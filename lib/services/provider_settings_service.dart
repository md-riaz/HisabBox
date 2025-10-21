import 'package:hisabbox/models/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hisabbox/services/sms_preferences_cache.dart';

/// Manages the enabled/disabled state of SMS providers.
///
/// Provider preferences are stored in [SharedPreferences] so they can be
/// accessed from background isolates (for example, when the another_telephony plugin
/// processes messages while the Flutter runtime is killed).
class ProviderSettingsService {
  static const String _providerPrefix = 'provider_enabled_';

  /// Returns whether a provider is enabled by default when no preference has
  /// been stored yet.
  ///
  /// Only bKash starts enabled out of the box so the app behaves like legacy
  /// installs until users explicitly opt into other providers.
  static bool isDefaultEnabled(Provider provider) => provider == Provider.bkash;

  /// Returns whether [provider] is currently enabled.
  ///
  /// Defaults to [isDefaultEnabled] so bKash starts enabled while other
  /// providers stay disabled until explicitly toggled by the user.
  static Future<bool> isProviderEnabled(Provider provider) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPreference = prefs.getBool(_keyFor(provider));
    return storedPreference ?? isDefaultEnabled(provider);
  }

  /// Persists the enabled/disabled flag for [provider].
  static Future<void> setProviderEnabled(
    Provider provider,
    bool enabled,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFor(provider), enabled);
    invalidateSmsPreferencesCache();
  }

  /// Loads the full provider preference map.
  static Future<Map<Provider, bool>> getProviderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<Provider, bool> result = {};

    for (final provider in Provider.values) {
      result[provider] =
          prefs.getBool(_keyFor(provider)) ?? isDefaultEnabled(provider);
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
}
