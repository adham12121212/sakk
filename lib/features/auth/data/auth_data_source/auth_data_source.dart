import 'dart:io';

import 'package:sakk/core/error/supabase_error_mapper.dart';
import 'package:sakk/features/auth/data/models/user_model.dart';

import '../../../../core/error/Exceptions.dart';
import '../../../../core/service/storage_service.dart';
import '../../../../core/service/supabase_client.dart';

abstract class AuthDataSource {
  Future<UserModel> signIn({required String email, required String password});
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  });
  Future<void> signOut();
  UserModel?  getUser();

  Future<void> sendPasswordResetOtp(String email);
  Future<void> verifyPasswordResetOtp({required String email, required String otp});
  Future<void> updatePassword(String newPassword);
  Future<UserModel> updateAvatar(File imageFile);
}

class AuthDataSourceImpl implements AuthDataSource {
  final SupabaseService _supabaseService;
 final StorageService _storageService;
  AuthDataSourceImpl(this._supabaseService ,this._storageService);

  @override
  Future<UserModel> signIn(
      {required String email, required String password}) async {
    try {
      final response = await _supabaseService.signIn(
          email: email, password: password);
      final user = response.user;
      if (user == null) {
        throw ServerException('Sign in failed: no user returned');
      }
      return UserModel.fromSupabaseUser(user);
    } catch (e, s) {
      return SupabaseErrorMapper.handle(e, s);
    }
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      final response = await _supabaseService.signUp(
        email: email,
        password: password,
        data: {'name': fullName, 'phone': phone},
      );
      var user = response.user;

      if (user == null) {
        throw ServerException('Sign up failed: no user returned');
      }

      if (user.identities != null && user.identities!.isEmpty) {
        throw ServerException('An account with this email already exists');
      }

      if (response.session != null) {
        try {
          final updateResponse = await _supabaseService.updatePhone(phone);
          user = updateResponse.user ?? user;
        } catch (_) {

        }
      }

      return UserModel.fromSupabaseUser(user!);
    } catch (e, s) {
      if (e is ServerException) rethrow;
      return SupabaseErrorMapper.handle(e, s);
    }
  }

  @override
  UserModel? getUser() {
    final user = _supabaseService.currentUser;
    if (user == null) return null;
    return UserModel.fromSupabaseUser(user);
  }

  @override
  Future<void> signOut() async {
    await _supabaseService.signOut();
  }

  @override
  Future<void> sendPasswordResetOtp(String email) async {
    try {
      await _supabaseService.resetPasswordForEmail(email);
    } catch (e, s) {
      SupabaseErrorMapper.handle(e, s);
    }
  }

  @override
  Future<void> verifyPasswordResetOtp({required String email, required String otp}) async {
    try {
      await _supabaseService.verifyRecoveryOtp(email: email, token: otp);
    } catch (e, s) {
      SupabaseErrorMapper.handle(e, s);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabaseService.updatePassword(newPassword);
    } catch (e, s) {
      SupabaseErrorMapper.handle(e, s);
    }
  }

  @override

  Future<UserModel> updateAvatar(File imageFile) async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) {
        throw ServerException('No user found');
      }

      final fileExt = imageFile.path.split('.').last;
      final storagePath = '${user.id}/avatar.$fileExt';

      await _storageService.uploadFile(
        bucket: 'avatars',
        path: storagePath,
        file: imageFile,
        upsert: true,
      );

      final publicUrl = _storageService.getPublicUrl(
        bucket: 'avatars',
        path: storagePath,
      );
      final bustedUrl =
          '$publicUrl?updated=${DateTime.now().millisecondsSinceEpoch}';

      final updatedUser = await _supabaseService.updateUserMetadata(
        {'avatar_url': bustedUrl},
      );

      return UserModel.fromSupabaseUser(updatedUser);
    } catch (e, s) {
      return SupabaseErrorMapper.handle(e, s);
    }
  }
}