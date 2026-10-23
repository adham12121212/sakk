import 'package:sakk/features/chat/domain/entities/chat_message_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../pro/domain/pro_limit.dart';
import '../models/chat_message_model.dart';

abstract class ChatDataSource {
  /// Sends [content]; the function answers from the stored history and
  /// saves both messages.
  Future<ChatMessageModel> sendMessage({
    required String content,
    required List<ChatMessageEntity> history,
  });

  /// The latest stored messages, oldest first.
  Future<List<ChatMessageModel>> getHistory({int limit});
}

class ChatDataSourceImpl implements ChatDataSource {
  final SupabaseClient _client;
  ChatDataSourceImpl(this._client);

  static const _functionName = 'ai-chat';
  static const _table = 'chat_messages';

  /// The AI provider's rate limit was hit; try again shortly (503).
  static const aiBusy = 'chat_busy';

  @override
  Future<ChatMessageModel> sendMessage({
    required String content,
    required List<ChatMessageEntity> history,
  }) async {
    try {
      final response = await _client.functions.invoke(
        _functionName,
        // The history now comes from chat_messages on the server.
        body: {'message': content},
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
    } on FunctionException catch (e) {
      final limit = ProLimit.codeFor(e);
      if (limit != null) throw ServerException(limit);
      if (e.status == 503) throw ServerException(aiBusy);
      throw ServerException('AI chat failed: $e');
    } catch (e) {
      throw ServerException('AI chat failed: $e');
    } finally {
      // One message from the daily quota (given back if it failed).
      ProLimit.notifyUsageChanged();
    }
  }

  @override
  Future<List<ChatMessageModel>> getHistory({int limit = 50}) async {
    try {
      final rows = await _client
          .from(_table)
          .select('id, role, content, created_at')
          .order('created_at', ascending: false)
          .limit(limit);
      return [
        for (final row in (rows as List).reversed)
          ChatMessageModel.fromRow(row as Map<String, dynamic>),
      ];
    } catch (e) {
      throw ServerException('Failed to load chat history: $e');
    }
  }
}
