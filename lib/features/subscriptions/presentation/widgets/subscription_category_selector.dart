import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entities/subscription_category.dart';
import '../util/subscription_category_ui.dart';

/// Horizontal category chips, styled like the product CategorySelector.
class SubscriptionCategorySelector extends StatelessWidget {
  const SubscriptionCategorySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final SubscriptionCategory selected;
  final ValueChanged<SubscriptionCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: SubscriptionCategory.values.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final category = SubscriptionCategory.values[index];
          final isSelected = category == selected;
          final color = SubscriptionCategoryUi.color(category);
          final label = SubscriptionCategoryUi.label(context, category);

          return Semantics(
            button: true,
            selected: isSelected,
            label: label,
            excludeSemantics: true,
            child: InkWell(
              onTap: () => onChanged(category),
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      SubscriptionCategoryUi.icon(category),
                      size: 16.sp,
                      color: isSelected ? Colors.white : color,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
