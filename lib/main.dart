import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hisabbox/controllers/transaction_controller.dart';
import 'package:hisabbox/controllers/settings_controller.dart';
import 'package:hisabbox/screens/dashboard_screen.dart';
import 'package:hisabbox/screens/permission_required_screen.dart';
import 'package:hisabbox/screens/pin_lock_screen.dart';
import 'package:hisabbox/services/database_service.dart';
import 'package:hisabbox/services/sms_service.dart';
import 'package:hisabbox/services/permission_service.dart';
import 'package:hisabbox/services/webhook_service.dart';
import 'package:hisabbox/services/pin_lock_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseService.instance.database;

  // Check current permissions before initializing services
  final permissionsGranted = await PermissionService.checkPermissions();
  var pinLockEnabled = false;

  if (permissionsGranted) {
    await _initializeServicesAndControllers();
    pinLockEnabled = await PinLockService.instance.hasPin();
  }

  runApp(
    MyApp(
      permissionsGranted: permissionsGranted,
      pinLockEnabled: pinLockEnabled,
    ),
  );
}

Future<void> _initializeServicesAndControllers() async {
  await SmsService.instance.initialize();
  await WebhookService.initialize();

  if (!Get.isRegistered<TransactionController>()) {
    Get.put(TransactionController());
  }
  if (!Get.isRegistered<SettingsController>()) {
    Get.put(SettingsController());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.permissionsGranted,
    required this.pinLockEnabled,
  });

  final bool permissionsGranted;
  final bool pinLockEnabled;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'HisabBox',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: permissionsGranted
          ? (pinLockEnabled
              ? const PinLockScreen()
              : const DashboardScreen())
          : PermissionRequiredScreen(
              onPermissionsGranted: () async {
                await _initializeServicesAndControllers();
                final hasPin = await PinLockService.instance.hasPin();
                if (hasPin) {
                  Get.offAll(() => const PinLockScreen());
                } else {
                  Get.offAll(() => const DashboardScreen());
                }
              },
            ),
    );
  }
}
