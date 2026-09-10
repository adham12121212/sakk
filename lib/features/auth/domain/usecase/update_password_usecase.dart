import 'package:dartz/dartz.dart';

import '../../../../core/error/Failure.dart';
import '../auth_repo/auth_repo.dart';

abstract class UpdatePasswordUseCase {
  Future<Either<Failure, void>> call({required String newPassword});
}

class UpdatePasswordUseCaseImpl implements UpdatePasswordUseCase {
  final AuthRepository _authRepository;
  UpdatePasswordUseCaseImpl(this._authRepository);

  @override
  Future<Either<Failure, void>> call({required String newPassword}) {
    return _authRepository.updatePassword(newPassword: newPassword);
  }
}