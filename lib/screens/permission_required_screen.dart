import 'package:flutter/material.dart';
import 'package:hisabbox/services/permission_service.dart';

class PermissionRequiredScreen extends StatefulWidget {
  const PermissionRequiredScreen({super.key, required this.onPermissionsGranted});

  final Future<void> Function() onPermissionsGranted;

  @override
  State<PermissionRequiredScreen> createState() => _PermissionRequiredScreenState();
}

class _PermissionRequiredScreenState extends State<PermissionRequiredScreen>
    with WidgetsBindingObserver {
  bool _isHandlingGranted = false;

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

  Future<void> _openSettings() async {
    await PermissionService.openSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions Required'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.sms_failed_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'SMS access needed',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'HisabBox requires SMS and notification permissions to automatically read and process your transaction messages. Because Android blocks automated permission prompts for SMS access, you need to enable it manually from system settings.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Follow these steps to continue:',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _InstructionStep(text: 'Open the app settings using the button below.'),
                _InstructionStep(
                  text: 'Tap the three dots in the top-right corner and choose "Allow restricted settings".',
                ),
                _InstructionStep(text: 'Select Permissions → SMS and change it to "Allow".'),
                _InstructionStep(text: 'Return to HisabBox to continue.'),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _openSettings,
                    child: const Text('Open app settings'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
