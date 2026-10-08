import 'package:dartz/dartz.dart';

import '../../../../core/error/Failure.dart';
import '../auth_repo/auth_repo.dart';

abstract class DeleteAccountUseCase {
  Future<Either<Failure, void>> call();
}

class DeleteAccountUseCaseImpl implements DeleteAccountUseCase {
  final AuthRepository _authRepository;
  DeleteAccountUseCaseImpl(this._authRepository);

  @override
  Future<Either<Failure, void>> call() {
    return _authRepository.deleteAccount();
  }
}