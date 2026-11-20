import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/exceptions.dart';
import '../domain/entities/pro_status.dart';

abstract class ProStatusDataSource {
  /// The signed-in user's plan, today's AI use and item counts.
  Future<ProStatus> getStatus();

  /// Asks the server to copy the user's subscription from the store
  /// (RevenueCat) now, instead of waiting for the webhook. Returns whether
  /// the server has Pro afterwards.
  Future<bool> syncFromStore();
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

  @override
  Future<bool> syncFromStore() async {
    try {
      final response = await _client.functions.invoke('sync-pro');
      final data = response.data;
      return data is Map && data['pro'] == true;
    } catch (e) {
      throw ServerException('Failed to sync the Pro plan: $e');
    }
  }
}
