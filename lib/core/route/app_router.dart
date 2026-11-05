import 'package:flutter/material.dart';
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
import '../../features/papers/domain/entities/paper.dart';
import '../../features/papers/presentation/cubit/paper_form_cubit.dart';
import '../../features/papers/presentation/cubit/papers_cubit.dart';
import '../../features/papers/presentation/views/paper_details_view.dart';
import '../../features/papers/presentation/views/paper_form_view.dart';
import '../../features/papers/presentation/views/papers_view.dart';
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
import '../../features/subscriptions/domain/entities/user_subscription.dart';
import '../../features/subscriptions/presentation/views/subscription_details_view.dart';
import '../../features/subscriptions/presentation/views/subscription_form_view.dart';
import '../../features/subscriptions/presentation/views/subscriptions_view.dart';
import '../../features/pro/domain/pro_limit.dart';
import '../../features/pro/presentation/cubit/paywall_cubit.dart';
import '../../features/pro/presentation/cubit/pro_cubit.dart';
import '../../features/pro/presentation/views/monthly_summary_view.dart';
import '../../features/pro/presentation/views/paywall_view.dart';
import '../di/get_it.dart';
import '../service/share_intake.dart';
import '../widgets/tablet_frame.dart';

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
  static const subscriptionDetails = '/subscriptions/details';
  static const reminders = '/reminders';
  static const installments = '/installments';
  static const installmentForm = '/installments/form';
  static const installmentDetails = '/installments/plan';
  static const papers = '/papers';
  static const paperForm = '/papers/form';
  static const paperDetails = '/papers/details';
  static const paywall = '/pro';
  static const monthlySummary = '/pro/monthly-summary';
}

/// A full-screen route, centred in a column on tablets.
GoRoute _screen({
  required String path,
  required GoRouterWidgetBuilder builder,
  GoRouterRedirect? redirect,
}) => GoRoute(
  path: path,
  redirect: redirect,
  builder: (context, state) => TabletColumn(child: builder(context, state)),
);

