import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/di/get_it.dart';
import 'package:sakk/core/service/amount_visibility_controller.dart';
import 'package:sakk/features/analytics/presentation/widgets/total_spent_card.dart';
import 'package:sakk/features/products/domain/enties/product_entity.dart';
import 'package:sakk/features/products/presentation/cubit/product_state.dart';
import 'package:sakk/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget app() => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TotalSpentCard(
            state: ProductsState(products: [
              ProductEntity(id: '1', name: 'TV', price: 18500, purchaseDate: DateTime(2026), warrantyMonths: 12),
            ]),
            l10n: AppLocalizations.of(context)!,
          ),
        ),
      ),
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
  });

  testWidgets('hidden by default; tapping shows it and the choice is remembered', (tester) async {
    final visibility = AmountVisibilityController();
    getIt.registerSingleton(visibility);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(visibility.value, isTrue);
    expect(find.bySemanticsLabel('Total spent hidden'), findsOneWidget);

    await tester.tap(find.text('18,500')); // tapping the blurred amount reveals it
    await tester.pumpAndSettle();
    expect(visibility.value, isFalse);
    expect(find.byTooltip('Hide total spent'), findsOneWidget);

    final again = AmountVisibilityController();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    expect(again.value, isFalse);
  });
}
