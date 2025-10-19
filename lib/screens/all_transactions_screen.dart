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

  @override
  void initState() {
    super.initState();
    _transactionController = Get.find<TransactionController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transactionController.loadTransactions(limit: null, updateLimit: true);
    });
  }

  Future<void> _refresh() async {
    await _transactionController.loadTransactions();
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
                      const ProviderFilter(),
                      const SizedBox(height: 12),
                      Text(
                        'Showing ${transactions.length} entr${transactions.length == 1 ? 'y' : 'ies'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
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
