import 'package:dartz/dartz.dart';

import '../../../../core/error/Failure.dart';
import '../entities/chat_message_entity.dart';

abstract class ChatRepo {
   Future<Either<Failure, ChatMessageEntity>> sendMessage({
    required String content,
    required List<ChatMessageEntity> history,
  });
}