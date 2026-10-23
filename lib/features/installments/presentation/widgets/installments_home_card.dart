import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/installments_cubit.dart';
import '../cubit/installments_state.dart';
import '../util/installment_format.dart';
import 'installment_tile.dart';

/// Home entry point, under the Subscriptions card: what's left to pay and the
/// next installment (red when one is overdue), or an invitation to add the
/// first plan. Tapping opens the Installments screen.
class InstallmentsHomeCard extends StatelessWidget {
  const InstallmentsHomeCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<InstallmentsCubit, InstallmentsState>(
      builder: (context, state) {
        final isInitialLoading = state.isLoading && !state.hasLoadedOnce;
        final today = DateTime.now();
        final active = state.activePlans;
        // Plans are sorted by next due date, overdue first.
        final next = active.isEmpty ? null : active.first;
        final nextPayment = next?.nextPayment;
        final totals = state.remainingTotals;
        final main = totals.containsKey('EGP') || totals.isEmpty
            ? 'EGP'
            : totals.keys.first;
        final extraCurrencies =
            totals.length - (totals.containsKey(main) ? 1 : 0);
        final hasActive = active.isNotEmpty || isInitialLoading;

        return AppCard(
          onTap: onTap,
          child: Skeletonizer(
            enabled: isInitialLoading,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        AppIcons.installments,
                        color: colorScheme.primary,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.installments, style: textTheme.titleMedium),
                          Text(
                            hasActive
                                ? l10n.installmentsLeftToPay
                                : l10n.installmentsHomeEmpty,
                            style: textTheme.bodySmall?.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (hasActive)
                      Text(
                        extraCurrencies > 0
                            ? '${formatMoney(context, totals[main] ?? 0, main)} +'
                            : formatMoney(context, totals[main] ?? 0, main),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    else
                      Icon(AppIcons.add, color: colorScheme.primary),
                    const SizedBox(width: 2),
                  ],
                ),
                if (next != null && nextPayment != null) ...[
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: colorScheme.outline.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      InstallmentIcon(
                        overdue: next.overdueAmount(today) > 0,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '${next.name} · '),
                              TextSpan(
                                text: dueLabel(
                                  context,
                                  nextPayment.daysLeft(today),
                                ),
                                style:
                                    dueColor(
                                          context,
                                          nextPayment.daysLeft(today),
                                        ) ==
                                        null
                                    ? null
                                    : TextStyle(
                                        color: dueColor(
                                          context,
                                          nextPayment.daysLeft(today),
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatMoney(context, nextPayment.amount, next.currency),
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
