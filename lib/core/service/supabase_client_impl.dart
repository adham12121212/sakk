import 'package:sakk/core/service/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseServiceImpl implements SupabaseService {
  final SupabaseClient _client;
  SupabaseServiceImpl(this._client);

  @override
  Future<AuthResponse> signIn({required String email, required String password}) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) {
    return _client.auth.signUp(email: email, password: password, data: data);
  }

  @override
  Future<UserResponse> updatePhone(String phone) {
    return _client.auth.updateUser(UserAttributes(phone: phone));
  }

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Future<void> add(String tableName, Map<String, dynamic> data) {
     return _client.from(tableName).insert(data);
  }


  @override
  Future<List<Map<String, dynamic>>> get(
      String tableName, {
        Map<String, dynamic>? filters,
      }) {
    var query = _client.from(tableName).select();
    filters?.forEach((column, value) {
      query = query.eq(column, value);
    });
    return query;
  }

  @override
  Future<void> update(
      String tableName,
      Map<String, dynamic> data, {
        required String matchColumn,
        required dynamic matchValue,
      }) {
    return _client.from(tableName).update(data).eq(matchColumn, matchValue);
  }

  @override
  Future<void> delete(
      String tableName, {
        required String matchColumn,
        required dynamic matchValue,
      }) {
    return _client.from(tableName).delete().eq(matchColumn, matchValue);
  }

  @override
  Future<void> signOut() {
   return _client.auth.signOut();
  }

}