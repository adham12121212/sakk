import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sakk/core/service/app_permissions.dart';
import 'package:sakk/core/service/installment_reminder_service.dart';
import 'package:sakk/core/service/reminder_controller.dart';
import 'package:sakk/core/service/reminder_settings.dart';
import 'package:sakk/core/service/subscription_reminder_service.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/features/notification/presentation/views/reminder_settings_view.dart';
import 'package:sakk/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DeniedBackend extends PermissionBackend {
  PermissionStatus current = PermissionStatus.permanentlyDenied;

  @override
  Future<PermissionStatus> status(Permission permission) async => current;

  @override
  Future<bool> openSettings() async => true;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ReminderSettings', () {
    test('everything is on by default', () async {
      final s = ReminderSettings();
      await s.ready;
      expect(
        s.warrantyEnabled && s.subscriptionsEnabled && s.installmentsEnabled,
        isTrue,
      );
      // All but Sakk Pro's earlier reminder, which is off until days are picked.
      final subscriptionKinds = RenewalReminder.values.where(
        (k) => k != RenewalReminder.custom,
      );
      final installmentKinds = InstallmentReminder.values.where(
        (k) => k != InstallmentReminder.custom,
      );
      expect(subscriptionKinds.every(s.wantsSubscription), isTrue);
      expect(installmentKinds.every(s.wantsInstallment), isTrue);
      expect(s.wantsSubscription(RenewalReminder.custom), isFalse);
      expect(s.wantsInstallment(InstallmentReminder.custom), isFalse);
    });

    test(
      'choices are remembered, and the switch keeps them while off',
      () async {
        final s = ReminderSettings();
        await s.ready;
        await s.setSubscriptionKind(RenewalReminder.dayAfter, false);
        await s.setInstallmentsEnabled(false);
        await s.setWarrantyEnabled(false);

        final again = ReminderSettings();
        await again.ready;
        expect(again.warrantyEnabled, isFalse);
        expect(again.subscriptionKinds, {
          RenewalReminder.threeDaysBefore,
          RenewalReminder.dayBefore,
        });
        expect(again.wantsInstallment(InstallmentReminder.dueDay), isFalse);
        await again.setInstallmentsEnabled(true);
        expect(again.installmentKinds, {
          InstallmentReminder.threeDaysBefore,
          InstallmentReminder.dueDay,
        });
      },
    );

    test('the last reminder of a kind stays on', () async {
      final s = ReminderSettings();
      await s.ready;
      await s.setInstallmentKind(InstallmentReminder.threeDaysBefore, false);
      await s.setInstallmentKind(InstallmentReminder.dueDay, false);
      expect(s.installmentKinds, {InstallmentReminder.dueDay});
    });

    test('names this version does not know are ignored', () async {
      SharedPreferences.setMockInitialValues({
        'reminders_subscription_kinds': ['weekly', 'dayBefore'],
      });
      final s = ReminderSettings();
      await s.ready;
      expect(s.subscriptionKinds, {RenewalReminder.dayBefore});
    });
  });

  group('ReminderSettingsView', () {
    Future<(ReminderSettings, ReminderController)> open(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
      AppPermissions? permissions,
    }) async {
      // Phone width, tall enough for every section (the list builds lazily).
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final settings = ReminderSettings();
      final lead = ReminderController();
      await tester.runAsync(() async {
        await settings.ready;
        await lead.ready;
      });
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            locale: locale,
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ReminderSettingsView(
              settings: settings,
              leadTime: lead,
              permissions: permissions,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return (settings, lead);
    }

    testWidgets('three sections; switching one off hides its choices', (
      tester,
    ) async {
      final (settings, _) = await open(tester);
      expect(find.text('Warranties'), findsOneWidget);
      expect(find.text('Subscriptions'), findsOneWidget);
      expect(find.text('Installments'), findsOneWidget);
      expect(find.text('On the due day'), findsOneWidget);

      final installments = find.byType(Switch).at(2);
      await tester.ensureVisible(installments);
      await tester.pumpAndSettle();
      await tester.tap(installments);
      await tester.pumpAndSettle();
      expect(settings.installmentsEnabled, isFalse);
      expect(find.text('On the due day'), findsNothing);
    });

    testWidgets('switching on needs notifications; off never asks', (
      tester,
    ) async {
      final backend = _DeniedBackend();
      final (settings, _) = await open(
        tester,
        permissions: AppPermissions(backend: backend),
      );
      await tester.runAsync(() => settings.setInstallmentsEnabled(false));
      await tester.pumpAndSettle();

      final installments = find.byType(Switch).at(2);
      await tester.ensureVisible(installments);
      await tester.pumpAndSettle();

      // Blocked: the dialog explains, Cancel leaves the switch off.
      await tester.tap(installments);
      await tester.pumpAndSettle();
      expect(find.text('Open Settings'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(settings.installmentsEnabled, isFalse);

      // Turned on in Settings: the switch comes on after the check.
      await tester.tap(installments);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      backend.current = PermissionStatus.granted;
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
      await tester.pumpAndSettle();
      expect(settings.installmentsEnabled, isTrue);

      // Off works whatever the permission says.
      backend.current = PermissionStatus.permanentlyDenied;
      await tester.tap(installments);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(settings.installmentsEnabled, isFalse);
    });

    group('notifications-off banner', () {
      const hint =
          "Your reminders won't arrive until you allow notifications. "
          'Tap to turn them on.';

      void awayAndBack(WidgetTester tester) {
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
      }

      testWidgets('not shown while notifications are allowed', (tester) async {
        final backend = _DeniedBackend()..current = PermissionStatus.granted;
        await open(tester, permissions: AppPermissions(backend: backend));
        expect(find.text(hint), findsNothing);
      });

      testWidgets('not shown when the check fails', (tester) async {
        // No plugin in tests: the real backend throws.
        await open(tester);
        expect(find.text(hint), findsNothing);
      });

      testWidgets('tapping it explains, and allowing it there removes it', (
        tester,
      ) async {
        final backend = _DeniedBackend();
        await open(tester, permissions: AppPermissions(backend: backend));
        expect(find.text(hint), findsOneWidget);

        await tester.tap(find.text(hint));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open Settings'));
        await tester.pumpAndSettle();
        backend.current = PermissionStatus.granted;
        awayAndBack(tester);
        await tester.pumpAndSettle();
        expect(find.text(hint), findsNothing);
      });

      testWidgets('allowed in Settings on the side: gone on coming back', (
        tester,
      ) async {
        final backend = _DeniedBackend();
        await open(tester, permissions: AppPermissions(backend: backend));
        backend.current = PermissionStatus.granted;
        awayAndBack(tester);
        await tester.pumpAndSettle();
        expect(find.text(hint), findsNothing);
      });

      testWidgets('turned off in Settings on the side: back on coming back', (
        tester,
      ) async {
        final backend = _DeniedBackend()..current = PermissionStatus.granted;
        await open(tester, permissions: AppPermissions(backend: backend));
        backend.current = PermissionStatus.permanentlyDenied;
        awayAndBack(tester);
        await tester.pumpAndSettle();
        expect(find.text(hint), findsOneWidget);
      });

      testWidgets('not shown once every reminder is off', (tester) async {
        final (settings, _) = await open(
          tester,
          permissions: AppPermissions(backend: _DeniedBackend()),
        );
        await tester.runAsync(() async {
          await settings.setWarrantyEnabled(false);
          await settings.setSubscriptionsEnabled(false);
          await settings.setInstallmentsEnabled(false);
          await settings.setPapersEnabled(false);
        });
        await tester.pumpAndSettle();
        expect(find.text(hint), findsNothing);
      });

      testWidgets('lays out in Arabic', (tester) async {
        await open(
          tester,
          locale: const Locale('ar'),
          permissions: AppPermissions(backend: _DeniedBackend()),
        );
        expect(
          find.text('لن تصلك التذكيرات حتى تسمح بالإشعارات. اضغط لتفعيلها.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('Pro: an earlier reminder for subscriptions and installments', (
      tester,
    ) async {
      final (settings, _) = await open(tester);
      settings.setProActive(true);
      await tester.pumpAndSettle();
      expect(find.text('Earlier reminder'), findsNWidgets(2));

      await tester.tap(find.text('7 days').first);
      await tester.pumpAndSettle();
      expect(settings.subscriptionCustomDays, 7);
      expect(settings.wantsSubscription(RenewalReminder.custom), isTrue);

      await tester.tap(find.text('14 days').last);
      await tester.pumpAndSettle();
      expect(settings.installmentCustomDays, 14);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'unticking a reminder saves it; the last one cannot be unticked',
      (tester) async {
        final (settings, _) = await open(tester);
        await tester.tap(find.text('The day after, to check the charge'));
        await tester.pumpAndSettle();
        expect(
          settings.subscriptionKinds.contains(RenewalReminder.dayAfter),
          isFalse,
        );

        final installmentsEarly = find
            .text('3 days before')
            .last; // installments
        await tester.ensureVisible(installmentsEarly);
        await tester.pumpAndSettle();
        await tester.tap(installmentsEarly);
        await tester.pumpAndSettle();
        await tester.tap(find.text('On the due day'));
        await tester.pumpAndSettle();
        expect(settings.installmentKinds, {InstallmentReminder.dueDay});
      },
    );

    testWidgets('choosing how early warranty reminders come', (tester) async {
      final (_, lead) = await open(tester);
      await tester.tap(find.text('1 wk'));
      await tester.pumpAndSettle();
      expect(lead.value, 7);
    });

    testWidgets('lays out in Arabic', (tester) async {
      await open(tester, locale: const Locale('ar'));
      expect(tester.takeException(), isNull);
      expect(find.text('التذكيرات'), findsOneWidget);
    });
  });
}
