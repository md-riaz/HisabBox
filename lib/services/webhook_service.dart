import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/database_service.dart';

class WebhookService {
  static const String _webhookUrlKey = 'webhook_url';
  static const String _webhookEnabledKey = 'webhook_enabled';

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
  }

  static Future<void> syncTransactions() async {
    final enabled = await isWebhookEnabled();
    if (!enabled) return;

    final url = await getWebhookUrl();
    if (url == null || url.isEmpty) return;

    final unsyncedTransactions = await DatabaseService.instance.getUnsyncedTransactions();
    
    for (final transaction in unsyncedTransactions) {
      try {
        await _sendTransaction(url, transaction);
        await DatabaseService.instance.markAsSynced(transaction.id);
      } catch (e) {
        // Log error but continue with other transactions
        print('Error syncing transaction ${transaction.id}: $e');
      }
    }
  }

  static Future<void> _sendTransaction(String url, Transaction transaction) async {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(transaction.toJson()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to sync transaction: ${response.statusCode}');
    }
  }

  static Future<bool> testWebhook(String url) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'test': true,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    }
  }
}
