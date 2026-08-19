import 'package:dartz/dartz.dart';

import 'package:sakk/core/error/Failure.dart';

import 'package:sakk/features/chat/domain/entities/chat_message_entity.dart';

import '../../../../core/error/Exceptions.dart';
import '../../../../core/error/network_info.dart';
import '../../../../core/logger/app_logger.dart';
import '../../domain/chat_repo/chat_repo.dart';
import '../chat_data_source/chat_data_source.dart';

class ChatRepoImpl implements ChatRepo {
  final ChatDataSource _dataSource;
  final NetworkInfo _networkInfo;
  final AppLogger _logger;
  ChatRepoImpl(this._dataSource, this._networkInfo, this._logger);




  @override
  Future<Either<Failure, ChatMessageEntity>> sendMessage({
    required String content,
    required List<ChatMessageEntity> history,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure("No internet connection"));
    }
    try {
      final result = await _dataSource.sendMessage(
        content: content,
        history: history,
      );
      return Right(result);
    } on ServerException catch (e, st) {
      _logger.error('ServerException: $e', error: e, stackTrace: st);
      return Left(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('Exception: $e', error: e, stackTrace: st);
      return Left(ServerFailure(e.toString()));
    }
  }
}
