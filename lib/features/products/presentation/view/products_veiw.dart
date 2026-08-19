import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sakk/features/products/presentation/view/product_search_view.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/route/app_router.dart';
import '../../../category/domain/entities/product_category.dart';
import '../../../category/presentation/views/category_view.dart';
import '../../../category/presentation/widgets/category_ui.dart';
import '../../../details/presentation/views/details_view.dart';
import '../../../home/presentation/widgets/circle_icon_button.dart';
import '../../../home/presentation/widgets/recent_product_data.dart';
import '../../domain/enties/product_entity.dart';
import '../cubit/product_cubit.dart';
import '../cubit/product_state.dart';

enum _ProductFilter { all, active, expiring, expired }



class ProductsView extends StatefulWidget {
  const ProductsView({super.key});

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  _ProductFilter _filter = _ProductFilter.all;
  ProductCategory? _categoryFilter;

  @override
  void initState() {
    super.initState();
    context.read<ProductsCubit>().loadIfNeeded();
  }

  List<ProductEntity> _applyFilter(List<ProductEntity> products) {
    var result = switch (_filter) {
      _ProductFilter.all => products,
      _ProductFilter.active =>
          products.where((p) => p.status == WarrantyStatus.active).toList(),
      _ProductFilter.expiring =>
          products.where((p) => p.status == WarrantyStatus.expiring).toList(),
      _ProductFilter.expired =>
          products.where((p) => p.status == WarrantyStatus.expired).toList(),
    };

    if (_categoryFilter != null) {
      result = result.where((p) => p.category == _categoryFilter).toList();
    }

    return result;
  }

  Future<void> _openCategoryFilter() async {
    final selected = await Navigator.of(context).push<ProductCategory?>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ProductsCubit>(),
          child: CategoriesView(currentCategory: _categoryFilter),
        ),
      ),
    );

    setState(() => _categoryFilter = selected);
  }

  void _openProductDetails(ProductEntity product) {
    context.push(AppRoutes.details, extra: product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<ProductsCubit, ProductsState>(
          builder: (context, state) {
            final filtered = _applyFilter(state.products);

            return RefreshIndicator(
              onRefresh: () => context.read<ProductsCubit>().refresh(),
              color: AppColors.primary,
              backgroundColor: AppColors.white,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'My Products',
                            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
                          ),
                        ),
                        CircleIconButton(icon: Icons.search_rounded, onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<ProductsCubit>(),
                                child: const ProductSearchView(),
                              ),
                            ),
                          );
                        }),
                        SizedBox(width: 8.w),
                        CircleIconButton(
                          icon: Icons.filter_alt_rounded,
                          onTap: _openCategoryFilter,
                          showBadge: _categoryFilter != null,
                        ),
                        SizedBox(width: 8.w),
                        CircleIconButton(icon: Icons.grid_view_rounded, onTap: () {}),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    height: 40.h,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _filter == _ProductFilter.all,
                          onTap: () => setState(() => _filter = _ProductFilter.all),
                        ),
                        SizedBox(width: 8.w),
                        _FilterChip(
                          label: 'Active',
                          selected: _filter == _ProductFilter.active,
                          onTap: () => setState(() => _filter = _ProductFilter.active),
                        ),
                        SizedBox(width: 8.w),
                        _FilterChip(
                          label: 'Expiring',
                          selected: _filter == _ProductFilter.expiring,
                          onTap: () => setState(() => _filter = _ProductFilter.expiring),
                        ),
                        SizedBox(width: 8.w),
                        _FilterChip(
                          label: 'Expired',
                          selected: _filter == _ProductFilter.expired,
                          onTap: () => setState(() => _filter = _ProductFilter.expired),
                        ),
                      ],
                    ),
                  ),
                  if (_categoryFilter != null) ...[
                    SizedBox(height: 10.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _ActiveCategoryChip(
                          category: _categoryFilter!,
                          onClear: () => setState(() => _categoryFilter = null),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 12.h),
                  Divider(height: 1, color: Colors.grey.shade200),
                  Expanded(child: _buildBody(state, filtered)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(ProductsState state, List<ProductEntity> filtered) {
    if (state.isLoading && state.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.products.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              SizedBox(height: 12.h),
              OutlinedButton(
                onPressed: () => context.read<ProductsCubit>().refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          state.products.isEmpty ? 'No products yet' : 'Nothing in this filter',
          style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final product = filtered[index];
        return RecentProductTile(
          data: RecentProductData.fromEntity(product),
          onTap: () => _openProductDetails(product),
        );
      },
    );
  }

}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : AppColors.black.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

class _ActiveCategoryChip extends StatelessWidget {
  const _ActiveCategoryChip({required this.category, required this.onClear});

  final ProductCategory category;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final color = CategoryUi.color(category);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CategoryUi.icon(category), size: 14.sp, color: color),
          SizedBox(width: 6.w),
          Text(
            CategoryUi.label(category),
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: color),
          ),
          SizedBox(width: 6.w),
          InkWell(
            onTap: onClear,
            child: Icon(Icons.close_rounded, size: 14.sp, color: color),
          ),
        ],
      ),
    );
  }
}