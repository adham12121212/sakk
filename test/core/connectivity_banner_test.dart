import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakk/core/error/network_info.dart';
import 'package:sakk/core/widgets/connectivity_banner.dart';
import 'package:sakk/l10n/app_localizations.dart';

class _Network implements NetworkInfo {
  final changes = StreamController<bool>.broadcast();
  @override
  Future<bool> get isConnected async => true;
  @override
  Stream<bool> get onConnectivityChanged => changes.stream;
}

void main() {
  // Regression: the banner used to swap a wrapper widget in and out, which
  // rebuilt the Router from scratch and crashed screens opened with `extra`.
  testWidgets('going offline and back keeps the same Router and open screen', (
    tester,
  ) async {
    final network = _Network();
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('home')),
        GoRoute(
          path: '/details',
          builder: (_, state) => Text('details ${state.extra}'),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            ConnectivityBanner(networkInfo: network, child: child!),
      ),
    );
    router.push('/details', extra: 'TV');
    await tester.pumpAndSettle();
    final routerState = tester.state(find.byType(Router<Object>));

    network.changes.add(false);
    await tester.pumpAndSettle();
    expect(find.text("You're offline. Showing saved data."), findsOneWidget);
    network.changes.add(true);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(
      identical(routerState, tester.state(find.byType(Router<Object>))),
      isTrue,
    );
    expect(find.text('details TV'), findsOneWidget);
  });
}
