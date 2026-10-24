import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;

import '../../features/auth/domain/usecase/get_user_usecase.dart';
import '../../features/notification/domain/entities/notification_entity.dart';
import '../../features/notification/domain/usecase/add_notification_use_case.dart';
import '../../features/papers/domain/entities/paper.dart';
import '../../features/papers/presentation/util/paper_ui.dart';
import '../../l10n/app_localizations.dart';
import '../logger/app_logger.dart';
import '../util/date_math.dart';
import '../util/localized_number.dart';
import '../util/notification_ids.dart';
import '../util/notified_warranties_tracker.dart';
import 'notification_service.dart';
import 'reminder_settings.dart';

/// The reminders each paper with an expiry date gets.
enum PaperReminder {
  /// "Expires in 30 days": time to start renewing.
  monthBefore,

  /// "Expires in 7 days".
  weekBefore,

  /// "Expires today".
  expiryDay,
}

/// What a paper reminder carries, so tapping it opens My papers. Other
/// notifications carry just the user id.
class PaperReminderPayload {
  const PaperReminderPayload(this.userId);

  final String userId;

  static const _prefix = 'paper';

  String encode() => '$_prefix|$userId';

  /// Null for any other notification's payload.
  static PaperReminderPayload? tryParse(String? payload) {
    final parts = payload?.split('|');
    if (parts == null || parts.length != 2 || parts.first != _prefix) {
      return null;
    }
    return PaperReminderPayload(parts[1]);
  }
}

/// Reminds the user before each paper expires: a month before, a week
/// before and on the day. Each is a local push scheduled ahead, plus one
/// entry in the in-app notification list. The papers counterpart of
/// SubscriptionReminderService.
///
/// Only each paper's next reminder is scheduled: iOS keeps at most 64
/// pending notifications for the whole app. The one after it is scheduled
/// when the list syncs again after it has passed.
class PaperReminderService {
  PaperReminderService({
    required GetUserUseCase getUserUseCase,
    required AddNotificationUseCase addNotificationUseCase,
    required NotifiedWarrantiesTracker tracker,
    required NotificationService localNotifications,
    required AppLogger logger,
    ValueListenable<Locale>? locale,
    ReminderSettings? settings,
  }) : _getUserUseCase = getUserUseCase,
       _addNotificationUseCase = addNotificationUseCase,
       _tracker = tracker,
       _localNotifications = localNotifications,
       _logger = logger,
       _locale = locale,
       _settings = settings;

  final GetUserUseCase _getUserUseCase;
  final AddNotificationUseCase _addNotificationUseCase;
  final NotifiedWarrantiesTracker _tracker;
  final NotificationService _localNotifications;
  final AppLogger _logger;
  final ValueListenable<Locale>? _locale;

  /// Which reminders the user wants (Reminders screen); all when null.
  final ReminderSettings? _settings;
  bool _wants(PaperReminder kind) => _settings?.wantsPaper(kind) ?? true;

  /// Reminders arrive mid-morning rather than at midnight.
  static const _reminderHour = 10;

  Locale get _currentLocale => _locale?.value ?? const Locale('en');
  AppLocalizations get _l10n => lookupAppLocalizations(_currentLocale);

  /// Days before the expiry date each reminder comes.
  static int daysBefore(PaperReminder kind) => switch (kind) {
    PaperReminder.monthBefore => 30,
    PaperReminder.weekBefore => 7,
    PaperReminder.expiryDay => 0,
  };

  /// When [kind]'s push for a paper expiring on [expiry] is due.
  static DateTime reminderTime(PaperReminder kind, DateTime expiry) {
    return DateTime(
      expiry.year,
      expiry.month,
      expiry.day - daysBefore(kind),
      _reminderHour,
    );
  }

  /// The reminder whose window [daysLeft] is in: from its day until the
  /// next one's (the expiry day's lasts one more day). Null outside them.
  static PaperReminder? dueReminder(int daysLeft) {
    if (daysLeft < -1) return null;
    if (daysLeft <= 0) return PaperReminder.expiryDay;
    if (daysLeft <= 7) return PaperReminder.weekBefore;
    if (daysLeft <= 30) return PaperReminder.monthBefore;
    return null;
  }

  static int notificationId(String paperId, PaperReminder kind) =>
      paperReminderNotificationId(paperId, kind.index);

  static String _trackerId(String paperId) => 'paper:$paperId';
  static String _notifiedKey(PaperReminder kind, DateTime expiry) =>
      '${kind.name}-${_isoDate(expiry)}';
  static String _scheduledKey(PaperReminder kind, DateTime expiry) =>
      '${kind.name}-scheduled-${_isoDate(expiry)}';
  static String _isoDate(DateTime d) => d.toIso8601String().split('T').first;

  /// Re-schedules reminders when the user switches the language or changes
  /// which reminders they want.
  void followLanguage(List<Paper> Function() current) {
    _locale?.addListener(() => syncAll(current()));
    _settings?.addListener(() => syncAll(current()));
  }

