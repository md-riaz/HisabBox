import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hisabbox/controllers/transaction_controller.dart';
import 'package:hisabbox/models/provider_extensions.dart';
import 'package:hisabbox/models/transaction.dart';

class ProviderFilter extends StatelessWidget {
  const ProviderFilter({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TransactionController>();
    final theme = Theme.of(context);
    return Obx(() {
      final activeProviders = controller.activeProviders.toList();
      return DecoratedBox(
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Filter by provider',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Choose which mobile money providers you want to see in the list below.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: compact ? 8 : 12,
                runSpacing: compact ? 8 : 12,
                children: Provider.values.map((providerValue) {
                  final isActive = activeProviders.contains(providerValue);
                  return _ProviderFilterPill(
                    provider: providerValue,
                    isActive: isActive,
                    compact: compact,
                    onTap: () {
                      final updatedProviders =
                          List<Provider>.from(activeProviders);
                      if (isActive) {
                        if (updatedProviders.length == 1) {
                          return;
                        }
                        updatedProviders.remove(providerValue);
                      } else {
                        updatedProviders.add(providerValue);
                      }
                      controller.setActiveProviders(updatedProviders);
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

class _ProviderFilterPill extends StatelessWidget {
  const _ProviderFilterPill({
    required this.provider,
    required this.isActive,
    this.compact = false,
    required this.onTap,
  });

  final Provider provider;
  final bool isActive;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = provider.accentColor;
    final background =
        isActive ? accent.withValues(alpha: 0.12) : theme.colorScheme.surface;
    final borderColor = isActive
        ? accent
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.4);
    final textColor = isActive ? accent : theme.colorScheme.onSurface;

    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 14);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: padding,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: compact ? 12 : 16,
                backgroundColor: accent.withValues(alpha: 0.12),
                child: Icon(
                  provider.glyph,
                  size: compact ? 14 : 18,
                  color: accent,
                ),
              ),
              SizedBox(width: compact ? 8 : 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    provider.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      fontSize: compact ? 12 : null,
                    ),
                  ),
                  if (!compact) const SizedBox(height: 4),
                  if (!compact)
                    Text(
                      isActive ? 'Visible in feed' : 'Hidden from feed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
              SizedBox(width: compact ? 6 : 12),
              AnimatedOpacity(
                opacity: isActive ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.check_circle,
                  color: accent,
                  size: compact ? 16 : 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
