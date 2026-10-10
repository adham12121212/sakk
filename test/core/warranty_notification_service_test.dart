import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/error/Failure.dart';
import 'package:sakk/core/logger/app_logger.dart';
import 'package:sakk/core/service/notification_service.dart';
import 'package:sakk/core/service/reminder_controller.dart';
import 'package:sakk/core/service/warranty_notification_service.dart';
import 'package:sakk/core/util/notified_warranties_tracker.dart';
import 'package:sakk/features/auth/domain/entities/user_entity.dart';
import 'package:sakk/features/auth/domain/usecase/get_user_usecase.dart';
import 'package:sakk/features/notification/domain/entities/notification_enitiy.dart';
import 'package:sakk/features/notification/domain/usecase/add_notification_use_case.dart';
import 'package:sakk/features/products/domain/enties/product_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    added.add('$productId:$title');
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
  }

  @override
  Future<void> cancelNotification(int id) async => scheduled.remove(id);

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _NoLog implements AppLogger {
  @override
  dynamic noSuchMethod(Invocation i) {}
}

ProductEntity endingIn(String id, int days, {int? returnDays, DateTime? bought}) {
  final today = DateTime.now();
  final end = DateTime(today.year, today.month, today.day + days);
  return ProductEntity(
    id: id,
    name: id,
    purchaseDate: bought ?? DateTime(end.year - 1, end.month, end.day),
    warrantyMonths: bought == null ? 12 : (end.year - bought.year) * 12 + end.month - bought.month,
    returnDays: returnDays,
  );
}

void main() {
  late ReminderController reminders;
  late _Notifications notifications;
  late _AddNotification added;
  late WarrantyNotificationService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    reminders = ReminderController();
    await reminders.ready;
    notifications = _Notifications();
    added = _AddNotification();
    service = WarrantyNotificationService(
      getUserUseCase: _User(),
      addNotificationUseCase: added,
      tracker: _Tracker(),
      localNotifications: notifications,
      reminders: reminders,
      logger: _NoLog(),
    );
  });

  test('reminder lead time defaults to 3 months and is remembered', () async {
    expect(reminders.value, 90);
    await reminders.setDays(7);
    final again = ReminderController();
    await again.ready;
    expect(again.value, 7);
  });

  test('immediate reminders respect the chosen lead time, once each', () async {
    await reminders.setDays(7);
    final products = [endingIn('in30', 30), endingIn('in5', 5), endingIn('gone', -3)];
    await service.checkAndNotify(products);
    await service.checkAndNotify(products); // no duplicates on refresh
    expect(added.added, ['in5:Warranty expiring soon', 'gone:Warranty expired']);
  });

  test('changing the lead time moves the scheduled reminder', () async {
    final p = endingIn('p', 200);
    await service.scheduleFutureNotifications(p);
    DateTime earliest() => notifications.scheduled.values.reduce((a, b) => a.isBefore(b) ? a : b);
    expect(p.warrantyEndDate.difference(earliest()).inDays, 90);

    await reminders.setDays(7);
    await service.rescheduleAll([p]);
    expect(p.warrantyEndDate.difference(earliest()).inDays, 7);
    expect(notifications.scheduled, hasLength(2)); // "expiring" + "expired"
  });

  test('return window reminder 2 days before it closes, cancelled when cleared', () async {
    final today = DateTime.now();
    final bought = DateTime(today.year, today.month, today.day - 2);
    final p = endingIn('r', 365, returnDays: 14, bought: bought);
    await service.scheduleFutureNotifications(p);
    expect(notifications.scheduled.values, contains(DateTime(bought.year, bought.month, bought.day + 12)));
    expect(notifications.scheduled, hasLength(3));

    await service.scheduleFutureNotifications(endingIn('r', 365, bought: bought)); // return window removed
    expect(notifications.scheduled, hasLength(2));

    await service.cancelScheduledNotifications('r');
    expect(notifications.scheduled, isEmpty);
  });
}
