import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/di/get_it.dart';
import 'core/error/network_info.dart';
import 'core/locale_controller/locale_controller.dart';
import 'core/logger/app_logger.dart';
import 'core/logger/crash_reporting.dart';
import 'core/observer/app_bloc_observer.dart';
import 'core/route/app_router.dart';
import 'core/service/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/widgets/connectivity_banner.dart';
import 'core/widgets/sakk_logo.dart';
import 'features/notification/presentation/cubit/notification_cubit.dart';
import 'features/products/presentation/cubit/product_cubit.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Loaded first: CrashReporting reads SENTRY_DSN from it.
  await dotenv.load(fileName: ".env");
  await CrashReporting.init(appRunner: _bootstrap);
}

Future<void> _bootstrap() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
    await notificationService.init();
    await notificationService.requestPermission();
  } catch (e, stackTrace) {
    getIt<AppLogger>().error(
      'Notification service initialization failed',
      error: e,
      stackTrace: stackTrace,
    );
  }

  try {
    await SakkLogo.precache();
  } catch (e, stackTrace) {
    getIt<AppLogger>().error('Splash logo precache failed', error: e, stackTrace: stackTrace);
  }

  runApp(const MyApp());

  final launchPayload = await notificationService.getLaunchPayload();
  if (launchPayload != null && launchPayload.isNotEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openNotifications(launchPayload);
    });
  }
}


void _reloadAfterReconnect() {
  final products = getIt<ProductsCubit>();
  if (products.state.hasLoadedOnce || products.state.error != null) {
    products.refresh();
  }
  getIt<NotificationCubit>().refresh();
}

void _handleNotificationTap(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;
  _openNotifications(payload);
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
              builder: (context, child) => _RouteAwareConnectivityBanner(
                child: child ?? const SizedBox.shrink(),
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

              supportedLocales: const [
                Locale('en'),
                Locale('ar'),
              ],

              localeResolutionCallback: (locale, supportedLocales) {
                if (locale != null &&
                    supportedLocales
                        .any((l) => l.languageCode == locale.languageCode)) {
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

/// The offline strip, hidden on the splash screen. The router reports route
/// changes while the app is still building (e.g. at launch), so rebuilding
/// right then would throw "setState() called during build"; the rebuild waits
/// for the end of that frame instead.
class _RouteAwareConnectivityBanner extends StatefulWidget {
  const _RouteAwareConnectivityBanner({required this.child});

  final Widget child;

  @override
  State<_RouteAwareConnectivityBanner> createState() => _RouteAwareConnectivityBannerState();
}

class _RouteAwareConnectivityBannerState extends State<_RouteAwareConnectivityBanner> {
  bool get _onSplash => appRouter.routerDelegate.currentConfiguration.uri.path == AppRoutes.splash;
  late bool _suppressed = _onSplash;

  @override
  void initState() {
    super.initState();
    appRouter.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    appRouter.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    final suppressed = _onSplash;
    if (suppressed == _suppressed) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _suppressed = _onSplash);
      });
    } else {
      setState(() => _suppressed = suppressed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityBanner(
      networkInfo: getIt<NetworkInfo>(),
      onReconnected: _reloadAfterReconnect,
      suppressed: _suppressed,
      child: widget.child,
    );
  }
}
