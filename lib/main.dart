import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/di/get_it.dart';
import 'core/error/user_facing_error.dart';
import 'core/error/network_info.dart';
import 'core/locale_controller/locale_controller.dart';
import 'core/logger/app_logger.dart';
import 'core/logger/crash_reporting.dart';
import 'core/observer/app_bloc_observer.dart';
import 'core/route/app_router.dart';
import 'core/service/installment_reminder_service.dart';
import 'core/service/notification_service.dart';
import 'core/service/reminder_settings.dart';
import 'core/service/temp_file_cleaner.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/widgets/route_aware_connectivity_banner.dart';
import 'core/widgets/app_skeleton_config.dart';
import 'core/widgets/app_snackbar.dart';
import 'core/widgets/sakk_logo.dart';
import 'features/auth/domain/usecase/get_user_usecase.dart';
import 'features/installments/presentation/cubit/installments_cubit.dart';
import 'features/notification/presentation/cubit/notification_cubit.dart';
import 'features/pro/data/purchases_gateway.dart';
import 'features/pro/presentation/cubit/pro_cubit.dart';
import 'features/pro/presentation/widgets/pro_limit_listener.dart';
import 'features/products/presentation/cubit/product_cubit.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await CrashReporting.init();
  await _bootstrap();
}

Future<void> _bootstrap() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  CrashReporting.bindSupabaseUser(Supabase.instance.client.auth);
  setupLocator();
  Bloc.observer = AppBlocObserver(getIt<AppLogger>());

  final notificationService = getIt<NotificationService>();

  notificationService.onNotificationTap = _handleNotificationTap;

  try {
    // The iOS "Mark as paid" button is titled once, in the saved language.
    final locale = getIt<LocaleController>();
    await locale.loaded;
    await notificationService.init(
      markPaidLabel: lookupAppLocalizations(locale.value).markAsPaid,
    );
    await notificationService.requestPermission();
  } catch (e, stackTrace) {
    getIt<AppLogger>().error(
      'Notification service initialization failed',
      error: e,
      stackTrace: stackTrace,
    );
  }

  try {
    await getIt<PurchasesGateway>().init();
  } catch (e, stackTrace) {
    // The app works without the store (free plan; the paywall says so).
    getIt<AppLogger>().error(
      'RevenueCat setup failed',
      error: e,
      stackTrace: stackTrace,
    );
  }
  // Created now so it logs in to RevenueCat with the restored session and
  // loads the plan before any screen asks. The Pro reminders follow it.
  final pro = getIt<ProCubit>();
  final reminderSettings = getIt<ReminderSettings>();
  pro.stream.listen((state) => reminderSettings.setProActive(state.isPro));

  try {
    await SakkLogo.precache();
  } catch (e, stackTrace) {
    getIt<AppLogger>().error(
      'Splash logo precache failed',
      error: e,
      stackTrace: stackTrace,
    );
  }

  runApp(const MyApp());

  // Leftover photos and share files from earlier sessions.
  unawaited(TempFileCleaner().clean());

  final launch = await notificationService.getLaunchResponse();
  if (launch != null && (launch.payload ?? '').isNotEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotificationTap(launch, coldStart: true);
    });
  }
}

void _reloadAfterReconnect() {
  final products = getIt<ProductsCubit>();
  if (products.state.hasLoadedOnce || products.state.error != null) {
    products.refresh();
  }
  getIt<NotificationCubit>().refresh();
  getIt<ProCubit>().refresh();
}

/// [coldStart]: the notification launched the app, and the splash screen
/// is about to replace the stack (with Home or the lock screen), so an
/// installment reminder's button only marks the payment paid.
void _handleNotificationTap(
  NotificationResponse response, {
  bool coldStart = false,
}) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;
  final installment = InstallmentReminderPayload.tryParse(payload);
  if (installment != null) {
    _openInstallment(
      installment,
      markPaid: response.actionId == NotificationService.markPaidActionId,
      navigate: !coldStart,
    );
    return;
  }
  _openNotifications(payload);
}

Future<void> _openInstallment(
  InstallmentReminderPayload reminder, {
  required bool markPaid,
  required bool navigate,
}) async {
  // Another account's reminder (signed out before this device re-synced).
  if (getIt<GetUserUseCase>()()?.id != reminder.userId) return;
  if (navigate) {
    appRouter.push(AppRoutes.installmentDetails, extra: reminder.planId);
  }
  if (!markPaid) return;
  final error = await getIt<InstallmentsCubit>().markPaidFromReminder(
    reminder.planId,
    reminder.paymentId,
  );
  final context = appRouter.routerDelegate.navigatorKey.currentContext;
  if (context == null || !context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  if (error == null) {
    AppSnackBar.success(context, l10n.installmentMarkedPaid);
  } else {
    AppSnackBar.error(context, userFacingError(l10n, error));
  }
}

void _openNotifications(String userId) {
  appRouter.push(AppRoutes.notifications, extra: userId);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        getIt<ThemeController>(),
        getIt<LocaleController>(),
      ]),
      builder: (context, _) {
        return ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (_, child) {
            return MaterialApp.router(
              routerConfig: appRouter,

              // App-wide offline strip; reloads data when the connection returns.
              builder: (context, child) => AppSkeletonConfig(
                child: RouteAwareConnectivityBanner(
                  routerDelegate: appRouter.routerDelegate,
                  isSuppressed: () =>
                      appRouter.routerDelegate.currentConfiguration.uri.path ==
                      AppRoutes.splash,
                  networkInfo: getIt<NetworkInfo>(),
                  onReconnected: _reloadAfterReconnect,
                  // A free-plan limit hit anywhere opens the paywall.
                  child: ProLimitListener(
                    router: appRouter,
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),

              onGenerateTitle: (context) =>
                  AppLocalizations.of(context)!.appName,

              locale: getIt<LocaleController>().value,
              themeMode: getIt<ThemeController>().value,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),

              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],

              supportedLocales: const [Locale('en'), Locale('ar')],

              localeResolutionCallback: (locale, supportedLocales) {
                if (locale != null &&
                    supportedLocales.any(
                      (l) => l.languageCode == locale.languageCode,
                    )) {
                  return Locale(locale.languageCode);
                }
                return const Locale('en');
              },

              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }
}
