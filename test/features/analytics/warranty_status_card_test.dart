import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/features/analytics/presentation/widgets/warranty_status_card.dart';
import 'package:sakk/features/products/domain/entities/product_entity.dart';
import 'package:sakk/features/products/presentation/cubit/product_state.dart';
import 'package:sakk/l10n/app_localizations.dart';

void main() {
  testWidgets('the bar draws a full-height segment per status', (tester) async {
    final now = DateTime.now();
    ProductEntity bought(String id, DateTime date, int months) => ProductEntity(
      id: id,
      name: id,
      purchaseDate: date,
      warrantyMonths: months,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => WarrantyStatusCard(
              state: ProductsState(
                products: [
                  bought('active', now, 24),
                  bought('expired', DateTime(now.year - 3), 12),
                ],
              ),
              l10n: AppLocalizations.of(context)!,
            ),
          ),
        ),
      ),
    );

    final segments = find.descendant(
      of: find.byType(WarrantyStatusCard),
      matching: find.byType(ColoredBox),
    );
    expect(segments, findsNWidgets(2));
    for (final segment in segments.evaluate()) {
      expect(tester.getSize(find.byWidget(segment.widget)).height, 12);
    }
  });
}
