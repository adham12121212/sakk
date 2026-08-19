import 'package:dartz/dartz.dart';
import 'package:sakk/core/logger/app_logger.dart';
import 'package:sakk/features/auth/domain/entities/user_entity.dart';
import '../../../../core/error/Exceptions.dart';
import '../../../../core/error/Failure.dart';
import '../../../../core/error/network_info.dart';
import '../../../../core/util/pii_masker.dart';
import '../../domain/auth_repo/auth_repo.dart';
import '../auth_data_source/auth_data_source.dart';

class AuthRepoImpl implements AuthRepository {
  final AuthDataSource _authDataSource;
  final NetworkInfo _networkInfo;
  final AppLogger _logger;
  AuthRepoImpl(this._authDataSource, this._networkInfo, this._logger);

  @override
  Future<Either<Failure, UserEntity>> signIn({required String email, required String password}) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final response = await _authDataSource.signIn(email: email, password: password);
      return Right(response);
    } on ServerException catch (e, st) {
      _logger.error(
        'Server error during signIn',
        error: e,
        stackTrace: st,
        data: {'email': PiiMasker.maskEmail(email)},
      );
      return Left(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error(
        'Unexpected error during signIn',
        error: e,
        stackTrace: st,
        data: {'email': PiiMasker.maskEmail(email)},
      );
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final response = await _authDataSource.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      return Right(response);
    } on ServerException catch (e, st) {
      _logger.error('Server error during signUp', error: e, stackTrace: st,
          data: {'email': PiiMasker.maskEmail(email)});
      return Left(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('Unexpected error during signUp', error: e, stackTrace: st,
          data: {'email': PiiMasker.maskEmail(email)});
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  UserEntity? getUser() {
    try{
      final user = _authDataSource.getUser();
      return user;
    }catch(e,st){
      _logger.error('Unexpected error during getUser', error: e, stackTrace: st);
      return null;
    }
  }

  @override
  Future<void> signOut() {
    return _authDataSource.signOut();
  }
}