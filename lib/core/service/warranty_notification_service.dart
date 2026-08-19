import 'dart:async';

import '../../features/auth/domain/usecase/get_user_usecase.dart';
import '../../features/notification/domain/entities/notification_enitiy.dart';
import '../../features/notification/domain/usecase/add_notification_use_case.dart';
import '../../features/products/domain/enties/product_entity.dart';
import '../logger/app_logger.dart';
import '../util/notified_warranties_tracker.dart';
import 'notification_service.dart';

/// Bridges product warranty status to both local push notifications and
/// the in-app notification list.
class WarrantyNotificationService {
  WarrantyNotificationService({
    required GetUserUseCase getUserUseCase,
    required AddNotificationUseCase addNotificationUseCase,
    required NotifiedWarrantiesTracker tracker,
    required NotificationService localNotifications,
    required AppLogger logger,
  })  : _getUserUseCase = getUserUseCase,
        _addNotificationUseCase = addNotificationUseCase,
        _tracker = tracker,
        _localNotifications = localNotifications,
        _logger = logger;

  final GetUserUseCase _getUserUseCase;
  final AddNotificationUseCase _addNotificationUseCase;
  final NotifiedWarrantiesTracker _tracker;
  final NotificationService _localNotifications;
  final AppLogger _logger;

  static const _expiringSoonDays = ProductEntity.expiringSoonMonths * 30;

  /// Small buffer before an "immediate" warranty push actually fires.
  /// Using scheduleNotification() with a short delay instead of an
  /// instant show() mirrors the delivery path that's been confirmed to
  /// work reliably, and gives the UI a moment to settle (e.g. finish
  /// popping back to the product list) before the notification lands.
  static const _immediateNotificationDelay = Duration(seconds: 4);

  /// Call whenever the product list is (re)loaded — app open, pull to
  /// refresh, after saving a new product. Fires a near-immediate local
  /// push + an in-app notification for any product that is currently
  /// "expiring" or "expired" and hasn't been flagged yet. Safe to call
  /// repeatedly.
  Future<void> checkAndNotify(List<ProductEntity> products) async {
    final user = _getUserUseCase();
    if (user == null) return;

    for (final product in products) {
      if (product.status == WarrantyStatus.active) continue;

      final statusKey = product.status.name;
      if (await _tracker.hasNotified(product.id, statusKey)) continue;

      final isExpired = product.status == WarrantyStatus.expired;
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

    final expiringDate =
    product.warrantyEndDate.subtract(const Duration(days: _expiringSoonDays));

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
  }

  /// Call when a product is deleted, to cancel any pending reminders.
  Future<void> cancelScheduledNotifications(String productId) async {
    await _localNotifications.cancelNotification(_notificationIdFor(productId, 0));
    await _localNotifications.cancelNotification(_notificationIdFor(productId, 1));
  }

  /// Deterministic 32-bit int id required by flutter_local_notifications,
  /// derived from the product id plus a 0/1 suffix so the "expiring" and
  /// "expired" reminders for the same product don't collide.
  int _notificationIdFor(String productId, int suffix) {
    return (productId.hashCode & 0x7FFFFFFF) ~/ 10 * 10 + suffix;
  }
}