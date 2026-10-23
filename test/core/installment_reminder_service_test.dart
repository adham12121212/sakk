import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakk/core/service/reminder_settings.dart';
import 'package:sakk/core/error/failure.dart';
import 'package:sakk/core/logger/app_logger.dart';
import 'package:sakk/core/service/installment_reminder_service.dart';
import 'package:sakk/core/service/notification_service.dart';
import 'package:sakk/core/util/notification_ids.dart';
import 'package:sakk/core/util/notified_warranties_tracker.dart';
import 'package:sakk/features/auth/domain/entities/user_entity.dart';
import 'package:sakk/features/auth/domain/usecase/get_user_usecase.dart';
import 'package:sakk/features/installments/domain/entities/installment_payment.dart';
import 'package:sakk/features/installments/domain/entities/installment_plan.dart';
import 'package:sakk/features/installments/domain/usecase/get_installment_plans_usecase.dart';
import 'package:sakk/features/installments/domain/usecase/set_payment_paid_usecase.dart';
import 'package:sakk/features/installments/presentation/cubit/installments_cubit.dart';
import 'package:sakk/features/notification/domain/entities/notification_enitiy.dart';
import 'package:sakk/features/notification/domain/usecase/add_notification_use_case.dart';

import '../features/installments/installment_fixtures.dart';

class _User implements GetUserUseCase {
  @override
  UserEntity? call() => UserEntity(id: 'u', email: 'e', name: 'n');
}

class _AddNotification implements AddNotificationUseCase {
  final added = <String>[];
  @override
  Future<Either<Failure, void>> call({
    required String userId,
    required String title,
    required String subtitle,
    required NotificationType type,
    String? productId,
  }) async {
    added.add(subtitle);
    return const Right(null);
  }
}

class _Tracker implements NotifiedWarrantiesTracker {
  final seen = <String>{};
  @override
  Future<bool> hasNotified(String p, String s) async => seen.contains('$p:$s');
  @override
  Future<void> markNotified(String p, String s) async => seen.add('$p:$s');
}

/// Records scheduled reminders by id; skips past dates like the real one.
class _Notifications implements NotificationService {
  final scheduled = <int, DateTime>{};
  final bodies = <int, String>{};
  final payloads = <int, String?>{};
  final buttons = <int, String?>{};
  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
    String? payload,
    dynamic matchDateTimeComponents,
    String? markPaidLabel,
  }) async {
    if (dateTime.isBefore(DateTime.now())) return;
    scheduled[id] = dateTime;
    bodies[id] = body;
    payloads[id] = payload;
    buttons[id] = markPaidLabel;
  }

  @override
  Future<void> cancelNotification(int id) async => scheduled.remove(id);
  @override
  Future<List<PendingNotificationRequest>> pendingNotifications() async => [
    for (final id in scheduled.keys)
      PendingNotificationRequest(id, null, null, null),
  ];
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _NoLog implements AppLogger {
  @override
  dynamic noSuchMethod(Invocation i) {}
}

