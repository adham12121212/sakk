import '../notification_repo/notification_repo.dart';

abstract class WatchAddedNotificationsUseCase {
  /// Emits the user id each time a notification is added from this device.
  Stream<String> call();
}

class WatchAddedNotificationsUseCaseImpl implements WatchAddedNotificationsUseCase {
  final NotificationRepo notificationRepo;
  WatchAddedNotificationsUseCaseImpl({required this.notificationRepo});

  @override
  Stream<String> call() => notificationRepo.onNotificationAdded;
}
