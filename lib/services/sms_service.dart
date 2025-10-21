import 'dart:async';

import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';
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
    try {
      await _processMessage(message);
    } catch (error, stackTrace) {
      debugPrint('Failed to process background SMS: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _onNewMessage(SmsMessage message) {
    // Handle SMS in foreground
    unawaited(
      _processMessage(message),
    );
  }

  static Future<bool> _processMessage(SmsMessage message) async {
    try {
      final listeningEnabled =
          await CaptureSettingsService.isSmsListeningEnabled();
      if (!listeningEnabled) {
        return false;
      }

      final address = message.address ?? '';
      final body = message.body ?? '';
      final timestamp = message.date != null
          ? DateTime.fromMillisecondsSinceEpoch(message.date!)
          : DateTime.now();

      // Parse the SMS
      final enabledProviders =
          await ProviderSettingsService.getEnabledProviders();
      if (enabledProviders.isEmpty) {
        return false;
      }

      final Transaction? transaction = await BaseSmsProvider.parse(
        address,
        body,
        timestamp,
        enabledProviders: enabledProviders,
      );

      // Save to database if it's a valid transaction
      if (transaction != null) {
        final typeEnabled =
            await CaptureSettingsService.isTransactionTypeEnabled(
          transaction.type,
        );
        if (!typeEnabled) {
          return false;
        }

        final isEnabled = await ProviderSettingsService.isProviderEnabled(
          transaction.provider,
        );
        if (!isEnabled) {
          return false;
        }

        try {
          await DatabaseService.instance.insertTransaction(transaction);
        } catch (error, stackTrace) {
          debugPrint('Failed to persist transaction from SMS: $error');
          debugPrintStack(stackTrace: stackTrace);
          return false;
        }

        try {
          await WebhookService.processNewTransaction(transaction);
        } catch (error, stackTrace) {
          debugPrint(
            'Failed to process webhook for SMS transaction: $error',
          );
          debugPrintStack(stackTrace: stackTrace);
        }

        return true;
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to process SMS message: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    return false;
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

    var importedAny = false;
    for (final message in messages) {
      try {
        final imported = await _processMessage(message);
        importedAny ||= imported;
      } catch (error, stackTrace) {
        debugPrint('Failed to import historical SMS: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    if (syncImported) {
      if (!importedAny) {
        debugPrint(
          'Forced webhook sync requested after SMS import with no new transactions.',
        );
      }
      try {
        await WebhookService.syncTransactionsForce();
      } catch (_) {
        // ignore; scheduling/retry will be handled by WebhookService if needed
      }
    }
  }

  Future<List<SmsMessage>> getAllMessages() async {
    return await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
    );
  }
}
