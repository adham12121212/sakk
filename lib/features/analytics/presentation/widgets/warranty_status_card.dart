import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakk/features/analytics/presentation/widgets/segment.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/util/app_radius.dart';
import '../../../../core/util/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/presentation/cubit/product_state.dart';
import 'donut_chart_painter.dart';
import 'legend_row.dart';

class WarrantyStatusCard extends StatelessWidget {
  const WarrantyStatusCard({required this.state, required this.l10n});

  final ProductsState state;
  final AppLocalizations l10n;


  @override
  Widget build(BuildContext context) {
    final isInitialLoading = state.isLoading && state.products.isEmpty;
    // Fake but plausible proportions purely so the donut has a shape to
    // skeletonize — never shown as real data.
    final active = isInitialLoading ? 2 : state.active;
    final expiring = isInitialLoading ? 1 : state.expiring;
    final expired = isInitialLoading ? 1 : state.expired;
    final total = active + expiring + expired;
    final colorScheme = Theme.of(context).colorScheme;


    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.0.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: colorScheme.outline.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.warrantyStatus,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          AppSpacing.h20,
          if (total == 0)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Text(
                l10n.noProductsYet,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14.sp),
              ),
            )
          else
            Skeletonizer(
              enabled: isInitialLoading,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 110.w,
                    height: 110.w,
                    child: Skeleton.leaf(
                      child: CustomPaint(
                        painter: DonutChartPainter(
                          segments: [
                            Segment(active.toDouble(), AppColors.success),
                            Segment(expiring.toDouble(), const Color(0xFFF59E0B)),
                            Segment(expired.toDouble(), AppColors.error),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LegendRow(
                          color: AppColors.success,
                          label: l10n.active,
                          value: active,
                        ),
                        SizedBox(height: 10.h),
                        LegendRow(
                          color: const Color(0xFFF59E0B),
                          label: l10n.expiring,
                          value: expiring,
                        ),
                        SizedBox(height: 10.h),
                        LegendRow(
                          color: AppColors.error,
                          label: l10n.expired,
                          value: expired,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
