import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hisabbox/providers/transaction_provider.dart';
import 'package:hisabbox/providers/settings_provider.dart';
import 'package:hisabbox/screens/dashboard_screen.dart';
import 'package:hisabbox/services/database_service.dart';
import 'package:hisabbox/services/sms_service.dart';
import 'package:hisabbox/services/permission_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  await DatabaseService.instance.database;
  
  // Request permissions
  await PermissionService.requestPermissions();
  
  // Initialize SMS monitoring
  await SmsService.instance.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
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
      ),
    );
  }
}
