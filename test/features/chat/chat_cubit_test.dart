import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/error/failure.dart';
import 'package:sakk/features/chat/domain/entities/chat_message_entity.dart';
import 'package:sakk/features/chat/domain/usecase/send_message_use_case.dart';
import 'package:sakk/features/chat/presentation/cubit/chat_cubit.dart';

/// Each call waits for the test to complete [next].
class _SendMessage implements SendMessageUseCase {
  Completer<Either<Failure, ChatMessageEntity>> next = Completer();
  List<ChatMessageEntity>? lastHistory;

  @override
  Future<Either<Failure, ChatMessageEntity>> call({
    required String content,
    required List<ChatMessageEntity> history,
  }) {
    lastHistory = history;
    return next.future;
  }
}

ChatMessageEntity reply(String text) =>
    ChatMessageEntity(id: 'a$text', content: text, role: ChatRole.assistant, createdAt: DateTime(2026));

void main() {
  test('a failed message can be retried and is sent again without itself in history', () async {
    final send = _SendMessage();
    final cubit = ChatCubit(send, const Stream.empty());

    final first = cubit.sendMessage('hello');
    send.next.complete(const Left(ServerFailure('x')));
    await first;
    expect(cubit.state.failedMessageId, cubit.state.messages.single.id);

    send.next = Completer();
    final retry = cubit.retryFailedMessage();
    expect(cubit.state.failedMessageId, isNull);
    expect(send.lastHistory, isEmpty);
    send.next.complete(Right(reply('hi')));
    await retry;
    expect(cubit.state.messages.map((m) => m.content), ['hello', 'hi']);
  });

  test('signing out clears the chat and drops a reply still on its way', () async {
    final send = _SendMessage();
    final users = StreamController<String?>();
    final cubit = ChatCubit(send, users.stream);
    users.add('u1');
    await Future<void>.delayed(Duration.zero);

    final pending = cubit.sendMessage('hello');
    users.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.messages, isEmpty);

    send.next.complete(Right(reply('late')));
    await pending;
    expect(cubit.state.messages, isEmpty);
    expect(cubit.state.isSending, isFalse);
  });

  test('blank messages are ignored', () async {
    final cubit = ChatCubit(_SendMessage(), const Stream.empty());
    await cubit.sendMessage('   ');
    expect(cubit.state.messages, isEmpty);
  });
}
