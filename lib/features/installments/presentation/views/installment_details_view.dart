import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/error/user_facing_error.dart';
import '../../../../core/route/app_router.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../details/presentation/widgets/detail_row.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../domain/entities/installment_payment.dart';
import '../../domain/entities/installment_plan.dart';
import '../../domain/entities/installment_plan_draft.dart';
import '../cubit/installment_form_cubit.dart';
import '../cubit/installments_cubit.dart';
import '../cubit/installments_state.dart';
import '../util/installment_format.dart';
import '../widgets/installment_progress.dart';
import '../widgets/installment_tile.dart';
import 'installment_form_view.dart';

/// One plan: what's left, its terms and the payment schedule, where each
/// installment can be marked paid (or unpaid again). Edit, cancel and delete
/// are in the app bar.
class InstallmentDetailsView extends StatelessWidget {
  const InstallmentDetailsView({super.key, required this.planId});

  final String planId;

  void _onFormState(BuildContext context, InstallmentFormState state) {
    final l10n = AppLocalizations.of(context)!;
    switch (state) {
      case InstallmentFormSaved(:final plan):
        AppSnackBar.success(
          context,
          plan.isCancelled ? l10n.installmentPlanCancelled : l10n.installmentPlanReactivated,
        );
      case InstallmentFormDeleted():
        AppSnackBar.success(context, l10n.installmentDeleted);
        Navigator.of(context).pop();
      case InstallmentFormFailure(:final message):
        AppSnackBar.error(context, userFacingError(l10n, message));
      case InstallmentFormIdle() || InstallmentFormBusy():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<InstallmentFormCubit, InstallmentFormState>(
      listener: _onFormState,
      child: BlocBuilder<InstallmentsCubit, InstallmentsState>(
        builder: (context, state) {
          final plan = state.planById(planId);
          if (plan == null) {
            // Deleted, or the list isn't loaded yet (opened from a reminder).
            return Scaffold(
              appBar: AppBar(surfaceTintColor: Colors.transparent, elevation: 0),
              body: state.isLoading || !state.hasLoadedOnce
                  ? const Center(child: CircularProgressIndicator())
                  : AppEmptyView(
                      icon: AppIcons.installments,
                      title: l10n.installmentNotFound,
                      message: l10n.installmentNotFoundBody,
                    ),
            );
          }
          return _PlanDetails(plan: plan, updating: state.updatingPaymentIds);
        },
      ),
    );
  }
}

enum _MenuAction { cancelPlan, reactivate, delete }

class _PlanDetails extends StatelessWidget {
  const _PlanDetails({required this.plan, required this.updating});

  final InstallmentPlan plan;
  final Set<String> updating;

