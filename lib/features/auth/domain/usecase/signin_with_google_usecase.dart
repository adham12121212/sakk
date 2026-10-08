import 'package:dartz/dartz.dart';
import '../../../../core/error/Failure.dart';
import '../auth_repo/auth_repo.dart';
import '../entities/user_entity.dart';

abstract class SignInWithGoogleUseCase {
  Future<Either<Failure, UserEntity>> call();
}

class SignInWithGoogleUseCaseImpl implements SignInWithGoogleUseCase {
  final AuthRepository _authRepository;
  SignInWithGoogleUseCaseImpl(this._authRepository);

  @override
  Future<Either<Failure, UserEntity>> call() => _authRepository.signInWithGoogle();
}