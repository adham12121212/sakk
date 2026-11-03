import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'app_permissions.dart';

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

  /// The "Mark as paid" button on installment reminders. Both platforms
  /// open the app to run it (no background isolate), so it reaches
  /// [onNotificationTap] or [getLaunchResponse] with this as the actionId.
  static const markPaidActionId = 'mark_paid';
  static const _installmentCategoryId = 'installment_due';

  bool _initialized = false;

  /// Called whenever a notification is tapped while the app process is
  /// already alive (foreground or backgrounded-but-not-killed). For the
  /// "app was fully closed/terminated" case, see [getLaunchPayload].
  void Function(NotificationResponse response)? onNotificationTap;

  /// [markPaidLabel] titles the iOS "Mark as paid" button. iOS registers it
  /// once here, so it changes language on the next app start; Android takes
  /// the title with each notification.
  Future<void> init({String markPaidLabel = 'Mark as paid'}) async {
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
        developer.log('Unknown timezone "$timezoneId", defaulting to UTC: $e');
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      // Android initialization.
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS initialization. Alert/badge/sound permission is requested
      // explicitly later via requestPermission(); leaving these false here
      // just avoids a duplicate system prompt at init time.
      final iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: [
          DarwinNotificationCategory(
            _installmentCategoryId,
            actions: [
              DarwinNotificationAction.plain(
                markPaidActionId,
                markPaidLabel,
                // Unlocked phone only: it changes the user's data.
                options: {
                  DarwinNotificationActionOption.foreground,
                  DarwinNotificationActionOption.authenticationRequired,
                },
              ),
            ],
          ),
        ],
      );

      final settings = InitializationSettings(
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
            AndroidFlutterLocalNotificationsPlugin
          >()
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
  Future<String?> getLaunchPayload() async =>
      (await getLaunchResponse())?.payload;

  /// Like [getLaunchPayload], with the button that was pressed, if any
  /// (see [markPaidActionId]).
  Future<NotificationResponse?> getLaunchResponse() async {
    try {
      final details = await _notifications.getNotificationAppLaunchDetails();
      if (details != null && details.didNotificationLaunchApp) {
        return details.notificationResponse;
      }
    } catch (e) {
      developer.log('getLaunchResponse failed: $e');
    }
    return null;
  }

  /// Asks for notifications if the system still can, for app start, where
  /// nothing was tapped. Taps go through [AppPermissions.ensure], which also
  /// handles a permission the system will no longer ask for.
  Future<bool> requestPermission() async {
    final granted = await AppPermissions.instance.requestQuietly(
      AppPermission.notifications,
    );
    developer.log('>>> Notification permission granted: $granted');
    return granted;
  }

  /// Shows a notification now (a banner, also while the app is open).
  /// Set [markPaidLabel] to add a "Mark as paid" button (installments).
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? markPaidLabel,
  }) async {
    if (!await AppPermissions.instance.isGranted(AppPermission.notifications)) {
      developer.log(
        '>>> showNotification SKIPPED-ISH (permission not confirmed granted): '
        'id=$id title="$title". The call will still be attempted, but the '
        'OS will most likely display nothing. Check Settings > Notifications '
        'for this app.',
      );
    }

    try {
      await _notifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _details(markPaidLabel),
        payload: payload,
      );
      developer.log('>>> showNotification CALLED OK: id=$id title="$title"');
    } catch (e, stack) {
      developer.log('>>> showNotification THREW: $e', stackTrace: stack);
    }
  }

  /// How every reminder looks: high importance on Android; banner, list,
  /// badge and sound on iOS, also in the foreground. With [markPaidLabel],
  /// a "Mark as paid" button that opens the app.
  ///
  /// presentAlert is Apple's old foreground API; newer iOS versions read
  /// presentBanner/presentList instead, and setting only presentAlert can
  /// silently show nothing. All of them are set.
  NotificationDetails _details(String? markPaidLabel) {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      actions: markPaidLabel == null
          ? null
          : [
              AndroidNotificationAction(
                markPaidActionId,
                markPaidLabel,
                showsUserInterface: true,
              ),
            ],
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: markPaidLabel == null ? null : _installmentCategoryId,
    );
    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  /// Schedules a one-off notification at [dateTime].
  ///
  /// Set [matchDateTimeComponents] to repeat (e.g.
  /// [DateTimeComponents.dayOfMonthAndTime] for a yearly reminder on
  /// warranty expiry, or [DateTimeComponents.time] for daily).
  ///
  /// Set [markPaidLabel] to add a "Mark as paid" button (installments).
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
    String? markPaidLabel,
  }) async {
    if (dateTime.isBefore(DateTime.now())) {
      developer.log(
        'scheduleNotification: dateTime $dateTime is in the past, skipping.',
      );
      return;
    }

    if (!await AppPermissions.instance.isGranted(AppPermission.notifications)) {
      developer.log(
        '>>> scheduleNotification SKIPPED-ISH (permission not confirmed '
        'granted): id=$id title="$title" for $dateTime.',
      );
    }

    final details = _details(markPaidLabel);
    final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);

    // Inexact on purpose: Play only allows the exact-alarm permission for
    // alarm-clock and calendar apps, and a warranty reminder a few minutes
    // late is fine.
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
      developer.log(
        '>>> scheduleNotification CALLED OK: id=$id at $scheduledDate',
      );
    } catch (e, stack) {
      developer.log('>>> scheduleNotification THREW: $e', stackTrace: stack);
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
