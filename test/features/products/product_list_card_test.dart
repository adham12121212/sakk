import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/features/products/domain/entities/product_entity.dart';
import 'package:sakk/features/products/presentation/widgets/product_list_card.dart';
import 'package:sakk/l10n/app_localizations.dart';

Widget app(Widget child, {Locale locale = const Locale('en')}) =>
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, _) => MaterialApp(
        locale: locale,
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );

void main() {
  final now = DateTime.now();
  ProductEntity product(String name, {int monthsAgo = 2}) => ProductEntity(
    id: name,
    name: name,
    brand: 'Samsung',
    purchaseDate: DateTime(now.year, now.month - monthsAgo, now.day),
    warrantyMonths: 12,
  );

  testWidgets('name, brand · category, status and time left', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      app(
        Column(
          children: [
            ProductListCard(product: product('TV'), onTap: () => opened = true),
            ProductListCard(product: product('Old phone', monthsAgo: 20)),
          ],
        ),
      ),
    );
    expect(find.text('TV'), findsOneWidget);
    expect(find.text('Samsung · Other'), findsNWidgets(2));
    expect(find.text('Warranty expired'), findsOneWidget);
    await tester.tap(find.text('TV'));
    expect(opened, isTrue);
  });

  testWidgets('fits in Arabic on a small phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(
        ProductListCard(product: product('تليفزيون سامسونج ٥٥ بوصة سمارت')),
        locale: const Locale('ar'),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
