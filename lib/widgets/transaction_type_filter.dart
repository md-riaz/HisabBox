import 'dart:async';

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
      final activeTypes = controller.activeTransactionTypes.toList();
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
                children: TransactionType.values.map((type) {
                  final isActive = activeTypes.contains(type);
                  return FilterChip(
                    label: Text(type.displayName),
                    avatar: isActive ? null : Icon(type.icon, size: 18),
                    selected: isActive,
                    onSelected: (selected) {
                      final updatedTypes = List<TransactionType>.from(
                        activeTypes,
                      );
                      if (selected) {
                        if (!updatedTypes.contains(type)) {
                          updatedTypes.add(type);
                        }
                      } else {
                        updatedTypes.remove(type);
                      }
                      if (updatedTypes.isNotEmpty) {
                        unawaited(
                          controller.setActiveTransactionTypes(updatedTypes),
                        );
                      }
                    },
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
