import 'package:get/get.dart';
import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/provider_settings_service.dart';
import 'package:hisabbox/services/webhook_service.dart';

class SettingsController extends GetxController {
  final RxBool webhookEnabled = false.obs;
  final RxString webhookUrl = ''.obs;
  final RxBool autoSync = true.obs;
  final RxMap<Provider, bool> providerSettings = {
    for (final provider in Provider.values) provider: true,
  }.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  List<Provider> get enabledProviders => providerSettings.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList(growable: false);

  Future<void> loadSettings() async {
    webhookEnabled.value = await WebhookService.isWebhookEnabled();
    webhookUrl.value = await WebhookService.getWebhookUrl() ?? '';
    autoSync.value = await WebhookService.isAutoSyncEnabled();
    providerSettings.assignAll(
      await ProviderSettingsService.getProviderSettings(),
    );
  }

  Future<void> setWebhookEnabled(bool enabled) async {
    webhookEnabled.value = enabled;
    await WebhookService.setWebhookEnabled(enabled);
  }

  Future<void> setWebhookUrl(String url) async {
    webhookUrl.value = url;
    await WebhookService.setWebhookUrl(url);
  }

  Future<void> setAutoSync(bool enabled) async {
    autoSync.value = enabled;
    await WebhookService.setAutoSyncEnabled(enabled);
  }

  Future<void> setProviderEnabled(Provider provider, bool enabled) async {
    providerSettings[provider] = enabled;
    await ProviderSettingsService.setProviderEnabled(provider, enabled);
  }

  Future<bool> testWebhook() async {
    if (webhookUrl.isEmpty) return false;
    return WebhookService.testWebhook(webhookUrl.value);
  }
}
