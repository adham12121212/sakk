import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../domain/entities/installment_plan.dart';
import '../util/installment_format.dart';

/// How much of a plan is paid: a bar (by amount, down payment included)
/// with "4 of 12 paid" under it.
class InstallmentProgress extends StatelessWidget {
  const InstallmentProgress({
    super.key,
    required this.plan,
    this.dense = false,
  });

  final InstallmentPlan plan;

  /// Thinner bar and no percentage, for small cards.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (plan.status) {
      InstallmentPlanStatus.completed => context.palette.success,
      InstallmentPlanStatus.cancelled => colorScheme.onSurfaceVariant,
      InstallmentPlanStatus.active => colorScheme.primary,
    };
    final percent = formatCount(context, (plan.progress * 100).round());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: plan.progress,
            minHeight: dense ? 5 : 8,
            color: color,
            backgroundColor: colorScheme.outline.withValues(alpha: 0.35),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                paidOfLabel(context, plan.paidCount, plan.totalCount),
                style: textTheme.bodySmall,
              ),
            ),
            if (!dense)
              Text(
                '$percent${_percentSign(context)}',
                style: textTheme.bodySmall,
              ),
          ],
        ),
      ],
    );
  }

  static String _percentSign(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar' ? '٪' : '%';
}