  Future<void> _setPaid(BuildContext context, InstallmentPayment payment, bool paid) async {
    final l10n = AppLocalizations.of(context)!;
    if (!paid) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.markUnpaidQuestion),
          content: Text(l10n.markUnpaidBody(formatInstallmentDate(context, payment.dueDate))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.markUnpaid),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }
    final error = await context.read<InstallmentsCubit>().setPaymentPaid(plan.id, payment.id, paid: paid);
    if (!context.mounted) return;
    if (error != null) {
      AppSnackBar.error(context, userFacingError(l10n, error));
    } else if (paid) {
      AppSnackBar.success(context, l10n.installmentMarkedPaid);
    }
  }

  void _edit(BuildContext context) => context.push(
    AppRoutes.installmentForm,
    extra: InstallmentFormArgs.edit(plan),
  );

  Future<void> _onMenu(BuildContext context, _MenuAction action) async {
    final l10n = AppLocalizations.of(context)!;
    final form = context.read<InstallmentFormCubit>();
    switch (action) {
      case _MenuAction.cancelPlan || _MenuAction.reactivate:
        final draft = plan.toDraft();
        form.save(
          InstallmentPlanDraft(
            productId: draft.productId,
            title: draft.title,
            provider: draft.provider,
            currency: draft.currency,
            terms: draft.terms,
            notes: draft.notes,
            isCancelled: action == _MenuAction.cancelPlan,
          ),
          current: plan,
        );
      case _MenuAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.deleteInstallmentQuestion),
            content: Text(l10n.deleteInstallmentBody(plan.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.delete, style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
        if (confirmed == true) form.delete(plan.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final isBusy = context.watch<InstallmentFormCubit>().state is InstallmentFormBusy;
    final today = DateTime.now();
    final overdue = plan.overduePayments(today);

    return Scaffold(
      appBar: AppBar(
        title: Text(plan.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: l10n.edit,
            icon: const Icon(AppIcons.edit),
            onPressed: isBusy ? null : () => _edit(context),
          ),
          PopupMenuButton<_MenuAction>(
            enabled: !isBusy,
            onSelected: (action) => _onMenu(context, action),
            itemBuilder: (_) => [
              if (plan.isCancelled)
                PopupMenuItem(value: _MenuAction.reactivate, child: Text(l10n.reactivateInstallmentPlan))
              else
                PopupMenuItem(value: _MenuAction.cancelPlan, child: Text(l10n.cancelInstallmentPlan)),
              PopupMenuItem(
                value: _MenuAction.delete,
                child: Text(l10n.delete, style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _SummaryCard(
              plan: plan,
              today: today,
              busy: plan.nextPayment != null && updating.contains(plan.nextPayment!.id),
              onMarkNextPaid: plan.nextPayment == null
                  ? null
                  : () => _setPaid(context, plan.nextPayment!, true),
            ),
            if (overdue.isNotEmpty && !plan.isCancelled) ...[
              const SizedBox(height: 12),
              _OverdueBanner(
                count: overdue.length,
                amount: formatMoney(context, plan.overdueAmount(today), plan.currency),
              ),
            ],
            const SizedBox(height: 16),
            _TermsCard(plan: plan),
            const SizedBox(height: 24),
            SectionHeader(title: l10n.paymentSchedule),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < plan.payments.length; i++)
                    _PaymentRow(
                      number: i + 1,
                      payment: plan.payments[i],
                      currency: plan.currency,
                      today: today,
                      busy: updating.contains(plan.payments[i].id),
                      isLast: i == plan.payments.length - 1,
                      onToggle: (paid) => _setPaid(context, plan.payments[i], paid),
                    ),
                ],
              ),
            ),
            if (plan.notes != null && plan.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 24),
              SectionHeader(title: l10n.notes),
              const SizedBox(height: 8),
              AppCard(
                child: Text(plan.notes!, style: textTheme.bodyMedium),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.plan,
    required this.today,
    required this.busy,
    required this.onMarkNextPaid,
  });

  final InstallmentPlan plan;
  final DateTime today;
  final bool busy;
  final VoidCallback? onMarkNextPaid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final next = plan.nextPayment;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InstallmentIcon(overdue: plan.isActive && plan.overdueAmount(today) > 0),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.installmentsLeftToPay, style: textTheme.bodySmall?.copyWith(fontSize: 13)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        formatMoney(context, plan.remainingBalance, plan.currency),
                        style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      l10n.installmentOfTotal(formatMoney(context, plan.totalPayable, plan.currency)),
                      style: textTheme.bodySmall?.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              _StatusPill(plan: plan),
            ],
          ),
          const SizedBox(height: 16),
          InstallmentProgress(plan: plan),
          if (next != null && !plan.isCancelled) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.nextInstallment, style: textTheme.bodySmall?.copyWith(fontSize: 13)),
                      Text(
                        formatMoney(context, next.amount, plan.currency),
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${formatInstallmentDate(context, next.dueDate)} · ${dueLabel(context, next.daysLeft(today))}',
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          color: dueColor(context, next.daysLeft(today)),
                          fontWeight: dueColor(context, next.daysLeft(today)) == null ? null : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: busy ? null : onMarkNextPaid,
                  icon: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(AppIcons.check, size: 18),
                  label: Text(l10n.markAsPaid),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// "Active" / "Paid off" / "Cancelled".
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.plan});

  final InstallmentPlan plan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final colorScheme = Theme.of(context).colorScheme;
    final (label, fg, bg) = switch (plan.status) {
      InstallmentPlanStatus.active => (l10n.active, palette.success, palette.successContainer),
      InstallmentPlanStatus.completed => (l10n.installmentPaidOff, palette.success, palette.successContainer),
      InstallmentPlanStatus.cancelled => (
        l10n.installmentCancelled,
        colorScheme.onSurfaceVariant,
        colorScheme.surfaceContainerHighest,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _OverdueBanner extends StatelessWidget {
  const _OverdueBanner({required this.count, required this.amount});

  final int count;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.dangerContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(AppIcons.warning, color: palette.danger, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.installmentsOverdueBanner(count, formatCount(context, count), amount),
              style: TextStyle(color: palette.danger, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Provider, linked product and the money terms.
class _TermsCard extends StatelessWidget {
  const _TermsCard({required this.plan});

  final InstallmentPlan plan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final terms = plan.terms;
    final productId = plan.productId;
    final product = productId == null
        ? null
        : getIt<ProductsCubit>().state.products.where((p) => p.id == productId).firstOrNull;
    String money(double v) => formatMoney(context, v, plan.currency);

    final rows = <(IconData, String, String, VoidCallback?)>[
      if (product != null)
        (AppIcons.productPlaceholder, l10n.linkedProduct, product.name, () => context.push(AppRoutes.details, extra: product)),
      if (plan.provider != null) (AppIcons.store, l10n.installmentProvider, plan.provider!, null),
      (AppIcons.price, l10n.totalPrice, money(terms.totalPrice), null),
      if (terms.downPayment > 0) (AppIcons.wallet, l10n.downPayment, money(terms.downPayment), null),
      if ((terms.interestOrFees ?? 0) > 0) (AppIcons.receipt, l10n.interestOrFees, money(terms.interestOrFees!), null),
      (
        AppIcons.installments,
        l10n.installmentAmount,
        l10n.installmentsTimesAmount(formatCount(context, terms.installmentsCount), money(terms.installmentAmount)),
        null,
      ),
      (AppIcons.calendar, l10n.dueDayOfMonth, l10n.dueDayValue(formatCount(context, terms.dueDayOfMonth)), null),
    ];

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (final (i, (icon, label, value, onTap)) in rows.indexed)
            InkWell(
              onTap: onTap,
              child: DetailRow(icon: icon, label: label, value: value, isLast: i == rows.length - 1),
            ),
        ],
      ),
    );
  }
}

/// One installment: number, due date, status and amount, with a check to
/// mark it paid (or unpaid again).
class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.number,
    required this.payment,
    required this.currency,
    required this.today,
    required this.busy,
    required this.isLast,
    required this.onToggle,
  });

  final int number;
  final InstallmentPayment payment;
  final String currency;
  final DateTime today;
  final bool busy;
  final bool isLast;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final palette = context.palette;
    final status = payment.status(today);
    final daysLeft = payment.daysLeft(today);

    final (String subtitle, Color? subtitleColor) = switch (status) {
      PaymentStatus.paid => (
        l10n.paidOn(formatInstallmentDate(context, payment.paidAt!.toLocal())),
        palette.success,
      ),
      PaymentStatus.overdue => (dueLabel(context, daysLeft), palette.danger),
      PaymentStatus.pending => (dueLabel(context, daysLeft), dueColor(context, daysLeft)),
    };

    final Widget toggle = busy
        ? const SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          )
        : IconButton(
            tooltip: status == PaymentStatus.paid ? l10n.markUnpaid : l10n.markAsPaid,
            onPressed: () => onToggle(status != PaymentStatus.paid),
            icon: Icon(
              status == PaymentStatus.paid ? AppIcons.successFilled : AppIcons.unpaid,
              color: switch (status) {
                PaymentStatus.paid => palette.success,
                PaymentStatus.overdue => palette.danger,
                PaymentStatus.pending => colorScheme.onSurfaceVariant,
              },
            ),
          );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 4, 6),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  formatCount(context, number),
                  style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatInstallmentDate(context, payment.dueDate), style: textTheme.bodyMedium),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                        fontWeight: subtitleColor == null ? null : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatMoney(context, payment.amount, currency),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  decoration: status == PaymentStatus.paid ? TextDecoration.lineThrough : null,
                  color: status == PaymentStatus.paid ? colorScheme.onSurfaceVariant : null,
                ),
              ),
              toggle,
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, indent: 16, endIndent: 16, color: colorScheme.outline.withValues(alpha: 0.4)),
      ],
    );
  }
}
