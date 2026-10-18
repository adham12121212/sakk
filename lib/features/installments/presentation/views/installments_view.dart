import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/route/app_router.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/installment_payment.dart';
import '../../domain/entities/installment_plan.dart';
import '../../domain/entities/installment_terms.dart';
import '../../domain/installment_totals.dart';
import '../cubit/installments_cubit.dart';
import '../cubit/installments_state.dart';
import '../widgets/installment_tile.dart';
import '../widgets/remaining_total_card.dart';
import 'installment_form_view.dart';
import '../../../pro/domain/pro_limit.dart';
import '../../../pro/presentation/pro_actions.dart';

/// The user's installment plans: what's left to pay, then the plans by next
/// due date.
class InstallmentsView extends StatefulWidget {
  const InstallmentsView({super.key});

  @override
  State<InstallmentsView> createState() => _InstallmentsViewState();
}

class _InstallmentsViewState extends State<InstallmentsView> {
  @override
  void initState() {
    super.initState();
    context.read<InstallmentsCubit>().loadIfNeeded();
  }

  void _add() {
    if (!ProActions.ensureCanAdd(context, LimitedItem.installments)) return;
    context.push(AppRoutes.installmentForm, extra: const InstallmentFormArgs.add());
  }

  void _open(InstallmentPlan plan) =>
      context.push(AppRoutes.installmentDetails, extra: plan.id);

  // Never shown as real data: Skeletonizer paints shimmer bones over it.
  List<InstallmentPlan> _placeholders() {
    final now = DateTime.now();
    return List.generate(
      4,
      (i) => InstallmentPlan(
        id: 'placeholder-$i',
        title: 'Installment plan',
        provider: 'Provider',
        terms: InstallmentTerms(
          totalPrice: 12000,
          installmentAmount: 1000,
          installmentsCount: 12,
          startDate: now,
          dueDayOfMonth: now.day,
        ),
        payments: [
          InstallmentPayment(
            id: 'placeholder-$i-p',
            planId: 'placeholder-$i',
            dueDate: now.add(Duration(days: 5 + i * 4)),
            amount: 1000,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.installments),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButton:
          BlocSelector<InstallmentsCubit, InstallmentsState, bool>(
            selector: (state) => state.plans.isNotEmpty,
            builder: (context, hasAny) => hasAny
                ? FloatingActionButton.extended(
                    onPressed: _add,
                    icon: const Icon(AppIcons.add),
                    label: Text(l10n.addInstallment),
                  )
                : const SizedBox.shrink(),
          ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<InstallmentsCubit, InstallmentsState>(
          builder: (context, state) => AppRefreshIndicator(
            onRefresh: context.read<InstallmentsCubit>().refresh,
            child: _body(context, state),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, InstallmentsState state) {
    final l10n = AppLocalizations.of(context)!;
    final isInitialLoading = state.isLoading && state.plans.isEmpty;

    if (state.error != null && state.plans.isEmpty && !isInitialLoading) {
      return AppErrorView(
        message: state.error,
        onRetry: context.read<InstallmentsCubit>().refresh,
        fillRemaining: true,
      );
    }

    if (state.plans.isEmpty && !isInitialLoading) {
      return AppEmptyView(
        icon: AppIcons.installments,
        title: l10n.noInstallmentsYet,
        message: l10n.noInstallmentsBody,
        actionLabel: l10n.addInstallment,
        onAction: _add,
        fillRemaining: true,
      );
    }

    final items = isInitialLoading ? _placeholders() : state.plans;
    final today = DateTime.now();

    return Skeletonizer(
      enabled: isInitialLoading,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        // Bottom room so the last row clears the floating button.
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
        itemCount: items.length + 1,
        separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 20 : 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return RemainingTotalCard(
              remaining: remainingByCurrency(items),
              dueThisMonth: dueInMonthByCurrency(items, today.year, today.month),
              overdue: overdueByCurrency(items, today),
              activeCount: items.where((p) => p.isActive).length,
            );
          }
          final plan = items[index - 1];
          return InstallmentTile(
            plan: plan,
            today: today,
            onTap: isInitialLoading ? null : () => _open(plan),
          );
        },
      ),
    );
  }
}
