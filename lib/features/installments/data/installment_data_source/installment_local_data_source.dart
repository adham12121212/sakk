import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/service/supabase_client.dart';
import '../models/installment_plan_model.dart';

/// On-device copy of the signed-in user's installment plans (per user id),
/// so they still show without a connection.
abstract class InstallmentLocalDataSource {
  Future<List<InstallmentPlanModel>?> getCachedPlans();
  Future<void> cachePlans(List<InstallmentPlanModel> plans);

  /// Removes every user's cached plans (sign-out, account deletion).
  Future<void> clearAll();
}

class InstallmentLocalDataSourceImpl implements InstallmentLocalDataSource {
  final SupabaseService _supabaseService;
  InstallmentLocalDataSourceImpl(this._supabaseService);

  static const _keyPrefix = 'cached_installments_';

  /// Null when nobody is signed in. The Supabase session is restored from
  /// device storage, so this works offline too.
  String? get _key {
    final userId = _supabaseService.currentUser?.id;
    return userId == null ? null : '$_keyPrefix$userId';
  }

  @override
  Future<List<InstallmentPlanModel>?> getCachedPlans() async {
    final key = _key;
    if (key == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List)
          .map(
            (row) => InstallmentPlanModel.fromJson(row as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      // Written by an older, incompatible version: drop it rather than crash.
      await prefs.remove(key);
      return null;
    }
  }

  @override
  Future<void> cachePlans(List<InstallmentPlanModel> plans) async {
    final key = _key;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode([for (final p in plans) p.toCacheJson()]),
    );
  }

  @override
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key
        in prefs.getKeys().where((k) => k.startsWith(_keyPrefix)).toList()) {
      await prefs.remove(key);
    }
  }
}
