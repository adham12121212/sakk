import 'dart:async';

import '../../features/auth/domain/usecase/get_user_usecase.dart';
import '../../features/notification/domain/entities/notification_enitiy.dart';
import '../../features/notification/domain/usecase/add_notification_use_case.dart';
import '../../features/products/domain/enties/product_entity.dart';
import '../logger/app_logger.dart';
import '../util/notified_warranties_tracker.dart';
import 'notification_service.dart';
import 'reminder_controller.dart';

/// Bridges product warranty status to both local push notifications and
/// the in-app notification list.
class WarrantyNotificationService {
  WarrantyNotificationService({
    required GetUserUseCase getUserUseCase,
    required AddNotificationUseCase addNotificationUseCase,
    required NotifiedWarrantiesTracker tracker,
    required NotificationService localNotifications,
    required ReminderController reminders,
    required AppLogger logger,
  })  : _getUserUseCase = getUserUseCase,
        _addNotificationUseCase = addNotificationUseCase,
        _tracker = tracker,
        _localNotifications = localNotifications,
        _reminders = reminders,
        _logger = logger;

  final GetUserUseCase _getUserUseCase;
  final AddNotificationUseCase _addNotificationUseCase;
  final NotifiedWarrantiesTracker _tracker;
  final NotificationService _localNotifications;
  final ReminderController _reminders;
  final AppLogger _logger;

  /// Days before the end date for the "expiring soon" reminder (Profile setting).
  Future<int> _reminderDays() async {
    await _reminders.ready;
    return _reminders.value;
  }

  /// Small buffer before an "immediate" warranty push actually fires.
  /// Using scheduleNotification() with a short delay instead of an
  /// instant show() mirrors the delivery path that's been confirmed to
  /// work reliably, and gives the UI a moment to settle (e.g. finish
  /// popping back to the product list) before the notification lands.
  static const _immediateNotificationDelay = Duration(seconds: 4);

  /// Call whenever the product list is (re)loaded — app open, pull to
  /// refresh, after saving a new product. Fires a near-immediate local
  /// push + an in-app notification for any product that has expired or is
  /// within the user's reminder window and hasn't been flagged yet. Safe to
  /// call repeatedly.
  Future<void> checkAndNotify(List<ProductEntity> products) async {
    final user = _getUserUseCase();
    if (user == null) return;
    final reminderDays = await _reminderDays();

    for (final product in products) {
      final isExpired = product.status == WarrantyStatus.expired;
      if (!isExpired && product.daysRemaining > reminderDays) continue;

      final statusKey = isExpired ? WarrantyStatus.expired.name : WarrantyStatus.expiring.name;
      if (await _tracker.hasNotified(product.id, statusKey)) continue;

      final title = isExpired ? 'Warranty expired' : 'Warranty expiring soon';
      final subtitle = isExpired
          ? "${product.name}'s warranty has expired"
          : "${product.name}'s warranty expires in ${product.daysRemaining} days";

      try {
        await _localNotifications.scheduleNotification(
          id: _notificationIdFor(product.id, isExpired ? 1 : 0),
          title: title,
          body: subtitle,
          dateTime: DateTime.now().add(_immediateNotificationDelay),
          // The user's id, so a tap can route straight back to the
          // notifications view for the right account (see main.dart).
          payload: user.id,
        );

        await _addNotificationUseCase(
          userId: user.id,
          title: title,
          subtitle: subtitle,
          type: isExpired ? NotificationType.error : NotificationType.warning,
          productId: product.id,
        );

        await _tracker.markNotified(product.id, statusKey);
      } catch (e, st) {
        _logger.error('Failed to send warranty notification', error: e, stackTrace: st);
      }
    }
  }

  /// Call right after a product is saved to schedule future local
  /// notifications for the day it becomes "expiring soon" and the day it
  /// expires, so the user is notified even without opening the app. Dates
  /// already in the past are silently skipped by [NotificationService].
  Future<void> scheduleFutureNotifications(ProductEntity product) async {
    final user = _getUserUseCase();
    final reminderDays = await _reminderDays();

    final expiringDate = product.warrantyEndDate.subtract(Duration(days: reminderDays));

    await _localNotifications.scheduleNotification(
      id: _notificationIdFor(product.id, 0),
      title: 'Warranty expiring soon',
      body: "${product.name}'s warranty is expiring soon",
      dateTime: expiringDate,
      payload: user?.id,
    );

    await _localNotifications.scheduleNotification(
      id: _notificationIdFor(product.id, 1),
      title: 'Warranty expired',
      body: "${product.name}'s warranty has expired",
      dateTime: product.warrantyEndDate,
      payload: user?.id,
    );

    // Return window: a nudge two days before the last day to return it.
    final returnBy = product.returnByDate;
    if (returnBy == null) {
      await _localNotifications.cancelNotification(_notificationIdFor(product.id, 2));
    } else {
      await _localNotifications.scheduleNotification(
        id: _notificationIdFor(product.id, 2),
        title: 'Return window closing',
        body: "You have 2 days left to return ${product.name} if you need to",
        dateTime: returnBy.subtract(const Duration(days: _returnReminderDaysBefore)),
        payload: user?.id,
      );
    }
  }

  static const _returnReminderDaysBefore = 2;

  /// Call after the reminder setting changes so every product's pending
  /// "expiring soon" reminder moves to the new date. Reminders keep the same
  /// ids, so each one replaces the old schedule.
  Future<void> rescheduleAll(List<ProductEntity> products) async {
    for (final product in products) {
      if (product.isExpired) continue;
      await _localNotifications.cancelNotification(_notificationIdFor(product.id, 0));
      await scheduleFutureNotifications(product);
    }
  }

  /// Call when a product is deleted, to cancel any pending reminders.
  Future<void> cancelScheduledNotifications(String productId) async {
    await _localNotifications.cancelNotification(_notificationIdFor(productId, 0));
    await _localNotifications.cancelNotification(_notificationIdFor(productId, 1));
    await _localNotifications.cancelNotification(_notificationIdFor(productId, 2));
  }

  /// Deterministic 32-bit int id required by flutter_local_notifications,
  /// derived from the product id plus a suffix so a product's reminders don't
  /// collide: 0 "expiring", 1 "expired", 2 "return window closing".
  int _notificationIdFor(String productId, int suffix) {
    return (productId.hashCode & 0x7FFFFFFF) ~/ 10 * 10 + suffix;
  }
}