/// A pre-sign-in route, shown as a centred card on tablets.
GoRoute _authScreen({
  required String path,
  required GoRouterWidgetBuilder builder,
}) => GoRoute(
  path: path,
  builder: (context, state) => TabletCard(child: builder(context, state)),
);

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashView(),
    ),
    _authScreen(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingView(),
    ),
    _authScreen(
      path: AppRoutes.signin,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<AuthCubit>(),
        child: const SigninView(),
      ),
    ),
    _authScreen(
      path: AppRoutes.signup,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<AuthCubit>(),
        child: const SignupView(),
      ),
    ),
    _authScreen(
      path: AppRoutes.forgotPassword,

      builder: (context, state) => const ForgotPasswordView(),
    ),

    _screen(
      path: AppRoutes.biometricLock,
      builder: (context, state) => const BiometricLockView(),
    ),

    _screen(
      path: AppRoutes.terms,
      builder: (context, state) => const TermsOfServiceView(),
    ),
    _screen(
      path: AppRoutes.privacy,
      builder: (context, state) => const PrivacyPolicyView(),
    ),

    GoRoute(
      path: AppRoutes.scan,
      // `extra`: a receipt shared from another app (SharedReceiptListener).
      builder: (context, state) => ScanView(
        shared: state.extra is SharedReceipt
            ? state.extra as SharedReceipt
            : null,
      ),
    ),
    _screen(
      path: AppRoutes.notifications,
      // Opened with the user's id as `extra`; same fallback as details.
      redirect: (context, state) =>
          state.extra is String ? null : AppRoutes.home,
      builder: (context, state) =>
          // .value: the cubit is app-wide (shared with the Home badge), so
          // leaving this screen must not close it.
          BlocProvider.value(
            value: getIt<NotificationCubit>(),
            child: NotificationsView(userId: state.extra as String),
          ),
    ),

    _screen(
      path: AppRoutes.details,
      // Opened with the product as `extra`. If the route is ever rebuilt
      // without it (e.g. Android restoring the app after killing it), the
      // product can't be recovered, so fall back to the list.
      redirect: (context, state) =>
          state.extra is ProductEntity ? null : AppRoutes.products,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: getIt<ProductsCubit>()),
          BlocProvider(create: (_) => getIt<DetailsCubit>()),
        ],
        child: DetailsView(product: state.extra as ProductEntity),
      ),
    ),

    _screen(
      path: AppRoutes.subscriptions,
      builder: (context, state) => BlocProvider.value(
        value: getIt<SubscriptionsCubit>(),
        child: const SubscriptionsView(),
      ),
    ),
    _screen(
      path: AppRoutes.subscriptionCatalog,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<CatalogCubit>()),
          BlocProvider(create: (_) => getIt<SmartAddCubit>()),
        ],
        child: const CatalogPickerView(),
      ),
    ),
    _screen(
      path: AppRoutes.subscriptionDetails,
      // Opened with the UserSubscription as `extra`; same fallback as details.
      redirect: (context, state) =>
          state.extra is UserSubscription ? null : AppRoutes.subscriptions,
      builder: (context, state) => BlocProvider.value(
        value: getIt<SubscriptionsCubit>(),
        child: SubscriptionDetailsView(
          subscription: state.extra as UserSubscription,
        ),
      ),
    ),
    _screen(
      path: AppRoutes.subscriptionForm,
      // Opened with SubscriptionFormArgs as `extra`; same fallback as details.
      redirect: (context, state) =>
          state.extra is SubscriptionFormArgs ? null : AppRoutes.subscriptions,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<SubscriptionFormCubit>(),
        child: SubscriptionFormView(args: state.extra as SubscriptionFormArgs),
      ),
    ),

    _screen(
      path: AppRoutes.papers,
      builder: (context, state) => BlocProvider.value(
        value: getIt<PapersCubit>(),
        child: const PapersView(),
      ),
    ),
    _screen(
      path: AppRoutes.paperDetails,
      // Opened with the Paper as `extra`; same fallback as details.
      redirect: (context, state) =>
          state.extra is Paper ? null : AppRoutes.papers,
      builder: (context, state) => BlocProvider.value(
        value: getIt<PapersCubit>(),
        child: PaperDetailsView(paper: state.extra as Paper),
      ),
    ),
    _screen(
      path: AppRoutes.paperForm,
      // A Paper as `extra` to edit it; nothing to add a new one.
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<PaperFormCubit>(),
        child: PaperFormView(existing: state.extra as Paper?),
      ),
    ),

    _screen(
      path: AppRoutes.installments,
      builder: (context, state) => BlocProvider.value(
        value: getIt<InstallmentsCubit>(),
        child: const InstallmentsView(),
      ),
    ),
    _screen(
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
    _screen(
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
      path: AppRoutes.paywall,
      // Opened with a PaywallReason as `extra`; a general upgrade without one.
      pageBuilder: (context, state) => MaterialPage(
        fullscreenDialog: true,
        child: TabletColumn(
          child: BlocProvider(
            create: (_) => getIt<PaywallCubit>(),
            child: PaywallView(
              reason: state.extra is PaywallReason
                  ? state.extra as PaywallReason
                  : PaywallReason.upgrade,
            ),
          ),
        ),
      ),
    ),
    _screen(
      path: AppRoutes.monthlySummary,
      // Pro only: free users get the paywall in its place. Follows the plan,
      // so it turns into the summary once the plan loads or after buying.
      builder: (context, state) => BlocBuilder<ProCubit, ProState>(
        bloc: getIt<ProCubit>(),
        buildWhen: (a, b) => a.isPro != b.isPro,
        builder: (context, pro) => pro.isPro
            ? MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: getIt<SubscriptionsCubit>()),
                  BlocProvider.value(value: getIt<InstallmentsCubit>()),
                  BlocProvider.value(value: getIt<ProductsCubit>()),
                ],
                child: const MonthlySummaryView(),
              )
            : BlocProvider(
                create: (_) => getIt<PaywallCubit>(),
                child: const PaywallView(reason: PaywallReason.monthlySummary),
              ),
      ),
    ),
    _screen(
      path: AppRoutes.reminders,
      builder: (context, state) => const ReminderSettingsView(),
    ),
    _screen(
      path: AppRoutes.profile,
      builder: (context, state) => BlocProvider(
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
              builder: (context, state) => BlocProvider.value(
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
              builder: (context, state) => BlocProvider.value(
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
              builder: (context, state) => BlocProvider.value(
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
