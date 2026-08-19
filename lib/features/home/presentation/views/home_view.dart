import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/route/app_router.dart';
import '../../../auth/domain/usecase/get_user_usecase.dart';

import '../../../details/presentation/views/details_view.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../products/presentation/cubit/product_state.dart';
import '../../../products/presentation/view/product_search_view.dart';
import '../widgets/circle_icon_button.dart';
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
  @override
  void initState() {
    super.initState();
    context.read<ProductsCubit>().loadIfNeeded();
  }

  String _resolveDisplayName() {
    final user = getIt<GetUserUseCase>()();

    final name = user?.name;
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }

    final email = user?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'there';
  }

  void _openNotifications(BuildContext context) {

    final userId = getIt<GetUserUseCase>()()?.id;
    if (userId == null) return;
    context.push(AppRoutes.notifications, extra: userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<ProductsCubit, ProductsState>(
          builder: (context, state) {
            final sourceProducts = state.products.take(5).toList();
            final recentProducts =
            sourceProducts.map(RecentProductData.fromEntity).toList();

            return RefreshIndicator(
              onRefresh: () => context.read<ProductsCubit>().refresh(),
              color: AppColors.primary,
              backgroundColor: AppColors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeHeader(
                      userName: _resolveDisplayName(),
                      hasUnreadNotifications: true,
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

                    if (state.isLoading && state.products.isEmpty)
                      SizedBox(
                        height: 200.h,
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    else if (state.error != null && state.products.isEmpty)
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
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    else ...[
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
                                  value: '${state.total}',
                                  label: 'Total Products',
                                  icon: Icons.inventory_2_outlined,
                                  iconColor: AppColors.primary,
                                  iconBackgroundColor: AppColors.primary.withOpacity(0.1),
                                ),
                              ),
                              _card(
                                StatCard(
                                  value: '${state.active}',
                                  label: 'Active Warranties',
                                  icon: Icons.shield_outlined,
                                  iconColor: AppColors.success,
                                  iconBackgroundColor: AppColors.success.withOpacity(0.1),
                                ),
                              ),
                              _card(
                                StatCard(
                                  value: '${state.expiring}',
                                  label: 'Expiring Soon',
                                  icon: Icons.warning_amber_rounded,
                                  iconColor: const Color(0xFFF59E0B),
                                  iconBackgroundColor: const Color(0xFFFEF3C7),
                                ),
                              ),
                              _card(
                                StatCard(
                                  value: '${state.expired}',
                                  label: 'Expired',
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
                          onSeeAllTap: () {
                            context.go(AppRoutes.products);
                          },
                          onItemTap: (index) {
                            context.push(AppRoutes.details, extra: sourceProducts[index]);
                          },
                        ),
                        SizedBox(height: 24.h),
                      ],
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}