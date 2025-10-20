import 'package:another_telephony/telephony.dart';
import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/capture_settings_service.dart';
import 'package:hisabbox/services/database_service.dart';
import 'package:hisabbox/services/provider_settings_service.dart';
import 'package:hisabbox/services/providers/base_sms_provider.dart';
import 'package:hisabbox/services/webhook_service.dart';

class SmsService {
  static final SmsService instance = SmsService._init();
  final Telephony telephony = Telephony.instance;
  bool _isListening = false;

  SmsService._init();

  Future<void> initialize() async {
    final shouldListen = await CaptureSettingsService.isSmsListeningEnabled();
    if (shouldListen) {
      await startListening();
    }
  }

  Future<void> startListening() async {
    if (_isListening) {
      return;
    }

    telephony.listenIncomingSms(
      onNewMessage: _onNewMessage,
      onBackgroundMessage: _onBackgroundMessage,
      listenInBackground: true,
    );
    _isListening = true;
  }

  Future<void> stopListening() async {
    _isListening = false;
  }

  @pragma('vm:entry-point')
  static Future<void> _onBackgroundMessage(SmsMessage message) async {
    // Handle SMS in background
    await _processMessage(message);
  }

  void _onNewMessage(SmsMessage message) {
    // Handle SMS in foreground
    _processMessage(message);
  }

  static Future<void> _processMessage(SmsMessage message) async {
    final listeningEnabled =
        await CaptureSettingsService.isSmsListeningEnabled();
    if (!listeningEnabled) {
      return;
    }

    final address = message.address ?? '';
    final body = message.body ?? '';
    final timestamp = message.date != null
        ? DateTime.fromMillisecondsSinceEpoch(message.date!)
        : DateTime.now();

    // Parse the SMS
    final Transaction? transaction =
        BaseSmsProvider.parse(address, body, timestamp);

    // Save to database if it's a valid transaction
    if (transaction != null) {
      final typeEnabled = await CaptureSettingsService.isTransactionTypeEnabled(
        transaction.type,
      );
      if (!typeEnabled) {
        return;
      }

      final isEnabled = await ProviderSettingsService.isProviderEnabled(
        transaction.provider,
      );
      if (!isEnabled) {
        return;
      }

      await DatabaseService.instance.insertTransaction(transaction);
      await WebhookService.processNewTransaction(transaction);
    }
  }

  Future<void> importHistoricalSms({
    DateTime? startDate,
    DateTime? endDate,
    bool syncImported = false,
  }) async {
    final messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      filter: SmsFilter.where(SmsColumn.DATE)
          .greaterThanOrEqualTo(
            startDate?.millisecondsSinceEpoch.toString() ?? '0',
          )
          .and(SmsColumn.DATE)
          .lessThanOrEqualTo(
            endDate?.millisecondsSinceEpoch.toString() ??
                DateTime.now().millisecondsSinceEpoch.toString(),
          ),
    );

    for (final message in messages) {
      await _processMessage(message);
      if (syncImported) {
        try {
          await WebhookService.syncTransactionsForce();
        } catch (_) {
          // ignore; scheduling/retry will be handled by WebhookService if needed
        }
      }
    }
  }

  Future<List<SmsMessage>> getAllMessages() async {
    return await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
    );
  }
}
