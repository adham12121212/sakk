import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;

import '../../features/auth/domain/usecase/get_user_usecase.dart';
import '../../features/notification/domain/entities/notification_enitiy.dart';
import '../../features/notification/domain/usecase/add_notification_use_case.dart';
import '../../features/subscriptions/domain/entities/billing_cycle.dart';
import '../../features/subscriptions/domain/entities/user_subscription.dart';
import '../../features/subscriptions/domain/renewal_schedule.dart';
import '../../l10n/app_localizations.dart';
import '../logger/app_logger.dart';
import '../util/localized_number.dart';
import '../util/notification_ids.dart';
import '../util/notified_warranties_tracker.dart';
import 'notification_service.dart';
import 'reminder_settings.dart';

/// The reminders each renewal gets.
enum RenewalReminder {
  /// "Renews in 3 days".
  threeDaysBefore,

  /// "Renews tomorrow".
  dayBefore,

  /// "Renewed yesterday: check the charge".
  dayAfter,
}

/// Reminds the user around each subscription renewal: 3 days before, the
/// day before, and the day after (to check the charge). Each is a local push
/// scheduled ahead, plus one entry in the in-app notification list. The
/// subscription counterpart of WarrantyNotificationService.
class SubscriptionReminderService {
  SubscriptionReminderService({
    required GetUserUseCase getUserUseCase,
    required AddNotificationUseCase addNotificationUseCase,
    required NotifiedWarrantiesTracker tracker,
    required NotificationService localNotifications,
    required AppLogger logger,
    ValueListenable<Locale>? locale,
    ReminderSettings? settings,
  })  : _settings = settings,
        _getUserUseCase = getUserUseCase,
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

  /// Which reminders the user wants (Reminders screen); all when null.
  final ReminderSettings? _settings;
  bool _wants(RenewalReminder kind) => _settings?.wantsSubscription(kind) ?? true;

  /// Reminders arrive mid-morning rather than at midnight.
  static const _reminderHour = 10;

  /// Same short delay as warranty pushes shown on app open.
  static const _immediateDelay = Duration(seconds: 4);

  Locale get _currentLocale => _locale?.value ?? const Locale('en');
  AppLocalizations get _l10n => lookupAppLocalizations(_currentLocale);

  /// When [kind]'s push for the renewal on [renewal] is due.
  static DateTime reminderTime(RenewalReminder kind, DateTime renewal) {
    final offset = switch (kind) {
      RenewalReminder.threeDaysBefore => -3,
      RenewalReminder.dayBefore => -1,
      RenewalReminder.dayAfter => 1,
    };
    return DateTime(renewal.year, renewal.month, renewal.day + offset, _reminderHour);
  }

  /// The renewal before [subscription]'s next one, when the subscription
  /// already existed then (so a new one never hears "renewed yesterday").
  static DateTime? previousRenewal(UserSubscription subscription) {
    final created = subscription.createdAt?.toLocal();
    if (created == null) return null;
    final previous = addMonthsClamped(subscription.nextRenewalDate, -subscription.billingCycle.months);
    return DateTime(created.year, created.month, created.day).isBefore(previous) ? previous : null;
  }

  /// Slot 5 "in 3 days", 6 "tomorrow", 7 "renewed" for the next renewal,
  /// 8 "renewed" for the previous one; see [reminderNotificationId]. The
  /// previous renewal has its own slot so its reminder survives the next
  /// one being scheduled when the date moves on.
  static int notificationId(String subscriptionId, RenewalReminder kind, {bool previous = false}) {
    final slot = switch (kind) {
      RenewalReminder.threeDaysBefore => 5,
      RenewalReminder.dayBefore => 6,
      RenewalReminder.dayAfter => previous ? 8 : 7,
    };
    return reminderNotificationId(subscriptionId, slot);
  }

  /// Tracker keys: one per reminder per renewal, so the next cycle reminds
  /// again. The 3-day keys keep their original names so reminders already
  /// sent by an older version aren't sent again.
  static String _trackerId(String subscriptionId) => 'subscription:$subscriptionId';
  static String _notifiedKey(RenewalReminder kind, DateTime renewal) => '${_keyPrefix(kind)}-${_isoDate(renewal)}';
  static String _scheduledKey(RenewalReminder kind, DateTime renewal) =>
      '${_keyPrefix(kind)}-scheduled-${_isoDate(renewal)}';
  static String _keyPrefix(RenewalReminder kind) => switch (kind) {
        RenewalReminder.threeDaysBefore => 'renewal',
        RenewalReminder.dayBefore => 'renewal-1d',
        RenewalReminder.dayAfter => 'renewed',
      };
  static String _isoDate(DateTime d) => d.toIso8601String().split('T').first;

  /// Re-schedules reminders when the user switches the language or changes
  /// which reminders they want.
  void followLanguage(List<UserSubscription> Function() current) {
    _locale?.addListener(() => syncAll(current()));
    _settings?.addListener(() => syncAll(current()));
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
    await _settings?.ready;
    final now = DateTime.now();
    final userId = _getUserUseCase()?.id;
    final wanted = [
      for (final s in subscriptions) ..._remindersFor(s).where((r) => _wants(r.kind) && r.dateTime.isAfter(now)),
    ];
    final wantedIds = {for (final r in wanted) r.id};

    for (final pending in await _localNotifications.pendingNotifications()) {
      if (!subscriptionReminderSlots.contains(reminderSlot(pending.id))) continue;
      if (!wantedIds.contains(pending.id)) await _localNotifications.cancelNotification(pending.id);
    }
    for (final r in wanted) {
      await _localNotifications.scheduleNotification(
        id: r.id,
        title: r.title,
        body: r.body,
        dateTime: r.dateTime,
        payload: userId,
      );
      // So opening the app inside the window doesn't push a second time.
      await _tracker.markNotified(_trackerId(r.subscriptionId), _scheduledKey(r.kind, r.renewal));
    }
  }

