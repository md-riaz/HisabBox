import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hisabbox/controllers/settings_controller.dart';
import 'package:hisabbox/controllers/transaction_controller.dart';
import 'package:hisabbox/screens/all_transactions_screen.dart';
import 'package:hisabbox/screens/import_screen.dart';
import 'package:hisabbox/screens/settings_screen.dart';
import 'package:hisabbox/widgets/provider_filter.dart';
import 'package:hisabbox/widgets/summary_card.dart';
import 'package:hisabbox/widgets/transaction_card.dart';

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
      _transactionController.loadTransactions(limit: 30, updateLimit: true),
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
          final transactions = _transactionController.transactions.toList();
          final isLoading = _transactionController.isLoading.value;

          if (isLoading && transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final previewTransactions = transactions.length > 5
              ? transactions.take(5).toList()
              : transactions;

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
                      const ProviderFilter(compact: true),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent transactions',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (transactions.isNotEmpty)
                            TextButton.icon(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AllTransactionsScreen(),
                                  ),
                                );
                                if (!mounted) return;
                                await _transactionController.loadTransactions(
                                  limit: 30,
                                  updateLimit: true,
                                );
                              },
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: const Text('View all'),
                            ),
                        ],
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
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final transaction = previewTransactions[index];
                        return TransactionCard(transaction: transaction);
                      },
                      childCount: previewTransactions.length,
                    ),
                  ),
                ),
              if (transactions.length > previewTransactions.length)
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),
            ],
          );
        }),
      ),
    );
  }
}
