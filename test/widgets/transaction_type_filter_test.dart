import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hisabbox/controllers/transaction_controller.dart';
import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/models/transaction_type_extensions.dart';
import 'package:hisabbox/services/capture_settings_service.dart';
import 'package:hisabbox/services/database_service.dart';
import 'package:hisabbox/widgets/transaction_type_filter.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqflite_ffi.sqfliteFfiInit();
    sqflite.databaseFactory = sqflite_ffi.databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseService.instance.resetForTesting();
    Get.reset();
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('toggling chips updates controller selections', (
    WidgetTester tester,
  ) async {
    final controller = Get.put(TransactionController());
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: TransactionTypeFilter())),
    );

    await tester.pumpAndSettle();

    expect(
      controller.selectedTransactionTypes.length,
      CaptureSettingsService.defaultEnabledTypes.length,
    );

    const targetType = TransactionType.sent;
    final chipFinder = find.widgetWithText(FilterChip, targetType.displayName);
    expect(chipFinder, findsOneWidget);

    expect(controller.selectedTransactionTypes.contains(targetType), isFalse);
    final initialChip = tester.widget<FilterChip>(chipFinder);
    expect(initialChip.selected, isFalse);

    await tester.tap(chipFinder);
    await tester.pumpAndSettle();

    expect(controller.selectedTransactionTypes.contains(targetType), isTrue);
    final selectedChip = tester.widget<FilterChip>(chipFinder);
    expect(selectedChip.selected, isTrue);

    await tester.tap(chipFinder);
    await tester.pumpAndSettle();

    expect(controller.selectedTransactionTypes.contains(targetType), isFalse);
    final deselectedChip = tester.widget<FilterChip>(chipFinder);
    expect(deselectedChip.selected, isFalse);
  });
}
