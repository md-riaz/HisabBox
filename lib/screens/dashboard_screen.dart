import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hisabbox/controllers/transaction_controller.dart';
import 'package:hisabbox/controllers/settings_controller.dart';
import 'package:hisabbox/screens/settings_screen.dart';
import 'package:hisabbox/screens/import_screen.dart';
import 'package:hisabbox/widgets/transaction_card.dart';
import 'package:hisabbox/widgets/provider_filter.dart';
import 'package:hisabbox/widgets/summary_card.dart';
import 'package:hisabbox/widgets/transaction_type_filter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final TransactionController _transactionController;
  late final SettingsController _settingsController;

  @override
  void initState() {
    super.initState();
    _transactionController = Get.find<TransactionController>();
    _settingsController = Get.find<SettingsController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      _transactionController.loadTransactions(),
      _settingsController.loadSettings(),
    ]);
  }

  Future<void> _syncWithWebhook() async {
    await _transactionController.syncWithWebhook();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Synced with webhook successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HisabBox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncWithWebhook,
            tooltip: 'Sync with webhook',
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ImportScreen()),
              );
            },
            tooltip: 'Import SMS',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Obx(() {
          if (_transactionController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = _transactionController.transactions;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SummaryCard(
                        totalSent: _transactionController.totalSent,
                        totalReceived: _transactionController.totalReceived,
                        balance: _transactionController.balance,
                      ),
                      const SizedBox(height: 16),
                      const ProviderFilter(),
                      const SizedBox(height: 16),
                      const TransactionTypeFilter(),
                      const SizedBox(height: 16),
                      Text(
                        'Recent Transactions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),
              if (transactions.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No transactions found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final transaction = transactions[index];
                      return TransactionCard(transaction: transaction);
                    }, childCount: transactions.length),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}
