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
import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/user_subscription.dart';
import '../cubit/subscriptions_cubit.dart';
import '../cubit/subscriptions_state.dart';
import '../widgets/monthly_total_card.dart';
import '../widgets/subscription_tile.dart';
import 'subscription_form_view.dart';

/// The user's subscriptions: monthly total, then the list by nearest renewal.
class SubscriptionsView extends StatefulWidget {
  const SubscriptionsView({super.key});

  @override
  State<SubscriptionsView> createState() => _SubscriptionsViewState();
}

class _SubscriptionsViewState extends State<SubscriptionsView> {
  @override
  void initState() {
    super.initState();
    context.read<SubscriptionsCubit>().loadIfNeeded();
  }

  void _add() => context.push(AppRoutes.subscriptionCatalog);

  void _edit(UserSubscription subscription) {
    context.push(
      AppRoutes.subscriptionForm,
      extra: SubscriptionFormArgs.edit(subscription),
    );
  }

  // Never shown as real data: Skeletonizer paints shimmer bones over it.
  List<UserSubscription> _placeholders() {
    final now = DateTime.now();
    return List.generate(
      5,
      (i) => UserSubscription(
        id: 'placeholder-$i',
        customName: 'Subscription',
        planName: 'Plan',
        price: 100,
        billingCycle: BillingCycle.monthly,
        nextRenewalDate: now.add(Duration(days: 3 + i * 5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.subscriptions),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButton:
          BlocSelector<SubscriptionsCubit, SubscriptionsState, bool>(
            selector: (state) => state.subscriptions.isNotEmpty,
            builder: (context, hasAny) => hasAny
                ? FloatingActionButton.extended(
                    onPressed: _add,
                    icon: const Icon(AppIcons.add),
                    label: Text(l10n.addSubscription),
                  )
                : const SizedBox.shrink(),
          ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<SubscriptionsCubit, SubscriptionsState>(
          builder: (context, state) => AppRefreshIndicator(
            onRefresh: context.read<SubscriptionsCubit>().refresh,
            child: _body(context, state),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, SubscriptionsState state) {
    final l10n = AppLocalizations.of(context)!;
    final isInitialLoading = state.isLoading && state.subscriptions.isEmpty;

    if (state.error != null &&
        state.subscriptions.isEmpty &&
        !isInitialLoading) {
      return AppErrorView(
        message: state.error,
        onRetry: context.read<SubscriptionsCubit>().refresh,
        fillRemaining: true,
      );
    }

    if (state.subscriptions.isEmpty && !isInitialLoading) {
      return AppEmptyView(
        icon: AppIcons.subscriptions,
        title: l10n.noSubscriptionsYet,
        message: l10n.noSubscriptionsBody,
        actionLabel: l10n.addSubscription,
        onAction: _add,
        fillRemaining: true,
      );
    }

    final items = isInitialLoading ? _placeholders() : state.subscriptions;
    final today = DateTime.now();
    final display = isInitialLoading
        ? SubscriptionsState(subscriptions: items)
        : state;

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
            return MonthlyTotalCard(
              totals: display.monthlyTotals,
              count: items.length,
            );
          }
          final subscription = items[index - 1];
          return SubscriptionTile(
            subscription: subscription,
            today: today,
            onTap: isInitialLoading ? null : () => _edit(subscription),
          );
        },
      ),
    );
  }
}
