import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constant/app_colors.dart';

import '../../../products/presentation/cubit/product_cubit.dart';
import '../../domain/entities/product_category.dart';
import '../widgets/category_ui.dart';


class CategoriesView extends StatelessWidget {
  const CategoriesView({super.key, this.currentCategory});

  final ProductCategory? currentCategory;

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsCubit>().state.products;

    final counts = <ProductCategory, int>{
      for (final category in ProductCategory.values) category: 0,
    };
    for (final product in products) {
      counts[product.category] = (counts[product.category] ?? 0) + 1;
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 8.h, 20.w, 8.h),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Categories',
                    style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(20.w),
                itemCount: ProductCategory.values.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (context, index) {
                  final category = ProductCategory.values[index];
                  final count = counts[category] ?? 0;
                  final isSelected = category == currentCategory;

                  return _CategoryCard(
                    category: category,
                    count: count,
                    isSelected: isSelected,
                    onTap: () => Navigator.of(context).pop(category),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
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
    final color = CategoryUi.color(category);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
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
              CategoryUi.label(category),
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            Text(
              '$count ${count == 1 ? 'product' : 'products'}',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}