 import 'package:dartz/dartz.dart';
import '../../../../core/error/Failure.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {

  Future<Either<Failure, UserEntity>> signIn({required String email, required String password});
  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  });
  Future<void> signOut();
  UserEntity?  getUser();
}

