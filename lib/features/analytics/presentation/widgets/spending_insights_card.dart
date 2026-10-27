import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/get_it.dart';
import '../../../../core/service/amount_visibility_controller.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/spending_insights.dart';

/// Money spent per year as slim bars. Amounts are blurred while the total
/// spent is hidden, so this card doesn't give it away.
class SpendingByYearCard extends StatelessWidget {
  const SpendingByYearCard({
    super.key,
    required this.years,
    required this.l10n,
  });

  /// From [spendingByYear]; not empty.
  final List<MapEntry<int, double>> years;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final tag = _numberTag(context);
    // Years without a thousands separator ("2026", not "2,026").
    final yearFormat = NumberFormat('0', tag);
    final max = years.map((y) => y.value).reduce((a, b) => a > b ? a : b);
    return _BarsCard(
      title: l10n.spendingByYear,
      rows: [
        for (final e in years)
          (
            label: yearFormat.format(e.key),
            value: e.value,
            share: e.value / max,
          ),
      ],
    );
  }
}

/// The stores where the most was spent, as slim bars, blurred like
/// [SpendingByYearCard] while the total is hidden.
class TopStoresCard extends StatelessWidget {
  const TopStoresCard({super.key, required this.stores, required this.l10n});

  /// From [topStores]; not empty.
  final List<MapEntry<String, double>> stores;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _BarsCard(
      title: l10n.topStores,
      rows: [
        for (final e in stores)
          (label: e.key, value: e.value, share: e.value / stores.first.value),
      ],
    );
  }
}

String _numberTag(BuildContext context) {
  final appLocale = Localizations.localeOf(context);
  return appLocale.languageCode == 'ar' ? 'ar_EG' : appLocale.toLanguageTag();
}

class _BarsCard extends StatelessWidget {
  const _BarsCard({required this.title, required this.rows});

  final String title;
  final List<({String label, double value, double share})> rows;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final format = NumberFormat.decimalPattern(_numberTag(context));
    return ValueListenableBuilder<bool>(
      valueListenable: getIt<AmountVisibilityController>(),
      builder: (context, hidden, _) => AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleMedium),
            const SizedBox(height: 16),
            for (final (i, row) in rows.indexed)
              _BarRow(
                label: row.label,
                amount: '${format.format(row.value.round())} EGP',
                share: row.share,
                hidden: hidden,
                last: i == rows.length - 1,
              ),
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
    required this.last,
  });

  final String label;
  final String amount;
  final double share;
  final bool hidden;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
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
