import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecase/delete_notification_use_case.dart';
import '../../domain/usecase/get_notification_use_case.dart';

import '../../domain/usecase/mark_notification_read_use_case.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final MarkNotificationAsReadUseCase markNotificationAsReadUseCase;
  final DeleteNotificationUseCase deleteNotificationUseCase;

  NotificationCubit({
    required this.getNotificationsUseCase,
    required this.markNotificationAsReadUseCase,
    required this.deleteNotificationUseCase,
  }) : super(NotificationInitial());

  Future<void> loadNotifications(String userId) async {
    emit(NotificationLoading());
    final result = await getNotificationsUseCase(userId);
    result.fold(
          (failure) => emit(NotificationError(failure.message)),
          (notifications) => emit(NotificationLoaded(notifications)),
    );
  }


  Future<void> markAsRead(String userId, String notificationId) async {
    final result = await markNotificationAsReadUseCase(notificationId);
    result.fold(
          (failure) => emit(NotificationError(failure.message)),
          (_) => loadNotifications(userId),
    );
  }

  Future<void> deleteNotification(String userId, String notificationId) async {
    final result = await deleteNotificationUseCase(notificationId);
    result.fold(
          (failure) => emit(NotificationError(failure.message)),
          (_) => loadNotifications(userId),
    );
  }
}