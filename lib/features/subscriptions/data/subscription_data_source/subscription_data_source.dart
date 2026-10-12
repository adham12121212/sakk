import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/catalog_service_model.dart';
import '../models/user_subscription_model.dart';

abstract class SubscriptionDataSource {
  Future<List<CatalogServiceModel>> getCatalog();

  Future<List<UserSubscriptionModel>> getSubscriptions();

  Future<UserSubscriptionModel> addSubscription(
    Map<String, dynamic> insertJson,
  );

  Future<UserSubscriptionModel> updateSubscription(
    String id,
    Map<String, dynamic> updateJson,
  );

  Future<void> deleteSubscription(String id);
}

class SubscriptionDataSourceImpl implements SubscriptionDataSource {
  final SupabaseClient _client;
  SubscriptionDataSourceImpl(this._client);

  static const _catalogTable = 'subscription_catalog';
  static const _table = 'user_subscriptions';

  @override
  Future<List<CatalogServiceModel>> getCatalog() async {
    try {
      // RLS lets users read inactive services too (so their subscriptions
      // keep a name and logo); only active ones are offered to pick.
      final rows = await _client
          .from(_catalogTable)
          .select()
          .eq('is_active', true)
          .order('name');
      return (rows as List)
          .map(
            (row) => CatalogServiceModel.fromJson(row as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw ServerException('Failed to load the subscription catalog: $e');
    }
  }

  @override
  Future<List<UserSubscriptionModel>> getSubscriptions() async {
    try {
      final rows = await _client
          .from(_table)
          .select(UserSubscriptionModel.selectColumns)
          .order('next_renewal_date');
      return (rows as List)
          .map(
            (row) =>
                UserSubscriptionModel.fromJson(row as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw ServerException('Failed to load subscriptions: $e');
    }
  }

  @override
  Future<UserSubscriptionModel> addSubscription(
    Map<String, dynamic> insertJson,
  ) async {
    try {
      final row = await _client
          .from(_table)
          .insert(insertJson)
          .select(UserSubscriptionModel.selectColumns)
          .single();
      return UserSubscriptionModel.fromJson(row);
    } catch (e) {
      throw ServerException('Failed to save subscription: $e');
    }
  }

  @override
  Future<UserSubscriptionModel> updateSubscription(
    String id,
    Map<String, dynamic> updateJson,
  ) async {
    try {
      final row = await _client
          .from(_table)
          .update(updateJson)
          .eq('id', id)
          .select(UserSubscriptionModel.selectColumns)
          .single();
      return UserSubscriptionModel.fromJson(row);
    } catch (e) {
      throw ServerException('Failed to update subscription: $e');
    }
  }

  @override
  Future<void> deleteSubscription(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (e) {
      throw ServerException('Failed to delete subscription: $e');
    }
  }
}
