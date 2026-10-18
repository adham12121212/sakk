import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakk/features/auth/domain/usecase/signout_usecase.dart';
import 'package:sakk/features/auth/domain/usecase/signup_usecase.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/service/biometric_auth_service.dart';
import '../../../household/presentation/cubit/household_cubit.dart';
import '../../../installments/domain/usecase/clear_cached_installments_usecase.dart';
import '../../../installments/presentation/cubit/installments_cubit.dart';
import '../../../notification/presentation/cubit/notification_cubit.dart';
import '../../../products/domain/usecase/clear_cached_products_usecase.dart';
import '../../../subscriptions/domain/usecase/clear_cached_subscriptions_usecase.dart';
import '../../../subscriptions/presentation/cubit/subscriptions_cubit.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecase/delete_account_usecase.dart';
import '../../domain/usecase/signin_usecase.dart';
import '../../domain/usecase/signin_with_google_usecase.dart';
import '../../domain/usecase/update_avatar_usecase.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignupUsecase _signupUsecase;
  final SignInUseCase _signInUsecase;
  final SignOutUseCase _signOutUseCase;
  final UpdateAvatarUseCase _updateAvatarUseCase;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final DeleteAccountUseCase _deleteAccountUseCase;

  AuthCubit(
      this._signupUsecase,
      this._signInUsecase,
      this._signOutUseCase,
      this._updateAvatarUseCase,
      this._signInWithGoogleUseCase,
      this._deleteAccountUseCase,
      ) : super(AuthInitial());


  Future<void> signin({required String email, required String password}) async{
    emit(AuthLoading());
    final result = await _signInUsecase.call(email: email, password: password);
    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (user) {

        getIt<ProductsCubit>().reset();

        getIt<SubscriptionsCubit>().reset();
        getIt<InstallmentsCubit>().reset();
        emit(AuthSuccess(user));
      },
    );

  }

  Future<void> signup({
    required String email,
    required String password,
    required String fullName,
  }) async {
    emit(AuthLoading());
    final result = await _signupUsecase.call(email: email, password: password, fullName: fullName);
    result.fold(
          (failure) {
        if (failure is EmailConfirmationRequiredFailure) {
          emit(AuthEmailConfirmationRequired());
          return;
        }
        emit(AuthError(failure.message));
      },
          (user) {
        getIt<ProductsCubit>().reset();
        getIt<SubscriptionsCubit>().reset();
        getIt<InstallmentsCubit>().reset();
        emit(AuthSuccess(user));
      },
    );
  }

  /// [keepBiometricLock] is for "use password instead" on the lock screen,
  /// where the same person is signing straight back in.
  Future<void> signOut({bool keepBiometricLock = false}) async {
    emit(AuthLoading());
    try {
      await _signOutUseCase.call();
      if (!keepBiometricLock) {
        await getIt<BiometricAuthService>().setEnabled(false);
      }
    } finally {
      getIt<ProductsCubit>().reset();
      getIt<SubscriptionsCubit>().reset();
      getIt<InstallmentsCubit>().reset();
      getIt<NotificationCubit>().reset();
      getIt<HouseholdCubit>().reset();
      try {
        await getIt<ClearCachedProductsUseCase>()();
        await getIt<ClearCachedSubscriptionsUseCase>()();
        await getIt<ClearCachedInstallmentsUseCase>()();
      } finally {
        if (!isClosed) emit(AuthInitial());
      }
    }
  }

  Future<void> updateAvatar(File imageFile) async {
    emit(AuthAvatarUpdating());
    final result = await _updateAvatarUseCase.call(imageFile);
    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (user) => emit(AuthAvatarUpdated(user)),
    );
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    final result = await _signInWithGoogleUseCase();
    result.fold(
          (failure) {
        if (failure is CancelledFailure) { emit(AuthInitial()); return; }
        emit(AuthError(failure.message));
      },
          (user) { getIt<ProductsCubit>().reset(); getIt<SubscriptionsCubit>().reset(); getIt<InstallmentsCubit>().reset(); emit(AuthSuccess(user)); },
    );
  }

  Future<void> deleteAccount() async {
    emit(AuthLoading());
    final result = await _deleteAccountUseCase.call();
    await result.fold(
          (failure) async => emit(AuthError(failure.message)),
          (_) async {
        await getIt<BiometricAuthService>().setEnabled(false);
        getIt<ProductsCubit>().reset();
        getIt<SubscriptionsCubit>().reset();
        getIt<InstallmentsCubit>().reset();
        getIt<NotificationCubit>().reset();
        getIt<HouseholdCubit>().reset();
        await getIt<ClearCachedProductsUseCase>()();
        await getIt<ClearCachedSubscriptionsUseCase>()();
        await getIt<ClearCachedInstallmentsUseCase>()();
        emit(AuthInitial());
      },
    );
  }

}
