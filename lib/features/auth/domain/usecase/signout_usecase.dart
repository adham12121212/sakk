
import '../auth_repo/auth_repo.dart';

abstract class SignOutUseCase {
  Future<void> call();
}


class SignOutUseCaseImpl  implements SignOutUseCase{

  final AuthRepository _authRepository;

  SignOutUseCaseImpl(this._authRepository);

  @override
  Future<void> call() {
    return _authRepository.signOut();
  }

}