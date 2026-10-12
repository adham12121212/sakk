import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/scanned_subscription.dart';
import '../subscription_repo/subscription_repo.dart';

abstract class ExtractSubscriptionUseCase {
  /// Reads a subscription from a screenshot ([imagePath]) and/or pasted
  /// [text]. [knownServices] are catalog names the AI should match.
  Future<Either<Failure, ScannedSubscription>> call({
    String? imagePath,
    String? text,
    List<String> knownServices = const [],
  });
}

class ExtractSubscriptionUseCaseImpl implements ExtractSubscriptionUseCase {
  final SubscriptionRepo _repository;
  ExtractSubscriptionUseCaseImpl(this._repository);

  @override
  Future<Either<Failure, ScannedSubscription>> call({
    String? imagePath,
    String? text,
    List<String> knownServices = const [],
  }) {
    return _repository.extractSubscription(
      imagePath: imagePath,
      text: text,
      knownServices: knownServices,
    );
  }
}
