import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sakk/features/products/presentation/view/product_search_view.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/route/app_router.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../category/domain/entities/product_category.dart';
import '../../../category/presentation/views/category_view.dart';
import '../../../category/presentation/widgets/category_ui.dart';
import '../../../home/presentation/widgets/circle_icon_button.dart';
import '../../../home/presentation/widgets/recent_product_data.dart';
import '../../domain/entities/product_entity.dart';
import '../cubit/product_cubit.dart';
import '../cubit/product_state.dart';
import '../util/products_csv_export.dart';
import '../../../../core/theme/app_icons.dart';

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

    // Back/swipe-back pops with null: keep the current filter. Picking a
    // category sets it; the chip's ✕ is how a filter gets cleared.
    if (selected == null || !mounted) return;
    setState(() => _categoryFilter = selected);
  }

  /// Shares every product as a CSV file, not just the current filter.
  Future<void> _export(List<ProductEntity> products) async {
    final l10n = AppLocalizations.of(context)!;
    if (products.isEmpty) {
      AppSnackBar.error(context, l10n.noProductsYet);
      return;
    }
    try {
      await shareProductsCsv(context, products);
    } catch (_) {
      if (mounted) AppSnackBar.error(context, l10n.couldNotShare);
    }
  }

  void _openProductDetails(ProductEntity product) {
    context.push(AppRoutes.details, extra: product);
  }

  // Same placeholder-shape idea as home_view.dart — this is never shown
  // as real data, Skeletonizer paints shimmer bones over it.
  List<ProductEntity> _placeholderProducts() {
    final now = DateTime.now();
    return List.generate(5, (i) => ProductEntity(
      id: 'placeholder-$i',
      name: 'Product name',
      brand: 'Brand',
      price: 100,
      purchaseDate: now.subtract(const Duration(days: 60)),
      warrantyMonths: 12,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<ProductsCubit, ProductsState>(
          builder: (context, state) {
            final filtered = _applyFilter(state.products);
            return AppRefreshIndicator(
              onRefresh: () => context.read<ProductsCubit>().refresh(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.myProducts,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        CircleIconButton(
                            icon: AppIcons.search,
                            semanticLabel: l10n.search,
                            onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<ProductsCubit>(),
                                child: const ProductSearchView(),
                              ),
                            ),
                          );
                        },
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 4),
                        CircleIconButton(
                          icon: AppIcons.filter,
                          semanticLabel: l10n.filterByCategory,
                          onTap: _openCategoryFilter,
                          showBadge: _categoryFilter != null,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 4),
                        CircleIconButton(
                          icon: AppIcons.share,
                          semanticLabel: l10n.exportProducts,
                          onTap: () => _export(state.products),
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      children: [
                        _FilterChip(
                          label: l10n.all,
                          selected: _filter == _ProductFilter.all,
                          onTap: () => setState(() => _filter = _ProductFilter.all),
                        ),
                        SizedBox(width: 8.w),
                        _FilterChip(
                          label: l10n.active,
                          selected: _filter == _ProductFilter.active,
                          onTap: () => setState(() => _filter = _ProductFilter.active),
                        ),
                        SizedBox(width: 8.w),
                        _FilterChip(
                          label: l10n.expiring,
                          selected: _filter == _ProductFilter.expiring,
                          onTap: () => setState(() => _filter = _ProductFilter.expiring),
                        ),
                        SizedBox(width: 8.w),
                        _FilterChip(
                          label: l10n.expired,
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
                  Expanded(child: _buildBody(context, state, filtered)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProductsState state, List<ProductEntity> filtered) {
    final l10n = AppLocalizations.of(context)!;

    final isInitialLoading = state.isLoading && state.products.isEmpty;
    if (isInitialLoading) {
      final placeholders = _placeholderProducts()
          .map(RecentProductData.fromEntity)
          .toList();
      return Skeletonizer(
        enabled: true,
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
          itemCount: placeholders.length,
          separatorBuilder: (_, _) => SizedBox(height: 12.h),
          itemBuilder: (context, index) => RecentProductTile(data: placeholders[index]),
        ),
      );
    }

    if (state.error != null && state.products.isEmpty) {
      return AppErrorView(
        message: state.error,
        onRetry: () => context.read<ProductsCubit>().refresh(),
        fillRemaining: true,
      );
    }

    if (filtered.isEmpty) {
      final noProducts = state.products.isEmpty;
      return AppEmptyView(
        icon: noProducts ? AppIcons.products : AppIcons.filterEmpty,
        title: noProducts ? l10n.noProductsYet : l10n.nothingInThisFilter,
        actionLabel: noProducts ? l10n.scanReceiptTitle : null,
        actionIcon: AppIcons.scan,
        onAction: noProducts ? () => context.push(AppRoutes.scan) : null,
        fillRemaining: true,
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.primary : colorScheme.surface,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? AppColors.primary : colorScheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : colorScheme.onSurfaceVariant,
              ),
            ),
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
    final label = CategoryUi.label(context, category);

    // The whole chip clears the filter. The pill keeps its compact look; the
    // tap area around it is at least 48px tall.
    return Semantics(
      button: true,
      label: '${AppLocalizations.of(context)!.clearCategoryFilter}: $label',
      excludeSemantics: true,
      child: InkWell(
        onTap: onClear,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CategoryUi.icon(category), size: 14.sp, color: color),
                  SizedBox(width: 6.w),
                  Text(
                    label,
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: color),
                  ),
                  SizedBox(width: 6.w),
                  Icon(AppIcons.close, size: 14.sp, color: color),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
