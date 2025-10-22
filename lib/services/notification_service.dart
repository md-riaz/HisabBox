import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initializationAttempted = false;
  static bool _isInitialized = false;

  static const AndroidNotificationChannel _webhookChannel =
      AndroidNotificationChannel(
    'webhook_sync_channel',
    'Webhook Sync',
    description:
        'Status updates when transactions are sent to your webhook.',
    importance: Importance.defaultImportance,
  );

  static const int _webhookNotificationId = 1001;

  static Future<void> initialize() async {
    if (_isInitialized || _initializationAttempted) {
      return;
    }

    _initializationAttempted = true;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettings = InitializationSettings(
        android: androidSettings,
      );

      await _notificationsPlugin.initialize(initializationSettings);
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_webhookChannel);

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService initialization failed: $e');
    }
  }

  static Future<void> showWebhookSummaryNotification({
    required bool success,
    required int totalTransactions,
    required int successfulTransactions,
  }) async {
    if (totalTransactions <= 0) {
      return;
    }

    if (!_initializationAttempted) {
      await initialize();
    }

    if (!_isInitialized) {
      return;
    }

    final body = _buildBody(
      success: success,
      totalTransactions: totalTransactions,
      successfulTransactions: successfulTransactions,
    );

    final androidDetails = AndroidNotificationDetails(
      _webhookChannel.id,
      _webhookChannel.name,
      channelDescription: _webhookChannel.description,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      styleInformation: BigTextStyleInformation(body),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    final title = success ? 'Webhook sync successful' : 'Webhook sync failed';

    try {
      await _notificationsPlugin.show(
        _webhookNotificationId,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Failed to show webhook notification: $e');
    }
  }

  static String _buildBody({
    required bool success,
    required int totalTransactions,
    required int successfulTransactions,
  }) {
    final totalLabel = _pluralize(totalTransactions);
    final successLabel = _pluralize(successfulTransactions);

    if (success) {
      return 'Sent $successfulTransactions $successLabel to your webhook.';
    }

    if (successfulTransactions <= 0) {
      return 'Failed to send $totalTransactions $totalLabel to your webhook. '
          'Will retry automatically.';
    }

    if (successfulTransactions >= totalTransactions) {
      return 'Sent $totalTransactions $totalLabel to your webhook.';
    }

    return 'Sent $successfulTransactions of $totalTransactions '
        '$totalLabel before failing. Will retry automatically.';
  }

  static String _pluralize(int count) {
    return count == 1 ? 'transaction' : 'transactions';
  }
}
