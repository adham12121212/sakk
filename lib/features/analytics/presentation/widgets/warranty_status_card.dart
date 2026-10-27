import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/util/localized_number.dart';
import '../../../../core/util/warranty_progress_color.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/presentation/cubit/product_state.dart';
import 'legend_row.dart';

/// One bar split into active / expiring / expired warranties, with a
/// legend of counts and shares below.
class WarrantyStatusCard extends StatelessWidget {
  const WarrantyStatusCard({
    super.key,
    required this.state,
    required this.l10n,
  });

  final ProductsState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isInitialLoading = state.isLoading && state.products.isEmpty;
    // Fake but plausible proportions purely so the bar has a shape to
    // skeletonize — never shown as real data.
    final counts = {
      WarrantyStatus.active: isInitialLoading ? 2 : state.active,
      WarrantyStatus.expiring: isInitialLoading ? 1 : state.expiring,
      WarrantyStatus.expired: isInitialLoading ? 1 : state.expired,
    };
    final total = counts.values.fold(0, (a, b) => a + b);
    final labels = {
      WarrantyStatus.active: l10n.active,
      WarrantyStatus.expiring: l10n.expiring,
      WarrantyStatus.expired: l10n.expired,
    };
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);
    String n(int v) => formatLocalizedInt(locale, v);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.warrantyStatus, style: textTheme.titleMedium),
          const SizedBox(height: 16),
          if (total == 0)
            Text(
              l10n.noProductsYet,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            Skeletonizer(
              enabled: isInitialLoading,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Skeleton.leaf(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: SizedBox(
                        height: 12,
                        child: Row(
                          // Full height: an empty ColoredBox is otherwise 0 tall.
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final (i, e)
                                in counts.entries
                                    .where((e) => e.value > 0)
                                    .indexed) ...[
                              // A sliver of surface between segments.
                              if (i > 0) const SizedBox(width: 2),
                              Expanded(
                                flex: e.value,
                                child: ColoredBox(
                                  color: warrantyStatusColor(context, e.key),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final (i, e) in counts.entries.indexed) ...[
                    if (i > 0) const SizedBox(height: 10),
                    LegendRow(
                      color: warrantyStatusColor(context, e.key),
                      label: labels[e.key]!,
                      value:
                          '${n(e.value)}  ·  ${n((e.value / total * 100).round())}%',
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
