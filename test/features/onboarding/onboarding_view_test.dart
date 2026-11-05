import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/di/get_it.dart';
import 'package:sakk/core/locale_controller/locale_controller.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/core/theme/screen_scaling.dart';
import 'package:sakk/features/onboarding/presentation/views/onboarding_view.dart';
import 'package:sakk/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    getIt.registerSingleton<LocaleController>(LocaleController());
  });

  tearDown(() => getIt.reset());

  Future<void> pumpAt(WidgetTester tester, Size size, Locale locale) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        enableScaleWH: scalesWithScreen,
        enableScaleText: scalesWithScreen,
        builder: (_, _) => MaterialApp(
          theme: AppTheme.light(),
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const OnboardingView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const screens = {
    'tablet landscape': Size(1280, 800),
    'tablet portrait': Size(800, 1280),
    'unfolded foldable': Size(673, 841),
    'phone': Size(390, 844),
  };

  for (final MapEntry(key: name, value: size) in screens.entries) {
    for (final locale in const [Locale('en'), Locale('ar')]) {
      testWidgets('fits on $name in ${locale.languageCode}', (tester) async {
        await pumpAt(tester, size, locale);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('keeps scaling on phones but not on tablets', (tester) async {
    await pumpAt(tester, const Size(430, 932), const Locale('en'));
    expect(16.sp, closeTo(16 * 430 / 390, 0.001));

    await pumpAt(tester, const Size(1280, 800), const Locale('en'));
    expect(16.sp, 16);
    expect(180.w, 180);
  });
}
