import 'package:get/get.dart';
import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/capture_settings_service.dart';
import 'package:hisabbox/services/provider_settings_service.dart';
import 'package:hisabbox/services/sms_service.dart';
import 'package:hisabbox/services/webhook_service.dart';

class SettingsController extends GetxController {
  final RxBool webhookEnabled = false.obs;
  final RxString webhookUrl = ''.obs;
  final RxMap<Provider, bool> providerSettings = {
    for (final provider in Provider.values)
      provider: provider == Provider.bkash,
  }.obs;
  final RxBool smsListeningEnabled = true.obs;
  final RxMap<TransactionType, bool> transactionTypeSettings = {
    for (final type in TransactionType.values)
      type: type == TransactionType.received,
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
    providerSettings.assignAll(
      await ProviderSettingsService.getProviderSettings(),
    );
    smsListeningEnabled.value =
        await CaptureSettingsService.isSmsListeningEnabled();
    transactionTypeSettings.assignAll(
      await CaptureSettingsService.getTransactionTypeSettings(),
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

  Future<void> setProviderEnabled(Provider provider, bool enabled) async {
    providerSettings[provider] = enabled;
    await ProviderSettingsService.setProviderEnabled(provider, enabled);
  }

  Future<void> setSmsListeningEnabled(bool enabled) async {
    smsListeningEnabled.value = enabled;
    await CaptureSettingsService.setSmsListeningEnabled(enabled);

    if (enabled) {
      await SmsService.instance.startListening();
    } else {
      await SmsService.instance.stopListening();
    }
  }

  Future<bool> setTransactionTypeEnabled(
    TransactionType type,
    bool enabled,
  ) async {
    if (!enabled) {
      final hasAnotherEnabled = transactionTypeSettings.entries
          .where((entry) => entry.key != type)
          .any((entry) => entry.value);
      if (!hasAnotherEnabled) {
        return false;
      }
    }

    transactionTypeSettings[type] = enabled;
    await CaptureSettingsService.setEnabledTransactionTypes(
      transactionTypeSettings.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toSet(),
    );
    return true;
  }

  Future<bool> testWebhook() async {
    if (webhookUrl.isEmpty) return false;
    return WebhookService.testWebhook(webhookUrl.value);
  }
}
