import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hisabbox/controllers/transaction_controller.dart';
import 'package:hisabbox/widgets/provider_filter.dart';
import 'package:hisabbox/widgets/transaction_card.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  late final TransactionController _transactionController;
  final RxInt _totalRecords = 0.obs;

  @override
  void initState() {
    super.initState();
    _transactionController = Get.find<TransactionController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transactionController.loadTransactions(limit: null, updateLimit: true);
      _loadTotalRecords();
    });
  }

  Future<void> _loadTotalRecords() async {
    final count = await _transactionController.getTransactionCount();
    _totalRecords.value = count;
  }

  Future<void> _refresh() async {
    await _transactionController.loadTransactions();
    await _loadTotalRecords();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All transactions'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Obx(() {
          final transactions = _transactionController.transactions.toList();
          final isLoading = _transactionController.isLoading.value;

          if (isLoading && transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Browse every transaction',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Filter by provider to quickly find specific SMS history and tap a card to inspect details.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const ProviderFilter(compact: true),
                      const SizedBox(height: 16),
                      // Analytics Section
                      Obx(() => Card(
                            elevation: 0,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Analytics',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: _AnalyticItem(
                                          label: 'Total Stored',
                                          value: '${_totalRecords.value}',
                                          icon: Icons.storage,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      Expanded(
                                        child: _AnalyticItem(
                                          label: 'Showing',
                                          value: '${transactions.length}',
                                          icon: Icons.visibility,
                                          color: theme.colorScheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: _AnalyticItem(
                                          label: 'Total Received',
                                          value:
                                              '৳${_transactionController.totalReceived.toStringAsFixed(2)}',
                                          icon: Icons.arrow_downward,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Expanded(
                                        child: _AnalyticItem(
                                          label: 'Total Sent',
                                          value:
                                              '৳${_transactionController.totalSent.toStringAsFixed(2)}',
                                          icon: Icons.arrow_upward,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _transactionController.balance >= 0
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.account_balance_wallet,
                                          size: 20,
                                          color:
                                              _transactionController.balance >=
                                                      0
                                                  ? Colors.green
                                                  : Colors.red,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Balance: ৳${_transactionController.balance.toStringAsFixed(2)}',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: _transactionController
                                                        .balance >=
                                                    0
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (transactions.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions found',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final transaction = transactions[index];
                        return TransactionCard(transaction: transaction);
                      },
                      childCount: transactions.length,
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _AnalyticItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _AnalyticItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
