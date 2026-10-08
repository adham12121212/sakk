
 import 'package:dartz/dartz.dart';

import '../../../../core/error/Failure.dart';
import '../auth_repo/auth_repo.dart';
import '../entities/user_entity.dart';

abstract class SignupUsecase {
  Future<Either<Failure, UserEntity>> call({
   required String email, required String password, required String fullName,});
 }

 class SignupUsecaseImpl implements SignupUsecase{
  final AuthRepository _authRepository;
  SignupUsecaseImpl(this._authRepository);
  @override
  Future<Either<Failure, UserEntity>> call({
   required String email,
   required String password,
   required String fullName,
  }) {
   return _authRepository.signUp(email: email, password: password, fullName: fullName,);
  }

 }
