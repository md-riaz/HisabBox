import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hisabbox/controllers/settings_controller.dart';
import 'package:hisabbox/controllers/transaction_controller.dart';
import 'package:hisabbox/models/provider_extensions.dart';
import 'package:hisabbox/models/transaction_type_extensions.dart';
import 'package:hisabbox/services/sender_id_settings_service.dart';
import 'package:hisabbox/widgets/sender_id_config_modal.dart';

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

  void _showWebhookInfoDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final textTheme = Theme.of(dialogContext).textTheme;
        const payloadFields = [
          'id — Stable unique identifier for the transaction',
          'provider — Source of the SMS (e.g., bkash, nagad)',
          'type — Transaction category (sent, received, cashout, cashin, payment, refund, fee, other)',
          'amount — Transaction amount as a decimal number',
          'recipient — Optional recipient account or phone',
          'sender — Optional sender account or phone',
          'transactionId — Provider reference / TRX ID',
          'transactionHash — SHA-256 hash used for deduping',
          'timestamp — ISO 8601 timestamp of the transaction',
          'note — Optional memo parsed from the SMS',
          'rawMessage — Original SMS body',
          'synced — true after the record has been delivered',
          'createdAt — When HisabBox stored the SMS locally',
        ];
        return AlertDialog(
          title: const Text('Webhook payload guide'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HisabBox sends an HTTP POST request with a JSON body to your webhook URL whenever pending transactions are synced.',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text('Headers', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  '• Content-Type: application/json',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text('Payload fields', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final field in payloadFields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2.0),
                    child: Text('• $field', style: textTheme.bodyMedium),
                  ),
                const SizedBox(height: 12),
                Text('Success criteria', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Your server should reply with an HTTP 2xx status code. Any other response or network error will make HisabBox retry automatically with exponential backoff until delivery succeeds.',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text('Test requests', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'The "Test Webhook" button sends {"test": true, "timestamp": "..."} so you can verify connectivity without storing a transaction.',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showDeveloperInfoDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Developer'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Name: Md. Riaz'),
                SizedBox(height: 8),
                Text('Email: mdriaz.wd@gmail.com'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handlePinLockToggle(bool value) async {
    if (value) {
      final pin = await _showCreatePinDialog();
      if (pin == null) {
        _settingsController.pinLockEnabled.value = false;
        return;
      }
      await _settingsController.enablePinLock(pin);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN lock enabled')),
      );
    } else {
      final disableConfirmed = await _showDisablePinDialog();
      if (!disableConfirmed) {
        _settingsController.pinLockEnabled.value = true;
        return;
      }
      await _settingsController.disablePinLock();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN lock disabled')),
      );
    }
  }

  Future<void> _changePin() async {
    final newPin = await _showChangePinDialog();
    if (newPin == null) {
      return;
    }
    await _settingsController.enablePinLock(newPin);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN updated successfully')),
    );
  }

  Future<String?> _showCreatePinDialog() {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final newPinController = TextEditingController();
        final confirmController = TextEditingController();
        String? error;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Enable PIN lock'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter a 4-6 digit PIN to secure HisabBox.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPinController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    obscureText: true,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'New PIN',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    obscureText: true,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Confirm PIN',
                      counterText: '',
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final newPin = newPinController.text.trim();
                    final confirmPin = confirmController.text.trim();
                    if (newPin.length < 4) {
                      setState(() {
                        error = 'PIN must be at least 4 digits';
                      });
                      return;
                    }
                    if (newPin != confirmPin) {
                      setState(() {
                        error = 'PIN codes do not match';
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(newPin);
                  },
                  child: const Text('Save PIN'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _showChangePinDialog() {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final currentPinController = TextEditingController();
        final newPinController = TextEditingController();
        final confirmController = TextEditingController();
        String? error;
        var isProcessing = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change PIN'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPinController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    obscureText: true,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Current PIN',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPinController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    obscureText: true,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'New PIN',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    obscureText: true,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Confirm PIN',
                      counterText: '',
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          final currentPin = currentPinController.text.trim();
                          final newPin = newPinController.text.trim();
                          final confirmPin = confirmController.text.trim();
                          final navigator = Navigator.of(dialogContext);

                          if (currentPin.length < 4) {
                            setState(() {
                              error = 'Current PIN is too short';
                            });
                            return;
                          }
                          if (newPin.length < 4) {
                            setState(() {
                              error = 'New PIN must be at least 4 digits';
                            });
                            return;
                          }
                          if (newPin != confirmPin) {
                            setState(() {
                              error = 'New PIN entries do not match';
                            });
                            return;
                          }

                          setState(() {
                            isProcessing = true;
                            error = null;
                          });

                          final isValid =
                              await _settingsController.verifyPin(currentPin);
                          if (!navigator.mounted) {
                            return;
                          }

                          if (!isValid) {
                            setState(() {
                              isProcessing = false;
                              error = 'Current PIN is incorrect';
                            });
                            return;
                          }

                          navigator.pop(newPin);
                        },
                  child: isProcessing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update PIN'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _showDisablePinDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final pinController = TextEditingController();
        String? error;
        var isProcessing = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Disable PIN lock'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter your current PIN to disable the lock.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    obscureText: true,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Current PIN',
                      counterText: '',
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          final pin = pinController.text.trim();
                          final navigator = Navigator.of(dialogContext);
                          if (pin.length < 4) {
                            setState(() {
                              error = 'PIN must be at least 4 digits';
                            });
                            return;
                          }
                          setState(() {
                            isProcessing = true;
                            error = null;
                          });
                          final isValid =
                              await _settingsController.verifyPin(pin);
                          if (!navigator.mounted) {
                            return;
                          }
                          if (!isValid) {
                            setState(() {
                              isProcessing = false;
                              error = 'Incorrect PIN';
                            });
                            return;
                          }
                          navigator.pop(true);
                        },
                  child: isProcessing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Disable'),
                ),
              ],
            );
          },
        );
      },
    );
    return result ?? false;
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
        final pinLockEnabled = _settingsController.pinLockEnabled.value;
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
                        await _settingsController.setSmsListeningEnabled(value);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
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
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'At least one transaction type must remain enabled.',
                                  ),
                                ),
                              );
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
                      'Security',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('PIN lock'),
                      subtitle: Text(
                        pinLockEnabled
                            ? 'Enabled — the app requires your PIN on launch'
                            : 'Disabled — anyone with access to your phone can open HisabBox',
                      ),
                      value: pinLockEnabled,
                      onChanged: (value) {
                        _handlePinLockToggle(value);
                      },
                    ),
                    if (pinLockEnabled) ...[
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.edit),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Change PIN'),
                        subtitle: const Text('Update the code that unlocks HisabBox'),
                        onTap: _changePin,
                      ),
                      ListTile(
                        leading: const Icon(Icons.lock_open),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Disable PIN lock'),
                        subtitle:
                            const Text('Remove the PIN requirement for launching the app'),
                        onTap: () async {
                          await _handlePinLockToggle(false);
                        },
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Provider Control',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings),
                          tooltip: 'Configure sender IDs',
                          onPressed: () {
                            showDialog<void>(
                              context: context,
                              builder: (context) => const SenderIdConfigModal(),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select which providers should be captured. Disabled providers will be ignored during live listening and history imports.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    for (final providerType
                        in SenderIdSettingsService.supportedProviders)
                      SwitchListTile(
                        title: Text(providerType.displayName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              providerSettings[providerType] ?? false
                                  ? 'Enabled — transactions will be recorded'
                                  : 'Disabled — SMS will be ignored',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              providerType.matchingDescription,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        secondary: Icon(
                          providerType.glyph,
                          color: providerType.accentColor,
                        ),
                        value: providerSettings[providerType] ?? false,
                        onChanged: (value) async {
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          await _settingsController.setProviderEnabled(
                            providerType,
                            value,
                          );

                          // Update active providers in transaction controller
                          final enabledProviders =
                              _settingsController.enabledProviders;
                          await _transactionController
                              .setActiveProviders(enabledProviders);

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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Webhook Configuration',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Webhook payload details',
                          icon: const Icon(Icons.info_outline),
                          onPressed: _showWebhookInfoDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Enable Webhook'),
                      subtitle: const Text(
                        'Automatically send new transactions to your webhook URL',
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'About',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Developer info',
                          icon: const Icon(Icons.info_outline),
                          onPressed: _showDeveloperInfoDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const ListTile(
                      title: Text('Version'),
                      subtitle: Text('1.0.1'),
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
