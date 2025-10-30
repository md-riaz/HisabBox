import 'package:hisabbox/models/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the enabled/disabled state of SMS providers.
///
/// Provider preferences are stored in [SharedPreferences] so they can be
/// accessed from background isolates (for example, when the another_telephony plugin
/// processes messages while the Flutter runtime is killed).
class ProviderSettingsService {
  static const String _providerPrefix = 'provider_enabled_';

  /// Providers that the settings UI exposes for capture control.
  static const List<Provider> supportedProviders = <Provider>[
    Provider.bkash,
    Provider.nagad,
    Provider.rocket,
  ];

  static bool isSupported(Provider provider) =>
      supportedProviders.contains(provider);

  /// Returns whether a provider is enabled by default when no preference has
  /// been stored yet.
  ///
  /// Fresh installs only enable bKash so the app can operate in a
  /// privacy-preserving mode until the user explicitly opts other providers in.
  static bool isDefaultEnabled(Provider provider) {
    if (!isSupported(provider)) {
      return false;
    }
    return provider == Provider.bkash;
  }

  /// Returns whether [provider] is currently enabled.
  ///
  /// Defaults to [isDefaultEnabled] so bKash starts enabled while other
  /// supported providers remain disabled until a user opts into them.
  static Future<bool> isProviderEnabled(Provider provider) async {
    if (!isSupported(provider)) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final storedPreference = prefs.getBool(_keyFor(provider));
    return storedPreference ?? isDefaultEnabled(provider);
  }

  /// Persists the enabled/disabled flag for [provider].
  static Future<void> setProviderEnabled(
    Provider provider,
    bool enabled,
  ) async {
    if (!isSupported(provider)) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFor(provider), enabled);
  }

  /// Loads the full provider preference map.
  static Future<Map<Provider, bool>> getProviderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<Provider, bool> result = {};

    for (final provider in Provider.values) {
      if (!isSupported(provider)) {
        result[provider] = false;
        continue;
      }

      result[provider] =
          prefs.getBool(_keyFor(provider)) ?? isDefaultEnabled(provider);
    }

    return result;
  }

  /// Convenience helper that returns the subset of enabled providers.
  static Future<List<Provider>> getEnabledProviders() async {
    final settings = await getProviderSettings();
    return supportedProviders
        .where((provider) => settings[provider] ?? false)
        .toList(growable: false);
  }

  static String _keyFor(Provider provider) =>
      '$_providerPrefix${provider.name}';
}
