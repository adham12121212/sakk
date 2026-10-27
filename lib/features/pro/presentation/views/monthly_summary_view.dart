import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/route/app_router.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../core/widgets/brand_gradient_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../installments/presentation/cubit/installments_cubit.dart';
import '../../../installments/presentation/cubit/installments_state.dart';
import '../../../installments/presentation/util/installment_format.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../products/presentation/cubit/product_state.dart';
import '../../../subscriptions/presentation/cubit/subscriptions_cubit.dart';
import '../../../subscriptions/presentation/cubit/subscriptions_state.dart';
import '../../../../core/util/localized_number.dart';
import '../../domain/monthly_summary.dart';

/// Sakk Pro's "What will I pay this month": the total still to pay, the
/// payments it's made of, and warranties ending soon. Built from the same
/// app-wide lists the Subscriptions, Installments and Products screens use.
class MonthlySummaryView extends StatefulWidget {
  const MonthlySummaryView({super.key, this.today});

  /// For tests.
  final DateTime? today;

  @override
  State<MonthlySummaryView> createState() => _MonthlySummaryViewState();
}

class _MonthlySummaryViewState extends State<MonthlySummaryView> {
  @override
  void initState() {
    super.initState();
    context.read<SubscriptionsCubit>().loadIfNeeded();
    context.read<InstallmentsCubit>().loadIfNeeded();
    context.read<ProductsCubit>().loadIfNeeded();
  }

  Future<void> _refresh() => Future.wait([
    context.read<SubscriptionsCubit>().refresh(),
    context.read<InstallmentsCubit>().refresh(),
    context.read<ProductsCubit>().refresh(),
  ]);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subscriptions = context.watch<SubscriptionsCubit>().state;
    final installments = context.watch<InstallmentsCubit>().state;
    final products = context.watch<ProductsCubit>().state;
    final loading = !_loaded(subscriptions, installments, products);

    final summary = MonthlySummary.build(
      subscriptions: subscriptions.subscriptions,
      plans: installments.plans,
      products: products.products,
      today: widget.today ?? DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.monthlySummary),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: AppRefreshIndicator(
        onRefresh: _refresh,
        child: Skeletonizer(
          enabled: loading,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _TotalCard(summary: summary),
              const SizedBox(height: 24),
              SectionHeader(title: l10n.monthlySummaryUpcoming),
              const SizedBox(height: 12),
              if (summary.payments.isEmpty && !loading)
                _EmptyLine(text: l10n.monthlySummaryNothingDue)
              else
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      for (final p
                          in loading ? _placeholderPayments : summary.payments)
                        _PaymentRow(payment: p),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              SectionHeader(title: l10n.monthlySummaryWarranties),
              const SizedBox(height: 12),
              if (summary.expiringWarranties.isEmpty)
                _EmptyLine(text: l10n.monthlySummaryNoWarranties)
              else
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      for (final product in summary.expiringWarranties)
                        ListTile(
                          leading: Icon(
                            AppIcons.warranty,
                            color: context.palette.warning,
                          ),
                          title: Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            formatInstallmentDate(
                              context,
                              product.warrantyEndDate,
                            ),
                          ),
                          trailing: Text(
                            l10n.daysLeft(
                              product.daysRemaining,
                              formatLocalizedInt(
                                Localizations.localeOf(context),
                                product.daysRemaining,
                              ),
                            ),
                            style: TextStyle(
                              color: context.palette.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () =>
                              context.push(AppRoutes.details, extra: product),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static bool _loaded(
    SubscriptionsState s,
    InstallmentsState i,
    ProductsState p,
  ) =>
      (s.hasLoadedOnce || s.error != null) &&
      (i.hasLoadedOnce || i.error != null) &&
      (p.hasLoadedOnce || p.error != null);

  static final _placeholderPayments = [
    for (var i = 0; i < 3; i++)
      SummaryPayment(
        kind: SummaryPaymentKind.renewal,
        name: 'Subscription name',
        amount: 100,
        currency: 'EGP',
        date: DateTime(2026),
      ),
  ];
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.summary});

  final MonthlySummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final white70 = Colors.white.withValues(alpha: 0.85);
    return BrandGradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                AppIcons.monthlySummary,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.monthlySummaryTotal,
                style: textTheme.titleSmall?.copyWith(color: white70),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            formatTotals(context, summary.totals),
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(
                '${l10n.subscriptions}: ${formatTotals(context, summary.subscriptionTotals)}',
                style: textTheme.bodyMedium?.copyWith(color: white70),
              ),
              Text(
                '${l10n.installments}: ${formatTotals(context, summary.installmentTotals)}',
                style: textTheme.bodyMedium?.copyWith(color: white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.monthlySummaryTotalHint,
            style: textTheme.bodySmall?.copyWith(color: white70),
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});

  final SummaryPayment payment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isRenewal = payment.kind == SummaryPaymentKind.renewal;
    final kindLabel = isRenewal ? l10n.summaryRenewal : l10n.summaryInstallment;
    final dateLabel = payment.isOverdue
        ? l10n.monthlySummaryOverdue
        : formatInstallmentDate(context, payment.date);
    return ListTile(
      leading: Icon(
        isRenewal ? AppIcons.subscriptions : AppIcons.installments,
        color: payment.isOverdue ? context.palette.danger : colorScheme.primary,
      ),
      title: Text(payment.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '$kindLabel · $dateLabel',
        style: payment.isOverdue
            ? TextStyle(color: context.palette.danger)
            : null,
      ),
      trailing: Text(
        formatMoney(context, payment.amount, payment.currency),
        style: Theme.of(context).textTheme.titleSmall,
      ),
      onTap: payment.planId == null
          ? () => context.push(AppRoutes.subscriptions)
          : () => context.push(
              AppRoutes.installmentDetails,
              extra: payment.planId,
            ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(AppIcons.success, color: context.palette.success),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
