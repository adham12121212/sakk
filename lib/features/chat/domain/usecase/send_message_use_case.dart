import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
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

abstract class GetChatHistoryUseCase {
  Future<Either<Failure, List<ChatMessageEntity>>> call();
}

class GetChatHistoryUseCaseImpl implements GetChatHistoryUseCase {
  final ChatRepo _repository;
  GetChatHistoryUseCaseImpl(this._repository);

  @override
  Future<Either<Failure, List<ChatMessageEntity>>> call() => _repository.getHistory();
}