import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;

import '../../features/auth/domain/usecase/get_user_usecase.dart';
import '../../features/notification/domain/entities/notification_enitiy.dart';
import '../../features/notification/domain/usecase/add_notification_use_case.dart';
import '../../features/subscriptions/domain/entities/user_subscription.dart';
import '../../l10n/app_localizations.dart';
import '../logger/app_logger.dart';
import '../util/localized_number.dart';
import '../util/notification_ids.dart';
import '../util/notified_warranties_tracker.dart';
import 'notification_service.dart';

/// Reminds the user before each subscription renews: a local push scheduled
/// [daysBefore] days ahead, and an entry in the in-app notification list.
/// The subscription counterpart of WarrantyNotificationService.
class SubscriptionReminderService {
  SubscriptionReminderService({
    required GetUserUseCase getUserUseCase,
    required AddNotificationUseCase addNotificationUseCase,
    required NotifiedWarrantiesTracker tracker,
    required NotificationService localNotifications,
    required AppLogger logger,
    ValueListenable<Locale>? locale,
  })  : _getUserUseCase = getUserUseCase,
        _addNotificationUseCase = addNotificationUseCase,
        _tracker = tracker,
        _localNotifications = localNotifications,
        _logger = logger,
        _locale = locale;

  final GetUserUseCase _getUserUseCase;
  final AddNotificationUseCase _addNotificationUseCase;
  final NotifiedWarrantiesTracker _tracker;
  final NotificationService _localNotifications;
  final AppLogger _logger;
  final ValueListenable<Locale>? _locale;

  static const daysBefore = 3;

  /// Reminders arrive mid-morning rather than at midnight.
  static const _reminderHour = 10;

  /// Same short delay as warranty pushes shown on app open.
  static const _immediateDelay = Duration(seconds: 4);

  Locale get _currentLocale => _locale?.value ?? const Locale('en');
  AppLocalizations get _l10n => lookupAppLocalizations(_currentLocale);

  /// When the reminder for [subscription]'s next renewal is due.
  static DateTime reminderTime(UserSubscription subscription) {
    final renewal = subscription.nextRenewalDate;
    return DateTime(renewal.year, renewal.month, renewal.day - daysBefore, _reminderHour);
  }

  static int notificationId(String subscriptionId) => reminderNotificationId(subscriptionId, subscriptionRenewalSlot);

  /// Tracker keys: one per renewal, so the next cycle reminds again.
  static String _trackerId(String subscriptionId) => 'subscription:$subscriptionId';
  static String _notifiedKey(DateTime renewal) => 'renewal-${_isoDate(renewal)}';
  static String _scheduledKey(DateTime renewal) => 'renewal-scheduled-${_isoDate(renewal)}';
  static String _isoDate(DateTime d) => d.toIso8601String().split('T').first;

  /// Re-schedules reminders in the new language when the user switches it.
  void followLanguage(List<UserSubscription> Function() current) {
    _locale?.addListener(() => syncAll(current()));
  }

  /// Makes this device's pending renewal reminders match [subscriptions]
  /// exactly (deleted ones and another account's are cancelled). Call
  /// whenever the list changes; pass [] on sign-out. Only touches
  /// subscription reminders, never warranty ones.
  Future<void> syncAll(List<UserSubscription> subscriptions) {
    return _syncQueue = _syncQueue.then((_) => _syncAll(subscriptions)).catchError((Object e, StackTrace st) {
      _logger.error('Syncing subscription reminders failed', error: e, stackTrace: st);
    });
  }

  Future<void> _syncQueue = Future.value();

  Future<void> _syncAll(List<UserSubscription> subscriptions) async {
    final now = DateTime.now();
    final userId = _getUserUseCase()?.id;
    final wanted = subscriptions.where((s) => reminderTime(s).isAfter(now)).toList();
    final wantedIds = {for (final s in wanted) notificationId(s.id)};

    for (final pending in await _localNotifications.pendingNotifications()) {
      if (reminderSlot(pending.id) != subscriptionRenewalSlot) continue;
      if (!wantedIds.contains(pending.id)) await _localNotifications.cancelNotification(pending.id);
    }
    for (final s in wanted) {
      await _localNotifications.scheduleNotification(
        id: notificationId(s.id),
        title: _l10n.notifRenewalTitle,
        body: _body(s, daysBefore),
        dateTime: reminderTime(s),
        payload: userId,
      );
      // So opening the app inside the window doesn't push a second time.
      await _tracker.markNotified(_trackerId(s.id), _scheduledKey(s.nextRenewalDate));
    }
  }

  /// Call when the list is (re)loaded. For each subscription renewing within
  /// [daysBefore] days, adds one in-app notification per renewal. It also
  /// pushes right away, but only if this device never scheduled that
  /// renewal's reminder (e.g. added two days before it renews), so nobody
  /// gets the same push twice.
  Future<void> checkAndNotify(List<UserSubscription> subscriptions, {DateTime? today}) async {
    final user = _getUserUseCase();
    if (user == null) return;
    final day = today ?? DateTime.now();

    for (final s in subscriptions) {
      final daysLeft = s.daysLeft(day);
      if (daysLeft < 0 || daysLeft > daysBefore) continue;
      final trackerId = _trackerId(s.id);
      if (await _tracker.hasNotified(trackerId, _notifiedKey(s.nextRenewalDate))) continue;

      final title = _l10n.notifRenewalTitle;
      final body = _body(s, daysLeft);
      try {
        if (!await _tracker.hasNotified(trackerId, _scheduledKey(s.nextRenewalDate))) {
          await _localNotifications.scheduleNotification(
            id: notificationId(s.id),
            title: title,
            body: body,
            dateTime: DateTime.now().add(_immediateDelay),
            payload: user.id,
          );
        }
        await _addNotificationUseCase(
          userId: user.id,
          title: title,
          subtitle: body,
          type: NotificationType.warning,
        );
        await _tracker.markNotified(trackerId, _notifiedKey(s.nextRenewalDate));
      } catch (e, st) {
        _logger.error('Failed to send subscription reminder', error: e, stackTrace: st);
      }
    }
  }

  String _body(UserSubscription s, int daysLeft) {
    final l10n = _l10n;
    final amount = formatLocalizedAmount(_currentLocale, s.price);
    final price = '$amount ${s.currency == 'EGP' ? l10n.currencyEgp : s.currency}';
    return l10n.notifRenewalBody(daysLeft, formatLocalizedInt(_currentLocale, daysLeft), s.name, price);
  }
}
