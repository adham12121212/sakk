import 'package:equatable/equatable.dart';

enum ChatRole { user, assistant }

class ChatMessageEntity extends Equatable {
  const ChatMessageEntity({
    required this.id,
    required this.content,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String content;
  final ChatRole role;
  final DateTime createdAt;

  bool get isUser => role == ChatRole.user;

  @override
  List<Object?> get props => [id, content, role, createdAt];
}