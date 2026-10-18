import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sakk/features/auth/presentation/views/signin_view.dart';
import 'package:sakk/features/auth/presentation/views/signup_view.dart';
import 'package:sakk/features/home/presentation/views/home_view.dart';
import '../../features/analytics/presentation/view/analytics_view.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/views/biometric_lock_view.dart';
import '../../features/auth/presentation/views/profile_view.dart';
import '../../features/chat/presentation/cubit/chat_cubit.dart';
import '../../features/chat/presentation/views/chat_view.dart';
import '../../features/details/presentation/cubit/details_cubit.dart';
import '../../features/details/presentation/views/details_view.dart';
import '../../features/forget_password/presentation/views/forgot_password_view.dart';
import '../../features/legal/presentation/views/privacy_policy_view.dart';
import '../../features/legal/presentation/views/terms_of_service_view.dart';
import '../../features/nav_bar/nav_bar.dart';
import '../../features/notification/presentation/cubit/notification_cubit.dart';
import '../../features/notification/presentation/views/notifications_view.dart';
import '../../features/onboarding/presentation/views/onboarding_view.dart';
import '../../features/products/domain/entities/product_entity.dart';
import '../../features/products/presentation/cubit/product_cubit.dart';
import '../../features/products/presentation/view/products_view.dart';
import '../../features/scan/presentation/views/scan_view.dart';
import '../../features/splash/presentation/views/splash_view.dart';
import '../../features/installments/presentation/cubit/installment_form_cubit.dart';
import '../../features/notification/presentation/views/reminder_settings_view.dart';
import '../../features/installments/presentation/cubit/installment_smart_add_cubit.dart';
import '../../features/installments/presentation/cubit/installments_cubit.dart';
import '../../features/installments/presentation/views/installment_details_view.dart';
import '../../features/installments/presentation/views/installment_form_view.dart';
import '../../features/installments/presentation/views/installments_view.dart';
import '../../features/subscriptions/presentation/cubit/catalog_cubit.dart';
import '../../features/subscriptions/presentation/cubit/smart_add_cubit.dart';
import '../../features/subscriptions/presentation/cubit/subscription_form_cubit.dart';
import '../../features/subscriptions/presentation/cubit/subscriptions_cubit.dart';
import '../../features/subscriptions/presentation/views/catalog_picker_view.dart';
import '../../features/subscriptions/presentation/views/subscription_form_view.dart';
import '../../features/subscriptions/presentation/views/subscriptions_view.dart';
import '../di/get_it.dart';


class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const signin = '/signin';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const biometricLock = '/biometric-lock';
  static const terms = '/terms';
  static const privacy = '/privacy';
  static const home = '/home';
  static const details = '/details';
  static const products = '/products';
  static const analytics = '/analytics';
  static const ai = '/ai';
  static const scan = '/scan';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const subscriptions = '/subscriptions';
  static const subscriptionCatalog = '/subscriptions/catalog';
  static const subscriptionForm = '/subscriptions/form';
  static const reminders = '/reminders';
  static const installments = '/installments';
  static const installmentForm = '/installments/form';
  static const installmentDetails = '/installments/plan';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashView(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingView(),
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
      path: AppRoutes.forgotPassword,

      builder: (context, state) => const ForgotPasswordView(),
    ),

    GoRoute(
      path: AppRoutes.biometricLock,
      builder: (context, state) => const BiometricLockView(),
    ),

    GoRoute(
      path: AppRoutes.terms,
      builder: (context, state) => const TermsOfServiceView(),
    ),
    GoRoute(
      path: AppRoutes.privacy,
      builder: (context, state) => const PrivacyPolicyView(),
    ),

    GoRoute(
      path: AppRoutes.scan,
      builder: (context, state) => ScanView(),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      // Opened with the user's id as `extra`; same fallback as details.
      redirect: (context, state) => state.extra is String ? null : AppRoutes.home,
      builder: (context, state) =>
          // .value: the cubit is app-wide (shared with the Home badge), so
          // leaving this screen must not close it.
          BlocProvider.value(
            value: getIt<NotificationCubit>(),
            child: NotificationsView(userId: state.extra as String),
          ),
    ),


    GoRoute(
      path: AppRoutes.details,
      // Opened with the product as `extra`. If the route is ever rebuilt
      // without it (e.g. Android restoring the app after killing it), the
      // product can't be recovered, so fall back to the list.
      redirect: (context, state) => state.extra is ProductEntity ? null : AppRoutes.products,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: getIt<ProductsCubit>()),
          BlocProvider(create: (_) => getIt<DetailsCubit>()),
        ],
        child: DetailsView(product: state.extra as ProductEntity),
      ),
    ),

    GoRoute(
      path: AppRoutes.subscriptions,
      builder: (context, state) => BlocProvider.value(
        value: getIt<SubscriptionsCubit>(),
        child: const SubscriptionsView(),
      ),
    ),
    GoRoute(
      path: AppRoutes.subscriptionCatalog,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<CatalogCubit>()),
          BlocProvider(create: (_) => getIt<SmartAddCubit>()),
        ],
        child: const CatalogPickerView(),
      ),
    ),
    GoRoute(
      path: AppRoutes.subscriptionForm,
      // Opened with SubscriptionFormArgs as `extra`; same fallback as details.
      redirect: (context, state) =>
          state.extra is SubscriptionFormArgs ? null : AppRoutes.subscriptions,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<SubscriptionFormCubit>(),
        child: SubscriptionFormView(args: state.extra as SubscriptionFormArgs),
      ),
    ),

    GoRoute(
      path: AppRoutes.installments,
      builder: (context, state) => BlocProvider.value(
        value: getIt<InstallmentsCubit>(),
        child: const InstallmentsView(),
      ),
    ),
    GoRoute(
      path: AppRoutes.installmentForm,
      // Opened with InstallmentFormArgs as `extra`; same fallback as details.
      redirect: (context, state) =>
          state.extra is InstallmentFormArgs ? null : AppRoutes.installments,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<InstallmentFormCubit>()),
          BlocProvider(create: (_) => getIt<InstallmentSmartAddCubit>()),
        ],
        child: InstallmentFormView(args: state.extra as InstallmentFormArgs),
      ),
    ),
    GoRoute(
      path: AppRoutes.installmentDetails,
      // Opened with the plan's id as `extra` (from the list, a product or a
      // reminder); the plan itself is read from the shared cubit.
      redirect: (context, state) =>
          state.extra is String ? null : AppRoutes.installments,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: getIt<InstallmentsCubit>()..loadIfNeeded()),
          BlocProvider(create: (_) => getIt<InstallmentFormCubit>()),
        ],
        child: InstallmentDetailsView(planId: state.extra as String),
      ),
    ),

    GoRoute(
      path: AppRoutes.reminders,
      builder: (context, state) => const ReminderSettingsView(),
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
