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

  /// How long before another code can be requested. Supabase limits
  /// recovery emails per address too; this keeps the app from hitting it.
  static const resendCooldown = Duration(seconds: 60);

  String? _email;
  String? get email => _email;
  DateTime? _sentAt;

  /// Time left before [sendOtp] will send another code; zero when it can.
  Duration get resendCooldownLeft {
    final sentAt = _sentAt;
    if (sentAt == null) return Duration.zero;
    final left = resendCooldown - DateTime.now().difference(sentAt);
    return left.isNegative ? Duration.zero : left;
  }

  Future<void> sendOtp(String email) async {
    if (state is PasswordResetLoading) return;
    // Back on the email screen and sent again to the same address: the code
    // that's already on its way still works, so go straight to entering it.
    if (email == _email && resendCooldownLeft > Duration.zero) {
      emit(PasswordResetOtpSent(resent: false));
      return;
    }
    emit(PasswordResetLoading());
    final resent = email == _email;
    final result = await _sendOtpUseCase(email: email);
    result.fold((failure) => emit(PasswordResetError(failure.message)), (_) {
      _email = email;
      _sentAt = DateTime.now();
      emit(PasswordResetOtpSent(resent: resent));
    });
  }

  Future<void> verifyOtp(String otp) async {
    final email = _email;
    if (email == null) {
      emit(PasswordResetError('No email to verify the code for'));
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
