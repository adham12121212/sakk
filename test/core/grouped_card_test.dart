import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/core/widgets/app_card.dart';

/// The decorated boxes drawn as cards (the ones with a shadow).
Finder cards() => find.byWidgetPredicate(
  (w) =>
      w is DecoratedBox &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).boxShadow != null,
);

void main() {
  testWidgets('cards inside a group draw as rows of one card', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: GroupedCard(
            children: [
              AppCard(onTap: () => taps++, child: const Text('one')),
              const AppCard(child: Text('two')),
              const AppCard(
                // A card inside a row's content is a card again.
                child: AppCard(child: Text('nested')),
              ),
            ],
          ),
        ),
      ),
    );

    expect(cards(), findsNWidgets(2)); // the group and the nested one
    expect(find.byType(Divider), findsNWidgets(2));
    await tester.tap(find.text('one'));
    expect(taps, 1);
  });
}
