import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;

import '../../features/auth/domain/usecase/get_user_usecase.dart';
import '../../features/installments/domain/entities/installment_payment.dart';
import '../../features/installments/domain/entities/installment_plan.dart';
import '../../features/notification/domain/entities/notification_enitiy.dart';
import '../../features/notification/domain/usecase/add_notification_use_case.dart';
import '../../l10n/app_localizations.dart';
import '../logger/app_logger.dart';
import '../util/date_math.dart';
import '../util/localized_number.dart';
import '../util/notification_ids.dart';
import '../util/notified_warranties_tracker.dart';
import 'notification_service.dart';
import 'reminder_settings.dart';

/// The reminders each installment gets.
enum InstallmentReminder {
  /// "Due in 3 days".
  threeDaysBefore,

  /// "Due today".
  dueDay,

  /// Sakk Pro: "Due in N days", N chosen on the Reminders screen.
  custom,
}

/// What an installment reminder carries, so tapping it (or its "Mark as
/// paid" button) can find the payment. Other notifications carry just the
/// user id.
class InstallmentReminderPayload {
  const InstallmentReminderPayload({
    required this.userId,
    required this.planId,
    required this.paymentId,
  });

  final String userId;
  final String planId;
  final String paymentId;

  static const _prefix = 'installment';

  String encode() => '$_prefix|$userId|$planId|$paymentId';

  /// Null for any other notification's payload.
  static InstallmentReminderPayload? tryParse(String? payload) {
    final parts = payload?.split('|');
    if (parts == null || parts.length != 4 || parts.first != _prefix) {
      return null;
    }
    return InstallmentReminderPayload(
      userId: parts[1],
      planId: parts[2],
      paymentId: parts[3],
    );
  }
}

/// Reminds the user before each installment: 3 days before and on the due
/// day, each with a "Mark as paid" button. Paid installments get none. Each
/// is a local push scheduled ahead, plus one entry in the in-app
/// notification list. The installment counterpart of
/// SubscriptionReminderService.
///
/// Only the next unpaid installment of each active plan is scheduled: iOS
/// keeps at most 64 pending notifications for the whole app, shared with
/// warranties and subscriptions. The following one is scheduled once this
/// one is paid (or its day has passed) and the list syncs again.
class InstallmentReminderService {
  InstallmentReminderService({
    required GetUserUseCase getUserUseCase,
    required AddNotificationUseCase addNotificationUseCase,
    required NotifiedWarrantiesTracker tracker,
    required NotificationService localNotifications,
    required AppLogger logger,
    ValueListenable<Locale>? locale,
    ReminderSettings? settings,
  }) : _settings = settings,
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
  bool _wants(InstallmentReminder kind) => kind == InstallmentReminder.custom
      ? _customDays != null && (_settings?.wantsInstallment(kind) ?? false)
      : _settings?.wantsInstallment(kind) ?? true;

  /// Reminders arrive mid-morning rather than at midnight.
  static const _reminderHour = 10;

  /// Same short delay as warranty pushes shown on app open.
  static const _immediateDelay = Duration(seconds: 4);

  Locale get _currentLocale => _locale?.value ?? const Locale('en');
  AppLocalizations get _l10n => lookupAppLocalizations(_currentLocale);

  /// The Pro reminder's days ahead now, or null (off, or not Pro).
  int? get _customDays => _settings?.activeInstallmentCustomDays;

  /// Days before the due date [kind] comes ([customDays] for the Pro one).
  static int daysBefore(InstallmentReminder kind, {int customDays = 0}) =>
      switch (kind) {
        InstallmentReminder.threeDaysBefore => 3,
        InstallmentReminder.dueDay => 0,
        InstallmentReminder.custom => customDays,
      };

  /// When [kind]'s push for an installment due on [due] is sent.
  static DateTime reminderTime(
    InstallmentReminder kind,
    DateTime due, {
    int customDays = 0,
  }) {
    final offset = -daysBefore(kind, customDays: customDays);
    return DateTime(due.year, due.month, due.day + offset, _reminderHour);
  }

  /// Slot 3 "due in 3 days", 4 "due today", 9 the Pro reminder (shared with
  /// subscriptions; see [ownsPending]); see [reminderNotificationId].
  static int notificationId(String paymentId, InstallmentReminder kind) =>
      reminderNotificationId(paymentId, switch (kind) {
        InstallmentReminder.threeDaysBefore => 3,
        InstallmentReminder.dueDay => 4,
        InstallmentReminder.custom => customReminderSlot,
      });

