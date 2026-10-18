import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakk/core/di/get_it.dart';
import 'package:sakk/core/route/app_router.dart';
import 'package:sakk/core/service/biometric_auth_service.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/features/auth/presentation/views/biometric_lock_view.dart';
import 'package:sakk/l10n/app_localizations.dart';

/// Counts prompts; each one waits until the test answers it.
class _FakeBiometrics implements BiometricAuthService {
  int prompts = 0;
  Completer<bool>? _pending;

  void answer(bool success) => _pending!.complete(success);

  @override
  Future<bool> authenticate({required String reason}) {
    prompts++;
    _pending = Completer<bool>();
    return _pending!.future;
  }

  @override
  Future<bool> get isAvailable async => true;
  @override
  Future<bool> get isEnabled async => true;
  @override
  Future<void> setEnabled(bool enabled) async {}
}

void main() {
  late _FakeBiometrics biometrics;

  setUp(() {
    biometrics = _FakeBiometrics();
    getIt.registerSingleton<BiometricAuthService>(biometrics);
  });
  tearDown(() => getIt.unregister<BiometricAuthService>());

  Future<void> open(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.biometricLock,
      routes: [
        GoRoute(path: AppRoutes.biometricLock, builder: (_, _) => const BiometricLockView()),
        GoRoute(path: AppRoutes.home, builder: (_, _) => const Text('home')),
      ],
    );
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, _) => MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pump();
  }

  /// What Android reports around its fingerprint dialog: the app goes
  /// inactive while it shows and is resumed when it closes.
  Future<void> dialogCloses(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
  }

  Future<void> leaveAndComeBack(WidgetTester tester) async {
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
  }

  testWidgets('asks once and opens Home after a match', (tester) async {
    await open(tester);
    expect(biometrics.prompts, 1);

    biometrics.answer(true);
    await dialogCloses(tester);
    await tester.pumpAndSettle();
    expect(biometrics.prompts, 1);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a cancelled prompt is not shown again by itself', (tester) async {
    await open(tester);
    biometrics.answer(false);
    await dialogCloses(tester);
    expect(biometrics.prompts, 1);

    // The Unlock button still asks.
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(biometrics.prompts, 2);
  });

  testWidgets('asks again after the user left the app and came back', (tester) async {
    await open(tester);
    biometrics.answer(false);
    await dialogCloses(tester);

    await leaveAndComeBack(tester);
    expect(biometrics.prompts, 2);
  });
}
