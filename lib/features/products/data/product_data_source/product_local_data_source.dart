import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/service/supabase_client.dart';
import '../models/product_model.dart';

/// On-device copy of the signed-in user's products, so the app can still show
/// them without a connection. Stored per user id in shared_preferences.
abstract class ProductLocalDataSource {
  Future<List<ProductModel>?> getCachedProducts();
  Future<void> cacheProducts(List<ProductModel> products);

  /// Removes every user's cached products (sign-out, account deletion).
  Future<void> clearAll();
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final SupabaseService _supabaseService;
  ProductLocalDataSourceImpl(this._supabaseService);

  static const _keyPrefix = 'cached_products_';

  /// Null when nobody is signed in. The Supabase session is restored from
  /// device storage, so this works offline too.
  String? get _key {
    final userId = _supabaseService.currentUser?.id;
    return userId == null ? null : '$_keyPrefix$userId';
  }

  @override
  Future<List<ProductModel>?> getCachedProducts() async {
    final key = _key;
    if (key == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List)
          .map((row) => ProductModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Written by an older, incompatible version: drop it rather than crash.
      await prefs.remove(key);
      return null;
    }
  }

  @override
  Future<void> cacheProducts(List<ProductModel> products) async {
    final key = _key;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode([for (final p in products) p.toCacheJson()]));
  }

  @override
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where((k) => k.startsWith(_keyPrefix)).toList()) {
      await prefs.remove(key);
    }
  }
}
