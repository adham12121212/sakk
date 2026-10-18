import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/service/installment_reminder_service.dart';
import 'package:sakk/core/service/reminder_controller.dart';
import 'package:sakk/core/service/reminder_settings.dart';
import 'package:sakk/core/service/subscription_reminder_service.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/features/notification/presentation/views/reminder_settings_view.dart';
import 'package:sakk/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ReminderSettings', () {
    test('everything is on by default', () async {
      final s = ReminderSettings();
      await s.ready;
      expect(s.warrantyEnabled && s.subscriptionsEnabled && s.installmentsEnabled, isTrue);
      // All but Sakk Pro's earlier reminder, which is off until days are picked.
      final subscriptionKinds = RenewalReminder.values.where((k) => k != RenewalReminder.custom);
      final installmentKinds = InstallmentReminder.values.where((k) => k != InstallmentReminder.custom);
      expect(subscriptionKinds.every(s.wantsSubscription), isTrue);
      expect(installmentKinds.every(s.wantsInstallment), isTrue);
      expect(s.wantsSubscription(RenewalReminder.custom), isFalse);
      expect(s.wantsInstallment(InstallmentReminder.custom), isFalse);
    });

    test('choices are remembered, and the switch keeps them while off', () async {
      final s = ReminderSettings();
      await s.ready;
      await s.setSubscriptionKind(RenewalReminder.dayAfter, false);
      await s.setInstallmentsEnabled(false);
      await s.setWarrantyEnabled(false);

      final again = ReminderSettings();
      await again.ready;
      expect(again.warrantyEnabled, isFalse);
      expect(again.subscriptionKinds, {RenewalReminder.threeDaysBefore, RenewalReminder.dayBefore});
      expect(again.wantsInstallment(InstallmentReminder.dueDay), isFalse);
      await again.setInstallmentsEnabled(true);
      expect(again.installmentKinds, {InstallmentReminder.threeDaysBefore, InstallmentReminder.dueDay});
    });

    test('the last reminder of a kind stays on', () async {
      final s = ReminderSettings();
      await s.ready;
      await s.setInstallmentKind(InstallmentReminder.threeDaysBefore, false);
      await s.setInstallmentKind(InstallmentReminder.dueDay, false);
      expect(s.installmentKinds, {InstallmentReminder.dueDay});
    });

    test('names this version does not know are ignored', () async {
      SharedPreferences.setMockInitialValues({'reminders_subscription_kinds': ['weekly', 'dayBefore']});
      final s = ReminderSettings();
      await s.ready;
      expect(s.subscriptionKinds, {RenewalReminder.dayBefore});
    });
  });

  group('ReminderSettingsView', () {
    Future<(ReminderSettings, ReminderController)> open(WidgetTester tester, {Locale locale = const Locale('en')}) async {
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
      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          locale: locale,
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ReminderSettingsView(settings: settings, leadTime: lead),
        ),
      ));
      await tester.pumpAndSettle();
      return (settings, lead);
    }

    testWidgets('three sections; switching one off hides its choices', (tester) async {
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

    testWidgets('Pro: an earlier reminder for subscriptions and installments', (tester) async {
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

    testWidgets('unticking a reminder saves it; the last one cannot be unticked', (tester) async {
      final (settings, _) = await open(tester);
      await tester.tap(find.text('The day after, to check the charge'));
      await tester.pumpAndSettle();
      expect(settings.subscriptionKinds.contains(RenewalReminder.dayAfter), isFalse);

      final installmentsEarly = find.text('3 days before').last; // installments
      await tester.ensureVisible(installmentsEarly);
      await tester.pumpAndSettle();
      await tester.tap(installmentsEarly);
      await tester.pumpAndSettle();
      await tester.tap(find.text('On the due day'));
      await tester.pumpAndSettle();
      expect(settings.installmentKinds, {InstallmentReminder.dueDay});
    });

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
