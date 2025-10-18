import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/providers/transaction_provider.dart';

class ProviderFilter extends StatelessWidget {
  const ProviderFilter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Provider',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Provider.values.map((providerValue) {
                    final isActive = provider.activeProviders.contains(providerValue);
                    return FilterChip(
                      label: Text(_getProviderName(providerValue)),
                      selected: isActive,
                      onSelected: (selected) {
                        final activeProviders = List<Provider>.from(provider.activeProviders);
                        if (selected) {
                          activeProviders.add(providerValue);
                        } else {
                          activeProviders.remove(providerValue);
                        }
                        if (activeProviders.isNotEmpty) {
                          provider.setActiveProviders(activeProviders);
                        }
                      },
                      selectedColor: _getProviderColor(providerValue).withOpacity(0.3),
                      checkmarkColor: _getProviderColor(providerValue),
                      avatar: isActive ? null : Icon(
                        _getProviderIcon(providerValue),
                        size: 18,
                        color: _getProviderColor(providerValue),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getProviderName(Provider provider) {
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

  Color _getProviderColor(Provider provider) {
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

  IconData _getProviderIcon(Provider provider) {
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
}
