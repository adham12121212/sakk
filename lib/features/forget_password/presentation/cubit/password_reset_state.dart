part of 'password_reset_cubit.dart';

@immutable
sealed class PasswordResetState {}

final class PasswordResetIdle extends PasswordResetState {}

final class PasswordResetLoading extends PasswordResetState {}

final class PasswordResetOtpSent extends PasswordResetState {
  /// A new code went to an address that already had one.
  final bool resent;
  PasswordResetOtpSent({required this.resent});
}

final class PasswordResetOtpVerified extends PasswordResetState {}

final class PasswordResetCompleted extends PasswordResetState {}

final class PasswordResetError extends PasswordResetState {
  final String message;
  PasswordResetError(this.message);
}
