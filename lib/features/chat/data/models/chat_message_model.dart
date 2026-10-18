
import 'package:sakk/features/chat/domain/entities/chat_message_entity.dart';

class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.id,
    required super.content,
    required super.role,
    required super.createdAt,
  });

  /// A row of chat_messages.
  factory ChatMessageModel.fromRow(Map<String, dynamic> row) {
    return ChatMessageModel(
      id: row['id'] as String,
      content: row['content'] as String,
      role: row['role'] == 'assistant' ? ChatRole.assistant : ChatRole.user,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }

  factory ChatMessageModel.assistantReply(String content) {
    return ChatMessageModel(
      id: 'a_${DateTime.now().microsecondsSinceEpoch}',
      content: content,
      role: ChatRole.assistant,
      createdAt: DateTime.now(),
    );
  }
}