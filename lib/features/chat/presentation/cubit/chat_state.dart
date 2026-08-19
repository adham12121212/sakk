

import 'package:equatable/equatable.dart';
import 'package:sakk/features/chat/domain/entities/chat_message_entity.dart';

class ChatState extends Equatable{
  const ChatState({
    this.messages = const [],
    this.isSending = false,
     this.error,
});
  final List<ChatMessageEntity> messages;
  final bool isSending;
  final String? error;


  ChatState copyWith({
    List<ChatMessageEntity>? messages,
    bool? isSending,
    String? error,
    bool clearError = false,
}){
    return ChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [messages, isSending, error];

}
