import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hisabbox/providers/settings_provider.dart';
import 'package:hisabbox/providers/transaction_provider.dart';
import 'package:hisabbox/models/transaction.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _webhookUrlController = TextEditingController();
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      _webhookUrlController.text = settingsProvider.webhookUrl;
    });
  }

  @override
  void dispose() {
    _webhookUrlController.dispose();
    super.dispose();
  }

  Future<void> _testWebhook() async {
    setState(() {
      _isTesting = true;
    });

    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    await settingsProvider.setWebhookUrl(_webhookUrlController.text);
    
    final success = await settingsProvider.testWebhook();

    setState(() {
      _isTesting = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Webhook test successful!' : 'Webhook test failed'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
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
                        'Provider Control',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select which providers should be captured. Disabled providers will be ignored during live listening and history imports.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ...provider.providerSettings.entries
                          .where((entry) => entry.key != Provider.other)
                          .map(
                        (entry) {
                          final providerType = entry.key;
                          final isEnabled = entry.value;
                          return SwitchListTile(
                            title: Text(_providerName(providerType)),
                            subtitle: Text(
                              isEnabled
                                  ? 'Enabled — transactions will be recorded'
                                  : 'Disabled — SMS will be ignored',
                            ),
                            secondary: Icon(
                              _providerIcon(providerType),
                              color: _providerColor(providerType),
                            ),
                            value: isEnabled,
                            onChanged: (value) async {
                              await provider.setProviderEnabled(
                                  providerType, value);

                              if (!mounted) return;

                              // Refresh dashboard filters so the change is
                              // reflected immediately.
                              final transactionProvider =
                                  Provider.of<TransactionProvider>(context,
                                      listen: false);
                              await transactionProvider.loadTransactions();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    value
                                        ? '${_providerName(providerType)} enabled'
                                        : '${_providerName(providerType)} disabled',
                                  ),
                                ),
                              );
                            },
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
                      Text(
                        'Webhook Configuration',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Enable Webhook'),
                        subtitle: const Text('Automatically sync transactions to webhook'),
                        value: provider.webhookEnabled,
                        onChanged: (value) {
                          provider.setWebhookEnabled(value);
                        },
                      ),
                      if (provider.webhookEnabled) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _webhookUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Webhook URL',
                            hintText: 'https://example.com/webhook',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            provider.setWebhookUrl(value);
                          },
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isTesting ? null : _testWebhook,
                          icon: _isTesting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
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
                        subtitle: const Text('Automatically sync new transactions'),
                        value: provider.autoSync,
                        onChanged: (value) {
                          provider.setAutoSync(value);
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
        },
      ),
    );
  }

  String _providerName(Provider provider) {
    switch (provider) {
      case Provider.bkash:
        return 'bKash';
      case Provider.nagad:
        return 'Nagad';
      case Provider.rocket:
        return 'Rocket';
      case Provider.bank:
        return 'Bank';
      default:
        return 'Other';
    }
  }

  IconData _providerIcon(Provider provider) {
    switch (provider) {
      case Provider.bkash:
        return Icons.mobile_friendly;
      case Provider.nagad:
        return Icons.smartphone;
      case Provider.rocket:
        return Icons.rocket_launch;
      case Provider.bank:
        return Icons.account_balance;
      default:
        return Icons.help_outline;
    }
  }

  Color _providerColor(Provider provider) {
    switch (provider) {
      case Provider.bkash:
        return Colors.pink;
      case Provider.nagad:
        return Colors.orange;
      case Provider.rocket:
        return Colors.purple;
      case Provider.bank:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
