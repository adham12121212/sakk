import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sakk/features/products/presentation/view/product_search_view.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/route/app_router.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../category/domain/entities/product_category.dart';
import '../../../category/presentation/widgets/category_ui.dart';
import '../../../home/presentation/widgets/circle_icon_button.dart';
import '../../domain/entities/product_entity.dart';
import '../cubit/product_cubit.dart';
import '../cubit/product_state.dart';
import '../util/products_csv_export.dart';
import '../widgets/product_list_card.dart';
import '../../../../core/theme/app_icons.dart';

/// Every product in one list, newest first, with a row of category chips
/// to narrow it down.
class ProductsView extends StatefulWidget {
  const ProductsView({super.key});

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  /// Null shows every category.
  ProductCategory? _category;

  @override
  void initState() {
    super.initState();
    context.read<ProductsCubit>().loadIfNeeded();
  }

  /// Shares every product as a CSV file, not just the current category.
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
    return List.generate(
      5,
      (i) => ProductEntity(
        id: 'placeholder-$i',
        name: 'Product name',
        brand: 'Brand',
        price: 100,
        purchaseDate: now.subtract(const Duration(days: 60)),
        warrantyMonths: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<ProductsCubit, ProductsState>(
          builder: (context, state) {
            final shown = _category == null
                ? state.products
                : state.products.where((p) => p.category == _category).toList();
            // Only the categories the user has, so no chip leads nowhere.
            final categories = [
              for (final c in ProductCategory.values)
                if (state.products.any((p) => p.category == c)) c,
            ];
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
                          icon: AppIcons.share,
                          semanticLabel: l10n.exportProducts,
                          onTap: () => _export(state.products),
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ],
                    ),
                  ),
                  if (categories.length > 1) ...[
                    SizedBox(height: 14.h),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        children: [
                          _CategoryChip(
                            label: l10n.all,
                            selected: _category == null,
                            onTap: () => setState(() => _category = null),
                          ),
                          for (final c in categories) ...[
                            SizedBox(width: 8.w),
                            _CategoryChip(
                              label: CategoryUi.label(context, c),
                              icon: CategoryUi.icon(c),
                              color: CategoryUi.color(c),
                              selected: _category == c,
                              onTap: () => setState(() => _category = c),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 8.h),
                  Expanded(child: _buildBody(context, state, shown)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProductsState state,
    List<ProductEntity> shown,
  ) {
    final l10n = AppLocalizations.of(context)!;

    final isInitialLoading = state.isLoading && state.products.isEmpty;
    if (isInitialLoading) {
      final placeholders = _placeholderProducts();
      return Skeletonizer(
        enabled: true,
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
          itemCount: placeholders.length,
          separatorBuilder: (_, _) => SizedBox(height: 12.h),
          itemBuilder: (context, index) =>
              ProductListCard(product: placeholders[index]),
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

    if (shown.isEmpty) {
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
      itemCount: shown.length,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final product = shown[index];
        return ProductListCard(
          product: product,
          onTap: () => _openProductDetails(product),
        );
      },
    );
  }
}

/// A category to show, or All: filled in its colour once picked.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  /// The category's colour; the brand colour for All.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = this.color ?? AppColors.primary;
    final foreground = selected ? Colors.white : colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? color : colorScheme.surface,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? color : colorScheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: selected ? Colors.white : color),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
