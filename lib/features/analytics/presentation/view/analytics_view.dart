import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../products/presentation/cubit/product_state.dart';
import '../widgets/category_break_down_card.dart';
import '../widgets/total_spent_card.dart';
import '../widgets/warranty_status_card.dart';

class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  @override
  void initState() {
    super.initState();
    context.read<ProductsCubit>().getTotalPrice();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<ProductsCubit, ProductsState>(
          builder: (context, state) {
            final refresh = context.read<ProductsCubit>().refresh;
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
                        child: Text(l10n.analytics, style: Theme.of(context).textTheme.headlineMedium),
                      ),
                    ),
                  ),
                  Expanded(
                    child: state.error != null && state.products.isEmpty && !state.isLoading
                        ? AppErrorView(message: state.error, onRetry: refresh, fillRemaining: true)
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                            children: [
                              TotalSpentCard(state: state, l10n: l10n),
                              const SizedBox(height: 16),
                              WarrantyStatusCard(state: state, l10n: l10n),
                              const SizedBox(height: 16),
                              CategoryBreakdownCard(products: state.products, isLoading: state.isLoading, l10n: l10n),
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
