import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hisabbox/controllers/settings_controller.dart';
import 'package:hisabbox/models/provider_extensions.dart';
import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/sender_id_settings_service.dart';

class SenderIdConfigModal extends StatefulWidget {
  const SenderIdConfigModal({super.key});

  @override
  State<SenderIdConfigModal> createState() => _SenderIdConfigModalState();
}

class _SenderIdConfigModalState extends State<SenderIdConfigModal> {
  late final SettingsController _settingsController;
  late final Worker _senderIdWorker;
  final Map<Provider, TextEditingController> _senderIdControllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _settingsController = Get.find<SettingsController>();
    _senderIdWorker = ever<Map<Provider, List<String>>>(
      _settingsController.senderIdSettings,
      _syncSenderIdControllers,
    );
    _syncSenderIdControllers(_settingsController.senderIdSettings);
  }

  @override
  void dispose() {
    _senderIdWorker.dispose();
    for (final controller in _senderIdControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncSenderIdControllers(Map<Provider, List<String>> values) {
    for (final provider in SenderIdSettingsService.supportedProviders) {
      final controller = _senderIdControllers.putIfAbsent(
        provider,
        () => TextEditingController(),
      );
      final text = (values[provider] ?? const <String>[]).join(', ');
      if (controller.text != text) {
        controller.text = text;
      }
    }
  }

  List<String> _extractSenderIds(String raw) {
    return raw
        .split(RegExp(r'[\n,]'))
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _saveAll() async {
    setState(() {
      _isSaving = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    int successCount = 0;
    int failCount = 0;

    try {
      for (final provider in SenderIdSettingsService.supportedProviders) {
        final controller = _senderIdControllers[provider];
        if (controller == null) continue;

        try {
          final parsed = _extractSenderIds(controller.text);
          await _settingsController.setSenderIds(provider, parsed);
          successCount++;
        } catch (error) {
          failCount++;
        }
      }

      if (!mounted) return;

      if (failCount == 0) {
        messenger.showSnackBar(
          const SnackBar(content: Text('All sender IDs saved successfully')),
        );
        Navigator.of(context).pop();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Saved $successCount provider(s), failed $failCount',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _resetSenderIds(Provider provider) async {
    try {
      await _settingsController.resetSenderIds(provider);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final defaults = SenderIdSettingsService.defaultSenderIdsFor(
        provider,
      ).join(', ');
      messenger.showSnackBar(
        SnackBar(content: Text('Restored defaults: $defaults')),
      );
    } catch (error, stackTrace) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reset: $error')),
      );
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'sender_id_config_modal',
          context: ErrorDescription('resetting sender IDs for $provider'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Icon(Icons.settings, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sender ID Configuration',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(24.0),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Important Guidelines',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '• Always use lowercase letters for sender IDs\n'
                                '• Separate multiple IDs with commas or new lines\n'
                                '• Example: 16247, bkash, bkash-alerts',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (int index = 0;
                      index < SenderIdSettingsService.supportedProviders.length;
                      index++)
                    Builder(
                      builder: (context) {
                        final provider =
                            SenderIdSettingsService.supportedProviders[index];
                        final controller = _senderIdControllers.putIfAbsent(
                          provider,
                          () => TextEditingController(),
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: provider.accentColor
                                      .withValues(alpha: 0.12),
                                  child: Icon(
                                    provider.glyph,
                                    size: 18,
                                    color: provider.accentColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  provider.displayName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: controller,
                              minLines: 1,
                              maxLines: 3,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'Sender IDs',
                                helperText:
                                    'Lowercase only: e.g., 16247, bkash',
                                helperStyle: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 12,
                                ),
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: IconButton(
                                    onPressed: _isSaving
                                        ? null
                                        : () => _resetSenderIds(provider),
                                    icon: Icon(
                                      Icons.restart_alt,
                                      size: 20,
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.7),
                                    ),
                                    tooltip: 'Reset to defaults',
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                ),
                              ),
                            ),
                            if (index <
                                SenderIdSettingsService
                                        .supportedProviders.length -
                                    1)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20.0),
                                child: Divider(height: 1),
                              ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveAll,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving…' : 'Save All Changes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
