
import '../auth_repo/auth_repo.dart';
import '../entities/user_entity.dart';

abstract class GetUserUseCase {
  UserEntity? call();
}

class GetUserUseCaseImpl implements GetUserUseCase {
  final AuthRepository _authRepository;
  GetUserUseCaseImpl(this._authRepository);

  @override
  UserEntity? call() {
    return _authRepository.getUser();
  }
}