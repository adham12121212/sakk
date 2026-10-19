import 'package:flutter/material.dart';
import '../../../household/presentation/cubit/household_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/route/app_router.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/util/localized_number.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/usecase/get_user_usecase.dart';
import '../../../notification/presentation/cubit/notification_cubit.dart';
import '../../../notification/presentation/cubit/notification_state.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../products/presentation/cubit/product_state.dart';
import '../../../products/presentation/view/product_search_view.dart';
import '../../../installments/presentation/cubit/installments_cubit.dart';
import '../../../installments/presentation/widgets/installments_home_card.dart';
import '../../../subscriptions/presentation/cubit/subscriptions_cubit.dart';
import '../../../subscriptions/presentation/widgets/subscriptions_home_card.dart';
import '../widgets/home_header.dart';
import '../widgets/recent_product_data.dart';
import '../widgets/recent_products_section.dart';
import '../widgets/stat_card.dart';
import '../../../../core/theme/app_icons.dart';

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
  final _notificationCubit = getIt<NotificationCubit>();
  final _subscriptionsCubit = getIt<SubscriptionsCubit>();
  final _installmentsCubit = getIt<InstallmentsCubit>();

  @override
  void initState() {
    super.initState();
    context.read<ProductsCubit>().loadIfNeeded();
    _subscriptionsCubit.loadIfNeeded();
    _installmentsCubit.loadIfNeeded();
    // Member names for "Added by ..." on shared products.
    getIt<HouseholdCubit>().load();
    final userId = getIt<GetUserUseCase>()()?.id;
    if (userId != null) {
      _notificationCubit
        ..watch(userId)
        ..refresh();
    }
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
      ProductEntity(
        id: 'p1',
        name: 'Product name',
        brand: 'Brand',
        price: 100,
        purchaseDate: now.subtract(const Duration(days: 30)),
        warrantyMonths: 24,
      ),
      ProductEntity(
        id: 'p2',
        name: 'Product name',
        brand: 'Brand',
        price: 100,
        purchaseDate: now.subtract(const Duration(days: 300)),
        warrantyMonths: 12,
      ),
      ProductEntity(
        id: 'p3',
        name: 'Product name',
        brand: 'Brand',
        price: 100,
        purchaseDate: now.subtract(const Duration(days: 600)),
        warrantyMonths: 12,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final palette = context.palette;
    final locale = Localizations.localeOf(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<ProductsCubit, ProductsState>(
          builder: (context, state) {
            final isInitialLoading = state.isLoading && state.products.isEmpty;
            final displayProducts = isInitialLoading
                ? _placeholderProducts()
                : state.products;
            final displayState = isInitialLoading
                ? ProductsState(products: displayProducts)
                : state;

            final sourceProducts = displayProducts.take(5).toList();
            final recentProducts = sourceProducts
                .map(RecentProductData.fromEntity)
                .toList();

            return AppRefreshIndicator(
              onRefresh: () => Future.wait([
                context.read<ProductsCubit>().refresh(),
                _notificationCubit.refresh(),
                _subscriptionsCubit.refresh(),
                _installmentsCubit.refresh(),
              ]),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocBuilder<NotificationCubit, NotificationState>(
                      bloc: _notificationCubit,
                      builder: (context, _) => HomeHeader(
                        userName: _resolveDisplayName(context),
                        avatarUrl: getIt<GetUserUseCase>()()?.avatarUrl,
                        unreadNotificationCount: _notificationCubit.unreadCount,
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
                        onExpiringBannerTap: () =>
                            context.go(AppRoutes.products),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    if (state.error != null && state.products.isEmpty)
                      AppErrorView(
                        message: state.error,
                        onRetry: () => context.read<ProductsCubit>().refresh(),
                      )
                    else
                      Skeletonizer(
                        enabled: isInitialLoading,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Column(
                                children: [
                                  _statRow(
                                    StatCard(
                                      value: formatLocalizedInt(locale, displayState.total),
                                      label: l10n.totalProducts,
                                      icon: AppIcons.products,
                                      iconColor: colorScheme.primary,
                                      iconBackgroundColor:
                                          colorScheme.primaryContainer,
                                      onTap: isInitialLoading
                                          ? null
                                          : () =>
                                                context.go(AppRoutes.products),
                                    ),
                                    StatCard(
                                      value: formatLocalizedInt(locale, displayState.active),
                                      label: l10n.activeWarranties,
                                      icon: AppIcons.warranty,
                                      iconColor: palette.success,
                                      iconBackgroundColor:
                                          palette.successContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _statRow(
                                    StatCard(
                                      value: formatLocalizedInt(locale, displayState.expiring),
                                      label: l10n.expiringSoon,
                                      icon: AppIcons.expiring,
                                      iconColor: palette.warning,
                                      iconBackgroundColor:
                                          palette.warningContainer,
                                    ),
                                    StatCard(
                                      value: formatLocalizedInt(locale, displayState.expired),
                                      label: l10n.expired,
                                      icon: AppIcons.error,
                                      iconColor: palette.danger,
                                      iconBackgroundColor:
                                          palette.dangerContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Outside the products skeleton: it has its own loading state.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: BlocProvider.value(
                        value: _subscriptionsCubit,
                        child: SubscriptionsHomeCard(
                          onTap: () => context.push(AppRoutes.subscriptions),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: BlocProvider.value(
                        value: _installmentsCubit,
                        child: InstallmentsHomeCard(
                          onTap: () => context.push(AppRoutes.installments),
                        ),
                      ),
                    ),
                    if (!(state.error != null && state.products.isEmpty))
                      Skeletonizer(
                        enabled: isInitialLoading,
                        child: Column(
                          children: [
                            const SizedBox(height: 28),
                            RecentProductsSection(
                              items: recentProducts,
                              onSeeAllTap: isInitialLoading
                                  ? null
                                  : () {
                                      context.go(AppRoutes.products);
                                    },
                              onItemTap: isInitialLoading
                                  ? null
                                  : (index) {
                                      context.push(
                                        AppRoutes.details,
                                        extra: sourceProducts[index],
                                      );
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

  Widget _statRow(Widget start, Widget end) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: start),
          const SizedBox(width: 12),
          Expanded(child: end),
        ],
      ),
    );
  }
}
