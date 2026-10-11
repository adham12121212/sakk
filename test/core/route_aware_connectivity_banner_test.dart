import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakk/core/error/network_info.dart';
import 'package:sakk/core/widgets/route_aware_connectivity_banner.dart';
import 'package:sakk/l10n/app_localizations.dart';

class _Network implements NetworkInfo {
  final changes = StreamController<bool>.broadcast();
  @override
  Future<bool> get isConnected async => true;
  @override
  Stream<bool> get onConnectivityChanged => changes.stream;
}

void main() {
  // Regression: the router reports its first route while the app is still
  // building, before any frame. Rebuilding the banner right then threw
  // "setState() or markNeedsBuild() called during build" at every launch.
  testWidgets('no build error at launch; hidden on splash, shown after', (tester) async {
    final network = _Network();
    final router = GoRouter(initialLocation: '/', routes: [
      GoRoute(path: '/', builder: (_, _) => const Text('splash')),
      GoRoute(path: '/home', builder: (_, _) => const Text('home')),
    ]);
    // Attach the way runApp does (outside a frame), not via pumpWidget, which
    // builds inside one and hides the bug.
    tester.binding.attachRootWidget(tester.binding.wrapWithDefaultView(MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => RouteAwareConnectivityBanner(
        routerDelegate: router.routerDelegate,
        isSuppressed: () => router.routerDelegate.currentConfiguration.uri.path == '/',
        networkInfo: network,
        child: child!,
      ),
    )));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    network.changes.add(false);
    await tester.pumpAndSettle();
    expect(find.text("You're offline. Showing saved data."), findsNothing); // splash

    router.go('/home');
    await tester.pumpAndSettle();
    expect(find.text("You're offline. Showing saved data."), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