DateTime get today {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime at10(DateTime day, int offset) =>
    DateTime(day.year, day.month, day.day + offset, 10);

int idOf(String paymentId, InstallmentReminder kind) =>
    InstallmentReminderService.notificationId(paymentId, kind);

void main() {
  late _Notifications notifications;
  late _AddNotification added;
  late _Tracker tracker;
  late ValueNotifier<Locale> locale;
  late InstallmentReminderService service;

  setUp(() {
    notifications = _Notifications();
    added = _AddNotification();
    tracker = _Tracker();
    locale = ValueNotifier(const Locale('en'));
    service = InstallmentReminderService(
      getUserUseCase: _User(),
      addNotificationUseCase: added,
      tracker: tracker,
      localNotifications: notifications,
      logger: _NoLog(),
      locale: locale,
    );
  });

  /// 12 x 1,000 EGP, the first due [days] from today.
  InstallmentPlan dueIn(
    String id,
    int days, {
    Set<int> paid = const {},
    bool cancelled = false,
  }) => plan(
    id,
    t: terms(total: 12000, count: 12, start: today.add(Duration(days: days))),
    paid: paid,
    cancelled: cancelled,
  );

  test(
    'reminds 3 days before and on the due day at 10:00, with Mark as paid',
    () async {
      final tv = dueIn('tv', 10);
      await service.syncAll([tv]);
      final due = tv.payments.first.dueDate;

      expect(notifications.scheduled, {
        idOf('tv-p0', InstallmentReminder.threeDaysBefore): at10(due, -3),
        idOf('tv-p0', InstallmentReminder.dueDay): at10(due, 0),
      });
      final id = idOf('tv-p0', InstallmentReminder.dueDay);
      expect(notifications.buttons[id], 'Mark as paid');
      expect(notifications.bodies[id], 'tv: 1,000 EGP is due today');
      final payload = InstallmentReminderPayload.tryParse(
        notifications.payloads[id],
      );
      expect(
        [payload!.userId, payload.planId, payload.paymentId],
        ['u', 'tv', 'tv-p0'],
      );
    },
  );

  test('only the next unpaid installment; paid ones get none', () async {
    await service.syncAll([
      dueIn('tv', -20, paid: {0}),
    ]); // 2nd due in ~10 days
    expect(
      notifications.scheduled.keys.map(reminderSlot).toSet(),
      installmentReminderSlots,
    );
    expect(
      notifications.scheduled.containsKey(
        idOf('tv-p1', InstallmentReminder.dueDay),
      ),
      isTrue,
    );
    expect(
      notifications.scheduled.containsKey(
        idOf('tv-p0', InstallmentReminder.dueDay),
      ),
      isFalse,
    );
  });

  test('an overdue installment is skipped for the next one', () async {
    // 1st was due 5 days ago and is unpaid; the 2nd is next month.
    final tv = dueIn('tv', -5);
    await service.syncAll([tv]);
    expect(
      notifications.scheduled.containsKey(
        idOf('tv-p1', InstallmentReminder.dueDay),
      ),
      isTrue,
    );
    expect(
      notifications.scheduled.keys.any(
        (id) => id == idOf('tv-p0', InstallmentReminder.dueDay),
      ),
      isFalse,
    );
  });

  test('no reminders for paid-off or cancelled plans', () async {
    final done = plan(
      'done',
      t: terms(count: 1, total: 100, start: today.add(const Duration(days: 9))),
      paid: {0},
    );
    await service.syncAll([done, dueIn('cancelled', 9, cancelled: true)]);
    expect(notifications.scheduled, isEmpty);
  });

  test(
    're-syncing cancels what changed and leaves other features alone',
    () async {
      notifications.scheduled[reminderNotificationId('sub-1', 5)] = today.add(
        const Duration(days: 30),
      );
      final tv = dueIn('tv', 10);
      await service.syncAll([tv]);

      // Paid: the next installment takes over.
      await service.syncAll([
        tv.withPayment(tv.payments.first.withPaidAt(DateTime.now())),
      ]);
      expect(
        notifications.scheduled.containsKey(
          idOf('tv-p0', InstallmentReminder.dueDay),
        ),
        isFalse,
      );
      expect(
        notifications.scheduled.containsKey(
          idOf('tv-p1', InstallmentReminder.dueDay),
        ),
        isTrue,
      );

      // Deleted (or signed out).
      await service.syncAll([]);
      expect(notifications.scheduled.keys, [
        reminderNotificationId('sub-1', 5),
      ]);
    },
  );

  test('opening the app inside the window adds one in-app reminder', () async {
    final tv = dueIn('tv', 2);
    await service.checkAndNotify([tv], today: today);
    await service.checkAndNotify([tv], today: today);
    expect(added.added, ['tv: 1,000 EGP is due in 2 days']);
    // Not scheduled ahead on this device, so it also pushes now.
    expect(
      notifications.scheduled.containsKey(
        idOf('tv-p0', InstallmentReminder.threeDaysBefore),
      ),
      isTrue,
    );

    await service.checkAndNotify([dueIn('tv', 0)], today: today);
    expect(added.added.last, 'tv: 1,000 EGP is due today');
  });

  test('no second push when the reminder was scheduled ahead', () async {
    final tv = dueIn('tv', 10);
    await service.syncAll([tv]);
    notifications.scheduled.clear();
    await service.checkAndNotify([
      tv,
    ], today: tv.payments.first.dueDate.subtract(const Duration(days: 3)));
    expect(added.added, hasLength(1));
    expect(notifications.scheduled, isEmpty);
  });

  test('follows the app language', () async {
    final tv = dueIn('tv', 10);
    service.followLanguage(() => [tv]);
    locale.value = const Locale('ar');
    await service.syncAll([tv]);
    final id = idOf('tv-p0', InstallmentReminder.threeDaysBefore);
    expect(notifications.bodies[id], 'tv: قسط ١٬٠٠٠ ج.م مستحق بعد ٣ أيام');
    expect(notifications.buttons[id], 'تسجيل كمدفوع');
  });

  test('payload round-trips and ignores other notifications', () {
    const p = InstallmentReminderPayload(
      userId: 'u',
      planId: 'p',
      paymentId: 'x',
    );
    final back = InstallmentReminderPayload.tryParse(p.encode())!;
    expect([back.userId, back.planId, back.paymentId], ['u', 'p', 'x']);
    expect(InstallmentReminderPayload.tryParse('some-user-id'), isNull);
    expect(InstallmentReminderPayload.tryParse(null), isNull);
  });

  group('InstallmentsCubit keeps reminders in step', () {
    test(
      'marking paid moves the reminders on; the reminder button works on a cold start',
      () async {
        final tv = dueIn('tv', 10);
        final repoPlans = [tv];
        final cubit = InstallmentsCubit(
          _Get(repoPlans),
          _SetPaid(repoPlans),
          reminders: service,
          clock: () => today,
        );
        expect(await cubit.markPaidFromReminder('tv', 'tv-p0'), isNull);
        await Future<void>.delayed(Duration.zero);
        await service.syncAll(cubit.state.plans); // let the queued syncs finish
        expect(cubit.state.planById('tv')!.paidCount, 1);
        expect(
          notifications.scheduled.containsKey(
            idOf('tv-p1', InstallmentReminder.dueDay),
          ),
          isTrue,
        );

        // Pressing it again (already paid) changes nothing.
        expect(await cubit.markPaidFromReminder('tv', 'tv-p0'), isNull);
        expect(cubit.state.planById('tv')!.paidCount, 1);

        cubit.reset();
        await service.syncAll(const []);
        expect(notifications.scheduled, isEmpty);
        await cubit.close();
      },
    );
  });

  test(
    'only the reminders chosen in Reminders are scheduled and shown',
    () async {
      SharedPreferences.setMockInitialValues({});
      final settings = ReminderSettings();
      await settings.ready;
      final chosen = InstallmentReminderService(
        getUserUseCase: _User(),
        addNotificationUseCase: added,
        tracker: tracker,
        localNotifications: notifications,
        logger: _NoLog(),
        locale: locale,
        settings: settings,
      );
      final tv = dueIn('tv', 10);
      chosen.followLanguage(() => [tv]);

      await settings.setInstallmentKind(
        InstallmentReminder.threeDaysBefore,
        false,
      );
      await chosen.syncAll([tv]);
      expect(notifications.scheduled.keys.toSet(), {
        idOf('tv-p0', InstallmentReminder.dueDay),
      });

      await settings.setInstallmentsEnabled(false);
      await chosen.syncAll([tv]);
      expect(notifications.scheduled, isEmpty);
      await chosen.checkAndNotify([dueIn('tv', 0)], today: today);
      expect(added.added, isEmpty);
    },
  );
}

class _Get implements GetInstallmentPlansUseCase {
  _Get(this.plans);
  final List<InstallmentPlan> plans;
  @override
  Future<Either<Failure, List<InstallmentPlan>>> call() async =>
      Right(List.of(plans));
}

class _SetPaid implements SetPaymentPaidUseCase {
  _SetPaid(this.plans);
  final List<InstallmentPlan> plans;
  @override
  Future<Either<Failure, InstallmentPayment>> call(
    String paymentId, {
    required bool paid,
    DateTime? paidAt,
  }) async {
    final p = plans
        .expand((plan) => plan.payments)
        .firstWhere((p) => p.id == paymentId);
    return Right(p.withPaidAt(paid ? DateTime.now() : null));
  }
}
