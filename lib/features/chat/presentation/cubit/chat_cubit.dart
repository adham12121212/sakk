import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/usecase/send_message_use_case.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  /// [userIdChanges] emits the signed-in user's id (null when signed out).
  /// The cubit is an app-wide singleton, so the conversation is wiped whenever
  /// that id changes; otherwise the next account on the device would see it.
  ChatCubit(this._sendMessageUseCase, Stream<String?> userIdChanges) : super(const ChatState()) {
    _userSubscription = userIdChanges.distinct().listen((_) => clearChat());
  }

  final SendMessageUseCase _sendMessageUseCase;
  late final StreamSubscription<String?> _userSubscription;

  /// Bumped by [clearChat] so a reply that arrives after the chat was cleared
  /// (e.g. the user logged out mid-request) is dropped instead of shown.
  int _conversation = 0;

  Future<void> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || state.isSending) return;

    final userMessage = ChatMessageEntity(
      id: 'u_${DateTime.now().microsecondsSinceEpoch}',
      content: trimmed,
      role: ChatRole.user,
      createdAt: DateTime.now(),
    );

    final conversation = _conversation;
    final historyForRequest = state.messages;
    emit(state.copyWith(
      messages: [...state.messages, userMessage],
      isSending: true,
      clearError: true,
      clearFailedMessage: true,
    ));

    final result = await _sendMessageUseCase(
      content: trimmed,
      history: historyForRequest,
    );
    if (isClosed || conversation != _conversation) return;

    result.fold(
      (failure) => emit(state.copyWith(
        isSending: false,
        error: failure.message,
        failedMessageId: userMessage.id,
      )),
      (reply) => emit(state.copyWith(
        messages: [...state.messages, reply],
        isSending: false,
      )),
    );
  }

  /// Resends the message that failed last: it's taken out of the list and sent
  /// again, so it reappears at the bottom with the reply after it.
  Future<void> retryFailedMessage() async {
    final failedId = state.failedMessageId;
    if (failedId == null || state.isSending) return;
    final failed = state.messages.where((m) => m.id == failedId).firstOrNull;
    if (failed == null) return;

    emit(state.copyWith(
      messages: state.messages.where((m) => m.id != failedId).toList(),
      clearFailedMessage: true,
    ));
    await sendMessage(failed.content);
  }

  void clearChat() {
    _conversation++;
    emit(const ChatState());
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    return super.close();
  }
}
