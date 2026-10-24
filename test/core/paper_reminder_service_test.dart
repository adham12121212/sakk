import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakk/core/error/failure.dart';
import 'package:sakk/core/logger/app_logger.dart';
import 'package:sakk/core/service/notification_service.dart';
import 'package:sakk/core/service/paper_reminder_service.dart';
import 'package:sakk/core/service/reminder_settings.dart';
import 'package:sakk/core/service/subscription_reminder_service.dart';
import 'package:sakk/core/service/installment_reminder_service.dart';
import 'package:sakk/core/util/notification_ids.dart';
import 'package:sakk/core/util/notified_warranties_tracker.dart';
import 'package:sakk/features/auth/domain/entities/user_entity.dart';
import 'package:sakk/features/auth/domain/usecase/get_user_usecase.dart';
import 'package:sakk/features/notification/domain/entities/notification_entity.dart';
import 'package:sakk/features/notification/domain/usecase/add_notification_use_case.dart';
import 'package:sakk/features/papers/domain/entities/paper.dart';

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

  /// Banners shown right away (not scheduled), by id.
  final shown = <int>[];
  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? markPaidLabel,
  }) async {
    shown.add(id);
    bodies[id] = body;
  }

  final payloads = <int, String?>{};
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
  }

  @override
  Future<void> cancelNotification(int id) async => scheduled.remove(id);
  @override
  Future<List<PendingNotificationRequest>> pendingNotifications() async => [
    for (final id in scheduled.keys)
      PendingNotificationRequest(id, null, null, payloads[id]),
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

Paper expiringIn(String id, int? days, {PaperKind kind = PaperKind.passport}) {
  return Paper(
    id: id,
    kind: kind,
    expiryDate: days == null ? null : inDays(days),
  );
}

/// Calendar days ahead (not 24-hour steps, which daylight saving shifts).
DateTime inDays(int days) =>
    DateTime(today.year, today.month, today.day + days);

DateTime at10(DateTime day, int offset) =>
    DateTime(day.year, day.month, day.day + offset, 10);

int idOf(String paper, PaperReminder kind) =>
    PaperReminderService.notificationId(paper, kind);

void main() {
  late _Notifications notifications;
  late _AddNotification added;
  late _Tracker tracker;
  late PaperReminderService service;

  PaperReminderService build({ReminderSettings? settings}) =>
      PaperReminderService(
        getUserUseCase: _User(),
        addNotificationUseCase: added,
        tracker: tracker,
        localNotifications: notifications,
        logger: _NoLog(),
        locale: ValueNotifier(const Locale('en')),
        settings: settings,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    notifications = _Notifications();
    added = _AddNotification();
    tracker = _Tracker();
    service = build();
  });

  test('schedules only the next reminder: a month before, at 10:00', () async {
    final expiry = inDays(90);
    await service.syncAll([expiringIn('p', 90)]);

    expect(notifications.scheduled, {
      idOf('p', PaperReminder.monthBefore): at10(expiry, -30),
    });
    expect(
      notifications.bodies.values.single,
      'Passport expires in 30 days. Time to renew it.',
    );
    expect(
      notifications.payloads.values.single,
      const PaperReminderPayload('u').encode(),
    );
  });

  test('moves on to the week-before and expiry-day reminders', () async {
    await service.syncAll([expiringIn('week', 20), expiringIn('day', 3)]);

    expect(notifications.scheduled.keys, {
      idOf('week', PaperReminder.weekBefore),
      idOf('day', PaperReminder.expiryDay),
    });
  });

  test('papers without an expiry date, or long expired, get none', () async {
    await service.syncAll([expiringIn('none', null), expiringIn('old', -5)]);
    expect(notifications.scheduled, isEmpty);
  });

  test('a deleted paper loses its reminder; other reminders stay', () async {
    final subscriptionId = SubscriptionReminderService.notificationId(
      's',
      RenewalReminder.dayBefore,
    );
    notifications.scheduled[subscriptionId] = inDays(2);
    await service.syncAll([expiringIn('p', 90)]);
    await service.syncAll([]);

    expect(notifications.scheduled.keys, [subscriptionId]);
  });

  test('ids never collide with the other reminders\' slots', () {
    final id = idOf('p', PaperReminder.monthBefore);
    expect(isPaperReminderId(id), isTrue);
    expect(reminderSlot(id), -1);
    expect(SubscriptionReminderService.ownsPending(id, null), isFalse);
    expect(InstallmentReminderService.ownsPending(id, null), isFalse);
    expect({
      for (final k in PaperReminder.values) idOf('p', k),
    }, hasLength(PaperReminder.values.length));
  });

  test('turned-off reminders are skipped', () async {
    final settings = ReminderSettings();
    await settings.ready;
    await settings.setPaperKind(PaperReminder.monthBefore, false);
    service = build(settings: settings);

    await service.syncAll([expiringIn('p', 90)]);
    expect(notifications.scheduled.keys, [idOf('p', PaperReminder.weekBefore)]);

    await settings.setPapersEnabled(false);
    await service.syncAll([expiringIn('p', 90)]);
    expect(notifications.scheduled, isEmpty);
  });

  group('on app open', () {
    test('adds an in-app notification once per reminder window', () async {
      final paper = expiringIn('p', 20);
      await service.checkAndNotify([paper]);
      // The next day, still inside the month-before window.
      await service.checkAndNotify([paper], today: inDays(1));

      expect(added.added, ['Passport expires in 20 days. Time to renew it.']);
      // Well past the month-before day: no push now, only the list entry.
      expect(notifications.scheduled, isEmpty);
    });

    test(
      'shows it as a banner now when it was never scheduled ahead',
      () async {
        await service.checkAndNotify([expiringIn('p', 7)]);

        expect(notifications.shown, [idOf('p', PaperReminder.weekBefore)]);
        expect(added.added, ['Passport expires in 7 days. Time to renew it.']);
      },
    );

    test('says so once it has expired', () async {
      await service.checkAndNotify([
        expiringIn('today', 0, kind: PaperKind.nationalId),
        expiringIn('yesterday', -1, kind: PaperKind.drivingLicence),
      ]);

      expect(added.added, [
        'National ID expires today.',
        'Driving licence has expired. Renew it as soon as you can.',
      ]);
    });

    test('a paper\'s own name is used when it has one', () async {
      await service.checkAndNotify([
        Paper(
          id: 'p',
          kind: PaperKind.passport,
          title: "Mona's passport",
          expiryDate: inDays(30),
        ),
      ]);
      expect(added.added, [
        "Mona's passport expires in 30 days. Time to renew it.",
      ]);
    });
  });

  test('due reminder windows', () {
    expect(PaperReminderService.dueReminder(31), isNull);
    expect(PaperReminderService.dueReminder(30), PaperReminder.monthBefore);
    expect(PaperReminderService.dueReminder(8), PaperReminder.monthBefore);
    expect(PaperReminderService.dueReminder(7), PaperReminder.weekBefore);
    expect(PaperReminderService.dueReminder(1), PaperReminder.weekBefore);
    expect(PaperReminderService.dueReminder(0), PaperReminder.expiryDay);
    expect(PaperReminderService.dueReminder(-1), PaperReminder.expiryDay);
    expect(PaperReminderService.dueReminder(-2), isNull);
  });

  test('payload round trip', () {
    const payload = PaperReminderPayload('user-1');
    expect(PaperReminderPayload.tryParse(payload.encode())?.userId, 'user-1');
    expect(PaperReminderPayload.tryParse('user-1'), isNull);
    expect(PaperReminderPayload.tryParse('installment|u|plan|payment'), isNull);
  });
}
