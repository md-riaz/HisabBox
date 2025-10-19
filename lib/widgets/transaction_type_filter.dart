import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hisabbox/controllers/transaction_controller.dart';
import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/models/transaction_type_extensions.dart';

class TransactionTypeFilter extends StatelessWidget {
  const TransactionTypeFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TransactionController>();
    return Obx(() {
      final activeTypes = controller.selectedTransactionTypes.toList();
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter by Transaction Type',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TransactionType.values.map((typeValue) {
                  final isActive = activeTypes.contains(typeValue);
                  return FilterChip(
                    label: Text(typeValue.displayName),
                    selected: isActive,
                    onSelected: (selected) {
                      final updatedTypes = List<TransactionType>.from(
                        activeTypes,
                      );
                      if (selected) {
                        if (!updatedTypes.contains(typeValue)) {
                          updatedTypes.add(typeValue);
                        }
                      } else {
                        updatedTypes.remove(typeValue);
                      }
                      controller.setSelectedTransactionTypes(updatedTypes);
                    },
                    selectedColor: typeValue.accentColor.withOpacity(0.3),
                    checkmarkColor: typeValue.accentColor,
                    avatar: isActive
                        ? null
                        : Icon(
                            typeValue.glyph,
                            size: 18,
                            color: typeValue.accentColor,
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
