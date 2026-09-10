part of 'password_reset_cubit.dart';

@immutable
sealed class PasswordResetState {}

final class PasswordResetIdle extends PasswordResetState {}

final class PasswordResetLoading extends PasswordResetState {}

final class PasswordResetOtpSent extends PasswordResetState {}

final class PasswordResetOtpVerified extends PasswordResetState {}

final class PasswordResetCompleted extends PasswordResetState {}

final class PasswordResetError extends PasswordResetState {
  final String message;
  PasswordResetError(this.message);
}