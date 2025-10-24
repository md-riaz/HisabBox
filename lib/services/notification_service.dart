import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:hisabbox/screens/dashboard_screen.dart';
import 'package:hisabbox/screens/pin_lock_screen.dart';
import 'package:hisabbox/services/pin_lock_service.dart';

/// Centralized helper for foreground notifications.
///
/// The application uses a persistent notification whenever webhook syncing is
/// running so reviewers (and users) can immediately tell that background work
/// is happening. Tapping the notification should return the user to the app
/// while still honoring any PIN lock that has been configured.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _syncChannelId = 'hisabbox_sync_status';
  static const String _syncChannelName = 'Sync status';
  static const String _syncChannelDescription =
      'Shows when HisabBox is syncing transactions in the background.';
  static const String _summaryChannelId = 'hisabbox_sync_summary';
  static const String _summaryChannelName = 'Sync summary';
  static const String _summaryChannelDescription =
      'Summaries of recent HisabBox sync attempts.';
  static const int _syncNotificationId = 2001;
  static const int _summaryNotificationId = 2002;
  static const String _syncPayload = 'open_dashboard_from_sync';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _pendingNotificationNavigation = false;
  bool _pluginAvailable = true;

  /// Initializes the notification plugin and registers the sync channel.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    NotificationAppLaunchDetails? launchDetails;
    try {
      launchDetails = await _plugin.getNotificationAppLaunchDetails();
    } on MissingPluginException {
      _pluginAvailable = false;
      _initialized = true;
      return;
    }

    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    try {
      await _plugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload == _syncPayload) {
            _handleSyncNotificationTap();
          }
        },
      );
    } on MissingPluginException {
      _pluginAvailable = false;
      _initialized = true;
      return;
    }

    await _createAndroidChannels();

    _initialized = true;

    if ((launchDetails?.didNotificationLaunchApp ?? false) &&
        launchDetails?.notificationResponse?.payload == _syncPayload) {
      _handleSyncNotificationTap();
    }
  }

  Future<void> _createAndroidChannels() async {
    const syncChannel = AndroidNotificationChannel(
      _syncChannelId,
      _syncChannelName,
      description: _syncChannelDescription,
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );
    const summaryChannel = AndroidNotificationChannel(
      _summaryChannelId,
      _summaryChannelName,
      description: _summaryChannelDescription,
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(syncChannel);
    await androidPlugin?.createNotificationChannel(summaryChannel);
  }

  /// Displays the persistent sync notification.
  Future<void> showSyncInProgress({int? pendingCount}) async {
    await initialize();
    if (!_pluginAvailable) {
      return;
    }

    final plural = pendingCount == 1 ? '' : 's';
    final body = pendingCount != null && pendingCount > 0
        ? 'Delivering $pendingCount pending transaction$plural'
        : 'Delivering pending transactions';

    const androidDetails = AndroidNotificationDetails(
      _syncChannelId,
      _syncChannelName,
      channelDescription: _syncChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      enableVibration: false,
      playSound: false,
      category: AndroidNotificationCategory.progress,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    try {
      await _plugin.show(
        _syncNotificationId,
        'HisabBox sync running',
        body,
        details,
        payload: _syncPayload,
      );
    } on MissingPluginException {
      _pluginAvailable = false;
    }
  }

  /// Removes the sync notification if it is showing.
  Future<void> cancelSyncNotification() async {
    if (!_initialized) {
      await initialize();
    }
    if (!_pluginAvailable) {
      return;
    }
    try {
      await _plugin.cancel(_syncNotificationId);
    } on MissingPluginException {
      _pluginAvailable = false;
    }
  }

  /// Ensures any pending navigation from the sync notification runs once
  /// navigation is available.
  void consumePendingNavigation() {
    if (!_pendingNotificationNavigation) {
      return;
    }
    if (Get.key.currentState == null) {
      return;
    }
    _navigateRespectingPinLock();
  }

  void _handleSyncNotificationTap() {
    if (Get.key.currentState == null) {
      _pendingNotificationNavigation = true;
      return;
    }
    _navigateRespectingPinLock();
  }

  void _navigateRespectingPinLock() {
    _pendingNotificationNavigation = false;
    PinLockService.instance.hasPin().then((hasPin) {
      if (Get.key.currentState == null) {
        _pendingNotificationNavigation = true;
        return;
      }
      if (hasPin) {
        Get.offAll(() => const PinLockScreen());
      } else {
        Get.offAll(() => const DashboardScreen());
      }
    });
  }

  /// Shows a one-shot summary notification for the last sync attempt.
  Future<void> showSyncSummary({
    required int successCount,
    required int failureCount,
    required bool overallSuccess,
  }) async {
    await initialize();
    if (!_pluginAvailable) {
      return;
    }

    final total = successCount + failureCount;
    final title = overallSuccess
        ? 'HisabBox sync completed'
        : 'HisabBox sync needs attention';

    final String body;
    if (total == 0) {
      body = 'No transactions required syncing.';
    } else if (failureCount == 0) {
      final plural = successCount == 1 ? 'transaction' : 'transactions';
      body = 'Synced $successCount $plural successfully.';
    } else if (successCount == 0) {
      final plural = failureCount == 1 ? 'transaction' : 'transactions';
      body = 'All $failureCount $plural failed to sync.';
    } else {
      body =
          '$successCount successful · $failureCount failed. Some transactions failed to sync.';
    }

    final androidDetails = AndroidNotificationDetails(
      _summaryChannelId,
      _summaryChannelName,
      channelDescription: _summaryChannelDescription,
      importance: overallSuccess
          ? Importance.defaultImportance
          : Importance.high,
      priority: overallSuccess ? Priority.defaultPriority : Priority.high,
      autoCancel: true,
      enableVibration: !overallSuccess,
      playSound: !overallSuccess,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.status,
    );

    final details = NotificationDetails(android: androidDetails);

    try {
      await _plugin.show(
        _summaryNotificationId,
        title,
        body,
        details,
        payload: _syncPayload,
      );
    } on MissingPluginException {
      _pluginAvailable = false;
    }
  }
}
