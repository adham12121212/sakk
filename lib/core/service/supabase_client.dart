import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SupabaseService {
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  });

  Future<void> signOut();

  Future<UserResponse> updatePhone(String phone);
  User? get currentUser;

  Future<void> add(String tableName, Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> get(String tableName,{Map<String, dynamic>? filters});


  Future<void> update(
      String tableName,
      Map<String, dynamic> data, {
        required String matchColumn,
        required dynamic matchValue,
      });

  Future<void> delete(
      String tableName, {
        required String matchColumn,
        required dynamic matchValue,
      });
}
