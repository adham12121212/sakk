import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/brand_gradient_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../util/subscription_format.dart';

/// Brand-gradient hero card (like Analytics' total spent): what the
/// subscriptions cost per month. EGP is the headline amount; other currencies
/// are listed under it because the app has no exchange rates.
class MonthlyTotalCard extends StatelessWidget {
  const MonthlyTotalCard({
    super.key,
    required this.totals,
    required this.count,
  });

  /// Monthly cost per currency.
  final Map<String, double> totals;
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final main = totals.containsKey('EGP') || totals.isEmpty
        ? 'EGP'
        : totals.keys.first;
    final mainAmount = totals[main] ?? 0;
    final others = totals.entries.where((e) => e.key != main).toList();

    return BrandGradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  AppIcons.subscriptions,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.subscriptionsMonthlyTotal,
                  style: textTheme.titleSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              Text(
                l10n.subscriptionsCount(count),
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              formatMoney(context, mainAmount, main),
              style: textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          for (final other in others)
            Text(
              '+ ${formatMoney(context, other.value, other.key)}',
              style: textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 6),
          Text(
            l10n.subscriptionsYearlyTotal(
              formatMoney(context, mainAmount * 12, main),
            ),
            style: textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
