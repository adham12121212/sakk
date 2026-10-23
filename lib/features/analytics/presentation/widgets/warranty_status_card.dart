import 'package:flutter/material.dart';
import 'package:sakk/features/analytics/presentation/widgets/segment.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/util/localized_number.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/presentation/cubit/product_state.dart';
import 'donut_chart_painter.dart';
import 'legend_row.dart';

/// Donut of active / expiring / expired warranties with the total inside.
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
    // Fake but plausible proportions purely so the donut has a shape to
    // skeletonize — never shown as real data.
    final active = isInitialLoading ? 2 : state.active;
    final expiring = isInitialLoading ? 1 : state.expiring;
    final expired = isInitialLoading ? 1 : state.expired;
    final total = active + expiring + expired;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final locale = Localizations.localeOf(context);
    String n(int v) => formatLocalizedInt(locale, v);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.warrantyStatus, style: textTheme.titleMedium),
          const SizedBox(height: 20),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
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
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Skeleton.leaf(
                          child: CustomPaint(
                            size: const Size.square(120),
                            painter: DonutChartPainter(
                              trackColor: colorScheme.surfaceContainerHighest,
                              segments: [
                                Segment(active.toDouble(), palette.success),
                                Segment(expiring.toDouble(), palette.warning),
                                Segment(expired.toDouble(), palette.danger),
                              ],
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(n(total), style: textTheme.headlineSmall),
                            Text(l10n.products, style: textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        LegendRow(
                          color: palette.success,
                          label: l10n.active,
                          value: n(active),
                        ),
                        const SizedBox(height: 14),
                        LegendRow(
                          color: palette.warning,
                          label: l10n.expiring,
                          value: n(expiring),
                        ),
                        const SizedBox(height: 14),
                        LegendRow(
                          color: palette.danger,
                          label: l10n.expired,
                          value: n(expired),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