  /// Whether a pending notification is one of this service's: its slots,
  /// or the shared Pro slot with an installment's payload.
  static bool ownsPending(int id, String? payload) {
    final slot = reminderSlot(id);
    if (slot == customReminderSlot) {
      return InstallmentReminderPayload.tryParse(payload) != null;
    }
    return installmentReminderSlots.contains(slot);
  }

  /// The installment of [plan] that reminders are about: the earliest unpaid
  /// one due today or later. Null for a paid-off or cancelled plan. Overdue
  /// ones show in the app instead.
  static InstallmentPayment? upcomingPayment(
    InstallmentPlan plan,
    DateTime today,
  ) {
    if (!plan.isActive) return null;
    for (final p in plan.unpaidPayments) {
      if (p.daysLeft(today) >= 0) return p;
    }
    return null;
  }

  /// Tracker keys: one per reminder per installment (keyed by its due date,
  /// so an edit that moves it reminds again).
  static String _trackerId(String paymentId) => 'installment:$paymentId';
  static String _notifiedKey(InstallmentReminder kind, DateTime due) =>
      '${_keyPrefix(kind)}-${_isoDate(due)}';
  static String _scheduledKey(InstallmentReminder kind, DateTime due) =>
      '${_keyPrefix(kind)}-scheduled-${_isoDate(due)}';
  static String _keyPrefix(InstallmentReminder kind) => switch (kind) {
    InstallmentReminder.threeDaysBefore => 'due-3d',
    InstallmentReminder.dueDay => 'due-0d',
    InstallmentReminder.custom => 'due-custom',
  };
  static String _isoDate(DateTime d) => d.toIso8601String().split('T').first;

  /// Re-schedules reminders when the user switches the language or changes
  /// which reminders they want.
  void followLanguage(List<InstallmentPlan> Function() current) {
    _locale?.addListener(() => syncAll(current()));
    _settings?.addListener(() => syncAll(current()));
  }

  /// Makes this device's pending installment reminders match [plans] exactly
  /// (paid, edited, deleted and another account's are cancelled). Call
  /// whenever the list changes; pass [] on sign-out. Only touches
  /// installment reminders.
  Future<void> syncAll(List<InstallmentPlan> plans) {
    return _syncQueue = _syncQueue.then((_) => _syncAll(plans)).catchError((
      Object e,
      StackTrace st,
    ) {
      _logger.error(
        'Syncing installment reminders failed',
        error: e,
        stackTrace: st,
      );
    });
  }

  Future<void> _syncQueue = Future.value();

  Future<void> _syncAll(List<InstallmentPlan> plans) async {
    await _settings?.ready;
    final now = DateTime.now();
    final userId = _getUserUseCase()?.id;
    final wanted = <_Reminder>[];
    for (final plan in plans) {
      final payment = upcomingPayment(plan, now);
      if (payment == null) continue;
      for (final kind in InstallmentReminder.values.where(_wants)) {
        final r = _reminder(plan, payment, kind, userId: userId);
        if (r.dateTime.isAfter(now)) wanted.add(r);
      }
    }
    final wantedIds = {for (final r in wanted) r.id};

    for (final pending in await _localNotifications.pendingNotifications()) {
      if (!ownsPending(pending.id, pending.payload)) continue;
      if (!wantedIds.contains(pending.id)) {
        await _localNotifications.cancelNotification(pending.id);
      }
    }
    for (final r in wanted) {
      await _localNotifications.scheduleNotification(
        id: r.id,
        title: r.title,
        body: r.body,
        dateTime: r.dateTime,
        payload: r.payload,
        markPaidLabel: _l10n.markAsPaid,
      );
      // So opening the app inside the window doesn't push a second time.
      await _tracker.markNotified(
        _trackerId(r.paymentId),
        _scheduledKey(r.kind, r.due),
      );
    }
  }

