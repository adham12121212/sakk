import 'package:flutter/material.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/brand_gradient_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../util/installment_format.dart';

/// Brand-gradient hero card (like Subscriptions' monthly total): what's left
/// to pay across active plans, what's due this month and what's overdue. EGP
/// is the headline amount; other currencies are listed under it because the
/// app has no exchange rates.
class RemainingTotalCard extends StatelessWidget {
  const RemainingTotalCard({
    super.key,
    required this.remaining,
    required this.dueThisMonth,
    required this.overdue,
    required this.activeCount,
  });

  final Map<String, double> remaining;
  final Map<String, double> dueThisMonth;
  final Map<String, double> overdue;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final main = remaining.containsKey('EGP') || remaining.isEmpty
        ? 'EGP'
        : remaining.keys.first;
    final others = remaining.entries.where((e) => e.key != main).toList();
    final muted = Colors.white.withValues(alpha: 0.85);

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
                  AppIcons.installments,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.installmentsLeftToPay,
                  style: textTheme.titleSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              Text(
                l10n.installmentsActiveCount(
                  activeCount,
                  formatCount(context, activeCount),
                ),
                style: textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              formatMoney(context, remaining[main] ?? 0, main),
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
            l10n.installmentsDueThisMonth(formatTotals(context, dueThisMonth)),
            style: textTheme.bodySmall?.copyWith(color: muted),
          ),
          if (overdue.isNotEmpty) ...[
            const SizedBox(height: 10),
            // A white pill so red-on-gradient stays readable in both themes.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(AppIcons.warning, size: 16, color: AppColors.error),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l10n.installmentsOverdueTotal(formatTotals(context, overdue)),
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
