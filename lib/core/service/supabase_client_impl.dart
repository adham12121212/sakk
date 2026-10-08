import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sakk/core/service/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/Exceptions.dart';

class SupabaseServiceImpl implements SupabaseService {
  final SupabaseClient _client;
  SupabaseServiceImpl(this._client);

  bool _googleSignInInitialized = false;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: dotenv.env['GOOGLE_IOS_CLIENT_ID'],
      serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
    );
    _googleSignInInitialized = true;
  }


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

  @override
  Future<void> resetPasswordForEmail(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> verifyRecoveryOtp({required String email, required String token}) async {
    await _client.auth.verifyOTP(
      type: OtpType.recovery,
      email: email,
      token: token,
    );
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
    
    await _client.auth.signOut();
  }

  @override
  Future<User> updateUserMetadata(Map<String, dynamic> data) async {
    final response = await _client.auth.updateUser(UserAttributes(data: data));
    final user = response.user;
    if (user == null) {
      throw ServerException('Failed to update user metadata');
    }
    return user;
  }

  @override
  Future<FunctionResponse> invokeFunction(String functionName, {Map<String, dynamic>? body}) {
    return _client.functions.invoke(functionName, body: body);
  }

  @override
  Future<AuthResponse> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();
    final GoogleSignInAccount googleUser;
    try {
      googleUser = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw GoogleSignInCancelledException();
      }
      throw ServerException('Google sign-in failed: ${e.description ?? e.code}');
    }

    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw ServerException('Google sign-in did not return an ID token');
    }
    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }

}