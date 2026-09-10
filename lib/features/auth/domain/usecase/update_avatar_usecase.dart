import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/Failure.dart';
import '../auth_repo/auth_repo.dart';
import '../entities/user_entity.dart';


abstract  class UpdateAvatarUseCase {
  Future<Either<Failure, UserEntity>> call(File imageFile);
}

class UpdateAvatarUsecaseImpl  implements UpdateAvatarUseCase{

  final AuthRepository _repository;
  UpdateAvatarUsecaseImpl(this._repository);
  @override
  Future<Either<Failure, UserEntity>> call(File imageFile) {
    return _repository.updateAvatar(imageFile);
  }
}