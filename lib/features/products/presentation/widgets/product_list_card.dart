import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/util/warranty_progress_color.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../category/presentation/widgets/category_ui.dart';
import '../../../../core/util/localized_number.dart';
import '../../domain/entities/product_entity.dart';

/// A product in the Products list: its photo on the side, the name, brand
/// and category, the status, how long the warranty has left and a slim bar
/// of it.
class ProductListCard extends StatelessWidget {
  const ProductListCard({super.key, required this.product, this.onTap});

  final ProductEntity product;
  final VoidCallback? onTap;

  /// Share of the warranty still left, 0 once it has ended.
  static double _remaining(ProductEntity product) {
    final total = product.warrantyEndDate
        .difference(product.purchaseDate)
        .inDays;
    if (total <= 0 || product.isExpired) return 0;
    return (product.daysRemaining / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final status = WarrantyStatusColors.of(context, product.status);
    final categoryColor = CategoryUi.color(product.category);
    final remaining = _remaining(product);
    final imageUrl = product.imageUrl ?? product.receiptUrl;
    final placeholder = ColoredBox(
      color: categoryColor.withValues(alpha: 0.12),
      child: Center(
        child: Icon(
          CategoryUi.icon(product.category),
          color: categoryColor,
          size: 30,
        ),
      ),
    );
    final subtitle = [
      if (product.brand != null && product.brand!.trim().isNotEmpty)
        product.brand!,
      CategoryUi.label(context, product.category),
    ].join(' · ');

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox.square(
              dimension: 68,
              child: imageUrl == null
                  ? placeholder
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => placeholder,
                    ),
            ),
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
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(status: product.status),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: product.isExpired ? 1 : remaining,
                          minHeight: 6,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(
                            warrantyStatusColor(context, product.status),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      flex: 2,
                      child: Text(
                        product.isExpired
                            ? l10n.warrantyExpired
                            : l10n.daysLeft(
                                product.daysRemaining,
                                formatLocalizedInt(
                                  Localizations.localeOf(context),
                                  product.daysRemaining,
                                ),
                              ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelMedium?.copyWith(
                          color: status.foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            AppIcons.chevronForward,
            size: 20,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}
