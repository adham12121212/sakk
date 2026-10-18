import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/get_it.dart';
import '../../../../core/route/app_router.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../domain/entities/installment_plan.dart';
import '../cubit/installments_cubit.dart';
import '../cubit/installments_state.dart';
import '../util/installment_format.dart';
import '../views/installment_form_view.dart';
import 'installment_progress.dart';
import '../../../pro/domain/pro_limit.dart';
import '../../../pro/presentation/pro_actions.dart';

/// Installments on the product details screen (the user's own products
/// only): each linked plan's status, and "Add installment".
class ProductInstallmentsSection extends StatefulWidget {
  const ProductInstallmentsSection({super.key, required this.product});

  final ProductEntity product;

  @override
  State<ProductInstallmentsSection> createState() => _ProductInstallmentsSectionState();
}

class _ProductInstallmentsSectionState extends State<ProductInstallmentsSection> {
  final _cubit = getIt<InstallmentsCubit>();

  @override
  void initState() {
    super.initState();
    _cubit.loadIfNeeded();
  }

  void _add() {
    if (!ProActions.ensureCanAdd(context, LimitedItem.installments)) return;
    context.push(AppRoutes.installmentForm, extra: InstallmentFormArgs.add(product: widget.product));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<InstallmentsCubit, InstallmentsState>(
      bloc: _cubit,
      builder: (context, state) {
        final plans = state.plansForProduct(widget.product.id);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Text(l10n.installments, style: textTheme.titleMedium)),
                TextButton.icon(
                  onPressed: _add,
                  icon: const Icon(AppIcons.add, size: 18),
                  label: Text(l10n.addInstallment),
                  style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (plans.isEmpty)
              Text(
                l10n.productInstallmentsHint,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              )
            else
              for (final plan in plans) ...[
                _PlanStatusCard(
                  plan: plan,
                  onTap: () => context.push(AppRoutes.installmentDetails, extra: plan.id),
                ),
                const SizedBox(height: 8),
              ],
          ],
        );
      },
    );
  }
}

/// "Valu · next 1,000 EGP due in 5 days" with the paid/total bar.
class _PlanStatusCard extends StatelessWidget {
  const _PlanStatusCard({required this.plan, required this.onTap});

  final InstallmentPlan plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final today = DateTime.now();
    final next = plan.nextPayment;
    final daysLeft = next?.daysLeft(today);

    final String status = switch (plan.status) {
      InstallmentPlanStatus.cancelled => l10n.installmentCancelled,
      InstallmentPlanStatus.completed => l10n.installmentPaidOff,
      InstallmentPlanStatus.active => l10n.nextInstallmentDue(
        formatMoney(context, next!.amount, plan.currency),
        dueLabel(context, daysLeft!),
      ),
    };
    final color = plan.isActive ? dueColor(context, daysLeft!) : null;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(AppIcons.installments, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  [if (plan.provider != null) plan.provider!, status].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: color == null ? null : FontWeight.w600,
                  ),
                ),
              ),
              const Icon(AppIcons.chevronForward, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          InstallmentProgress(plan: plan, dense: true),
        ],
      ),
    );
  }
}
