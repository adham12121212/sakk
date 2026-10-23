import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../domain/entities/product_category.dart';
import '../widgets/category_card.dart';
import '../../../../core/theme/app_icons.dart';

class CategoriesView extends StatelessWidget {
  const CategoriesView({super.key, this.currentCategory});

  final ProductCategory? currentCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final products = context.watch<ProductsCubit>().state.products;

    final counts = <ProductCategory, int>{
      for (final category in ProductCategory.values) category: 0,
    };
    for (final product in products) {
      counts[product.category] = (counts[product.category] ?? 0) + 1;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 8.h, 20.w, 8.h),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(AppIcons.back),
                    tooltip: l10n.back,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    l10n.categories,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(20.w),
                itemCount: ProductCategory.values.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                  // Fixed height, not an aspect ratio: long Arabic names or
                  // large text can't overflow the card.
                  mainAxisExtent: 148,
                ),
                itemBuilder: (context, index) {
                  final category = ProductCategory.values[index];
                  final count = counts[category] ?? 0;
                  final isSelected = category == currentCategory;

                  return CategoryCard(
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
