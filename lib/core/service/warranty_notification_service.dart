import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;

import '../../features/auth/domain/usecase/get_user_usecase.dart';
import '../../features/notification/domain/entities/notification_enitiy.dart';
import '../../features/notification/domain/usecase/add_notification_use_case.dart';
import '../../features/products/domain/entities/product_entity.dart';
import '../../l10n/app_localizations.dart';
import '../logger/app_logger.dart';
import '../util/notification_ids.dart';
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
    ValueListenable<Locale>? locale,
  })  : _locale = locale,
        _getUserUseCase = getUserUseCase,
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

  /// The app's language (it can differ from the phone's); English if unset.
  final ValueListenable<Locale>? _locale;

  AppLocalizations get _l10n => lookupAppLocalizations(_locale?.value ?? const Locale('en'));

  /// Re-schedules reminders in the new language when the user switches it.
  void followLanguage(List<ProductEntity> Function() currentProducts) {
    _locale?.addListener(() => syncAll(currentProducts()));
  }

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

      final l10n = _l10n;
      final title = isExpired ? l10n.notifExpiredTitle : l10n.notifExpiringTitle;
      final subtitle = isExpired
          ? l10n.notifExpiredBody(product.name)
          : l10n.notifExpiringInDays(product.daysRemaining, product.name);

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

  /// Call right after a product is saved or edited to schedule its future
  /// local reminders (expiring soon, expired, return window closing), so the
  /// user is notified even without opening the app. Past dates are skipped.
  Future<void> scheduleFutureNotifications(ProductEntity product) async {
    final reminderDays = await _reminderDays();
    final userId = _getUserUseCase()?.id;
    for (final id in _idsFor(product.id)) {
      await _localNotifications.cancelNotification(id);
    }
    for (final reminder in _remindersFor(product, reminderDays)) {
      await _schedule(reminder, userId);
    }
  }

  /// Makes this device's pending reminders match [products] exactly: every
  /// product gets its reminders, and anything else pending is cancelled
  /// (deleted products, another account's products after sign-out, ids from
  /// older app versions). Call whenever the product list is (re)loaded, so
  /// reminders also exist on a new phone, after a reinstall, and for products
  /// added on another device or by a household member. Pass [] on sign-out.
  Future<void> syncAll(List<ProductEntity> products) {
    // Serialize: overlapping syncs could interleave cancels and schedules.
    return _syncQueue = _syncQueue.then((_) => _syncAll(products)).catchError((Object e, StackTrace st) {
      _logger.error('Syncing warranty reminders failed', error: e, stackTrace: st);
    });
  }

  Future<void> _syncQueue = Future.value();

  Future<void> _syncAll(List<ProductEntity> products) async {
    final reminderDays = await _reminderDays();
    final userId = _getUserUseCase()?.id;
    final now = DateTime.now();
    final wanted = [
      for (final product in products)
        ..._remindersFor(product, reminderDays).where((r) => r.dateTime.isAfter(now)),
    ];
    final wantedIds = {for (final r in wanted) r.id};

    // Any pending warranty reminder that isn't wanted is stale. Other slots
    // belong to other reminders (subscriptions) and are left alone.
    for (final pending in await _localNotifications.pendingNotifications()) {
      if (!warrantyReminderSlots.contains(reminderSlot(pending.id))) continue;
      if (!wantedIds.contains(pending.id)) await _localNotifications.cancelNotification(pending.id);
    }
    for (final reminder in wanted) {
      await _schedule(reminder, userId);
    }
  }

  /// Call after the reminder setting changes so pending reminders move to
  /// the new date.
  Future<void> rescheduleAll(List<ProductEntity> products) => syncAll(products);

  List<_Reminder> _remindersFor(ProductEntity product, int reminderDays) {
    final returnBy = product.returnByDate;
    final l10n = _l10n;
    return [
      _Reminder(
        id: _notificationIdFor(product.id, 0),
        title: l10n.notifExpiringTitle,
        body: l10n.notifExpiringBody(product.name),
        dateTime: _daysBefore(product.warrantyEndDate, reminderDays),
      ),
      _Reminder(
        id: _notificationIdFor(product.id, 1),
        title: l10n.notifExpiredTitle,
        body: l10n.notifExpiredBody(product.name),
        dateTime: product.warrantyEndDate,
      ),
      if (returnBy != null)
        _Reminder(
          id: _notificationIdFor(product.id, 2),
          title: l10n.notifReturnTitle,
          body: l10n.notifReturnBody(product.name),
          dateTime: _daysBefore(returnBy, _returnReminderDaysBefore),
        ),
    ];
  }

  Future<void> _schedule(_Reminder reminder, String? userId) => _localNotifications.scheduleNotification(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        dateTime: reminder.dateTime,
        payload: userId,
      );

  static const _returnReminderDaysBefore = 2;

  /// [days] calendar days before [date], at the same time of day. Not
  /// `subtract(Duration(days: n))`, which counts 24-hour days and lands an
  /// hour off when a daylight-saving change falls in between.
  static DateTime _daysBefore(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day - days, date.hour, date.minute);

  /// Call when a product is deleted, to cancel any pending reminders.
  Future<void> cancelScheduledNotifications(String productId) async {
    for (final id in _idsFor(productId)) {
      await _localNotifications.cancelNotification(id);
    }
  }

  Iterable<int> _idsFor(String productId) => [0, 1, 2].map((s) => _notificationIdFor(productId, s));

  /// Slot 0 "expiring", 1 "expired", 2 "return window closing"; see
  /// [reminderNotificationId].
  int _notificationIdFor(String productId, int suffix) => reminderNotificationId(productId, suffix);
}

class _Reminder {
  const _Reminder({required this.id, required this.title, required this.body, required this.dateTime});

  final int id;
  final String title;
  final String body;
  final DateTime dateTime;
}