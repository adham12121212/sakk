import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/get_it.dart';
import '../../../../core/service/amount_visibility_controller.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../domain/spending_insights.dart';

/// Spending per year and the top stores, as slim bars. Amounts are blurred
/// while the total spent is hidden, so this card doesn't give it away.
class SpendingInsightsCard extends StatelessWidget {
  const SpendingInsightsCard({
    super.key,
    required this.products,
    required this.l10n,
  });

  final List<ProductEntity> products;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final years = spendingByYear(products);
    final stores = topStores(products);
    if (years.isEmpty) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    final appLocale = Localizations.localeOf(context);
    final format = NumberFormat.decimalPattern(
      appLocale.languageCode == 'ar' ? 'ar_EG' : appLocale.toLanguageTag(),
    );

    return ValueListenableBuilder<bool>(
      valueListenable: getIt<AmountVisibilityController>(),
      builder: (context, hidden, _) => AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.spendingByYear, style: textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final e in years)
              _BarRow(
                label: format.format(e.key),
                amount: '${format.format(e.value.round())} EGP',
                share:
                    e.value /
                    years.map((y) => y.value).reduce((a, b) => a > b ? a : b),
                hidden: hidden,
              ),
            if (stores.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(l10n.topStores, style: textTheme.titleMedium),
              const SizedBox(height: 12),
              for (final e in stores)
                _BarRow(
                  label: e.key,
                  amount: '${format.format(e.value.round())} EGP',
                  share: e.value / stores.first.value,
                  hidden: hidden,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.amount,
    required this.share,
    required this.hidden,
  });

  final String label;
  final String amount;
  final double share;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Semantics(
                label: hidden
                    ? AppLocalizations.of(context)!.totalSpentHidden
                    : null,
                excludeSemantics: hidden,
                child: ImageFiltered(
                  enabled: hidden,
                  imageFilter: ImageFilter.blur(
                    sigmaX: 8,
                    sigmaY: 8,
                    tileMode: TileMode.decal,
                  ),
                  child: Text(amount, style: textTheme.labelLarge),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: share.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}
