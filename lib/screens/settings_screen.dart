import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hisabbox/providers/settings_provider.dart';

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
}
