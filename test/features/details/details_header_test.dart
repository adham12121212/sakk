import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/features/details/presentation/widgets/details_header.dart';
import 'package:sakk/features/products/domain/entities/product_entity.dart';
import 'package:sakk/l10n/app_localizations.dart';

Widget app(Widget child, {Locale locale = const Locale('en')}) =>
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, _) => MaterialApp(
        locale: locale,
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  final now = DateTime.now();
  final tv = ProductEntity(
    id: 'tv',
    name: 'Samsung TV',
    brand: 'Samsung',
    purchaseDate: DateTime(now.year - 1, now.month, now.day),
    warrantyMonths: 24,
  );

  testWidgets('name, brand, status, warranty left and the top actions', (
    tester,
  ) async {
    var shared = false;
    await tester.pumpWidget(
      app(
        DetailsHeader(
          product: tv,
          imageUrl: null,
          warrantyProgress: 0.5,
          onBack: () {},
          onShare: () => shared = true,
          onDownload: () {},
        ),
      ),
    );
    expect(find.text('Samsung TV'), findsOneWidget);
    expect(find.textContaining('Samsung ·'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    // No photo: nothing to download.
    expect(find.text('Download Invoice'), findsNothing);
    await tester.tap(find.text('Share'));
    expect(shared, isTrue);
  });

  testWidgets('lays out in Arabic without overflow', (tester) async {
    await tester.pumpWidget(
      app(
        DetailsHeader(
          product: tv,
          imageUrl: null,
          warrantyProgress: 0.5,
          onBack: () {},
          onShare: () {},
          onDownload: () {},
        ),
        locale: const Locale('ar'),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
