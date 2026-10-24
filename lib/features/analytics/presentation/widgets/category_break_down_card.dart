import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/util/localized_number.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../category/domain/entities/product_category.dart';
import '../../../category/presentation/widgets/category_ui.dart';
import '../../../products/domain/entities/product_entity.dart';

/// Categories ranked by product count, as rows in one card: tinted icon,
/// name, count, percentage and a slim bar in the category colour.
class CategoryBreakdownCard extends StatelessWidget {
  const CategoryBreakdownCard({
    super.key,
    required this.products,
    required this.isLoading,
    required this.l10n,
  });

  final List<ProductEntity> products;
  final bool isLoading;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isInitialLoading = isLoading && products.isEmpty;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);

    final Map<ProductCategory, int> counts;
    final int total;
    if (isInitialLoading) {
      counts = {ProductCategory.electronics: 2, ProductCategory.furniture: 1};
      total = 3;
    } else {
      counts = <ProductCategory, int>{};
      for (final product in products) {
        counts[product.category] = (counts[product.category] ?? 0) + 1;
      }
      total = products.length;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 2, bottom: 8),
          child: Text(l10n.categoryBreakdown, style: textTheme.titleMedium),
        ),
        if (!isInitialLoading && total == 0)
          AppCard(
            child: Text(
              l10n.noProductsYet,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Skeletonizer(
            enabled: isInitialLoading,
            // One row per category, a hairline between them.
            child: GroupedCard(
              children: [
                for (final entry in entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: _CategoryRow(
                      category: entry.key,
                      count: formatLocalizedInt(locale, entry.value),
                      share: entry.value / total,
                      percent:
                          '${formatLocalizedInt(locale, (entry.value / total * 100).round())}%',
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.count,
    required this.share,
    required this.percent,
  });

  final ProductCategory category;
  final String count;
  final double share;
  final String percent;

  @override
  Widget build(BuildContext context) {
    final color = CategoryUi.color(category);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(CategoryUi.icon(category), color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      CategoryUi.label(context, category),
                      style: textTheme.titleSmall,
                    ),
                  ),
                  Text(count, style: textTheme.titleSmall),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    child: Text(
                      percent,
                      textAlign: TextAlign.end,
                      style: textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: share,
                  minHeight: 6,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
