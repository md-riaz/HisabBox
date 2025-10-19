import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hisabbox/controllers/settings_controller.dart';
import 'package:hisabbox/controllers/transaction_controller.dart';
import 'package:hisabbox/models/provider_extensions.dart';
import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/models/transaction_type_extensions.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _webhookUrlController = TextEditingController();
  bool _isTesting = false;
  late final SettingsController _settingsController;
  late final TransactionController _transactionController;
  late final Worker _webhookUrlWorker;

  @override
  void initState() {
    super.initState();
    _settingsController = Get.find<SettingsController>();
    _transactionController = Get.find<TransactionController>();
    _webhookUrlController.text = _settingsController.webhookUrl.value;
    _webhookUrlWorker = ever<String>(_settingsController.webhookUrl, (value) {
      if (_webhookUrlController.text != value) {
        _webhookUrlController.text = value;
      }
    });
  }

  @override
  void dispose() {
    _webhookUrlController.dispose();
    _webhookUrlWorker.dispose();
    super.dispose();
  }

  Future<void> _testWebhook() async {
    setState(() {
      _isTesting = true;
    });

    await _settingsController.setWebhookUrl(_webhookUrlController.text);

    final success = await _settingsController.testWebhook();

    setState(() {
      _isTesting = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Webhook test successful!' : 'Webhook test failed',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Obx(() {
        final providerSettings = _settingsController.providerSettings;
        final smsListeningEnabled =
            _settingsController.smsListeningEnabled.value;
        final transactionTypeSettings =
            _settingsController.transactionTypeSettings;
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SMS Capture',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Listen for new SMS'),
                      subtitle: const Text(
                        'Automatically import supported transaction messages as they arrive.',
                      ),
                      value: smsListeningEnabled,
                      onChanged: (value) async {
                        final messenger = ScaffoldMessenger.of(context);
                        await _settingsController.setSmsListeningEnabled(value);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'SMS listening enabled'
                                  : 'SMS listening paused',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Import transaction types',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose which categories should be recorded when messages are processed.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: transactionTypeSettings.entries.map((entry) {
                        final type = entry.key;
                        final isEnabled = entry.value;
                        return FilterChip(
                          label: Text(type.displayName),
                          selected: isEnabled,
                          avatar: isEnabled
                              ? null
                              : Icon(
                                  type.glyph,
                                  size: 18,
                                  color: type.accentColor,
                                ),
                          selectedColor: type.accentColor.withValues(
                            alpha: 0.25,
                          ),
                          checkmarkColor: type.accentColor,
                          onSelected: (selected) async {
                            final success = await _settingsController
                                .setTransactionTypeEnabled(type, selected);
                            if (!success) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'At least one transaction type must remain enabled.',
                                    ),
                                  ),
                                );
                              }
                              return;
                            }

                            final activeTypes = transactionTypeSettings.entries
                                .where((entry) => entry.value)
                                .map((entry) => entry.key)
                                .toList(growable: false);
                            await _transactionController
                                .setSelectedTransactionTypes(activeTypes);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Provider Control',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select which providers should be captured. Disabled providers will be ignored during live listening and history imports.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ...providerSettings.entries
                        .where((entry) => entry.key != Provider.other)
                        .map((entry) {
                          final providerType = entry.key;
                          final isEnabled = entry.value;
                          return SwitchListTile(
                            title: Text(providerType.displayName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isEnabled
                                      ? 'Enabled — transactions will be recorded'
                                      : 'Disabled — SMS will be ignored',
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  providerType.matchingDescription,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            secondary: Icon(
                              providerType.glyph,
                              color: providerType.accentColor,
                            ),
                            value: isEnabled,
                            onChanged: (value) async {
                              final scaffoldMessenger = ScaffoldMessenger.of(
                                context,
                              );
                              await _settingsController.setProviderEnabled(
                                providerType,
                                value,
                              );

                              await _transactionController.loadTransactions();

                              if (!mounted) return;

                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    value
                                        ? '${providerType.displayName} enabled'
                                        : '${providerType.displayName} disabled',
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Webhook Configuration',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Enable Webhook'),
                      subtitle: const Text(
                        'Automatically sync transactions to webhook',
                      ),
                      value: _settingsController.webhookEnabled.value,
                      onChanged: (value) {
                        _settingsController.setWebhookEnabled(value);
                      },
                    ),
                    if (_settingsController.webhookEnabled.value) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _webhookUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Webhook URL',
                          hintText: 'https://example.com/webhook',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _settingsController.setWebhookUrl(value);
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isTesting ? null : _testWebhook,
                        icon: _isTesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle),
                        label: Text(_isTesting ? 'Testing...' : 'Test Webhook'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sync Settings',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Auto Sync'),
                      subtitle: const Text(
                        'Automatically sync new transactions',
                      ),
                      value: _settingsController.autoSync.value,
                      onChanged: (value) {
                        _settingsController.setAutoSync(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    const ListTile(
                      title: Text('Version'),
                      subtitle: Text('1.0.0'),
                    ),
                    const ListTile(
                      title: Text('Description'),
                      subtitle: Text(
                        'HisabBox is an offline-first SMS parser that tracks bKash, Nagad, Rocket, and bank messages',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
