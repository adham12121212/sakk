import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/error/failure.dart';
import 'package:sakk/core/logger/app_logger.dart';
import 'package:sakk/core/service/notification_service.dart';
import 'package:sakk/core/service/subscription_reminder_service.dart';
import 'package:sakk/core/util/notification_ids.dart';
import 'package:sakk/core/util/notified_warranties_tracker.dart';
import 'package:sakk/features/auth/domain/entities/user_entity.dart';
import 'package:sakk/features/auth/domain/usecase/get_user_usecase.dart';
import 'package:sakk/features/notification/domain/entities/notification_enitiy.dart';
import 'package:sakk/features/notification/domain/usecase/add_notification_use_case.dart';
import 'package:sakk/features/subscriptions/domain/entities/billing_cycle.dart';
import 'package:sakk/features/subscriptions/domain/entities/user_subscription.dart';

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
  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
    String? payload,
    dynamic matchDateTimeComponents,
  }) async {
    if (dateTime.isBefore(DateTime.now())) return;
    scheduled[id] = dateTime;
    bodies[id] = body;
  }

  @override
  Future<void> cancelNotification(int id) async => scheduled.remove(id);
  @override
  Future<List<PendingNotificationRequest>> pendingNotifications() async =>
      [for (final id in scheduled.keys) PendingNotificationRequest(id, null, null, null)];
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _NoLog implements AppLogger {
  @override
  dynamic noSuchMethod(Invocation i) {}
}

UserSubscription renewingIn(String id, int days, {double price = 240, String currency = 'EGP'}) {
  final now = DateTime.now();
  return UserSubscription(
    id: id,
    customName: id,
    price: price,
    currency: currency,
    billingCycle: BillingCycle.monthly,
    nextRenewalDate: DateTime(now.year, now.month, now.day + days),
  );
}

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

  test('schedules a push at 10:00 three days before each renewal', () async {
    final netflix = renewingIn('Netflix', 10);
    await service.syncAll([netflix]);

    final id = SubscriptionReminderService.notificationId('Netflix');
    expect(reminderSlot(id), subscriptionRenewalSlot);
    final r = netflix.nextRenewalDate;
    expect(notifications.scheduled, {id: DateTime(r.year, r.month, r.day - 3, 10)});
    expect(notifications.bodies[id], 'Netflix renews in 3 days for 240 EGP');
  });

  test('sync cancels stale subscription reminders but never warranty ones', () async {
    final warrantyId = reminderNotificationId('fridge', 0);
    notifications.scheduled[warrantyId] = DateTime.now().add(const Duration(days: 90));

    await service.syncAll([renewingIn('a', 10), renewingIn('b', 20)]);
    expect(notifications.scheduled, hasLength(3));

    await service.syncAll([renewingIn('a', 10)]); // "b" deleted
    expect(notifications.scheduled.keys, unorderedEquals([warrantyId, SubscriptionReminderService.notificationId('a')]));

    await service.syncAll(const []); // signed out
    expect(notifications.scheduled.keys, [warrantyId]);
  });

  test('inside the window: one in-app entry per renewal, no second push if one was scheduled', () async {
    final netflix = renewingIn('Netflix', 5);
    await service.syncAll([netflix]); // scheduled ahead on this device

    // Two days later the app is opened inside the window.
    final later = DateTime.now().add(const Duration(days: 3));
    notifications.scheduled.clear(); // the scheduled push has fired
    await service.checkAndNotify([netflix], today: later);
    await service.checkAndNotify([netflix], today: later); // opened again
    expect(added.added, ['Netflix renews in 2 days for 240 EGP']);
    expect(notifications.scheduled, isEmpty);
  });

  test('added inside the window: pushes right away, once', () async {
    final shahid = renewingIn('Shahid', 1, price: 100);
    await service.syncAll([shahid]); // too late to schedule ahead
    expect(notifications.scheduled, isEmpty);

    await service.checkAndNotify([shahid]);
    expect(notifications.scheduled.keys, [SubscriptionReminderService.notificationId('Shahid')]);
    expect(added.added, ['Shahid renews tomorrow for 100 EGP']);

    notifications.scheduled.clear();
    await service.checkAndNotify([shahid]);
    expect(notifications.scheduled, isEmpty);
    expect(added.added, hasLength(1));
  });

  test('the next renewal reminds again; far-off ones do not yet', () async {
    final today = DateTime.now();
    final sub = renewingIn('Spotify', 2);
    await service.checkAndNotify([sub, renewingIn('Far', 10)]);
    expect(added.added, hasLength(1));

    final next = sub.copyWith(nextRenewalDate: DateTime(today.year, today.month + 1, today.day + 2));
    await service.checkAndNotify([next], today: DateTime(today.year, today.month + 1, today.day));
    expect(added.added, hasLength(2));
  });

  test('uses the app language and re-schedules when it changes', () async {
    final subs = [renewingIn('Netflix', 10, price: 5.99, currency: 'USD')];
    service.followLanguage(() => subs);
    await service.syncAll(subs);
    final id = SubscriptionReminderService.notificationId('Netflix');
    expect(notifications.bodies[id], 'Netflix renews in 3 days for 5.99 USD');

    locale.value = const Locale('ar');
    await service.syncAll(subs); // waits behind the sync the change queued
    expect(notifications.bodies[id], 'يتجدد Netflix بعد ٣ أيام بقيمة ٥٫٩٩ USD');
  });
}
