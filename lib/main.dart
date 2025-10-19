import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hisabbox/controllers/transaction_controller.dart';
import 'package:hisabbox/controllers/settings_controller.dart';
import 'package:hisabbox/screens/dashboard_screen.dart';
import 'package:hisabbox/screens/permission_required_screen.dart';
import 'package:hisabbox/services/database_service.dart';
import 'package:hisabbox/services/sms_service.dart';
import 'package:hisabbox/services/permission_service.dart';
import 'package:hisabbox/services/webhook_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseService.instance.database;

  // Check current permissions before initializing services
  final permissionsGranted = await PermissionService.checkPermissions();

  if (permissionsGranted) {
    await _initializeServicesAndControllers();
  }

  runApp(MyApp(permissionsGranted: permissionsGranted));
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
  const MyApp({super.key, required this.permissionsGranted});

  final bool permissionsGranted;

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
          ? const DashboardScreen()
          : PermissionRequiredScreen(
              onPermissionsGranted: () async {
                await _initializeServicesAndControllers();
                Get.offAll(() => const DashboardScreen());
              },
            ),
    );
  }
}
