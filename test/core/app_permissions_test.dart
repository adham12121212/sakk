import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sakk/core/service/app_permissions.dart';
import 'package:sakk/l10n/app_localizations.dart';

/// The OS: [onRequest] answers a request, optionally showing a prompt.
class _Backend extends PermissionBackend {
  _Backend(this.current);

  PermissionStatus current;
  int requests = 0;
  int settingsOpened = 0;
  bool canOpenSettings = true;
  Future<PermissionStatus> Function()? onRequest;

  @override
  Future<PermissionStatus> status(Permission permission) async => current;

  @override
  Future<PermissionStatus> request(Permission permission) async {
    requests++;
    return onRequest == null ? current : await onRequest!();
  }

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return canOpenSettings;
  }
}

/// What the app goes through on a trip to Settings.
const _awayAndBack = [
  AppLifecycleState.inactive,
  AppLifecycleState.hidden,
  AppLifecycleState.paused,
  AppLifecycleState.hidden,
  AppLifecycleState.inactive,
  AppLifecycleState.resumed,
];

/// Pretends to be the system prompt: the app loses focus while it's up.
Future<PermissionStatus> _prompted(
  WidgetTester tester,
  PermissionStatus answer,
) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  return answer;
}

void main() {
  late BuildContext context;

  Future<void> pumpApp(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale ?? const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
  }

  /// Runs [ensure] and records what it completes with.
  Future<bool?> Function() start(
    WidgetTester tester,
    AppPermissions permissions,
    AppPermission permission,
    List<bool> results,
  ) {
    unawaited(permissions.ensure(context, permission).then(results.add));
    return () async {
      await tester.pumpAndSettle();
      return results.isEmpty ? null : results.last;
    };
  }

  void leaveAndComeBack(WidgetTester tester) {
    for (final state in _awayAndBack) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
  }

  testWidgets('granted: goes ahead without asking', (tester) async {
    await pumpApp(tester);
    final backend = _Backend(PermissionStatus.granted);
    final permissions = AppPermissions(backend: backend);

    expect(
      await permissions.ensure(context, AppPermission.notifications),
      isTrue,
    );
    expect(backend.requests, 0);
  });

  testWidgets('iOS provisional notifications count as allowed', (tester) async {
    await pumpApp(tester);
    final permissions = AppPermissions(
      backend: _Backend(PermissionStatus.provisional),
    );
    expect(
      await permissions.ensure(context, AppPermission.notifications),
      isTrue,
    );
  });

  testWidgets('denied: asks again on every tap, and no dialog after a no', (
    tester,
  ) async {
    await pumpApp(tester);
    final backend = _Backend(PermissionStatus.denied)
      ..onRequest = () => _prompted(tester, PermissionStatus.denied);
    final permissions = AppPermissions(backend: backend);

    expect(
      await permissions.ensure(context, AppPermission.notifications),
      isFalse,
    );
    expect(
      await permissions.ensure(context, AppPermission.notifications),
      isFalse,
    );
    expect(backend.requests, 2);
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('denied, then allowed at the prompt: goes ahead', (tester) async {
    await pumpApp(tester);
    final backend = _Backend(PermissionStatus.denied)
      ..onRequest = () => _prompted(tester, PermissionStatus.granted);
    final permissions = AppPermissions(backend: backend);

    expect(
      await permissions.ensure(context, AppPermission.notifications),
      isTrue,
    );
  });

  testWidgets(
    'Android, permanently denied: the prompt is skipped, status said denied, '
    'and the dialog still appears',
    (tester) async {
      await pumpApp(tester);
      final backend = _Backend(PermissionStatus.denied)
        ..onRequest = () async => PermissionStatus.permanentlyDenied;
      final permissions = AppPermissions(backend: backend);
      final results = <bool>[];
      final settle = start(
        tester,
        permissions,
        AppPermission.notifications,
        results,
      );

      expect(await settle(), isNull);
      expect(find.text('Notifications are off'), findsOneWidget);
    },
  );

  testWidgets(
    'Android 12 and below: "denied" with no prompt shows the dialog, not nothing',
    (tester) async {
      await pumpApp(tester);
      final permissions = AppPermissions(
        backend: _Backend(PermissionStatus.denied),
      );
      final results = <bool>[];
      final settle = start(
        tester,
        permissions,
        AppPermission.notifications,
        results,
      );

      expect(await settle(), isNull);
      expect(find.text('Notifications are off'), findsOneWidget);
    },
  );

  for (final status in [
    PermissionStatus.permanentlyDenied,
    PermissionStatus.restricted,
  ]) {
    testWidgets('$status: explains without asking; Cancel stops', (
      tester,
    ) async {
      await pumpApp(tester);
      final backend = _Backend(status);
      final permissions = AppPermissions(backend: backend);
      final results = <bool>[];
      final settle = start(
        tester,
        permissions,
        AppPermission.notifications,
        results,
      );
      await settle();
      expect(backend.requests, 0);

      await tester.tap(find.text('Cancel'));
      expect(await settle(), isFalse);
      expect(backend.settingsOpened, 0);
      expect(find.byType(AlertDialog), findsNothing);
    });
  }

  testWidgets('Open Settings: turned on there, the action continues', (
    tester,
  ) async {
    await pumpApp(tester);
    final backend = _Backend(PermissionStatus.permanentlyDenied);
    final permissions = AppPermissions(backend: backend);
    final results = <bool>[];
    final settle = start(
      tester,
      permissions,
      AppPermission.notifications,
      results,
    );
    await settle();

    await tester.tap(find.text('Open Settings'));
    expect(await settle(), isNull);
    expect(backend.settingsOpened, 1);

    backend.current = PermissionStatus.granted;
    leaveAndComeBack(tester);
    expect(await settle(), isTrue);
  });

  testWidgets('Open Settings: left off there, the action stops', (
    tester,
  ) async {
    await pumpApp(tester);
    final backend = _Backend(PermissionStatus.permanentlyDenied);
    final permissions = AppPermissions(backend: backend);
    final results = <bool>[];
    final settle = start(
      tester,
      permissions,
      AppPermission.notifications,
      results,
    );
    await settle();
    await tester.tap(find.text('Open Settings'));
    await settle();

    leaveAndComeBack(tester);
    expect(await settle(), isFalse);
  });

  testWidgets('a flick through inactive is not coming back from Settings', (
    tester,
  ) async {
    await pumpApp(tester);
    final backend = _Backend(PermissionStatus.permanentlyDenied);
    final permissions = AppPermissions(backend: backend);
    final results = <bool>[];
    final settle = start(
      tester,
      permissions,
      AppPermission.notifications,
      results,
    );
    await settle();
    await tester.tap(find.text('Open Settings'));
    await settle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(await settle(), isNull);

    backend.current = PermissionStatus.granted;
    leaveAndComeBack(tester);
    expect(await settle(), isTrue);
  });

  testWidgets('Settings that will not open: stops', (tester) async {
    await pumpApp(tester);
    final backend = _Backend(PermissionStatus.permanentlyDenied)
      ..canOpenSettings = false;
    final permissions = AppPermissions(backend: backend);
    final results = <bool>[];
    final settle = start(
      tester,
      permissions,
      AppPermission.notifications,
      results,
    );
    await settle();
    await tester.tap(find.text('Open Settings'));
    expect(await settle(), isFalse);
  });

  testWidgets('a new tap replaces an unfinished trip: one action, not two', (
    tester,
  ) async {
    await pumpApp(tester);
    final backend = _Backend(PermissionStatus.permanentlyDenied);
    final permissions = AppPermissions(backend: backend);
    final first = <bool>[];
    final settleFirst = start(
      tester,
      permissions,
      AppPermission.notifications,
      first,
    );
    await settleFirst();
    await tester.tap(find.text('Open Settings'));
    await settleFirst();

    // Back (without the app having noticed), and tapped again: now allowed.
    backend.current = PermissionStatus.granted;
    expect(
      await permissions.ensure(context, AppPermission.notifications),
      isTrue,
    );
    await settleFirst();
    expect(first, [false]);
  });

  testWidgets('a second tap while the prompt is up does not ask twice', (
    tester,
  ) async {
    await pumpApp(tester);
    final answer = Completer<PermissionStatus>();
    final backend = _Backend(PermissionStatus.denied)
      ..onRequest = () => answer.future;
    final permissions = AppPermissions(backend: backend);

    final first = permissions.ensure(context, AppPermission.notifications);
    await tester.pump();
    expect(
      await permissions.ensure(context, AppPermission.notifications),
      isFalse,
    );
    answer.complete(PermissionStatus.granted);
    expect(await first, isTrue);
    expect(backend.requests, 1);
  });

  testWidgets('a failing check leaves the outcome to the action', (
    tester,
  ) async {
    await pumpApp(tester);
    final backend = _Backend(PermissionStatus.denied)
      ..onRequest = () => throw StateError('no plugin');
    final permissions = AppPermissions(backend: backend);
    expect(
      await permissions.ensure(context, AppPermission.notifications),
      isTrue,
    );
    // And the next tap isn't stuck behind the failed one.
    backend.onRequest = () => _prompted(tester, PermissionStatus.denied);
    expect(
      await permissions.ensure(context, AppPermission.notifications),
      isFalse,
    );
  });

  group('camera', () {
    testWidgets('Android needs no permission: nothing is asked', (
      tester,
    ) async {
      await pumpApp(tester);
      final backend = _Backend(PermissionStatus.permanentlyDenied);
      final permissions = AppPermissions(backend: backend);

      expect(await permissions.ensure(context, AppPermission.camera), isTrue);
      expect(await permissions.isGranted(AppPermission.camera), isTrue);
      expect(await permissions.requestQuietly(AppPermission.camera), isTrue);
      expect(backend.requests, 0);
    });

    testWidgets('iOS denied: the camera dialog, in Arabic too', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await pumpApp(tester, locale: const Locale('ar'));
      final permissions = AppPermissions(
        backend: _Backend(PermissionStatus.permanentlyDenied),
      );
      final results = <bool>[];
      final settle = start(tester, permissions, AppPermission.camera, results);
      await settle();

      expect(find.text('الوصول إلى الكاميرا مُعطّل'), findsOneWidget);
      expect(find.text('فتح الإعدادات'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('requestQuietly (app start)', () {
    testWidgets('asks when it can', (tester) async {
      final backend = _Backend(PermissionStatus.denied)
        ..onRequest = () async => PermissionStatus.granted;
      expect(
        await AppPermissions(
          backend: backend,
        ).requestQuietly(AppPermission.notifications),
        isTrue,
      );
    });

    testWidgets('never shows the dialog', (tester) async {
      await pumpApp(tester);
      final permissions = AppPermissions(
        backend: _Backend(PermissionStatus.permanentlyDenied),
      );
      expect(
        await permissions.requestQuietly(AppPermission.notifications),
        isFalse,
      );
      await tester.pump();
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
