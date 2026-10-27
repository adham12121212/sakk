import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/error/failure.dart';
import 'package:sakk/core/service/password_recovery_service.dart';
import 'package:sakk/features/auth/domain/usecase/send_password_reset_otp_usecase.dart';
import 'package:sakk/features/auth/domain/usecase/signout_usecase.dart';
import 'package:sakk/features/auth/domain/usecase/update_password_usecase.dart';
import 'package:sakk/features/auth/domain/usecase/verify_password_reset_otp_usecase.dart';
import 'package:sakk/features/forget_password/presentation/cubit/password_reset_cubit.dart';

class _FakeSend implements SendPasswordResetOtpUseCase {
  final sentTo = <String>[];
  Failure? failure;

  @override
  Future<Either<Failure, void>> call({required String email}) async {
    sentTo.add(email);
    final failure = this.failure;
    return failure == null ? const Right(null) : Left(failure);
  }
}

class _UnusedVerify implements VerifyPasswordResetOtpUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _UnusedUpdate implements UpdatePasswordUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _UnusedSignOut implements SignOutUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _UnusedRecovery implements PasswordRecoveryService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late _FakeSend send;
  late PasswordResetCubit cubit;

  setUp(() {
    send = _FakeSend();
    cubit = PasswordResetCubit(
      send,
      _UnusedVerify(),
      _UnusedUpdate(),
      _UnusedSignOut(),
      _UnusedRecovery(),
    );
  });

  tearDown(() => cubit.close());

  test('a sent code starts the resend cooldown', () async {
    expect(cubit.resendCooldownLeft, Duration.zero);
    await cubit.sendOtp('a@example.com');

    expect(cubit.state, isA<PasswordResetOtpSent>());
    expect((cubit.state as PasswordResetOtpSent).resent, isFalse);
    expect(cubit.resendCooldownLeft, greaterThan(const Duration(seconds: 55)));
  });

  test('the same email during the cooldown is not sent again', () async {
    await cubit.sendOtp('a@example.com');
    await cubit.sendOtp('a@example.com');

    expect(send.sentTo, ['a@example.com']);
    expect(cubit.state, isA<PasswordResetOtpSent>());
  });

  test('a different email is sent right away', () async {
    await cubit.sendOtp('a@example.com');
    await cubit.sendOtp('b@example.com');

    expect(send.sentTo, ['a@example.com', 'b@example.com']);
  });

  test('a failed send leaves no cooldown', () async {
    send.failure = const ServerFailure('reset_rate_limited');
    await cubit.sendOtp('a@example.com');

    expect(cubit.state, isA<PasswordResetError>());
    expect(cubit.resendCooldownLeft, Duration.zero);
  });
}
