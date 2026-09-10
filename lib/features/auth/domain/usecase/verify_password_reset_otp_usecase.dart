import 'package:dartz/dartz.dart';

import '../../../../core/error/Failure.dart';
import '../auth_repo/auth_repo.dart';

abstract class VerifyPasswordResetOtpUseCase {
  Future<Either<Failure, void>> call({required String email, required String otp});
}

class VerifyPasswordResetOtpUseCaseImpl implements VerifyPasswordResetOtpUseCase {
  final AuthRepository _authRepository;
  VerifyPasswordResetOtpUseCaseImpl(this._authRepository);

  @override
  Future<Either<Failure, void>> call({required String email, required String otp}) {
    return _authRepository.verifyPasswordResetOtp(email: email, otp: otp);
  }
}