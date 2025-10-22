import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestPermissions() async {
    // Request SMS permissions
    final smsStatus = await Permission.sms.request();

    // Request notification permissions (for background service)
    final notificationStatus = await Permission.notification.request();

    return smsStatus.isGranted && notificationStatus.isGranted;
  }

  static Future<bool> checkPermissions() async {
    final smsStatus = await Permission.sms.status;
    final notificationStatus = await Permission.notification.status;

    return smsStatus.isGranted && notificationStatus.isGranted;
  }

  static Future<PermissionStatus> ensureSmsPermissionForImport() async {
    final status = await Permission.sms.status;
    if (status.isGranted) {
      return status;
    }
    return Permission.sms.request();
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
