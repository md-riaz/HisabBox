import 'package:telephony/telephony.dart';
import 'package:hisabbox/services/sms_parser.dart';
import 'package:hisabbox/services/database_service.dart';
import 'package:hisabbox/services/provider_settings_service.dart';
import 'package:hisabbox/services/webhook_service.dart';
import 'package:hisabbox/models/transaction.dart';

class SmsService {
  static final SmsService instance = SmsService._init();
  final Telephony telephony = Telephony.instance;

  SmsService._init();

  Future<void> initialize() async {
    // Set up SMS listener for new messages
    telephony.listenIncomingSms(
      onNewMessage: _onNewMessage,
      onBackgroundMessage: _onBackgroundMessage,
    );
  }

  static void _onBackgroundMessage(SmsMessage message) {
    // Handle SMS in background
    _processMessage(message);
  }

  void _onNewMessage(SmsMessage message) {
    // Handle SMS in foreground
    _processMessage(message);
  }

  static Future<void> _processMessage(SmsMessage message) async {
    final address = message.address ?? '';
    final body = message.body ?? '';
    final timestamp = message.date != null
        ? DateTime.fromMillisecondsSinceEpoch(message.date!)
        : DateTime.now();

    // Parse the SMS
    final transaction = SmsParser.parse(address, body, timestamp);

    // Save to database if it's a valid transaction
    if (transaction != null) {
      final isEnabled =
          await ProviderSettingsService.isProviderEnabled(transaction.provider);
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
  }) async {
    final messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      filter: SmsFilter.where(SmsColumn.DATE)
          .greaterThanOrEqualTo(startDate?.millisecondsSinceEpoch.toString() ?? '0')
          .and(SmsColumn.DATE)
          .lessThanOrEqualTo(endDate?.millisecondsSinceEpoch.toString() ?? 
              DateTime.now().millisecondsSinceEpoch.toString()),
    );

    for (final message in messages) {
      await _processMessage(message);
    }
  }

  Future<List<SmsMessage>> getAllMessages() async {
    return await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
    );
  }
}
