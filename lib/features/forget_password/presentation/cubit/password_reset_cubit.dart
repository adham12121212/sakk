import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/service/password_recovery_service.dart';
import '../../../auth/domain/usecase/send_password_reset_otp_usecase.dart';
import '../../../auth/domain/usecase/signout_usecase.dart';
import '../../../auth/domain/usecase/update_password_usecase.dart';
import '../../../auth/domain/usecase/verify_password_reset_otp_usecase.dart';
part 'password_reset_state.dart';

class PasswordResetCubit extends Cubit<PasswordResetState> {
  PasswordResetCubit(
    this._sendOtpUseCase,
    this._verifyOtpUseCase,
    this._updatePasswordUseCase,
    this._signOutUseCase,
    this._recoveryService,
  ) : super(PasswordResetIdle());

  final SendPasswordResetOtpUseCase _sendOtpUseCase;
  final VerifyPasswordResetOtpUseCase _verifyOtpUseCase;
  final UpdatePasswordUseCase _updatePasswordUseCase;
  final SignOutUseCase _signOutUseCase;
  final PasswordRecoveryService _recoveryService;

  String? _email;
  String? get email => _email;

  Future<void> sendOtp(String email) async {
    emit(PasswordResetLoading());
    _email = email;
    final result = await _sendOtpUseCase(email: email);
    result.fold(
      (failure) => emit(PasswordResetError(failure.message)),
      (_) => emit(PasswordResetOtpSent()),
    );
  }

  Future<void> verifyOtp(String otp) async {
    final email = _email;
    if (email == null) {
      emit(PasswordResetError('Something went wrong — please start over.'));
      return;
    }
    emit(PasswordResetLoading());
    // Marked before verifying: a correct code creates the session right away.
    await _recoveryService.markPending();
    final result = await _verifyOtpUseCase(email: email, otp: otp);
    await result.fold((failure) async {
      await _recoveryService.clear();
      emit(PasswordResetError(failure.message));
    }, (_) async => emit(PasswordResetOtpVerified()));
  }

  Future<void> updatePassword(String newPassword) async {
    emit(PasswordResetLoading());
    final result = await _updatePasswordUseCase(newPassword: newPassword);
    await result.fold(
      (failure) async => emit(PasswordResetError(failure.message)),
      (_) async {
        await _recoveryService.clear();
        emit(PasswordResetCompleted());
      },
    );
  }

  /// Leaving the new-password screen without saving: drop the recovery
  /// session so the user isn't left signed in.
  Future<void> abandon() async {
    await _signOutUseCase();
    await _recoveryService.clear();
  }
}
