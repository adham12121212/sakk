import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/util/app_spacing.dart';
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
        child: BlocBuilder<ProductsCubit, ProductsState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(16.0.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.analytics,
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                  ),
                  AppSpacing.h20,
                  TotalSpentCard(state: state, l10n: l10n),
                  AppSpacing.h20,
                  WarrantyStatusCard(state: state, l10n: l10n),
                  AppSpacing.h20,
                  CategoryBreakdownCard(products: state.products, isLoading: state.isLoading, l10n: l10n),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}







