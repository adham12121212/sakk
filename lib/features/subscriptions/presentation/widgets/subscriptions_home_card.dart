import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/subscriptions_cubit.dart';
import '../cubit/subscriptions_state.dart';
import '../util/subscription_format.dart';
import 'subscription_logo.dart';

/// Home entry point: monthly total and the next renewal, or an invitation to
/// add the first subscription. Tapping opens the Subscriptions screen.
class SubscriptionsHomeCard extends StatelessWidget {
  const SubscriptionsHomeCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<SubscriptionsCubit, SubscriptionsState>(
      builder: (context, state) {
        final isInitialLoading = state.isLoading && !state.hasLoadedOnce;
        final today = DateTime.now();
        final next = state.nextRenewal(today);
        final totals = state.monthlyTotals;
        final main = totals.containsKey('EGP') || totals.isEmpty
            ? 'EGP'
            : totals.keys.first;
        final extraCurrencies =
            totals.length - (totals.containsKey(main) ? 1 : 0);

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
                        AppIcons.subscriptions,
                        color: colorScheme.primary,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.subscriptions,
                            style: textTheme.titleMedium,
                          ),
                          Text(
                            state.subscriptions.isEmpty && !isInitialLoading
                                ? l10n.subscriptionsHomeEmpty
                                : l10n.subscriptionsMonthlyTotal,
                            style: textTheme.bodySmall?.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (state.subscriptions.isNotEmpty || isInitialLoading)
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
                if (next != null) ...[
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: colorScheme.outline.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SubscriptionLogo(
                        name: next.name,
                        logoUrl: next.logoUrl,
                        domain: next.domain,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${next.name} · ${renewalLabel(l10n, next.daysLeft(today))}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium,
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
