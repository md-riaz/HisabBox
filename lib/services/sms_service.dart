import 'dart:async';

import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';
import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/capture_settings_service.dart';
import 'package:hisabbox/services/database_service.dart';
import 'package:hisabbox/services/provider_settings_service.dart';
import 'package:hisabbox/services/providers/base_sms_provider.dart';
import 'package:hisabbox/services/sender_id_settings_service.dart';
import 'package:hisabbox/services/sms_preferences_cache.dart';
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
      final snapshot = await _PreferencesSnapshot.load();
      if (!snapshot.listeningEnabled) {
        return false;
      }

      final address = message.address ?? '';
      final body = message.body ?? '';
      final timestamp = message.date != null
          ? DateTime.fromMillisecondsSinceEpoch(message.date!)
          : DateTime.now();

      // Parse the SMS
      final enabledProviders = snapshot.enabledProviders;
      if (enabledProviders.isEmpty) {
        return false;
      }

      final Transaction? transaction = await BaseSmsProvider.parse(
        address,
        body,
        timestamp,
        enabledProviders: enabledProviders,
        senderIdMap: snapshot.senderIdMap,
        providerSettings: snapshot.providerSettings,
      );

      // Save to database if it's a valid transaction
      if (transaction != null) {
        final typeEnabled = snapshot.isTransactionTypeEnabled(
          transaction.type,
        );
        if (!typeEnabled) {
          return false;
        }

        final isEnabled = snapshot.isProviderEnabled(
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
        importedAny = importedAny || imported;
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

@immutable
class _PreferencesSnapshot {
  const _PreferencesSnapshot._({
    required this.listeningEnabled,
    required this.providerSettings,
    required this.enabledTransactionTypes,
    required this.senderIdMap,
  });

  factory _PreferencesSnapshot({
    required bool listeningEnabled,
    required Map<Provider, bool> providerSettings,
    required Set<TransactionType> enabledTransactionTypes,
    required Map<Provider, List<String>> senderIdMap,
  }) {
    final normalizedProviderSettings =
        Map<Provider, bool>.unmodifiable(Map<Provider, bool>.from(
      providerSettings,
    ));
    final normalizedEnabledTypes =
        Set<TransactionType>.unmodifiable(Set<TransactionType>.from(
      enabledTransactionTypes,
    ));
    final normalizedSenderIds = Map<Provider, List<String>>.unmodifiable(
      senderIdMap.map(
        (provider, ids) => MapEntry(
          provider,
          List<String>.unmodifiable(List<String>.from(ids)),
        ),
      ),
    );

    return _PreferencesSnapshot._(
      listeningEnabled: listeningEnabled,
      providerSettings: normalizedProviderSettings,
      enabledTransactionTypes: normalizedEnabledTypes,
      senderIdMap: normalizedSenderIds,
    );
  }

  final bool listeningEnabled;
  final Map<Provider, bool> providerSettings;
  final Set<TransactionType> enabledTransactionTypes;
  final Map<Provider, List<String>> senderIdMap;

  static _PreferencesSnapshot? _cached;
  static Future<_PreferencesSnapshot>? _inProgress;
  static int _generation = 0;

  List<Provider> get enabledProviders => Provider.values
      .where((provider) => isProviderEnabled(provider))
      .toList(growable: false);

  bool isProviderEnabled(Provider provider) {
    final stored = providerSettings[provider];
    if (stored != null) {
      return stored;
    }
    return ProviderSettingsService.isDefaultEnabled(provider);
  }

  bool isTransactionTypeEnabled(TransactionType type) {
    if (enabledTransactionTypes.contains(type)) {
      return true;
    }
    if (enabledTransactionTypes.isEmpty) {
      return CaptureSettingsService.defaultEnabledTypes.contains(type);
    }
    return false;
  }

  static Future<_PreferencesSnapshot> load() {
    registerSmsPreferencesInvalidator(_PreferencesSnapshot.invalidate);

    final cached = _cached;
    if (cached != null) {
      return Future<_PreferencesSnapshot>.value(cached);
    }

    final pending = _inProgress;
    if (pending != null) {
      return pending;
    }

    final completer = Completer<_PreferencesSnapshot>();
    _inProgress = completer.future;

    unawaited(() async {
      try {
        final snapshot = await _createLoadFuture();
        completer.complete(snapshot);
      } catch (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      } finally {
        if (identical(_inProgress, completer.future)) {
          _inProgress = null;
        }
      }
    }());

    return completer.future;
  }

  static void invalidate() {
    _generation++;
    _cached = null;
    _inProgress = null;
  }

  static Future<_PreferencesSnapshot> _createLoadFuture() async {
    const retryDelay = Duration(milliseconds: 50);
    const maxInvalidationRetries = 5;
    const maxErrorRetries = 3;

    var invalidationRetries = 0;
    var errorRetries = 0;

    while (true) {
      final loadGeneration = _generation;
      try {
        final snapshot = await _loadInternal();
        if (loadGeneration == _generation) {
          _cached = snapshot;
          return snapshot;
        }

        invalidationRetries++;
        if (invalidationRetries > maxInvalidationRetries) {
          const message =
              'SMS preferences changed too frequently while loading.';
          debugPrint(message);
          throw SmsPreferencesLoadException(message);
        }
      } on SmsPreferencesLoadException {
        rethrow;
      } catch (error, stackTrace) {
        errorRetries++;
        debugPrint(
          'Failed to load SMS preferences snapshot (attempt $errorRetries): $error',
        );
        debugPrintStack(stackTrace: stackTrace);

        if (errorRetries >= maxErrorRetries) {
          throw SmsPreferencesLoadException(
            'Unable to load SMS preferences snapshot after $errorRetries attempts.',
            error,
            stackTrace,
          );
        }
      }

      await Future<void>.delayed(retryDelay);
    }
  }

  static Future<_PreferencesSnapshot> _loadInternal() async {
    try {
      final listeningEnabled =
          await CaptureSettingsService.isSmsListeningEnabled();

      if (!listeningEnabled) {
        return _emptySnapshot();
      }

      final providerSettings = await _loadProviderSettings();
      final enabledTypes = await _loadEnabledTransactionTypes();
      final senderIdMap = await _loadSenderIdMap();

      return _PreferencesSnapshot(
        listeningEnabled: listeningEnabled,
        providerSettings: providerSettings,
        enabledTransactionTypes: enabledTypes,
        senderIdMap: senderIdMap,
      );
    } on SmsPreferencesLoadException {
      rethrow;
    } catch (error, stackTrace) {
      throw SmsPreferencesLoadException(
        'Failed to load SMS preferences snapshot.',
        error,
        stackTrace,
      );
    }
  }

  static final _PreferencesSnapshot _disabledSnapshot = _PreferencesSnapshot(
    listeningEnabled: false,
    providerSettings: const <Provider, bool>{},
    enabledTransactionTypes: const <TransactionType>{},
    senderIdMap: const <Provider, List<String>>{},
  );

  static _PreferencesSnapshot _emptySnapshot() => _disabledSnapshot;

  static Future<Map<Provider, bool>> _loadProviderSettings() async {
    try {
      return await ProviderSettingsService.getProviderSettings();
    } catch (error, stackTrace) {
      throw SmsPreferencesLoadException(
        'Failed to load provider settings.',
        error,
        stackTrace,
      );
    }
  }

  static Future<Set<TransactionType>> _loadEnabledTransactionTypes() async {
    try {
      return await CaptureSettingsService.getEnabledTransactionTypes();
    } catch (error, stackTrace) {
      throw SmsPreferencesLoadException(
        'Failed to load transaction type settings.',
        error,
        stackTrace,
      );
    }
  }

  static Future<Map<Provider, List<String>>> _loadSenderIdMap() async {
    try {
      return await SenderIdSettingsService.getAllSenderIds();
    } catch (error, stackTrace) {
      throw SmsPreferencesLoadException(
        'Failed to load sender IDs.',
        error,
        stackTrace,
      );
    }
  }
}

class SmsPreferencesLoadException implements Exception {
  SmsPreferencesLoadException(this.message, [this.cause, this.stackTrace]);

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    if (cause == null) {
      return message;
    }
    return '$message: $cause';
  }
}
