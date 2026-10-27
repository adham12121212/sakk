import 'package:flutter/material.dart';
import '../../../household/presentation/cubit/household_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/route/app_router.dart';
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
import '../../../papers/presentation/cubit/papers_cubit.dart';
import '../../../subscriptions/presentation/cubit/subscriptions_cubit.dart';
import '../widgets/home_header.dart';
import '../widgets/home_sections.dart';
import '../widgets/recent_products_section.dart';
import '../../../../core/widgets/warranty_summary_card.dart';

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
  final _papersCubit = getIt<PapersCubit>();

  @override
  void initState() {
    super.initState();
    context.read<ProductsCubit>().loadIfNeeded();
    _subscriptionsCubit.loadIfNeeded();
    _installmentsCubit.loadIfNeeded();
    _papersCubit.loadIfNeeded();
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

            final sourceProducts = displayProducts.take(3).toList();

            return AppRefreshIndicator(
              onRefresh: () => Future.wait([
                context.read<ProductsCubit>().refresh(),
                _notificationCubit.refresh(),
                _subscriptionsCubit.refresh(),
                _installmentsCubit.refresh(),
                _papersCubit.refresh(),
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
                    SizedBox(height: 8.h),

                    if (state.error != null && state.products.isEmpty)
                      AppErrorView(
                        message: state.error,
                        onRetry: () => context.read<ProductsCubit>().refresh(),
                      )
                    else
                      Skeletonizer(
                        enabled: isInitialLoading,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: WarrantySummaryCard(
                            active: displayState.active,
                            expiring: displayState.expiring,
                            expired: displayState.expired,
                            onTap: isInitialLoading
                                ? null
                                : () => context.go(AppRoutes.products),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: HomeMoneySection(
                        subscriptions: _subscriptionsCubit,
                        installments: _installmentsCubit,
                        onSubscriptionsTap: () =>
                            context.push(AppRoutes.subscriptions),
                        onInstallmentsTap: () =>
                            context.push(AppRoutes.installments),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: HomePapersSection(
                        papers: _papersCubit,
                        onOpen: () => context.push(AppRoutes.papers),
                      ),
                    ),
                    if (!(state.error != null && state.products.isEmpty))
                      Skeletonizer(
                        enabled: isInitialLoading,
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            RecentProductsSection(
                              items: sourceProducts,
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
}
