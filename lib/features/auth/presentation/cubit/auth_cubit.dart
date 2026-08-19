import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:meta/meta.dart';
import 'package:sakk/features/auth/domain/usecase/signout_usecase.dart';
import 'package:sakk/features/auth/domain/usecase/signup_usecase.dart';
import '../../../../core/error/Failure.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecase/signin_usecase.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignupUsecase _signupUsecase;
  final SignInUseCase _signInUsecase;
  final SignOutUseCase _signOutUseCase;
  AuthCubit(
      this._signupUsecase,
      this._signInUsecase,
      this._signOutUseCase,
      ) : super(AuthInitial());


  Future<void> signin({required String email, required String password}) async{
    emit(AuthLoading());
    final result = await _signInUsecase.call(email: email, password: password);
    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (user) => emit(AuthSuccess(user)),
    );

  }

  Future<void> signup({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    emit(AuthLoading());
    final result = await _signupUsecase.call(email: email, password: password, fullName: fullName, phone: phone);
    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (user) => emit(AuthSuccess(user)),
    );
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    await _signOutUseCase.call();
    emit(AuthInitial());
  }



}