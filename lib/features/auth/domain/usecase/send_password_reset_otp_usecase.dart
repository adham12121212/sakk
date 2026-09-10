import 'package:dartz/dartz.dart';

import '../../../../core/error/Failure.dart';
import '../auth_repo/auth_repo.dart';

abstract class SendPasswordResetOtpUseCase {
  Future<Either<Failure, void>> call({required String email});
}

class SendPasswordResetOtpUseCaseImpl implements SendPasswordResetOtpUseCase {
  final AuthRepository _authRepository;
  SendPasswordResetOtpUseCaseImpl(this._authRepository);

  @override
  Future<Either<Failure, void>> call({required String email}) {
    return _authRepository.sendPasswordResetOtp(email: email);
  }
}