  _Reminder _reminder(
    InstallmentPlan plan,
    InstallmentPayment payment,
    InstallmentReminder kind, {
    String? userId,
  }) {
    final days = daysBefore(kind, customDays: _customDays ?? 0);
    return _Reminder(
      id: notificationId(payment.id, kind),
      paymentId: payment.id,
      kind: kind,
      due: payment.dueDate,
      title: _title(kind),
      body: _body(plan, payment, days),
      dateTime: reminderTime(kind, payment.dueDate, customDays: days),
      payload: userId == null
          ? null
          : InstallmentReminderPayload(
              userId: userId,
              planId: plan.id,
              paymentId: payment.id,
            ).encode(),
    );
  }

  /// Call when the list is (re)loaded. Adds one in-app notification per
  /// reminder per installment when the app is opened inside its window: 1–3
  /// days before ("due in N days") and on the day ("due today"). It also
  /// pushes right away, but only if this device never scheduled that
  /// reminder ahead (e.g. a plan added the day before it's due), so nobody
  /// gets the same push twice.
  Future<void> checkAndNotify(
    List<InstallmentPlan> plans, {
    DateTime? today,
  }) async {
    final user = _getUserUseCase();
    if (user == null) return;
    final day = dateOnly(today ?? DateTime.now());

    for (final plan in plans) {
      final payment = upcomingPayment(plan, day);
      if (payment == null) continue;
      final daysLeft = payment.daysLeft(day);
      final customDays = _customDays;
      // The Pro reminder, opened on its day or the day after.
      if (customDays != null &&
          daysLeft <= customDays &&
          daysLeft >= customDays - 1 &&
          daysLeft > 3) {
        await _notifyNow(
          plan,
          payment,
          InstallmentReminder.custom,
          daysLeft,
          user.id,
        );
      }
      if (daysLeft >= 1 && daysLeft <= 3) {
        await _notifyNow(
          plan,
          payment,
          InstallmentReminder.threeDaysBefore,
          daysLeft,
          user.id,
        );
      } else if (daysLeft == 0) {
        await _notifyNow(plan, payment, InstallmentReminder.dueDay, 0, user.id);
      }
    }
  }

  Future<void> _notifyNow(
    InstallmentPlan plan,
    InstallmentPayment payment,
    InstallmentReminder kind,
    int days,
    String userId,
  ) async {
    await _settings?.ready;
    if (!_wants(kind)) return;
    final trackerId = _trackerId(payment.id);
    if (await _tracker.hasNotified(
      trackerId,
      _notifiedKey(kind, payment.dueDate),
    )) {
      return;
    }

    final title = _title(kind);
    final body = _body(plan, payment, days);
    try {
      if (!await _tracker.hasNotified(
        trackerId,
        _scheduledKey(kind, payment.dueDate),
      )) {
        await _localNotifications.scheduleNotification(
          id: notificationId(payment.id, kind),
          title: title,
          body: body,
          dateTime: DateTime.now().add(_immediateDelay),
          payload: InstallmentReminderPayload(
            userId: userId,
            planId: plan.id,
            paymentId: payment.id,
          ).encode(),
          markPaidLabel: _l10n.markAsPaid,
        );
      }
      await _addNotificationUseCase(
        userId: userId,
        title: title,
        subtitle: body,
        type: NotificationType.warning,
      );
      await _tracker.markNotified(
        trackerId,
        _notifiedKey(kind, payment.dueDate),
      );
    } catch (e, st) {
      _logger.error(
        'Failed to send installment reminder',
        error: e,
        stackTrace: st,
      );
    }
  }

  String _title(InstallmentReminder kind) => kind == InstallmentReminder.dueDay
      ? _l10n.notifInstallmentDueTodayTitle
      : _l10n.notifInstallmentDueSoonTitle;

  /// [days] is days until the installment is due.
  String _body(InstallmentPlan plan, InstallmentPayment payment, int days) {
    final l10n = _l10n;
    final amount = formatLocalizedAmount(_currentLocale, payment.amount);
    final price =
        '$amount ${plan.currency == 'EGP' ? l10n.currencyEgp : plan.currency}';
    return l10n.notifInstallmentDueBody(
      days,
      formatLocalizedInt(_currentLocale, days),
      plan.name,
      price,
    );
  }
}

class _Reminder {
  const _Reminder({
    required this.id,
    required this.paymentId,
    required this.kind,
    required this.due,
    required this.title,
    required this.body,
    required this.dateTime,
    required this.payload,
  });

  final int id;
  final String paymentId;
  final InstallmentReminder kind;
  final DateTime due;
  final String title;
  final String body;
  final DateTime dateTime;
  final String? payload;
}
