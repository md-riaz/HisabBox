import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hisabbox/services/webhook_service.dart';

class SettingsProvider extends ChangeNotifier {
  bool _webhookEnabled = false;
  String _webhookUrl = '';
  bool _autoSync = true;

  bool get webhookEnabled => _webhookEnabled;
  String get webhookUrl => _webhookUrl;
  bool get autoSync => _autoSync;

  Future<void> loadSettings() async {
    _webhookEnabled = await WebhookService.isWebhookEnabled();
    _webhookUrl = await WebhookService.getWebhookUrl() ?? '';
    
    final prefs = await SharedPreferences.getInstance();
    _autoSync = prefs.getBool('auto_sync') ?? true;
    
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_sync', enabled);
    notifyListeners();
  }

  Future<bool> testWebhook() async {
    if (_webhookUrl.isEmpty) return false;
    return await WebhookService.testWebhook(_webhookUrl);
  }
}
