import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../category/domain/entities/product_category.dart';
import '../../../category/presentation/widgets/category_ui.dart';


class CategorySelector extends StatelessWidget {
  const CategorySelector({super.key, required this.selected, required this.onChanged});

  final ProductCategory selected;
  final ValueChanged<ProductCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ProductCategory.values.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final category = ProductCategory.values[index];
          final isSelected = category == selected;
          final color = CategoryUi.color(category);

          return InkWell(
            onTap: () => onChanged(category),
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CategoryUi.icon(category),
                    size: 16.sp,
                    color: isSelected ? Colors.white : color,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    CategoryUi.label(category),
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}