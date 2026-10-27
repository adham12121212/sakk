import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakk/core/service/reminder_settings.dart';
import 'package:sakk/core/error/failure.dart';
import 'package:sakk/core/logger/app_logger.dart';
import 'package:sakk/core/service/notification_service.dart';
import 'package:sakk/core/service/subscription_reminder_service.dart';
import 'package:sakk/core/util/notification_ids.dart';
import 'package:sakk/core/util/notified_warranties_tracker.dart';
import 'package:sakk/features/auth/domain/entities/user_entity.dart';
import 'package:sakk/features/auth/domain/usecase/get_user_usecase.dart';
import 'package:sakk/features/notification/domain/entities/notification_entity.dart';
import 'package:sakk/features/notification/domain/usecase/add_notification_use_case.dart';
import 'package:sakk/features/subscriptions/domain/entities/billing_cycle.dart';
import 'package:sakk/features/subscriptions/domain/entities/user_subscription.dart';
import 'package:sakk/features/subscriptions/domain/renewal_schedule.dart';

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

/// A monthly subscription renewing [days] from today. [createdDaysAgo] null
/// means unknown, so no "renewed" reminder for the previous renewal.
UserSubscription renewingIn(
  String id,
  int days, {
  double price = 240,
  String currency = 'EGP',
  int? createdDaysAgo,
}) {
  return UserSubscription(
    id: id,
    customName: id,
    price: price,
    currency: currency,
    billingCycle: BillingCycle.monthly,
    nextRenewalDate: today.add(Duration(days: days)),
    createdAt: createdDaysAgo == null
        ? null
        : today.subtract(Duration(days: createdDaysAgo)),
  );
}

DateTime at10(DateTime day, int offset) =>
    DateTime(day.year, day.month, day.day + offset, 10);

int idOf(String sub, RenewalReminder kind, {bool previous = false}) =>
    SubscriptionReminderService.notificationId(sub, kind, previous: previous);

