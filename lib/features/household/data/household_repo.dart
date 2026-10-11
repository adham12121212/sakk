import 'package:dartz/dartz.dart';

import '../../../core/error/Exceptions.dart';
import '../../../core/error/Failure.dart';
import '../../../core/error/network_info.dart';
import '../../../core/logger/app_logger.dart';
import '../domain/household.dart';
import 'household_data_source.dart';

class HouseholdRepo {
  HouseholdRepo(this._dataSource, this._networkInfo, this._logger);

  final HouseholdDataSource _dataSource;
  final NetworkInfo _networkInfo;
  final AppLogger _logger;

  Future<Either<Failure, (Household?, List<HouseholdMember>)>> load() => _run('load household', _dataSource.load);

  Future<Either<Failure, void>> create({required String name, required String displayName}) =>
      _run('create household', () => _dataSource.create(name: name, displayName: displayName));

  Future<Either<Failure, void>> join({required String inviteCode, required String displayName}) =>
      _run('join household', () => _dataSource.join(inviteCode: inviteCode, displayName: displayName));

  Future<Either<Failure, void>> leave() => _run('leave household', _dataSource.leave);

  Future<Either<Failure, void>> removeMember(String userId) =>
      _run('remove household member', () => _dataSource.removeMember(userId));

  Future<Either<Failure, void>> regenerateInviteCode() =>
      _run('regenerate invite code', _dataSource.regenerateInviteCode);

  Future<Either<Failure, T>> _run<T>(String action, Future<T> Function() run) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(NetworkFailure.noConnectionMessage));
    }
    try {
      return Right(await run());
    } on ServerException catch (e, st) {
      _logger.error('Failed to $action', error: e, stackTrace: st);
      return Left(ServerFailure(e.message));
    }
  }
}
