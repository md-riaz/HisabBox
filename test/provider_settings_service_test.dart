import 'package:flutter_test/flutter_test.dart';
import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/provider_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('supported providers are enabled by default', () async {
    final settings = await ProviderSettingsService.getProviderSettings();

    for (final provider in ProviderSettingsService.supportedProviders) {
      expect(settings[provider], isTrue);
    }

    for (final provider in Provider.values.where(
      (provider) => !ProviderSettingsService.isSupported(provider),
    )) {
      expect(settings[provider], isFalse);
    }
  });

  test('provider toggle is persisted', () async {
    expect(
      await ProviderSettingsService.isProviderEnabled(Provider.nagad),
      isTrue,
    );

    await ProviderSettingsService.setProviderEnabled(Provider.nagad, false);

    expect(
      await ProviderSettingsService.isProviderEnabled(Provider.nagad),
      isFalse,
    );

    await ProviderSettingsService.setProviderEnabled(Provider.nagad, true);

    expect(
      await ProviderSettingsService.isProviderEnabled(Provider.nagad),
      isTrue,
    );
  });

  test('unsupported providers stay disabled', () async {
    await ProviderSettingsService.setProviderEnabled(Provider.cityBank, true);

    expect(
      await ProviderSettingsService.isProviderEnabled(Provider.cityBank),
      isFalse,
    );

    final settings = await ProviderSettingsService.getProviderSettings();
    expect(settings[Provider.cityBank], isFalse);
  });
}
