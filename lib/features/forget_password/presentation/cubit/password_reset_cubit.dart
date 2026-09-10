import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/usecase/send_password_reset_otp_usecase.dart';
import '../../../auth/domain/usecase/update_password_usecase.dart';
import '../../../auth/domain/usecase/verify_password_reset_otp_usecase.dart';
part 'password_reset_state.dart';

class PasswordResetCubit extends Cubit<PasswordResetState> {
  PasswordResetCubit(
      this._sendOtpUseCase,
      this._verifyOtpUseCase,
      this._updatePasswordUseCase,
      ) : super(PasswordResetIdle());

  final SendPasswordResetOtpUseCase _sendOtpUseCase;
  final VerifyPasswordResetOtpUseCase _verifyOtpUseCase;
  final UpdatePasswordUseCase _updatePasswordUseCase;

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
    final result = await _verifyOtpUseCase(email: email, otp: otp);
    result.fold(
          (failure) => emit(PasswordResetError(failure.message)),
          (_) => emit(PasswordResetOtpVerified()),
    );
  }

  Future<void> updatePassword(String newPassword) async {
    emit(PasswordResetLoading());
    final result = await _updatePasswordUseCase(newPassword: newPassword);
    result.fold(
          (failure) => emit(PasswordResetError(failure.message)),
          (_) => emit(PasswordResetCompleted()),
    );
  }
}