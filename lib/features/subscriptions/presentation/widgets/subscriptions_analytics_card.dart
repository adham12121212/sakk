import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/util/localized_number.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_card_prompt.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/widgets/segmented_toggle.dart';
import '../../domain/entities/subscription_category.dart';
import '../cubit/subscriptions_state.dart';
import '../util/subscription_category_ui.dart';
import '../util/subscription_format.dart';

/// Analytics card: what subscriptions cost per month and per year, and how
/// that splits by category. Currencies are never added together (no
/// exchange rates): with more than one, a switch shows each on its own.
class SubscriptionsAnalyticsCard extends StatefulWidget {
  const SubscriptionsAnalyticsCard({
    super.key,
    required this.state,
    required this.onTap,
  });

  final SubscriptionsState state;
  final VoidCallback onTap;

  @override
  State<SubscriptionsAnalyticsCard> createState() =>
      _SubscriptionsAnalyticsCardState();
}

class _SubscriptionsAnalyticsCardState
    extends State<SubscriptionsAnalyticsCard> {
  /// The currency picked on the switch; EGP (or the only one) until then.
  String? _picked;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);
    final isInitialLoading = state.isLoading && !state.hasLoadedOnce;

    final totals = state.monthlyTotals;
    // EGP first, then the others as they come.
    final currencies = [
      if (totals.containsKey('EGP')) 'EGP',
      ...totals.keys.where((c) => c != 'EGP'),
    ];
    final main = currencies.contains(_picked)
        ? _picked!
        : (currencies.isEmpty ? 'EGP' : currencies.first);
    final mainMonthly = isInitialLoading ? 500.0 : totals[main] ?? 0;

    // Monthly cost by category, main currency only.
    final byCategory = <SubscriptionCategory, double>{};
    if (isInitialLoading) {
      byCategory[SubscriptionCategory.streaming] = 300;
      byCategory[SubscriptionCategory.music] = 200;
    } else {
      for (final s in state.subscriptions.where((s) => s.currency == main)) {
        byCategory.update(
          s.category,
          (sum) => sum + s.monthlyCost,
          ifAbsent: () => s.monthlyCost,
        );
      }
    }
    final entries = byCategory.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (!isInitialLoading && state.subscriptions.isEmpty) {
      return AppCard(
        onTap: widget.onTap,
        child: EmptyCardPrompt(
          icon: AppIcons.subscriptions,
          title: l10n.subscriptionsAnalyticsTitle,
          message: l10n.subscriptionsAnalyticsEmpty,
        ),
      );
    }

    return AppCard(
      onTap: widget.onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.subscriptionsAnalyticsTitle, style: textTheme.titleMedium),
          if (currencies.length > 1) ...[
            const SizedBox(height: 12),
            SegmentedToggle<String>(
              options: {
                for (final c in currencies)
                  c: c == 'EGP' ? l10n.currencyEgp : c,
              },
              selected: main,
              onChanged: (c) => setState(() => _picked = c),
            ),
          ],
          const SizedBox(height: 16),
          Skeletonizer(
            enabled: isInitialLoading,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Figure(
                        label: l10n.billingMonthly,
                        value: formatMoney(context, mainMonthly, main),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Figure(
                        label: l10n.billingYearly,
                        value: formatMoney(context, mainMonthly * 12, main),
                      ),
                    ),
                  ],
                ),
                if (entries.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  for (final (i, entry) in entries.indexed) ...[
                    if (i > 0) const SizedBox(height: 14),
                    _CategoryRow(
                      category: entry.key,
                      amount: formatMoney(context, entry.value, main),
                      share: mainMonthly == 0 ? 0 : entry.value / mainMonthly,
                      percent:
                          '${formatLocalizedInt(locale, mainMonthly == 0 ? 0 : (entry.value / mainMonthly * 100).round())}%',
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodySmall),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

/// Same look as the product CategoryBreakdownCard rows: tinted icon, name,
/// amount, share and a slim bar in the category colour.
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.share,
    required this.percent,
  });

  final SubscriptionCategory category;
  final String amount;
  final double share;
  final String percent;

  @override
  Widget build(BuildContext context) {
    final color = SubscriptionCategoryUi.color(category);
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
          child: Icon(
            SubscriptionCategoryUi.icon(category),
            color: color,
            size: 20,
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
                      SubscriptionCategoryUi.label(context, category),
                      style: textTheme.titleSmall,
                    ),
                  ),
                  Text(amount, style: textTheme.titleSmall),
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
                  value: share.clamp(0.0, 1.0),
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
