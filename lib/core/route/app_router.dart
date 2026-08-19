import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sakk/features/auth/presentation/views/signin_view.dart';
import 'package:sakk/features/auth/presentation/views/signup_view.dart';
import 'package:sakk/features/home/presentation/views/home_view.dart';
import '../../features/analytics/presentation/view/analytics_view.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/views/profile_view.dart';
import '../../features/chat/presentation/cubit/chat_cubit.dart';
import '../../features/chat/presentation/views/chat_view.dart';
import '../../features/details/presentation/views/details_view.dart';
import '../../features/nav_bar/nav_bar.dart';
import '../../features/notification/presentation/cubit/notification_cubit.dart';
import '../../features/notification/presentation/views/notifications_view.dart';
import '../../features/products/domain/enties/product_entity.dart';
import '../../features/products/presentation/cubit/product_cubit.dart';
import '../../features/products/presentation/view/products_veiw.dart';
import '../../features/scan/presentation/views/scan_view.dart';
import '../../features/spalsh/presentation/views/splash_view.dart';
import '../di/get_it.dart';


class AppRoutes {
  static const splash = '/';
  static const signin = '/signin';
  static const signup = '/signup';
  static const home = '/home';
  static const details = '/details';
  static const products = '/products';
  static const analytics = '/analytics';
  static const ai = '/ai';
  static const scan = '/scan';
  static const notifications = '/notifications';
  static const profile = '/profile';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashView(),
    ),
    GoRoute(
      path: AppRoutes.signin,
      builder: (context, state) =>
          BlocProvider(
            create: (_) => getIt<AuthCubit>(),
            child: const SigninView(),
          ),
    ),
    GoRoute(
      path: AppRoutes.signup,
      builder: (context, state) =>
          BlocProvider(
            create: (_) => getIt<AuthCubit>(),
            child: const SignupView(),
          ),
    ),


    GoRoute(
      path: AppRoutes.scan,
      builder: (context, state) => ScanView(),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) =>
          BlocProvider(
            create: (_) => getIt<NotificationCubit>(),
            child: NotificationsView(userId: state.extra as String),
          ),
    ),


    GoRoute(
      path: AppRoutes.details,
      builder: (context, state) =>
          BlocProvider.value(
            value: getIt<ProductsCubit>(),
            child: DetailsView(product: state.extra as ProductEntity),
          ),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) =>
      BlocProvider(
        create: (_) => getIt<AuthCubit>(),
        child: const ProfileView(),
      ),
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          ScaffoldWithNavBar(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeView(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.products,
              builder: (context, state) =>
                  BlocProvider.value(
                    value: getIt<ProductsCubit>(),
                    child: const ProductsView(),
                  ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.analytics,
              builder: (context, state) =>
                  BlocProvider.value(
                    value: getIt<ProductsCubit>(),
                    child: AnalyticsView(),
                  ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.ai,
              builder: (context, state) =>
                  BlocProvider.value(
                    value: getIt<ChatCubit>(),
                    child: const ChatView(),
                  ),
            ),
          ],
        ),
      ],
    ),
  ],
);