  List<_Reminder> _remindersFor(UserSubscription s) {
    final next = s.nextRenewalDate;
    final previous = previousRenewal(s);
    return [
      _reminder(s, RenewalReminder.threeDaysBefore, next, days: 3),
      _reminder(s, RenewalReminder.dayBefore, next, days: 1),
      _reminder(s, RenewalReminder.dayAfter, next, days: 1),
      if (previous != null) _reminder(s, RenewalReminder.dayAfter, previous, days: 1, previous: true),
    ];
  }

  _Reminder _reminder(
    UserSubscription s,
    RenewalReminder kind,
    DateTime renewal, {
    required int days,
    bool previous = false,
  }) {
    return _Reminder(
      id: notificationId(s.id, kind, previous: previous),
      subscriptionId: s.id,
      kind: kind,
      renewal: renewal,
      title: _title(kind),
      body: _body(s, kind, days),
      dateTime: reminderTime(kind, renewal),
    );
  }

  /// Call when the list is (re)loaded. Adds one in-app notification per
  /// reminder per renewal when the app is opened inside its window: 2–3
  /// days before ("in 3 days"), 0–1 days before ("tomorrow"), 1–2 days
  /// after ("renewed"). It also pushes right away, but only if this device
  /// never scheduled that reminder ahead (e.g. a subscription added the day
  /// before it renews), so nobody gets the same push twice.
  Future<void> checkAndNotify(List<UserSubscription> subscriptions, {DateTime? today}) async {
    final user = _getUserUseCase();
    if (user == null) return;
    final day = today ?? DateTime.now();

    for (final s in subscriptions) {
      final daysLeft = s.daysLeft(day);
      if (daysLeft >= 2 && daysLeft <= 3) {
        await _notifyNow(s, RenewalReminder.threeDaysBefore, s.nextRenewalDate, daysLeft, user.id);
      } else if (daysLeft >= 0 && daysLeft <= 1) {
        await _notifyNow(s, RenewalReminder.dayBefore, s.nextRenewalDate, daysLeft, user.id);
      }

      final previous = previousRenewal(s);
      if (previous != null) {
        final daysSince = s.copyWith(nextRenewalDate: previous).daysLeft(day) * -1;
        if (daysSince >= 1 && daysSince <= 2) {
          await _notifyNow(s, RenewalReminder.dayAfter, previous, daysSince, user.id, previous: true);
        }
      }
    }
  }

  Future<void> _notifyNow(
    UserSubscription s,
    RenewalReminder kind,
    DateTime renewal,
    int days,
    String userId, {
    bool previous = false,
  }) async {
    await _settings?.ready;
    if (!_wants(kind)) return;
    final trackerId = _trackerId(s.id);
    if (await _tracker.hasNotified(trackerId, _notifiedKey(kind, renewal))) return;

    final title = _title(kind);
    final body = _body(s, kind, days);
    try {
      if (!await _tracker.hasNotified(trackerId, _scheduledKey(kind, renewal))) {
        await _localNotifications.scheduleNotification(
          id: notificationId(s.id, kind, previous: previous),
          title: title,
          body: body,
          dateTime: DateTime.now().add(_immediateDelay),
          payload: userId,
        );
      }
      await _addNotificationUseCase(
        userId: userId,
        title: title,
        subtitle: body,
        type: kind == RenewalReminder.dayAfter ? NotificationType.success : NotificationType.warning,
      );
      await _tracker.markNotified(trackerId, _notifiedKey(kind, renewal));
    } catch (e, st) {
      _logger.error('Failed to send subscription reminder', error: e, stackTrace: st);
    }
  }

  String _title(RenewalReminder kind) =>
      kind == RenewalReminder.dayAfter ? _l10n.notifRenewedTitle : _l10n.notifRenewalTitle;

  /// [days] is days until the renewal, or since it for [RenewalReminder.dayAfter].
  String _body(UserSubscription s, RenewalReminder kind, int days) {
    final l10n = _l10n;
    final amount = formatLocalizedAmount(_currentLocale, s.price);
    final price = '$amount ${s.currency == 'EGP' ? l10n.currencyEgp : s.currency}';
    final daysText = formatLocalizedInt(_currentLocale, days);
    return kind == RenewalReminder.dayAfter
        ? l10n.notifRenewedBody(days, daysText, s.name, price)
        : l10n.notifRenewalBody(days, daysText, s.name, price);
  }
}

class _Reminder {
  const _Reminder({
    required this.id,
    required this.subscriptionId,
    required this.kind,
    required this.renewal,
    required this.title,
    required this.body,
    required this.dateTime,
  });

  final int id;
  final String subscriptionId;
  final RenewalReminder kind;
  final DateTime renewal;
  final String title;
  final String body;
  final DateTime dateTime;
}
