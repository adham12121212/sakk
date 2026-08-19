import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_timezone/timezone_info.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;


@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse response) {

  developer.log('Background notification tapped: ${response.payload}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'sakk_notifications';
  static const String _channelName = 'Sakk Notifications';
  static const String _channelDescription =
      'Warranty and product notifications';

  bool _initialized = false;

  /// Last known permission grant result, cached after [requestPermission]
  /// so [showNotification]/[scheduleNotification] can log a clear warning
  /// instead of silently doing nothing when permission is missing —
  /// that's the single most common reason a notification "goes nowhere".
  bool _permissionGranted = false;

  /// Called whenever a notification is tapped while the app process is
  /// already alive (foreground or backgrounded-but-not-killed). For the
  /// "app was fully closed/terminated" case, see [getLaunchPayload].
  void Function(NotificationResponse response)? onNotificationTap;

  Future<void> init() async {
    if (_initialized) return;

    try {
      // Must run before any getLocation()/setLocalLocation() call, or
      // lookups (including the 'UTC' fallback below) throw because the
      // timezone database hasn't been loaded into memory yet.
      tz.initializeTimeZones();

      String timezoneId;
      try {
        final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
        timezoneId = info.identifier;
      } catch (e) {
        developer.log('Failed to get local timezone, defaulting to UTC: $e');
        timezoneId = 'UTC';
      }

      try {
        tz.setLocalLocation(tz.getLocation(timezoneId));
      } catch (e) {
        developer.log(
          'Unknown timezone "$timezoneId", defaulting to UTC: $e',
        );
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      // Android initialization.
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS initialization. Alert/badge/sound permission is requested
      // explicitly later via requestPermission(); leaving these false here
      // just avoids a duplicate system prompt at init time.
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: _onNotificationTap,
        onDidReceiveBackgroundNotificationResponse:
        notificationTapBackgroundHandler,
      );

      // Explicitly create the Android channel so its settings (importance,
      // sound, vibration) are consistent from install to install.
      const androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      _initialized = true;
      developer.log('NotificationService initialized OK');
    } catch (e, stack) {
      developer.log('NotificationService.init failed: $e', stackTrace: stack);
      // Rethrow so the caller (e.g. main.dart) knows init didn't succeed,
      // rather than silently limping along with a half-configured plugin.
      rethrow;
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    onNotificationTap?.call(response);
  }

  /// Returns the `payload` of the notification that launched the app, if
  /// the app process was fully terminated and the user tapped a
  /// notification to (re)launch it. Returns null on a normal cold start.
  ///
  /// Call this once, right after [init], and use the result to navigate to
  /// the relevant screen — the normal [onNotificationTap] callback does
  /// NOT fire in this scenario, since there's no running app to deliver it
  /// to at the moment the notification was tapped.
  Future<String?> getLaunchPayload() async {
    try {
      final details = await _notifications.getNotificationAppLaunchDetails();
      if (details != null && details.didNotificationLaunchApp) {
        return details.notificationResponse?.payload;
      }
    } catch (e) {
      developer.log('getLaunchPayload failed: $e');
    }
    return null;
  }

  /// Requests notification permissions on iOS and Android 13+, and caches
  /// the result so later show/schedule calls can warn loudly instead of
  /// failing silently. **This does NOT re-prompt if the user already
  /// denied it** — that's an OS restriction, not a bug here; the user has
  /// to flip it on manually in system Settings once denied.
  Future<bool> requestPermission() async {
    bool? iosGranted;
    bool? androidGranted;

    try {
      iosGranted = await _notifications
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      developer.log('iOS permission request failed: $e');
    }

    try {
      androidGranted = await _notifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      developer.log('Android notification permission request failed: $e');
    }

    // Android 12+ requires a separate exact-alarm permission for
    // zonedSchedule with exactAllowWhileIdle. Without it, scheduling
    // either throws or silently degrades to an inexact alarm.
    try {
      await _notifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
    } catch (e) {
      developer.log('Exact alarm permission request failed: $e');
    }

    _permissionGranted = (iosGranted ?? false) || (androidGranted ?? false);


    developer.log('>>> Notification permission granted: $_permissionGranted');

    return _permissionGranted;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_permissionGranted) {
      developer.log(
        '>>> showNotification SKIPPED-ISH (permission not confirmed granted): '
            'id=$id title="$title". The call will still be attempted, but the '
            'OS will most likely display nothing. Check Settings > Notifications '
            'for this app.',
      );
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    // presentAlert is Apple's OLD foreground-presentation API; newer iOS
    // versions expect presentBanner/presentList instead (Apple deprecated
    // .alert in favor of .banner + .list). Setting only presentAlert can
    // silently produce no banner at all on current iOS — no error, it just
    // doesn't render. Set all of them so foreground display works
    // regardless of which API path the OS actually consults.
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
      developer.log('>>> showNotification CALLED OK: id=$id title="$title"');
    } catch (e, stack) {
      developer.log('>>> showNotification THREW: $e', stackTrace: stack);
    }
  }

  /// Schedules a one-off notification at [dateTime].
  ///
  /// Set [matchDateTimeComponents] to repeat (e.g.
  /// [DateTimeComponents.dayOfMonthAndTime] for a yearly reminder on
  /// warranty expiry, or [DateTimeComponents.time] for daily).
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    if (dateTime.isBefore(DateTime.now())) {
      developer.log(
        'scheduleNotification: dateTime $dateTime is in the past, skipping.',
      );
      return;
    }

    if (!_permissionGranted) {
      developer.log(
        '>>> scheduleNotification SKIPPED-ISH (permission not confirmed '
            'granted): id=$id title="$title" for $dateTime.',
      );
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);

    try {
      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        matchDateTimeComponents: matchDateTimeComponents,
      );
      developer.log('>>> scheduleNotification CALLED OK: id=$id at $scheduledDate');
    } catch (e, stack) {
      developer.log('>>> scheduleNotification THREW (exact): $e', stackTrace: stack);
      // Fall back to an inexact schedule rather than losing the
      // reminder entirely if exact-alarm permission was denied.
      try {
        await _notifications.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
          matchDateTimeComponents: matchDateTimeComponents,
        );
        developer.log('>>> scheduleNotification CALLED OK (inexact fallback): id=$id');
      } catch (e2, stack2) {
        developer.log(
          '>>> scheduleNotification THREW (inexact fallback too): $e2',
          stackTrace: stack2,
        );
      }
    }
  }

  Future<List<PendingNotificationRequest>> pendingNotifications() {
    return _notifications.pendingNotificationRequests();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}