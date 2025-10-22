import 'package:flutter_test/flutter_test.dart';
import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/provider_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('only bKash is enabled by default', () async {
    final settings = await ProviderSettingsService.getProviderSettings();

    expect(settings[Provider.bkash], isTrue);

    expect(settings[Provider.nagad], isFalse);
    expect(settings[Provider.rocket], isFalse);
    expect(settings[Provider.bracBank], isFalse);

    for (final provider in Provider.values.where(
      (provider) => !ProviderSettingsService.isSupported(provider),
    )) {
      expect(settings[provider], isFalse);
    }
  });

  test('getEnabledProviders only returns bKash by default', () async {
    final enabledProviders = await ProviderSettingsService.getEnabledProviders();

    expect(enabledProviders, [Provider.bkash]);
  });

  test('provider toggle is persisted', () async {
    expect(
      await ProviderSettingsService.isProviderEnabled(Provider.nagad),
      isFalse,
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
