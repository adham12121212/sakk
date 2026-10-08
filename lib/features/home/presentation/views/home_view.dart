import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/route/app_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/usecase/get_user_usecase.dart';
import '../../../notification/domain/usecase/get_notification_use_case.dart';
import '../../../products/domain/enties/product_entity.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../products/presentation/cubit/product_state.dart';
import '../../../products/presentation/view/product_search_view.dart';
import '../widgets/home_header.dart';
import '../widgets/recent_product_data.dart';
import '../widgets/recent_products_section.dart';
import '../widgets/stat_card.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<ProductsCubit>(),
      child: const _HomeContent(),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  bool _hasUnreadNotifications = false;

  @override
  void initState() {
    super.initState();
    context.read<ProductsCubit>().loadIfNeeded();
    _loadUnreadNotifications();
  }

  Future<void> _loadUnreadNotifications() async {
    final userId = getIt<GetUserUseCase>()()?.id;
    if (userId == null) return;

    final result = await getIt<GetNotificationsUseCase>()(userId);
    if (!mounted) return;

    result.fold(
      (_) {},
      (notifications) {
        final hasUnread = notifications.any((n) => !n.isRead);
        if (hasUnread != _hasUnreadNotifications) {
          setState(() => _hasUnreadNotifications = hasUnread);
        }
      },
    );
  }

  String _resolveDisplayName(BuildContext context) {

    final user = getIt<GetUserUseCase>()();
    final l10n = AppLocalizations.of(context)!;

    final name = user?.name;
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }

    final email = user?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return l10n.guestFallbackName;
  }

  void _openNotifications(BuildContext context) {

    final userId = getIt<GetUserUseCase>()()?.id;
    if (userId == null) return;
    context.push(AppRoutes.notifications, extra: userId);
  }

  List<ProductEntity> _placeholderProducts() {
    final now = DateTime.now();
    return [
      ProductEntity(id: 'p1', name: 'Product name', brand: 'Brand', price: 100,
          purchaseDate: now.subtract(const Duration(days: 30)), warrantyMonths: 24),
      ProductEntity(id: 'p2', name: 'Product name', brand: 'Brand', price: 100,
          purchaseDate: now.subtract(const Duration(days: 300)), warrantyMonths: 12),
      ProductEntity(id: 'p3', name: 'Product name', brand: 'Brand', price: 100,
          purchaseDate: now.subtract(const Duration(days: 600)), warrantyMonths: 12),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<ProductsCubit, ProductsState>(
          builder: (context, state) {
            final isInitialLoading = state.isLoading && state.products.isEmpty;
            final displayProducts = isInitialLoading ? _placeholderProducts() : state.products;
            final displayState = isInitialLoading ? ProductsState(products: displayProducts) : state;

            final sourceProducts = displayProducts.take(5).toList();
            final recentProducts = sourceProducts.map(RecentProductData.fromEntity).toList();

            return RefreshIndicator(
              onRefresh: () => context.read<ProductsCubit>().refresh(),
              color: AppColors.primary,
                      child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeHeader(
                      userName: _resolveDisplayName(context),
                      avatarUrl: getIt<GetUserUseCase>()()?.avatarUrl,
                      hasUnreadNotifications: _hasUnreadNotifications,
                      expiringSoonCount: state.expiring,
                      onSearchTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<ProductsCubit>(),
                              child: const ProductSearchView(),
                            ),
                          ),
                        );
                      },
                      onNotificationTap: () => _openNotifications(context),
                    onAvatarTap: () => context.push(AppRoutes.profile),
                      onExpiringBannerTap: () {},
                    ),
                    SizedBox(height: 16.h),

                    if (state.error != null && state.products.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
                        child: Column(
                          children: [
                            Text(
                              state.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            SizedBox(height: 12.h),
                            OutlinedButton(
                              onPressed: () => context.read<ProductsCubit>().refresh(),
                              child:  Text(l10n.retry),
                            ),
                          ],
                        ),
                      )
                    else
                      Skeletonizer(
                        enabled: isInitialLoading,
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              child: GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 16.w,
                                mainAxisSpacing: 16.h,
                                childAspectRatio: 1.25,
                                children: [
                                  _card(
                                    StatCard(
                                      value: '${displayState.total}',
                                      label:  l10n.totalProducts,
                                      icon: Icons.inventory_2_outlined,
                                      iconColor: AppColors.primary,
                                      iconBackgroundColor: AppColors.primary.withOpacity(0.1),
                                    ),
                                  ),
                                  _card(
                                    StatCard(
                                      value: '${displayState.active}',
                                      label: l10n.activeWarranties,
                                      icon: Icons.shield_outlined,
                                      iconColor: AppColors.success,
                                      iconBackgroundColor: AppColors.success.withOpacity(0.1),
                                    ),
                                  ),
                                  _card(
                                    StatCard(
                                      value: '${displayState.expiring}',
                                      label: l10n.expiringSoon,
                                      icon: Icons.warning_amber_rounded,
                                      iconColor: const Color(0xFFF59E0B),
                                      iconBackgroundColor: const Color(0xFFFEF3C7),
                                    ),
                                  ),
                                  _card(
                                    StatCard(
                                      value: '${displayState.expired}',
                                      label: l10n.expired,
                                      icon: Icons.error_outline_rounded,
                                      iconColor: AppColors.error,
                                      iconBackgroundColor: AppColors.error.withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24.h),
                            RecentProductsSection(
                              items: recentProducts,
                              onSeeAllTap: isInitialLoading ? null : () {
                                context.go(AppRoutes.products);
                              },
                              onItemTap: isInitialLoading ? null : (index) {
                                context.push(AppRoutes.details, extra: sourceProducts[index]);
                              },
                            ),
                            SizedBox(height: 24.h),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _card(Widget child) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
    decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(1),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.09),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}
