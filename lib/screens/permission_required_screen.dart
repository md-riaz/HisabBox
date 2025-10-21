import 'package:flutter/material.dart';
import 'package:hisabbox/services/permission_service.dart';

class PermissionRequiredScreen extends StatefulWidget {
  const PermissionRequiredScreen({
    super.key,
    required this.onPermissionsGranted,
  });

  final Future<void> Function() onPermissionsGranted;

  @override
  State<PermissionRequiredScreen> createState() =>
      _PermissionRequiredScreenState();
}

class _PermissionRequiredScreenState extends State<PermissionRequiredScreen>
    with WidgetsBindingObserver {
  bool _isHandlingGranted = false;
  bool _isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final granted = await PermissionService.checkPermissions();
    if (granted) {
      await _handlePermissionsGranted();
    }
  }

  Future<void> _handlePermissionsGranted() async {
    if (_isHandlingGranted) {
      return;
    }

    _isHandlingGranted = true;
    await widget.onPermissionsGranted();
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isRequestingPermission = true;
    });

    try {
      final granted = await PermissionService.requestPermissions();
      if (granted) {
        await _handlePermissionsGranted();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permissions denied. Please grant permissions manually from settings.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingPermission = false;
        });
      }
    }
  }

  Future<void> _openSettings() async {
    await PermissionService.openSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Permissions Required')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(
                Icons.sms_failed_outlined,
                size: 72,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Permissions Required',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Required Permissions Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Required Permissions:',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _PermissionItem(
                      icon: Icons.sms,
                      title: 'SMS Access',
                      description:
                          'To read and monitor transaction messages from banks and mobile financial services.',
                    ),
                    const SizedBox(height: 12),
                    const _PermissionItem(
                      icon: Icons.notifications,
                      title: 'Notifications',
                      description:
                          'To notify you about new transactions detected in the background.',
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Note: Android may also ask for Location permission. This is an Android OS requirement for SMS access, but HisabBox does not collect or use location data.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Try requesting permissions
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isRequestingPermission ? null : _requestPermissions,
                icon: _isRequestingPermission
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(
                  _isRequestingPermission
                      ? 'Requesting...'
                      : 'Grant Permissions',
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Divider(),
            const SizedBox(height: 16),

            // Manual instructions
            Text(
              'If automatic request doesn\'t work:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Android may block automated SMS permission prompts for security. Follow these steps to grant permissions manually — after opening App Settings you may need to force stop HisabBox before the three-dot menu appears:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InstructionStep(
                  number: '1',
                  text: 'Tap "Open App Settings" below',
                ),
                _InstructionStep(
                  number: '2',
                  text:
                      'Force stop (force close) HisabBox on the App Info screen — this makes the three-dot menu appear',
                ),
                _InstructionStep(
                  number: '3',
                  text:
                      'Tap the three dots (⋮) in the top-right corner once they appear',
                ),
                _InstructionStep(
                  number: '4',
                  text: 'Select "Allow restricted settings"',
                ),
                _InstructionStep(number: '5', text: 'Go to Permissions → SMS'),
                _InstructionStep(
                  number: '6',
                  text: 'Change permission to "Allow"',
                ),
                _InstructionStep(
                  number: '7',
                  text: 'Also enable Notifications permission',
                ),
                _InstructionStep(number: '8', text: 'Return to HisabBox'),
              ],
            ),
            const SizedBox(height: 24),

            // Visual Guide
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.image, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Visual Guide',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Here\'s what "Allow restricted settings" looks like:',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/android_allow_restricted_setting.jpg',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: theme.colorScheme.secondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Visual guide image not available',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Open Settings Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Open App Settings'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(text, style: theme.textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(description, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
