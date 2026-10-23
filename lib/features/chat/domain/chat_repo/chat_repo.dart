import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/chat_message_entity.dart';

abstract class ChatRepo {
  Future<Either<Failure, ChatMessageEntity>> sendMessage({
    required String content,
    required List<ChatMessageEntity> history,
  });

  /// The conversation saved on the server, oldest first.
  Future<Either<Failure, List<ChatMessageEntity>>> getHistory();
}