void main() {
  late _Notifications notifications;
  late _AddNotification added;
  late _Tracker tracker;
  late ValueNotifier<Locale> locale;
  late SubscriptionReminderService service;

  setUp(() {
    notifications = _Notifications();
    added = _AddNotification();
    tracker = _Tracker();
    locale = ValueNotifier(const Locale('en'));
    service = SubscriptionReminderService(
      getUserUseCase: _User(),
      addNotificationUseCase: added,
      tracker: tracker,
      localNotifications: notifications,
      logger: _NoLog(),
      locale: locale,
    );
  });

  test(
    'schedules 3 days before, the day before and the day after, at 10:00',
    () async {
      final netflix = renewingIn('Netflix', 10);
      await service.syncAll([netflix]);
      final r = netflix.nextRenewalDate;

      expect(notifications.scheduled, {
        idOf('Netflix', RenewalReminder.threeDaysBefore): at10(r, -3),
        idOf('Netflix', RenewalReminder.dayBefore): at10(r, -1),
        idOf('Netflix', RenewalReminder.dayAfter): at10(r, 1),
      });
      expect(
        notifications.bodies[idOf('Netflix', RenewalReminder.threeDaysBefore)],
        'Netflix renews in 3 days for 240 EGP',
      );
      expect(
        notifications.bodies[idOf('Netflix', RenewalReminder.dayBefore)],
        'Netflix renews tomorrow for 240 EGP',
      );
      expect(
        notifications.bodies[idOf('Netflix', RenewalReminder.dayAfter)],
        'Netflix renewed yesterday for 240 EGP. Check you were charged the right amount.',
      );
      expect(
        notifications.scheduled.keys.map(reminderSlot).toSet(),
        everyElement(isIn(subscriptionReminderSlots)),
      );
    },
  );

  test(
    'the "renewed" reminder for a renewal that just passed survives the date moving on',
    () async {
      // Renewed today (the date already moved a month on), existed before.
      final sub = renewingIn(
        'Spotify',
        0,
        createdDaysAgo: 60,
      ).copyWith(nextRenewalDate: addMonthsClamped(today, 1));
      await service.syncAll([sub]);
      expect(
        notifications.scheduled[idOf(
          'Spotify',
          RenewalReminder.dayAfter,
          previous: true,
        )],
        at10(today, 1),
      );
      // And the next renewal's reminders are there too.
      expect(
        notifications.scheduled[idOf('Spotify', RenewalReminder.dayAfter)],
        at10(sub.nextRenewalDate, 1),
      );
    },
  );

  test('a subscription added today never hears "renewed yesterday"', () async {
    final added0 = renewingIn(
      'Gym',
      30,
      createdDaysAgo: 0,
    ).copyWith(nextRenewalDate: addMonthsClamped(today, 1));
    await service.syncAll([added0]);
    expect(
      notifications.scheduled.containsKey(
        idOf('Gym', RenewalReminder.dayAfter, previous: true),
      ),
      isFalse,
    );

    await service.checkAndNotify([
      added0,
    ], today: today.add(const Duration(days: 1)));
    expect(added.added, isEmpty);
  });

  test(
    'sync cancels stale subscription reminders but never warranty ones',
    () async {
      final warrantyId = reminderNotificationId('fridge', 0);
      notifications.scheduled[warrantyId] = DateTime.now().add(
        const Duration(days: 90),
      );

      await service.syncAll([renewingIn('a', 10), renewingIn('b', 20)]);
      expect(notifications.scheduled, hasLength(1 + 3 + 3));

      await service.syncAll([renewingIn('a', 10)]); // "b" deleted
      expect(notifications.scheduled, hasLength(1 + 3));

      await service.syncAll(const []); // signed out
      expect(notifications.scheduled.keys, [warrantyId]);
    },
  );

  test(
    'inside each window: one in-app entry each, no second push when one was scheduled',
    () async {
      final netflix = renewingIn('Netflix', 5);
      await service.syncAll([
        netflix,
      ]); // all three scheduled ahead on this device
      notifications.scheduled
          .clear(); // ...and have fired by the time the app opens

      await service.checkAndNotify([
        netflix,
      ], today: today.add(const Duration(days: 2))); // 3 days left
      await service.checkAndNotify([
        netflix,
      ], today: today.add(const Duration(days: 2))); // opened again
      await service.checkAndNotify([
        netflix,
      ], today: today.add(const Duration(days: 4))); // 1 day left
      expect(added.added, [
        'Netflix renews in 3 days for 240 EGP',
        'Netflix renews tomorrow for 240 EGP',
      ]);
      expect(notifications.scheduled, isEmpty); // nothing pushed twice
    },
  );

  test(
    'the day after a renewal: "renewed" in the list, pushed only if not scheduled ahead',
    () async {
      // Renewed yesterday; the app already moved the date on. Existed before.
      final sub = renewingIn('Shahid', 0, price: 100, createdDaysAgo: 90)
          .copyWith(
            nextRenewalDate: addMonthsClamped(
              today.subtract(const Duration(days: 1)),
              1,
            ),
          );

      await service.checkAndNotify([sub]);
      expect(added.added, [
        'Shahid renewed yesterday for 100 EGP. Check you were charged the right amount.',
      ]);
      // This device never scheduled it ahead, so it shows now, once.
      expect(notifications.shown, [
        idOf('Shahid', RenewalReminder.dayAfter, previous: true),
      ]);

      await service.checkAndNotify([sub]);
      expect(added.added, hasLength(1));
      expect(notifications.shown, hasLength(1));
    },
  );

  test(
    'added the day before it renews: "tomorrow" pushes once, scheduled or right away',
    () async {
      // "Tomorrow" is due today at 10:00, so whether it can still be scheduled
      // depends on the time the test runs; both cases must push exactly once.
      final beforeTen = DateTime.now().isBefore(at10(today, 0));
      final shahid = renewingIn('Shahid', 1, price: 100);
      await service.syncAll([shahid]); // too late for the 3-day push either way
      expect(notifications.scheduled.keys.toSet(), {
        if (beforeTen) idOf('Shahid', RenewalReminder.dayBefore),
        idOf('Shahid', RenewalReminder.dayAfter),
      });

      await service.checkAndNotify([shahid]);
      // Shown now either way; one still waiting for 10:00 is dropped.
      expect(notifications.shown, [idOf('Shahid', RenewalReminder.dayBefore)]);
      expect(notifications.scheduled.keys, [
        idOf('Shahid', RenewalReminder.dayAfter),
      ]);
      expect(added.added, ['Shahid renews tomorrow for 100 EGP']);

      await service.checkAndNotify([shahid]);
      expect(notifications.shown, hasLength(1));
      expect(added.added, hasLength(1));
    },
  );

  test('the next renewal reminds again; far-off ones do not yet', () async {
    final sub = renewingIn('Spotify', 2);
    await service.checkAndNotify([sub, renewingIn('Far', 10)]);
    expect(added.added, hasLength(1));

    final next = sub.copyWith(
      nextRenewalDate: addMonthsClamped(sub.nextRenewalDate, 1),
    );
    await service.checkAndNotify([next], today: addMonthsClamped(today, 1));
    expect(added.added, hasLength(2));
  });

  test('uses the app language and re-schedules when it changes', () async {
    final subs = [renewingIn('Netflix', 10, price: 5.99, currency: 'USD')];
    service.followLanguage(() => subs);
    await service.syncAll(subs);
    final before = idOf('Netflix', RenewalReminder.threeDaysBefore);
    final after = idOf('Netflix', RenewalReminder.dayAfter);
    expect(
      notifications.bodies[before],
      'Netflix renews in 3 days for 5.99 USD',
    );

    locale.value = const Locale('ar');
    await service.syncAll(subs); // waits behind the sync the change queued
    expect(
      notifications.bodies[before],
      'يتجدد Netflix بعد ٣ أيام بقيمة ٥٫٩٩ USD',
    );
    expect(
      notifications.bodies[after],
      'تم تجديد Netflix أمس بقيمة ٥٫٩٩ USD. تأكد من خصم المبلغ الصحيح.',
    );
  });

  test(
    'only the reminders chosen in Reminders are scheduled and shown',
    () async {
      SharedPreferences.setMockInitialValues({});
      final settings = ReminderSettings();
      await settings.ready;
      final chosen = SubscriptionReminderService(
        getUserUseCase: _User(),
        addNotificationUseCase: added,
        tracker: tracker,
        localNotifications: notifications,
        logger: _NoLog(),
        locale: locale,
        settings: settings,
      );
      final netflix = renewingIn('Netflix', 10);
      chosen.followLanguage(() => [netflix]);

      await settings.setSubscriptionKind(RenewalReminder.dayAfter, false);
      await chosen.syncAll([netflix]);
      expect(notifications.scheduled.keys.toSet(), {
        idOf('Netflix', RenewalReminder.threeDaysBefore),
        idOf('Netflix', RenewalReminder.dayBefore),
      });

      await settings.setSubscriptionsEnabled(false);
      await chosen.syncAll([netflix]);
      expect(notifications.scheduled, isEmpty);
      await chosen.checkAndNotify([renewingIn('Gym', 1)], today: today);
      expect(added.added, isEmpty);
    },
  );
}
