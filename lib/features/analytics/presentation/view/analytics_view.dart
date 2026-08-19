import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/util/app_radius.dart';
import '../../../../core/util/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../category/domain/entities/product_category.dart';
import '../../../category/presentation/widgets/category_ui.dart';
import '../../../products/domain/enties/product_entity.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../products/presentation/cubit/product_state.dart';

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
      backgroundColor: AppColors.white,
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
                    style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
                  ),
                  AppSpacing.h20,
                  _TotalSpentCard(state: state, l10n: l10n),
                  AppSpacing.h20,
                  _WarrantyStatusCard(state: state),
                  AppSpacing.h20,
                  _CategoryBreakdownCard(products: state.products, isLoading: state.isLoading),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TotalSpentCard extends StatelessWidget {
  const _TotalSpentCard({required this.state, required this.l10n});

  final ProductsState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
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

class _WarrantyStatusCard extends StatelessWidget {
  const _WarrantyStatusCard({required this.state});

  final ProductsState state;

  @override
  Widget build(BuildContext context) {
    final total = state.active + state.expiring + state.expired;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.0.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Warranty Status',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          AppSpacing.h20,
          if (state.isLoading && total == 0)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (total == 0)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Text(
                'No products yet',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14.sp),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 110.w,
                  height: 110.w,
                  child: CustomPaint(
                    painter: _DonutChartPainter(
                      segments: [
                        _Segment(state.active.toDouble(), AppColors.success),
                        _Segment(state.expiring.toDouble(), const Color(0xFFF59E0B)),
                        _Segment(state.expired.toDouble(), AppColors.error),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 20.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LegendRow(
                        color: AppColors.success,
                        label: 'Active',
                        value: state.active,
                      ),
                      SizedBox(height: 10.h),
                      _LegendRow(
                        color: const Color(0xFFF59E0B),
                        label: 'Expiring',
                        value: state.expiring,
                      ),
                      SizedBox(height: 10.h),
                      _LegendRow(
                        color: AppColors.error,
                        label: 'Expired',
                        value: state.expired,
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8.w),
        Expanded(child: Text(label, style: TextStyle(fontSize: 14.sp))),
        Text(
          '$value',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _Segment {
  const _Segment(this.value, this.color);

  final double value;
  final Color color;
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({required this.segments});

  final List<_Segment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    final rect = Offset.zero & size;
    final strokeWidth = size.width * 0.19;
    var startAngle = -math.pi / 2;

    for (final segment in segments) {
      if (segment.value <= 0) continue;
      final sweepAngle = (segment.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}

/// Category breakdown card: a legend of categories with their percentage
/// share, plus a filled pie chart. Categories with zero products are
/// omitted from both.
class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard({required this.products, required this.isLoading});

  final List<ProductEntity> products;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final counts = <ProductCategory, int>{};
    for (final product in products) {
      counts[product.category] = (counts[product.category] ?? 0) + 1;
    }

    final total = products.length;

    // Largest share first, so the legend roughly matches the pie's
    // reading order (starting from 12 o'clock, clockwise).
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.0.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Breakdown',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          AppSpacing.h20,
          if (isLoading && total == 0)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (total == 0)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Text(
                'No products yet',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14.sp),
              ),
            )
          else ...[
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  for (final entry in entries)
                    _CategoryLegendChip(
                      category: entry.key,
                      percent: (entry.value / total * 100).round(),
                    ),
                ],
              ),
              AppSpacing.h24,
              Center(
                child: SizedBox(
                  width: 160.w,
                  height: 160.w,
                  child: CustomPaint(
                    painter: _CategoryPiePainter(
                      segments: [
                        for (final entry in entries)
                          _Segment(entry.value.toDouble(), CategoryUi.color(entry.key)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }
}

class _CategoryLegendChip extends StatelessWidget {
  const _CategoryLegendChip({required this.category, required this.percent});

  final ProductCategory category;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final color = CategoryUi.color(category);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 6.w),
          Text(
            CategoryUi.label(category),
            style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700),
          ),
          SizedBox(width: 6.w),
          Text(
            '$percent%',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// A filled pie chart (unlike the donut used for warranty status) — no
/// hole in the middle, matching the Category Breakdown mockup.
class _CategoryPiePainter extends CustomPainter {
  _CategoryPiePainter({required this.segments});

  final List<_Segment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    var startAngle = -math.pi / 2;

    for (final segment in segments) {
      if (segment.value <= 0) continue;
      final sweepAngle = (segment.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryPiePainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}