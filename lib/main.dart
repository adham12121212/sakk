import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/di/get_it.dart';
import 'core/locale_controller/locale_controller.dart';
import 'core/logger/app_logger.dart';
import 'core/observer/app_bloc_observer.dart';
import 'core/route/app_router.dart';
import 'core/service/notification_service.dart';
import 'core/theme/theme_controller.dart';
import 'l10n/app_localizations.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  setupLocator();
  Bloc.observer = AppBlocObserver(getIt<AppLogger>());

  final notificationService = getIt<NotificationService>();


  notificationService.onNotificationTap = _handleNotificationTap;

  try {
    await notificationService.init();
    await notificationService.requestPermission();
  } catch (e) {
    print(e);
  }

  runApp(const MyApp());


  final launchPayload = await notificationService.getLaunchPayload();
  if (launchPayload != null && launchPayload.isNotEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openNotifications(launchPayload);
    });
  }
}

void _handleNotificationTap(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;
  _openNotifications(payload);
}

void _openNotifications(String userId) {
  // `appRouter` is a top-level GoRouter, so its navigation methods work
  // without a BuildContext — exactly what's needed here, since a
  // notification tap can happen before any screen/context exists yet.
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

              onGenerateTitle: (context) =>
              AppLocalizations.of(context)!.appName,

              locale: getIt<LocaleController>().value,
              themeMode: getIt<ThemeController>().value,
              theme: ThemeData(brightness: Brightness.light),
              darkTheme: ThemeData(brightness: Brightness.dark),

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

              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }
}