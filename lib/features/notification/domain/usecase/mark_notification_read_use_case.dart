import 'package:dartz/dartz.dart';

import '../../../../core/error/Failure.dart';
import '../notification_repo/notification_repo.dart';

abstract class MarkNotificationAsReadUseCase {
  Future<Either<Failure, void>> call(String notificationId);
}

class MarkNotificationAsReadUseCaseImpl implements MarkNotificationAsReadUseCase {
  final NotificationRepo notificationRepo;
  MarkNotificationAsReadUseCaseImpl({required this.notificationRepo});

  @override
  Future<Either<Failure, void>> call(String notificationId) {
    return notificationRepo.markNotificationAsRead(notificationId);
  }
}