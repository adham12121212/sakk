import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/usecase/send_message_use_case.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this._sendMessageUseCase) : super(const ChatState());

  final SendMessageUseCase _sendMessageUseCase;

  Future<void> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || state.isSending) return;

    final userMessage = ChatMessageEntity(
      id: 'u_${DateTime.now().microsecondsSinceEpoch}',
      content: trimmed,
      role: ChatRole.user,
      createdAt: DateTime.now(),
    );


    final historyForRequest = state.messages;
    emit(state.copyWith(
      messages: [...state.messages, userMessage],
      isSending: true,
      clearError: true,
    ));

    final result = await _sendMessageUseCase(
      content: trimmed,
      history: historyForRequest,
    );

    result.fold(
          (failure) => emit(state.copyWith(isSending: false, error: failure.message)),
          (reply) => emit(state.copyWith(
        messages: [...state.messages, reply],
        isSending: false,
      )),
    );
  }

  void clearChat() => emit(const ChatState());
}