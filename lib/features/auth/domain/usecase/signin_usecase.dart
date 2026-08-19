
import 'package:dartz/dartz.dart';

import '../../../../core/error/Failure.dart';
import '../auth_repo/auth_repo.dart';
import '../entities/user_entity.dart';

abstract class SignInUseCase {
  Future<Either<Failure, UserEntity>> call({required String email, required String password});
}

class SignInUseCaseImpl  implements SignInUseCase{
  final AuthRepository _authRepository;
  SignInUseCaseImpl(this._authRepository);
  @override
  Future<Either<Failure, UserEntity>> call({required String email, required String password}) async{
      return await _authRepository.signIn(email: email, password: password);
  }

}