


import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../category/domain/entities/product_category.dart';
import '../../../category/presentation/widgets/category_ui.dart';

class CategoryLegendChip extends StatelessWidget {
  const CategoryLegendChip({required this.category, required this.percent});

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
            CategoryUi.label(context,category),
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
