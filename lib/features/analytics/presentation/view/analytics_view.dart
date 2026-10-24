import 'package:flutter/material.dart';
import '../../../../core/widgets/section_header.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/get_it.dart';
import '../../../../core/route/app_router.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/usecase/get_user_usecase.dart';
import '../../../auth/presentation/widgets/segmented_toggle.dart';
import '../../../household/presentation/cubit/household_cubit.dart';
import '../../../installments/presentation/cubit/installments_cubit.dart';
import '../../../installments/presentation/cubit/installments_state.dart';
import '../../../installments/presentation/widgets/installments_analytics_card.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../products/presentation/cubit/product_state.dart';
import '../../../subscriptions/presentation/cubit/subscriptions_cubit.dart';
import '../../../subscriptions/presentation/cubit/subscriptions_state.dart';
import '../../../subscriptions/presentation/widgets/subscriptions_analytics_card.dart';
import '../../domain/spending_insights.dart';
import '../widgets/category_break_down_card.dart';
import '../widgets/spending_insights_card.dart';
import '../widgets/total_spent_card.dart';
import '../widgets/warranty_status_card.dart';

class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  /// In a household: only my products (default) or everyone's.
  bool _householdScope = false;
  final _subscriptionsCubit = getIt<SubscriptionsCubit>();
  final _installmentsCubit = getIt<InstallmentsCubit>();

  @override
  void initState() {
    super.initState();
    context.read<ProductsCubit>().getTotalPrice();
    _subscriptionsCubit.loadIfNeeded();
    _installmentsCubit.loadIfNeeded();
  }

  Future<void> _refresh() => Future.wait([
    context.read<ProductsCubit>().refresh(),
    _subscriptionsCubit.refresh(),
    _installmentsCubit.refresh(),
  ]);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<ProductsCubit, ProductsState>(
          builder: (context, allState) {
            final refresh = _refresh;
            final myId = getIt<GetUserUseCase>()()?.id;
            final inHousehold =
                getIt<HouseholdCubit>().state.members.length > 1;
            // Family sharing shows members' products everywhere; totals here
            // are your own unless you choose the whole household.
            final state = inHousehold && _householdScope
                ? allState
                : allState.copyWith(
                    products: allState.products
                        .where((p) => p.isOwnedBy(myId))
                        .toList(),
                  );
            return AppRefreshIndicator(
              onRefresh: refresh,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: SizedBox(
                      height: 48,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          l10n.analytics,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child:
                        state.error != null &&
                            state.products.isEmpty &&
                            !state.isLoading
                        ? AppErrorView(
                            message: state.error,
                            onRetry: refresh,
                            fillRemaining: true,
                          )
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                            children: [
                              if (inHousehold) ...[
                                SegmentedToggle<bool>(
                                  options: {
                                    false: l10n.analyticsMine,
                                    true: l10n.analyticsHousehold,
                                  },
                                  selected: _householdScope,
                                  onChanged: (v) =>
                                      setState(() => _householdScope = v),
                                ),
                                const SizedBox(height: 16),
                              ],
                              SectionHeader(title: l10n.products),
                              const SizedBox(height: 4),
                              // One empty state instead of a stack of
                              // empty cards.
                              if (state.products.isEmpty && !state.isLoading)
                                AppCard(
                                  child: Center(
                                    child: AppEmptyView(
                                      icon: AppIcons.analytics,
                                      title: l10n.analyticsEmptyTitle,
                                      message: l10n.analyticsEmptyMessage,
                                      actionLabel: l10n.scanReceiptTitle,
                                      actionIcon: AppIcons.scan,
                                      onAction: () =>
                                          context.push(AppRoutes.scan),
                                    ),
                                  ),
                                )
                              else ...[
                                TotalSpentCard(state: state, l10n: l10n),
                                const SizedBox(height: 16),
                                WarrantyStatusCard(state: state, l10n: l10n),
                                const SizedBox(height: 16),
                                CategoryBreakdownCard(
                                  products: state.products,
                                  isLoading: state.isLoading,
                                  l10n: l10n,
                                ),
                                // Products without prices have no insights.
                                if (spendingByYear(
                                  state.products,
                                ).isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  SectionHeader(title: l10n.analyticsInsights),
                                  const SizedBox(height: 4),
                                  SpendingInsightsCard(
                                    products: state.products,
                                    l10n: l10n,
                                  ),
                                ],
                              ],
                              // Subscriptions and installments are private, so only in "Mine".
                              if (!(inHousehold && _householdScope)) ...[
                                const SizedBox(height: 24),
                                SectionHeader(title: l10n.analyticsMoney),
                                const SizedBox(height: 4),
                                BlocBuilder<
                                  SubscriptionsCubit,
                                  SubscriptionsState
                                >(
                                  bloc: _subscriptionsCubit,
                                  builder: (context, subscriptions) =>
                                      SubscriptionsAnalyticsCard(
                                        state: subscriptions,
                                        onTap: () => context.push(
                                          AppRoutes.subscriptions,
                                        ),
                                      ),
                                ),
                                const SizedBox(height: 16),
                                BlocBuilder<
                                  InstallmentsCubit,
                                  InstallmentsState
                                >(
                                  bloc: _installmentsCubit,
                                  builder: (context, installments) =>
                                      InstallmentsAnalyticsCard(
                                        state: installments,
                                        onTap: () => context.push(
                                          AppRoutes.installments,
                                        ),
                                      ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
