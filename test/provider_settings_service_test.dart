import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/provider_settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('providers are enabled by default', () async {
    final settings = await ProviderSettingsService.getProviderSettings();

    for (final provider in Provider.values) {
      expect(settings[provider], isTrue);
    }
  });

  test('provider toggle is persisted', () async {
    await ProviderSettingsService.setProviderEnabled(Provider.nagad, false);

    expect(
      await ProviderSettingsService.isProviderEnabled(Provider.nagad),
      isFalse,
    );

    // Other providers should remain enabled.
    expect(
      await ProviderSettingsService.isProviderEnabled(Provider.bkash),
      isTrue,
    );
  });
}
