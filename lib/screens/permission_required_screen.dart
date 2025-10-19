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
  bool _isRequesting = false;
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

  Future<void> _requestPermissions() async {
    setState(() {
      _isRequesting = true;
    });

    final granted = await PermissionService.requestPermissions();

    if (!mounted) {
      return;
    }

    setState(() {
      _isRequesting = false;
    });

    if (granted) {
      await _handlePermissionsGranted();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SMS and notification permissions are required to continue.'),
        ),
      );
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
              'HisabBox requires SMS and notification permissions to automatically read and process your transaction messages. Without these permissions, the app cannot keep your records up to date.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRequesting ? null : _requestPermissions,
                    child: _isRequesting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Retry permission request'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