  /// Makes this device's pending paper reminders match [papers] exactly
  /// (deleted ones and another account's are cancelled). Call whenever the
  /// list changes; pass [] on sign-out. Only touches paper reminders.
  Future<void> syncAll(List<Paper> papers) {
    return _syncQueue = _syncQueue.then((_) => _syncAll(papers)).catchError((
      Object e,
      StackTrace st,
    ) {
      _logger.error('Syncing paper reminders failed', error: e, stackTrace: st);
    });
  }

  Future<void> _syncQueue = Future.value();

  Future<void> _syncAll(List<Paper> papers) async {
    await _settings?.ready;
    final now = DateTime.now();
    final userId = _getUserUseCase()?.id;
    final wanted = <_Reminder>[];
    if (userId != null) {
      for (final p in papers) {
        final r = _nextReminder(p, now);
        if (r == null) continue;
        // Already shown when the app was opened inside its window.
        if (await _tracker.hasNotified(
          _trackerId(r.paperId),
          _notifiedKey(r.kind, r.expiry),
        )) {
          continue;
        }
        wanted.add(r);
      }
    }
    final wantedIds = {for (final r in wanted) r.id};

    for (final pending in await _localNotifications.pendingNotifications()) {
      if (!isPaperReminderId(pending.id)) continue;
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
        payload: PaperReminderPayload(userId!).encode(),
      );
      // So opening the app on its day doesn't push a second time.
      await _tracker.markNotified(
        _trackerId(r.paperId),
        _scheduledKey(r.kind, r.expiry),
      );
    }
  }

  /// The paper's first wanted reminder still ahead of [now], if any.
  _Reminder? _nextReminder(Paper paper, DateTime now) {
    final expiry = paper.expiryDate;
    if (expiry == null) return null;
    for (final kind in PaperReminder.values) {
      final at = reminderTime(kind, expiry);
      if (!_wants(kind) || !at.isAfter(now)) continue;
      return _Reminder(
        id: notificationId(paper.id, kind),
        paperId: paper.id,
        kind: kind,
        expiry: expiry,
        title: _title(kind),
        body: _body(paper, daysBefore(kind)),
        dateTime: at,
      );
    }
    return null;
  }

  /// Call when the list is (re)loaded. Adds one in-app notification per
  /// reminder per expiry date when a paper is inside a reminder's window,
  /// and shows it as a banner right away, like the in-app list. The banner
  /// is skipped only if this device already delivered it (scheduled ahead,
  /// and its time has passed); one still waiting is replaced, so nobody
  /// gets the same push twice.
  Future<void> checkAndNotify(List<Paper> papers, {DateTime? today}) async {
    final user = _getUserUseCase();
    if (user == null) return;
    await _settings?.ready;
    final day = today ?? DateTime.now();

    for (final paper in papers) {
      final expiry = paper.expiryDate;
      final daysLeft = paper.daysLeft(day);
      if (expiry == null || daysLeft == null) continue;
      final kind = dueReminder(daysLeft);
      if (kind == null || !_wants(kind)) continue;

      final trackerId = _trackerId(paper.id);
      if (await _tracker.hasNotified(trackerId, _notifiedKey(kind, expiry))) {
        continue;
      }
      final title = _title(kind);
      final body = _body(paper, daysLeft);
      final id = notificationId(paper.id, kind);
      try {
        final delivered =
            await _tracker.hasNotified(
              trackerId,
              _scheduledKey(kind, expiry),
            ) &&
            !reminderTime(kind, expiry).isAfter(nowOn(today));
        // First, so a sync running meanwhile doesn't schedule it again.
        await _tracker.markNotified(trackerId, _notifiedKey(kind, expiry));
        if (!delivered) {
          await _localNotifications.cancelNotification(id);
          await _localNotifications.showNotification(
            id: id,
            title: title,
            body: body,
            payload: PaperReminderPayload(user.id).encode(),
          );
        }
        await _addNotificationUseCase(
          userId: user.id,
          title: title,
          subtitle: body,
          type: daysLeft <= 0
              ? NotificationType.error
              : NotificationType.warning,
        );
      } catch (e, st) {
        _logger.error(
          'Failed to send paper reminder',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  String _title(PaperReminder kind) => kind == PaperReminder.expiryDay
      ? _l10n.notifPaperExpiredTitle
      : _l10n.notifPaperExpiringTitle;

  /// [days] is days until the expiry date; 0 or less is "today" or passed.
  String _body(Paper paper, int days) {
    final l10n = _l10n;
    final name = PaperUi.name(l10n, paper);
    if (days < 0) return l10n.notifPaperExpiredBody(name);
    if (days == 0) return l10n.notifPaperExpiresTodayBody(name);
    return l10n.notifPaperExpiringBody(
      days,
      formatLocalizedInt(_currentLocale, days),
      name,
    );
  }
}

class _Reminder {
  const _Reminder({
    required this.id,
    required this.paperId,
    required this.kind,
    required this.expiry,
    required this.title,
    required this.body,
    required this.dateTime,
  });

  final int id;
  final String paperId;
  final PaperReminder kind;
  final DateTime expiry;
  final String title;
  final String body;
  final DateTime dateTime;
}
