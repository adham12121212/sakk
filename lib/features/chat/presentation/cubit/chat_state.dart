

import 'package:equatable/equatable.dart';
import 'package:sakk/features/chat/domain/entities/chat_message_entity.dart';

class ChatState extends Equatable{
  const ChatState({
    this.messages = const [],
    this.isSending = false,
    this.error,
    this.failedMessageId,
  });
  final List<ChatMessageEntity> messages;
  final bool isSending;
  final String? error;

  /// Id of the user message whose send failed; the UI offers a retry on it.
  final String? failedMessageId;


  ChatState copyWith({
    List<ChatMessageEntity>? messages,
    bool? isSending,
    String? error,
    bool clearError = false,
    String? failedMessageId,
    bool clearFailedMessage = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : error ?? this.error,
      failedMessageId: clearFailedMessage ? null : failedMessageId ?? this.failedMessageId,
    );
  }

  @override
  List<Object?> get props => [messages, isSending, error, failedMessageId];

}
