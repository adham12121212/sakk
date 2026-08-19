
import 'package:sakk/features/chat/domain/entities/chat_message_entity.dart';

class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.id,
    required super.content,
    required super.role,
    required super.createdAt,
  });

  factory ChatMessageModel.assistantReply(String content) {
    return ChatMessageModel(
      id: 'a_${DateTime.now().microsecondsSinceEpoch}',
      content: content,
      role: ChatRole.assistant,
      createdAt: DateTime.now(),
    );
  }
}