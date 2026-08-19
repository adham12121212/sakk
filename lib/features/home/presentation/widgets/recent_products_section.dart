import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakk/features/home/presentation/widgets/recent_product_data.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/util/app_sizes.dart';

class RecentProductsSection extends StatelessWidget {
  const RecentProductsSection({
    super.key,
    required this.items,
    this.onSeeAllTap,
    this.onItemTap,
  });

  final List<RecentProductData> items;
  final VoidCallback? onSeeAllTap;
  final ValueChanged<int>? onItemTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Products',
                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: onSeeAllTap,
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (items.isEmpty)
            _EmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) => RecentProductTile(
                data: items[index],
                onTap: onItemTap == null ? null : () => onItemTap!(index),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 32.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 32.sp, color: Colors.grey.shade400),
          SizedBox(height: 8.h),
          Text(
            'No products yet',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}