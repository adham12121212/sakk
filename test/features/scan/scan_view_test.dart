import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/features/scan/presentation/views/scan_view.dart';
import 'package:sakk/l10n/app_localizations.dart';

Widget app({Locale locale = const Locale('en')}) => ScreenUtilInit(
  designSize: const Size(390, 844),
  builder: (_, _) => MaterialApp(
    locale: locale,
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const ScanView(),
  ),
);

void main() {
  testWidgets('the camera first, then the other ways to add', (tester) async {
    await tester.pumpWidget(app());
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Other ways to add'), findsOneWidget);
    expect(find.text('Choose from Gallery'), findsOneWidget);
    expect(find.text('Upload PDF Invoice'), findsOneWidget);
    expect(find.text('Add by voice'), findsOneWidget);
    expect(find.text('Enter details manually'), findsOneWidget);
  });

  testWidgets('fits in Arabic on a small phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(locale: const Locale('ar')));
    expect(tester.takeException(), isNull);
  });
}
