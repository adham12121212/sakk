import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/installment_plan.dart';
import '../util/installment_format.dart';
import 'installment_progress.dart';

/// List row: name, "provider · due in N days", the amount due, and the
/// paid/total bar.
class InstallmentTile extends StatelessWidget {
  const InstallmentTile({
    super.key,
    required this.plan,
    required this.today,
    this.onTap,
  });

  final InstallmentPlan plan;
  final DateTime today;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final next = plan.nextPayment;
    final daysLeft = next?.daysLeft(today);
    final overdue = plan.overdueAmount(today);

    final (String status, Color? statusColor) = switch (plan.status) {
      InstallmentPlanStatus.cancelled => (l10n.installmentCancelled, null),
      InstallmentPlanStatus.completed => (
        l10n.installmentPaidOff,
        context.palette.success,
      ),
      InstallmentPlanStatus.active => (
        dueLabel(context, daysLeft!),
        dueColor(context, daysLeft),
      ),
    };
    final provider = plan.provider;
    // Everything overdue is due now; otherwise the next installment.
    final amountDue = !plan.isActive
        ? null
        : (overdue > 0 ? overdue : next!.amount);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InstallmentIcon(overdue: overdue > 0 && plan.isActive),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        children: [
                          if (provider != null) TextSpan(text: '$provider · '),
                          TextSpan(
                            text: status,
                            style: statusColor == null
                                ? null
                                : TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (amountDue != null)
                Text(
                  formatMoney(context, amountDue, plan.currency),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(width: 2),
              Icon(
                AppIcons.chevronForward,
                size: 20,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InstallmentProgress(plan: plan, dense: true),
        ],
      ),
    );
  }
}

/// The square icon in front of a plan; red while something is overdue.
class InstallmentIcon extends StatelessWidget {
  const InstallmentIcon({super.key, this.overdue = false, this.size = 44});

  final bool overdue;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: overdue
            ? context.palette.dangerContainer
            : colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        overdue ? AppIcons.warning : AppIcons.installments,
        color: overdue ? context.palette.danger : colorScheme.primary,
        size: size * 0.5,
      ),
    );
  }
}
