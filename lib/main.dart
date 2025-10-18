import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hisabbox/controllers/transaction_controller.dart';
import 'package:hisabbox/controllers/settings_controller.dart';
import 'package:hisabbox/screens/dashboard_screen.dart';
import 'package:hisabbox/services/database_service.dart';
import 'package:hisabbox/services/sms_service.dart';
import 'package:hisabbox/services/permission_service.dart';
import 'package:hisabbox/services/webhook_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseService.instance.database;

  // Request permissions
  await PermissionService.requestPermissions();

  // Initialize SMS monitoring
  await SmsService.instance.initialize();

  // Initialize webhook background dispatcher
  await WebhookService.initialize();

  // Register controllers
  Get.put(TransactionController());
  Get.put(SettingsController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: const DashboardScreen(),
    );
  }
}
