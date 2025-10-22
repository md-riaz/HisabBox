import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/database_service.dart';
import 'package:hisabbox/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class WebhookService {
  static const String _webhookUrlKey = 'webhook_url';
  static const String _webhookEnabledKey = 'webhook_enabled';
  static const String _webhookSyncTask = 'webhook_sync_task';
  static const String _webhookUniqueName = 'webhook_sync_unique';

  static Dio _dio = Dio(
    BaseOptions(
      headers: const {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  @visibleForTesting
  static void setHttpClientForTesting(Dio dio) {
    _dio = dio;
  }

  static Future<void> initialize() async {
    await Workmanager().initialize(
      webhookCallbackDispatcher,
    );
  }

  static Future<String?> getWebhookUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_webhookUrlKey);
  }

  static Future<void> setWebhookUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_webhookUrlKey, url);
  }

  static Future<bool> isWebhookEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_webhookEnabledKey) ?? false;
  }

  static Future<void> setWebhookEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_webhookEnabledKey, enabled);
    if (!enabled) {
      await Workmanager().cancelByUniqueName(_webhookUniqueName);
    }
  }

  static Future<void> processNewTransaction(Transaction transaction) async {
    if (transaction.synced) return;

    final success = await syncTransactions();
    if (!success) {
      await _scheduleSync(attempt: 1);
    } else {
      await Workmanager().cancelByUniqueName(_webhookUniqueName);
    }
  }

  static Future<void> syncTransactionsManually() async {
    final success = await syncTransactions();
    if (!success) {
      await _scheduleSync(attempt: 1);
    } else {
      await Workmanager().cancelByUniqueName(_webhookUniqueName);
    }
  }

  static Future<bool> syncTransactions() async {
    return _syncTransactionsInternal();
  }

  /// Force a sync attempt for imports or manual requests.
  /// This will ignore the auto-sync preference and attempt to send unsynced
  /// transactions if the webhook is enabled and configured.
  static Future<bool> syncTransactionsForce() async {
    return _syncTransactionsInternal();
  }

  static Future<bool> _syncTransactionsInternal() async {
    final enabled = await isWebhookEnabled();
    if (!enabled) return true;

    final url = await getWebhookUrl();
    if (url == null || url.isEmpty) return true;

    final unsyncedTransactions =
        await DatabaseService.instance.getUnsyncedTransactions();

    if (unsyncedTransactions.isEmpty) {
      return true;
    }

    final totalTransactions = unsyncedTransactions.length;
    var successfulTransactions = 0;

    for (final transaction in unsyncedTransactions) {
      try {
        await _sendTransaction(url, transaction);
        await DatabaseService.instance.markAsSynced(transaction.id);
        successfulTransactions++;
      } catch (e) {
        // ignore: avoid_print
        print('Error syncing transaction ${transaction.id}: $e');
        await NotificationService.showWebhookSummaryNotification(
          success: false,
          totalTransactions: totalTransactions,
          successfulTransactions: successfulTransactions,
        );
        return false;
      }
    }

    await NotificationService.showWebhookSummaryNotification(
      success: true,
      totalTransactions: totalTransactions,
      successfulTransactions: successfulTransactions,
    );

    return true;
  }

  static Future<void> _scheduleSync({int attempt = 0}) async {
    final delay = attempt == 0 ? Duration.zero : _backoffDelay(attempt);
    await Workmanager().registerOneOffTask(
      _webhookUniqueName,
      _webhookSyncTask,
      inputData: {'attempt': attempt},
      initialDelay: delay,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  static Duration _backoffDelay(int attempt) {
    final minutes = min<int>(30, pow(2, attempt).toInt());
    return Duration(minutes: minutes);
  }

  static Future<void> _sendTransaction(
    String url,
    Transaction transaction,
  ) async {
    await _dio.post(url, data: jsonEncode(transaction.toJson()));
  }

  static Future<bool> testWebhook(String url) async {
    try {
      final response = await _dio.post(
        url,
        data: jsonEncode({
          'test': true,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (e) {
      return false;
    }
  }
}

@pragma('vm:entry-point')
void webhookCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    await NotificationService.initialize();
    final attempt = (inputData?['attempt'] as int?) ?? 0;
    final success = await WebhookService.syncTransactions();
    if (!success) {
      await WebhookService._scheduleSync(attempt: attempt + 1);
    }
    return Future.value(true);
  });
}
