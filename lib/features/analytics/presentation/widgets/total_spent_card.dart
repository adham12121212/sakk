import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/util/app_radius.dart';
import '../../../../core/util/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/presentation/cubit/product_state.dart';

class TotalSpentCard extends StatelessWidget {
  const TotalSpentCard({required this.state, required this.l10n});

  final ProductsState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final formatted = state.totalPrice.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.0.w),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: colorScheme.outline.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ]
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.totalSpant,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.white.withOpacity(0.8),
            ),
          ),
          AppSpacing.h12,
          if (state.error != null && !state.isLoading)
            Text(
              state.error!,
              style: TextStyle(fontSize: 14.sp, color: AppColors.white),
            )
          else
            Text(
              state.isLoading ? '...' : 'EGP $formatted',
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
        ],
      ),
    );
  }
}
