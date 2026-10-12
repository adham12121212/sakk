import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/service/supabase_client.dart';
import '../models/catalog_service_model.dart';
import '../models/user_subscription_model.dart';

/// On-device copy of the signed-in user's subscriptions (per user id) and of
/// the catalog (shared), so both still show without a connection.
abstract class SubscriptionLocalDataSource {
  Future<List<UserSubscriptionModel>?> getCachedSubscriptions();
  Future<void> cacheSubscriptions(List<UserSubscriptionModel> subscriptions);

  Future<List<CatalogServiceModel>?> getCachedCatalog();
  Future<void> cacheCatalog(List<CatalogServiceModel> catalog);

  /// Removes every user's cached subscriptions and the catalog (sign-out,
  /// account deletion).
  Future<void> clearAll();
}

class SubscriptionLocalDataSourceImpl implements SubscriptionLocalDataSource {
  final SupabaseService _supabaseService;
  SubscriptionLocalDataSourceImpl(this._supabaseService);

  static const _keyPrefix = 'cached_subscriptions_';
  static const _catalogKey = 'cached_subscription_catalog';

  /// Null when nobody is signed in. The Supabase session is restored from
  /// device storage, so this works offline too.
  String? get _key {
    final userId = _supabaseService.currentUser?.id;
    return userId == null ? null : '$_keyPrefix$userId';
  }

  @override
  Future<List<UserSubscriptionModel>?> getCachedSubscriptions() async {
    final key = _key;
    if (key == null) return null;
    return _read(key, UserSubscriptionModel.fromJson);
  }

  @override
  Future<void> cacheSubscriptions(
    List<UserSubscriptionModel> subscriptions,
  ) async {
    final key = _key;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode([for (final s in subscriptions) s.toCacheJson()]),
    );
  }

  @override
  Future<List<CatalogServiceModel>?> getCachedCatalog() =>
      _read(_catalogKey, CatalogServiceModel.fromJson);

  @override
  Future<void> cacheCatalog(List<CatalogServiceModel> catalog) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _catalogKey,
      jsonEncode([for (final c in catalog) c.toCacheJson()]),
    );
  }

  Future<List<T>?> _read<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List)
          .map((row) => fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Written by an older, incompatible version: drop it rather than crash.
      await prefs.remove(key);
      return null;
    }
  }

  @override
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key
        in prefs
            .getKeys()
            .where((k) => k.startsWith(_keyPrefix) || k == _catalogKey)
            .toList()) {
      await prefs.remove(key);
    }
  }
}
