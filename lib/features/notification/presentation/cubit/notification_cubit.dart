import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/notification_enitiy.dart';
import '../../domain/usecase/delete_notification_use_case.dart';
import '../../domain/usecase/get_notification_use_case.dart';
import '../../domain/usecase/mark_notification_read_use_case.dart';
import '../../domain/usecase/watch_added_notifications_use_case.dart';
import 'notification_state.dart';

/// App-wide (lazy singleton) so the Home bell badge and the Notifications
/// screen share one list: reading or deleting there updates the badge.
///
/// Call [watch] once a user is known. The list then refreshes when a
/// notification is added on this device and when the app returns to the
/// foreground. (The `notifications` table isn't in the `supabase_realtime`
/// publication, so there are no live inserts from the server.)
class NotificationCubit extends Cubit<NotificationState> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final MarkNotificationAsReadUseCase markNotificationAsReadUseCase;
  final DeleteNotificationUseCase deleteNotificationUseCase;
  final WatchAddedNotificationsUseCase watchAddedNotificationsUseCase;

  NotificationCubit({
    required this.getNotificationsUseCase,
    required this.markNotificationAsReadUseCase,
    required this.deleteNotificationUseCase,
    required this.watchAddedNotificationsUseCase,
  }) : super(NotificationInitial());

  String? _userId;
  List<NotificationEntity>? _notifications;
  StreamSubscription<String>? _addedSubscription;
  AppLifecycleListener? _lifecycleListener;
  Future<void>? _inFlightLoad;

  /// Unread notifications in the last successfully loaded list. Kept through
  /// later loading/error states, so the badge doesn't blink during a refresh.
  int get unreadCount => _notifications?.where((n) => !n.isRead).length ?? 0;

  /// Starts tracking [userId]'s notifications. Switching users clears the
  /// previous user's list first. Does not load; call [refresh] for that.
  void watch(String userId) {
    if (_userId == userId) return;
    reset();
    _userId = userId;
    _addedSubscription = watchAddedNotificationsUseCase().listen((addedFor) {
      if (addedFor == _userId) refresh();
    });
    _lifecycleListener = AppLifecycleListener(onResume: refresh);
  }

  /// Stops tracking and forgets the list (e.g. on sign-out).
  void reset() {
    _addedSubscription?.cancel();
    _addedSubscription = null;
    _lifecycleListener?.dispose();
    _lifecycleListener = null;
    _userId = null;
    _notifications = null;
    _inFlightLoad = null;
    if (!isClosed) emit(NotificationInitial());
  }

  /// Reloads the watched user's notifications. Overlapping calls share one
  /// request.
  Future<void> refresh() {
    final userId = _userId;
    if (userId == null) return Future.value();
    return _inFlightLoad ??= loadNotifications(userId).whenComplete(() => _inFlightLoad = null);
  }

  Future<void> loadNotifications(String userId) async {
    // Skeleton only for the first load; later loads update in place.
    if (_notifications == null) emit(NotificationLoading());
    final result = await getNotificationsUseCase(userId);
    if (isClosed || userId != _userId) return;
    result.fold(
          (failure) {
        // With a list already on screen, keep it rather than replacing it
        // with an error (e.g. a background refresh while offline). The
        // repository has already logged the failure.
        if (_notifications == null) emit(NotificationError(failure.message));
      },
          (notifications) => _emitList(notifications),
    );
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    final previous = _notifications;
    if (previous != null) {
      _emitList([
        for (final n in previous) n.id == notificationId ? n.copyWith(isRead: true) : n,
      ]);
    }
    final result = await markNotificationAsReadUseCase(notificationId);
    result.fold(
          (failure) {
        _notifications = previous;
        emit(NotificationError(failure.message));
      },
          (_) {},
    );
  }

  Future<void> deleteNotification(String userId, String notificationId) async {
    final previous = _notifications;
    if (previous != null) {
      // Removed right away: the Dismissible that triggered this must not
      // stay in the tree.
      _emitList(previous.where((n) => n.id != notificationId).toList());
    }
    final result = await deleteNotificationUseCase(notificationId);
    result.fold(
          (failure) {
        _notifications = previous;
        emit(NotificationError(failure.message));
      },
          (_) {},
    );
  }

  void _emitList(List<NotificationEntity> notifications) {
    _notifications = List.unmodifiable(notifications);
    emit(NotificationLoaded(_notifications!));
  }

  @override
  Future<void> close() {
    _addedSubscription?.cancel();
    _lifecycleListener?.dispose();
    return super.close();
  }
}
