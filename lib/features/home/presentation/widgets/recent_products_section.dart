import 'package:flutter/material.dart';
import 'package:sakk/features/home/presentation/widgets/recent_product_data.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/app_localizations.dart';

class RecentProductsSection extends StatelessWidget {
  const RecentProductsSection({
    super.key,
    required this.items,
    this.onSeeAllTap,
    this.onItemTap,
  });

  final List<RecentProductData> items;
  final VoidCallback? onSeeAllTap;
  final ValueChanged<int>? onItemTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.recentProducts,
            actionLabel: items.isEmpty ? null : l10n.seeAll,
            onAction: onSeeAllTap,
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const _EmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => RecentProductTile(
                data: items[index],
                onTap: onItemTap == null ? null : () => onItemTap!(index),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 26,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.noProductsYet,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
