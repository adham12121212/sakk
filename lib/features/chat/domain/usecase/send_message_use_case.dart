import 'package:dartz/dartz.dart';
import '../../../../core/error/Failure.dart';
import '../chat_repo/chat_repo.dart';
import '../entities/chat_message_entity.dart';

abstract class SendMessageUseCase {
  Future<Either<Failure, ChatMessageEntity>> call({
    required String content,
    required List<ChatMessageEntity> history,
  });
}

class SendMessageUseCaseImpl implements SendMessageUseCase {
  final ChatRepo _repository;
  SendMessageUseCaseImpl(this._repository);

  @override
  Future<Either<Failure, ChatMessageEntity>> call({
    required String content,
    required List<ChatMessageEntity> history,
  }) {
    return _repository.sendMessage(content: content, history: history);
  }
}