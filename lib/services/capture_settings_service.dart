import 'package:hisabbox/models/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores SMS capture preferences such as whether live listening is enabled
/// and which transaction types should be imported.
class CaptureSettingsService {
  static const String _smsListeningEnabledKey = 'sms_listening_enabled';
  static const String _enabledTransactionTypesKey = 'enabled_transaction_types';

  /// Returns whether automatic SMS listening should be active.
  ///
  /// Defaults to `true` so the application behaves like previous versions
  /// until the user explicitly toggles the preference off.
  static Future<bool> isSmsListeningEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_smsListeningEnabledKey) ?? true;
  }

  /// Persists the SMS listening preference.
  static Future<void> setSmsListeningEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_smsListeningEnabledKey, enabled);
  }

  /// Loads the persisted transaction type selections.
  static Future<Set<TransactionType>> getEnabledTransactionTypes() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_enabledTransactionTypesKey);

    if (stored == null || stored.isEmpty) {
      return TransactionType.values.toSet();
    }

    final enabledTypes = <TransactionType>{};
    for (final name in stored) {
      final type = _typeFromName(name);
      if (type != null) {
        enabledTypes.add(type);
      }
    }

    if (enabledTypes.isEmpty) {
      return TransactionType.values.toSet();
    }

    return enabledTypes;
  }

  /// Saves the enabled transaction type collection.
  static Future<void> setEnabledTransactionTypes(
    Set<TransactionType> enabledTypes,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final names = enabledTypes.map((type) => type.name).toList(growable: false);
    await prefs.setStringList(_enabledTransactionTypesKey, names);
  }

  /// Returns the full on/off map for each [TransactionType].
  static Future<Map<TransactionType, bool>> getTransactionTypeSettings() async {
    final enabledTypes = await getEnabledTransactionTypes();
    return {
      for (final type in TransactionType.values)
        type: enabledTypes.contains(type),
    };
  }

  /// Convenience helper that checks whether a specific [TransactionType]
  /// should be captured.
  static Future<bool> isTransactionTypeEnabled(TransactionType type) async {
    final enabledTypes = await getEnabledTransactionTypes();
    return enabledTypes.contains(type);
  }

  static TransactionType? _typeFromName(String name) {
    for (final type in TransactionType.values) {
      if (type.name == name) {
        return type;
      }
    }
    return null;
  }
}
