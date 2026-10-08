
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakk/features/analytics/presentation/widgets/segment.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/util/app_radius.dart';
import '../../../../core/util/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../category/domain/entities/product_category.dart';
import '../../../category/presentation/widgets/category_ui.dart';
import '../../../products/domain/enties/product_entity.dart';
import 'category_legend_chip.dart';
import 'category_pie_painter.dart';

class CategoryBreakdownCard extends StatelessWidget {
  const CategoryBreakdownCard({required this.products, required this.isLoading, required this.l10n});

  final List<ProductEntity> products;
  final bool isLoading;
  final AppLocalizations l10n;



  @override
  Widget build(BuildContext context) {
    final isInitialLoading = isLoading && products.isEmpty;
    final colorScheme = Theme.of(context).colorScheme;

    final Map<ProductCategory, int> counts;
    final int total;
    if (isInitialLoading) {
      counts = {ProductCategory.electronics: 2, ProductCategory.furniture: 1};
      total = 3;
    } else {
      counts = <ProductCategory, int>{};
      for (final product in products) {
        counts[product.category] = (counts[product.category] ?? 0) + 1;
      }
      total = products.length;
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
            l10n.categoryBreakdown,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          AppSpacing.h20,
          if (!isInitialLoading && total == 0)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Text(
                l10n.noProductsYet,
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 14.sp),
              ),
            )
          else
            Skeletonizer(
              enabled: isInitialLoading,
              child: Column(
                children: [
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      for (final entry in entries)
                        CategoryLegendChip(
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
                      child: Skeleton.leaf(
                        child: CustomPaint(
                          painter: CategoryPiePainter(
                            segments: [
                              for (final entry in entries)
                                Segment(entry.value.toDouble(), CategoryUi.color(entry.key)),
                            ],
                          ),
                        ),
                      ),
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
