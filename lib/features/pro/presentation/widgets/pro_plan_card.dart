import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/route/app_router.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../installments/presentation/util/installment_format.dart';
import '../../domain/entities/pro_status.dart';
import '../cubit/pro_cubit.dart';
import '../pro_actions.dart';
import 'plan_badge.dart';
import '../util/share_pdf_report.dart';

/// Profile's "Sakk Pro" entry: the current plan, when it renews or ends,
/// and the way to upgrade, manage it on Google Play, see this month's
/// summary, or export a PDF report.
class ProPlanCard extends StatelessWidget {
  const ProPlanCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<ProCubit, ProState>(
      bloc: ProActions.cubit,
      builder: (context, state) {
        final status = state.status;
        final plan = status.plan;
        final e = status.entitlement;
        final date = e?.expiresAt == null
            ? null
            : formatInstallmentDate(context, e!.expiresAt!);
        final body = switch (plan) {
          PlanKind.free => l10n.proCardFreeBody,
          PlanKind.billingIssue => l10n.proCardBillingIssueBody,
          PlanKind.trial => date == null ? null : l10n.proCardTrialEndsOn(date),
          _ when date == null => null,
          _ =>
            e!.willRenew
                ? l10n.proCardRenewsOn(date)
                : l10n.proCardEndsOn(date),
        };

        // Never read (offline, server down): say so instead of loading forever.
        if (!state.hasLoadedOnce && !state.isPro && state.loadFailed) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(AppIcons.pro, color: Color(0xFFF2A900)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(l10n.sakkPro, style: textTheme.titleMedium),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.proStatusLoadFailed,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: ProActions.cubit.refresh,
                  icon: const Icon(AppIcons.retry, size: 18),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          );
        }

        return Skeletonizer(
          enabled: !state.hasLoadedOnce && !state.isPro,
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(AppIcons.pro, color: Color(0xFFF2A900)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(l10n.sakkPro, style: textTheme.titleMedium),
                    ),
                    PlanBadge(status: status, size: PlanBadgeSize.small),
                  ],
                ),
                if (body != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: textTheme.bodyMedium?.copyWith(
                      color: plan == PlanKind.billingIssue
                          ? context.palette.warning
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (plan == PlanKind.free)
                  FilledButton.icon(
                    onPressed: () => ProActions.openPaywall(context),
                    icon: const Icon(AppIcons.pro, size: 18),
                    label: Text(l10n.upgradeToPro),
                  )
                else ...[
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.monthlySummary),
                    icon: const Icon(AppIcons.monthlySummary, size: 18),
                    label: Text(l10n.monthlySummary),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => sharePdfReport(context),
                    icon: const Icon(AppIcons.pdf, size: 18),
                    label: Text(l10n.pdfReportExport),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: ProActions.manageSubscription,
                    child: Text(
                      plan == PlanKind.billingIssue
                          ? l10n.updatePaymentMethod
                          : l10n.manageSubscription,
                    ),
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
