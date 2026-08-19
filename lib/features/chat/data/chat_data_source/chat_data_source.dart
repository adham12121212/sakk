import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sakk/features/chat/domain/entities/chat_message_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/Exceptions.dart';
import '../models/chat_message_model.dart';

abstract class ChatDataSource {
  Future<ChatMessageModel> sendMessage({
    required String content,
    required List<ChatMessageEntity> history,
  });
}

class ChatDataSourceImpl implements ChatDataSource {
  final SupabaseClient _client;
  ChatDataSourceImpl(this._client);

  static const _functionName = 'ai-chat';

  @override
  Future<ChatMessageModel> sendMessage({
    required String content,
    required List<ChatMessageEntity> history,
  }) async {

    print('>>> DEBUG dotenv SUPABASE_URL = [${dotenv.env['SUPABASE_URL']}]');
    print('>>> DEBUG functions.invoke target = [$_functionName]');

    try {
      final response = await _client.functions.invoke(
        _functionName,
        body: {
          'message': content,
          'history': history
              .map((m) => {'role': m.role.name, 'content': m.content})
              .toList(),
        },
      );

      if (response.status != 200) {
        throw ServerException('AI chat failed (status ${response.status})');
      }

      final data = response.data as Map<String, dynamic>;
      final reply = data['reply'] as String?;
      if (reply == null || reply.trim().isEmpty) {
        throw ServerException('AI returned an empty response');
      }

      return ChatMessageModel.assistantReply(reply);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('AI chat failed: $e');
    }
  }
}