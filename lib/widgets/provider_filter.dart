import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hisabbox/controllers/transaction_controller.dart';
import 'package:hisabbox/models/provider_extensions.dart';
import 'package:hisabbox/models/transaction.dart';

class ProviderFilter extends StatelessWidget {
  const ProviderFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TransactionController>();
    return Obx(() {
      final activeProviders = controller.activeProviders.toList();
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
                  final isActive = activeProviders.contains(providerValue);
                  return FilterChip(
                    label: Text(providerValue.displayName),
                    selected: isActive,
                    onSelected: (selected) {
                      final updatedProviders = List<Provider>.from(
                        activeProviders,
                      );
                      if (selected) {
                        if (!updatedProviders.contains(providerValue)) {
                          updatedProviders.add(providerValue);
                        }
                      } else {
                        updatedProviders.remove(providerValue);
                      }
                      if (updatedProviders.isNotEmpty) {
                        controller.setActiveProviders(updatedProviders);
                      }
                    },
                    selectedColor:
                        providerValue.accentColor.withValues(alpha: 0.3),
                    checkmarkColor: providerValue.accentColor,
                    avatar: isActive
                        ? null
                        : Icon(
                            providerValue.glyph,
                            size: 18,
                            color: providerValue.accentColor,
                          ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    });
  }
}
