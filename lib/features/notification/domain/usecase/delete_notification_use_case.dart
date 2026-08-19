import 'package:dartz/dartz.dart';

import '../../../../core/error/Failure.dart';
import '../notification_repo/notification_repo.dart';

abstract class DeleteNotificationUseCase {
  Future<Either<Failure, void>> call(String notificationId);
}

class DeleteNotificationUseCaseImpl implements DeleteNotificationUseCase {
  final NotificationRepo notificationRepo;
  DeleteNotificationUseCaseImpl({required this.notificationRepo});

  @override
  Future<Either<Failure, void>> call(String notificationId) {
    return notificationRepo.deleteNotification(notificationId);
  }
}