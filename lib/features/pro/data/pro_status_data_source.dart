import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/exceptions.dart';
import '../domain/entities/pro_status.dart';

abstract class ProStatusDataSource {
  /// The signed-in user's plan, today's AI use and item counts.
  Future<ProStatus> getStatus();
}

class ProStatusDataSourceImpl implements ProStatusDataSource {
  ProStatusDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<ProStatus> getStatus() async {
    try {
      final data = await _client.rpc('get_usage_status');
      return ProStatus.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (e) {
      throw ServerException('Failed to load plan status: $e');
    }
  }
}
