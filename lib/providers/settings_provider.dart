import 'package:flutter/foundation.dart';
import 'package:hisabbox/services/webhook_service.dart';
import 'package:hisabbox/services/provider_settings_service.dart';
import 'package:hisabbox/models/transaction.dart';

class SettingsProvider extends ChangeNotifier {
  bool _webhookEnabled = false;
  String _webhookUrl = '';
  bool _autoSync = true;
  Map<Provider, bool> _providerSettings = {
    for (final provider in Provider.values) provider: true,
  };

  bool get webhookEnabled => _webhookEnabled;
  String get webhookUrl => _webhookUrl;
  bool get autoSync => _autoSync;
  Map<Provider, bool> get providerSettings => Map.unmodifiable(_providerSettings);
  List<Provider> get enabledProviders => _providerSettings.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList(growable: false);

  Future<void> loadSettings() async {
    _webhookEnabled = await WebhookService.isWebhookEnabled();
    _webhookUrl = await WebhookService.getWebhookUrl() ?? '';
    _autoSync = await WebhookService.isAutoSyncEnabled();
    _providerSettings = await ProviderSettingsService.getProviderSettings();

    notifyListeners();
  }

  Future<void> setWebhookEnabled(bool enabled) async {
    _webhookEnabled = enabled;
    await WebhookService.setWebhookEnabled(enabled);
    notifyListeners();
  }

  Future<void> setWebhookUrl(String url) async {
    _webhookUrl = url;
    await WebhookService.setWebhookUrl(url);
    notifyListeners();
  }

  Future<void> setAutoSync(bool enabled) async {
    _autoSync = enabled;
    await WebhookService.setAutoSyncEnabled(enabled);
    notifyListeners();
  }

  Future<void> setProviderEnabled(Provider provider, bool enabled) async {
    _providerSettings = Map.of(_providerSettings)
      ..[provider] = enabled;
    await ProviderSettingsService.setProviderEnabled(provider, enabled);
    notifyListeners();
  }

  Future<bool> testWebhook() async {
    if (_webhookUrl.isEmpty) return false;
    return await WebhookService.testWebhook(_webhookUrl);
  }
}
