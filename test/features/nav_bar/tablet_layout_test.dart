import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakk/core/route/app_router.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/core/widgets/tablet_frame.dart';
import 'package:sakk/features/nav_bar/nav_bar.dart';
import 'package:sakk/l10n/app_localizations.dart';

const _tablet = Size(1280, 800);
const _phone = Size(390, 844);

class _Tab extends StatefulWidget {
  const _Tab(this.name);

  final String name;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  int taps = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SizedBox.expand(
      key: Key('${widget.name}-body'),
      child: TextButton(
        onPressed: () => setState(() => taps++),
        child: Text('${widget.name} tapped $taps'),
      ),
    ),
  );
}

void main() {
  void setSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpShell(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) =>
              ScaffoldWithNavBar(navigationShell: shell),
          branches: [
            for (final (path, name) in const [
              (AppRoutes.home, 'home'),
              (AppRoutes.products, 'products'),
              (AppRoutes.analytics, 'analytics'),
              (AppRoutes.ai, 'ai'),
            ])
              StatefulShellBranch(
                routes: [GoRoute(path: path, builder: (_, _) => _Tab(name))],
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  group('navigation shell', () {
    testWidgets('phones keep the bottom bar', (tester) async {
      setSize(tester, _phone);
      await pumpShell(tester);

      expect(tester.getCenter(find.text('Home')).dy, greaterThan(760));
      expect(tester.getSize(find.byKey(const Key('home-body'))).width, 390);
    });

    testWidgets('tablets get a side rail and centred content', (tester) async {
      setSize(tester, _tablet);
      await pumpShell(tester);

      expect(tester.takeException(), isNull);
      expect(tester.getCenter(find.text('Home')).dx, lessThan(88));
      final body = tester.getRect(find.byKey(const Key('home-body')));
      expect(body.width, TabletColumn.maxWidth);
      // Centred in the space right of the 88dp rail plus its 1dp border.
      expect(body.center.dx, closeTo(88 + (1280 - 88) / 2, 1));
    });

    testWidgets('the rail moves to the right in Arabic', (tester) async {
      setSize(tester, _tablet);
      await pumpShell(tester, locale: const Locale('ar'));

      final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
      expect(tester.getCenter(find.text(l10n.home)).dx, greaterThan(1280 - 88));
    });

    testWidgets('the rail switches tabs', (tester) async {
      setSize(tester, _tablet);
      await pumpShell(tester);

      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();

      expect(find.textContaining('products tapped'), findsOneWidget);
    });

    testWidgets('tab state survives crossing the tablet width', (tester) async {
      setSize(tester, _phone);
      await pumpShell(tester);
      await tester.tap(find.text('home tapped 0'));
      await tester.pump();

      setSize(tester, _tablet);
      await tester.pumpAndSettle();
      expect(find.text('home tapped 1'), findsOneWidget);

      setSize(tester, _phone);
      await tester.pumpAndSettle();
      expect(find.text('home tapped 1'), findsOneWidget);
    });
  });

  group('frames', () {
    Future<void> pumpFrame(WidgetTester tester, Widget frame) =>
        tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: frame));

    Widget screen() => Builder(
      key: const Key('screen'),
      builder: (context) => SizedBox.expand(
        child: Text('${MediaQuery.sizeOf(context).width.round()}'),
      ),
    );

    testWidgets('both leave phones untouched', (tester) async {
      setSize(tester, _phone);
      for (final frame in [
        TabletColumn(child: screen()),
        TabletCard(child: screen()),
      ]) {
        await pumpFrame(tester, frame);
        expect(tester.getSize(find.byKey(const Key('screen'))), _phone);
      }
    });

    testWidgets('the column reports its own width to the screen', (
      tester,
    ) async {
      setSize(tester, _tablet);
      await pumpFrame(tester, TabletColumn(child: screen()));

      expect(find.text('600'), findsOneWidget);
    });

    testWidgets('the card stays clear of the keyboard', (tester) async {
      setSize(tester, _tablet);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await pumpFrame(tester, TabletCard(child: screen()));

      final card = tester.getRect(find.byKey(const Key('screen')));
      expect(card.width, TabletCard.maxWidth);
      expect(card.bottom, lessThanOrEqualTo(800 - 300));
    });
  });
}
