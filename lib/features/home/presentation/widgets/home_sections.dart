import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/util/localized_number.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../installments/presentation/cubit/installments_cubit.dart';
import '../../../installments/presentation/cubit/installments_state.dart';
import '../../../installments/presentation/util/installment_format.dart';
import '../../../papers/presentation/cubit/papers_cubit.dart';
import '../../../papers/presentation/cubit/papers_state.dart';
import '../../../subscriptions/presentation/cubit/subscriptions_cubit.dart';
import '../../../subscriptions/presentation/cubit/subscriptions_state.dart';
import '../../../subscriptions/presentation/util/subscription_format.dart';

/// "Money this month": a row for subscriptions (the monthly total and the
/// next renewal) and one for installments (the next payment and when it's
/// due). Each row opens its screen.
class HomeMoneySection extends StatelessWidget {
  const HomeMoneySection({
    super.key,
    required this.subscriptions,
    required this.installments,
    required this.onSubscriptionsTap,
    required this.onInstallmentsTap,
  });

  final SubscriptionsCubit subscriptions;
  final InstallmentsCubit installments;
  final VoidCallback onSubscriptionsTap;
  final VoidCallback onInstallmentsTap;

  /// The EGP amount, or the first currency's, with "+" when there are more.
  static String _total(BuildContext context, Map<String, double> totals) {
    final main = totals.containsKey('EGP') || totals.isEmpty
        ? 'EGP'
        : totals.keys.first;
    final more = totals.length - (totals.containsKey(main) ? 1 : 0) > 0;
    final amount = formatMoney(context, totals[main] ?? 0, main);
    return more ? '$amount +' : amount;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final today = DateTime.now();
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.moneyThisMonth),
        const SizedBox(height: 4),
        _RowsCard(
          children: [
            BlocBuilder<SubscriptionsCubit, SubscriptionsState>(
              bloc: subscriptions,
              builder: (context, state) {
                final next = state.nextRenewal(today);
                final days = next?.daysLeft(today);
                final isEmpty = state.subscriptions.isEmpty;
                return HomeRow(
                  icon: AppIcons.subscriptions,
                  title: l10n.subscriptions,
                  subtitle: next == null
                      ? l10n.subscriptionsHomeEmpty
                      : '${next.name} · ${renewalLabel(l10n, days!)}',
                  subtitleColor: days != null && days <= 3
                      ? palette.warning
                      : null,
                  value: isEmpty ? null : _total(context, state.monthlyTotals),
                  valueCaption: isEmpty ? null : l10n.billingMonthly,
                  onTap: onSubscriptionsTap,
                );
              },
            ),
            BlocBuilder<InstallmentsCubit, InstallmentsState>(
              bloc: installments,
              builder: (context, state) {
                final active = state.activePlans;
                // Sorted by next due date, overdue first.
                final next = active.isEmpty ? null : active.first;
                final payment = next?.nextPayment;
                final days = payment?.daysLeft(today);
                return HomeRow(
                  icon: AppIcons.installments,
                  title: l10n.installments,
                  subtitle: next == null || days == null
                      ? l10n.installmentsHomeEmpty
                      : '${next.name} · ${dueLabel(context, days)}',
                  subtitleColor: days == null ? null : dueColor(context, days),
                  value: payment == null
                      ? null
                      : formatMoney(context, payment.amount, next!.currency),
                  onTap: onInstallmentsTap,
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// "My papers": a heading and one row, like the money rows: how many
/// papers there are and how many need renewing. Tapping opens My papers.
class HomePapersSection extends StatelessWidget {
  const HomePapersSection({
    super.key,
    required this.papers,
    required this.onOpen,
  });

  final PapersCubit papers;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    return BlocBuilder<PapersCubit, PapersState>(
      bloc: papers,
      builder: (context, state) {
        final count = state.papers.length;
        final toRenew = state.needsAttention(DateTime.now());
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: l10n.myPapers),
            const SizedBox(height: 4),
            _RowsCard(
              children: [
                HomeRow(
                  icon: AppIcons.papers,
                  title: count == 0
                      ? l10n.addPaper
                      : l10n.papersCountLabel(
                          count,
                          formatLocalizedInt(locale, count),
                        ),
                  subtitle: count == 0
                      ? l10n.papersHomeEmpty
                      : toRenew > 0
                      ? l10n.papersToRenewCount(
                          toRenew,
                          formatLocalizedInt(locale, toRenew),
                        )
                      : l10n.papersAllUpToDate,
                  subtitleColor: toRenew > 0 ? context.palette.warning : null,
                  showAdd: false,
                  onTap: onOpen,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Rows in one card, a hairline between them.
class _RowsCard extends StatelessWidget {
  const _RowsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final divider = Divider(
      height: 1,
      indent: 64,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) divider,
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// One line on Home: an icon, a title with a subtitle under it, and a value
/// at the end (or a "+" when there's nothing yet).
class HomeRow extends StatelessWidget {
  const HomeRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.subtitleColor,
    this.value,
    this.valueCaption,
    this.showAdd = true,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final Color? subtitleColor;

  /// Null shows a "+" instead (nothing tracked yet), unless [showAdd] is
  /// false.
  final String? value;
  final String? valueCaption;
  final bool showAdd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final color = iconColor ?? colorScheme.primary;
    final value = this.value;
    final valueCaption = this.valueCaption;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      color: subtitleColor,
                      fontWeight: subtitleColor == null
                          ? null
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (value == null)
              if (showAdd)
                Icon(AppIcons.add, color: colorScheme.primary, size: 20)
              else
                const SizedBox.shrink()
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (valueCaption != null)
                    Text(valueCaption, style: textTheme.bodySmall),
                ],
              ),
            const SizedBox(width: 2),
            Icon(
              AppIcons.chevronForward,
              size: 18,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
