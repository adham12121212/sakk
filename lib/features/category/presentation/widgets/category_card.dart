

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/product_category.dart';
import 'category_ui.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    required this.category,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final ProductCategory category;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = CategoryUi.color(category);
    final colorScheme = Theme.of(context).colorScheme;


    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? color : colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.03),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(CategoryUi.icon(category), color: color, size: 22.sp),
            ),
            const Spacer(),
            Text(
              CategoryUi.label(context,category),
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            Text(
              '$count ${count == 1 ? l10n.product: l10n.products}',
              style: TextStyle(fontSize: 13.sp, color: colorScheme.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }
}