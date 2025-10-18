import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hisabbox/controllers/transaction_controller.dart';
import 'package:hisabbox/services/sms_service.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isImporting = false;
  DateTime? _startDate;
  DateTime? _endDate;
  final TransactionController _transactionController =
      Get.find<TransactionController>();

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _importSms() async {
    setState(() {
      _isImporting = true;
    });

    try {
      await SmsService.instance.importHistoricalSms(
        startDate: _startDate,
        endDate: _endDate,
      );

      await _transactionController.loadTransactions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS import completed successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import SMS')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import Historical SMS',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Import SMS messages from your inbox to extract transaction data',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ListTile(
                      title: const Text('Start Date'),
                      subtitle: Text(
                        _startDate != null
                            ? _startDate!.toString().split(' ')[0]
                            : 'Not selected',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _selectStartDate,
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('End Date'),
                      subtitle: Text(
                        _endDate != null
                            ? _endDate!.toString().split(' ')[0]
                            : 'Not selected',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _selectEndDate,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isImporting ? null : _importSms,
                      icon: _isImporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download),
                      label: Text(_isImporting ? 'Importing...' : 'Import SMS'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This will scan your SMS inbox for financial transactions from bKash, Nagad, Rocket, and banks.',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
