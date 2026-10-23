import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/error/failure.dart';
import 'package:sakk/core/logger/app_logger.dart';
import 'package:sakk/core/service/installment_reminder_service.dart';
import 'package:sakk/core/service/notification_service.dart';
import 'package:sakk/core/service/reminder_settings.dart';
import 'package:sakk/core/service/subscription_reminder_service.dart';
import 'package:sakk/core/util/notification_ids.dart';
import 'package:sakk/core/util/notified_warranties_tracker.dart';
import 'package:sakk/features/auth/domain/entities/user_entity.dart';
import 'package:sakk/features/auth/domain/usecase/get_user_usecase.dart';
import 'package:sakk/features/notification/domain/entities/notification_enitiy.dart';
import 'package:sakk/features/notification/domain/usecase/add_notification_use_case.dart';
import 'package:sakk/features/subscriptions/domain/entities/billing_cycle.dart';
import 'package:sakk/features/subscriptions/domain/entities/user_subscription.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// One notification store for both services, keeping payloads like the
/// real plugin does, so they can be told apart in the shared slot.
class _Notifications implements NotificationService {
  final scheduled = <int, DateTime>{};
  final bodies = <int, String>{};
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

DateTime at10(DateTime day, int offset) =>
    DateTime(day.year, day.month, day.day + offset, 10);

void main() {
  late _Notifications notifications;
  late _AddNotification added;
  late ReminderSettings settings;
  late SubscriptionReminderService subscriptions;
  late InstallmentReminderService installments;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = ReminderSettings();
    await settings.ready;
    notifications = _Notifications();
    added = _AddNotification();
    final tracker = _Tracker();
    final locale = ValueNotifier(const Locale('en'));
    subscriptions = SubscriptionReminderService(
      getUserUseCase: _User(),
      addNotificationUseCase: added,
      tracker: tracker,
      localNotifications: notifications,
      logger: _NoLog(),
      locale: locale,
      settings: settings,
    );
    installments = InstallmentReminderService(
      getUserUseCase: _User(),
      addNotificationUseCase: added,
      tracker: tracker,
      localNotifications: notifications,
      logger: _NoLog(),
      locale: locale,
      settings: settings,
    );
  });

  final netflix = UserSubscription(
    id: 'netflix',
    customName: 'Netflix',
    price: 240,
    billingCycle: BillingCycle.monthly,
    nextRenewalDate: today.add(const Duration(days: 20)),
  );
  final tv = plan(
    'tv',
    t: terms(
      total: 12000,
      count: 12,
      start: today.add(const Duration(days: 20)),
    ),
  );
  final subCustomId = SubscriptionReminderService.notificationId(
    'netflix',
    RenewalReminder.custom,
  );
  final instCustomId = InstallmentReminderService.notificationId(
    'tv-p0',
    InstallmentReminder.custom,
  );

  test('free users get no Pro reminder, even with days saved', () async {
    await settings.setSubscriptionCustomDays(7);
    await settings.setInstallmentCustomDays(7);
    await subscriptions.syncAll([netflix]);
    await installments.syncAll([tv]);
    expect(
      notifications.scheduled.keys.map(reminderSlot),
      isNot(contains(customReminderSlot)),
    );
  });

  test(
    'Pro: N days before at 10:00, with the regular reminders untouched',
    () async {
      settings.setProActive(true);
      await settings.setSubscriptionCustomDays(7);
      await settings.setInstallmentCustomDays(14);
      await subscriptions.syncAll([netflix]);
      await installments.syncAll([tv]);

      expect(
        notifications.scheduled[subCustomId],
        at10(netflix.nextRenewalDate, -7),
      );
      expect(
        notifications.bodies[subCustomId],
        'Netflix renews in 7 days for 240 EGP',
      );
      expect(
        notifications.scheduled[instCustomId],
        at10(tv.payments.first.dueDate, -14),
      );
      expect(notifications.payloads[instCustomId], startsWith('installment|'));
      // The 3-day ones are still there.
      expect(
        notifications.scheduled.containsKey(
          SubscriptionReminderService.notificationId(
            'netflix',
            RenewalReminder.threeDaysBefore,
          ),
        ),
        isTrue,
      );
    },
  );

  test(
    'the shared slot: each service re-syncs without cancelling the other\'s',
    () async {
      settings.setProActive(true);
      await settings.setSubscriptionCustomDays(7);
      await settings.setInstallmentCustomDays(7);
      await subscriptions.syncAll([netflix]);
      await installments.syncAll([tv]);

      // Subscriptions emptied (e.g. the last one deleted): only theirs go.
      await subscriptions.syncAll(const []);
      expect(notifications.scheduled.containsKey(subCustomId), isFalse);
      expect(notifications.scheduled.containsKey(instCustomId), isTrue);

      await subscriptions.syncAll([netflix]);
      await installments.syncAll(const []);
      expect(notifications.scheduled.containsKey(instCustomId), isFalse);
      expect(notifications.scheduled.containsKey(subCustomId), isTrue);
    },
  );

  test('Pro ending stops the Pro reminders and keeps the choice', () async {
    settings.setProActive(true);
    await settings.setSubscriptionCustomDays(10);
    await subscriptions.syncAll([netflix]);
    expect(notifications.scheduled.containsKey(subCustomId), isTrue);

    settings.setProActive(false);
    await subscriptions.syncAll([netflix]);
    expect(notifications.scheduled.containsKey(subCustomId), isFalse);
    expect(settings.subscriptionCustomDays, 10);
  });

  test(
    'opening the app on the day adds the in-app notification once',
    () async {
      settings.setProActive(true);
      await settings.setInstallmentCustomDays(5);
      final soon = plan(
        'fridge',
        t: terms(start: today.add(const Duration(days: 5))),
      );
      await installments.checkAndNotify([soon], today: today);
      await installments.checkAndNotify([soon], today: today);
      expect(added.added, ['fridge: 1,000 EGP is due in 5 days']);
    },
  );

  test('the saved choice survives a restart; bad values are ignored', () async {
    await settings.setSubscriptionCustomDays(14);
    final reloaded = ReminderSettings();
    await reloaded.ready;
    expect(reloaded.subscriptionCustomDays, 14);
    expect(reloaded.activeSubscriptionCustomDays, isNull);

    SharedPreferences.setMockInitialValues({
      'reminders_installment_custom_days': 3,
    });
    final bad = ReminderSettings();
    await bad.ready;
    expect(bad.installmentCustomDays, isNull);
  });
}
