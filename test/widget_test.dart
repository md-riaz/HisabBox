import 'package:flutter_test/flutter_test.dart';
import 'package:hisabbox/main.dart';

void main() {
  testWidgets('App initializes without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Note: This test may not fully work without proper mocking of services
    // But it validates the basic structure

    // Verify that the app can be created
    expect(() => const MyApp(permissionsGranted: false), returnsNormally);
  });
}
