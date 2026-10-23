import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sakk/core/service/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/exceptions.dart';

class SupabaseServiceImpl implements SupabaseService {
  final SupabaseClient _client;
  SupabaseServiceImpl(this._client);

  bool _googleSignInInitialized = false;

  /// Google puts the SHA-256 of this into the ID token (iOS always adds a
  /// nonce), and Supabase needs the raw value to match it. GoogleSignIn can
  /// only be initialized once, so one nonce serves the whole app session.
  late final String _googleRawNonce = _client.auth.generateRawNonce();

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: dotenv.env['GOOGLE_IOS_CLIENT_ID'],
      serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
      nonce: sha256.convert(utf8.encode(_googleRawNonce)).toString(),
    );
    _googleSignInInitialized = true;
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
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
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      // The local session is cleared before Supabase revokes it on the
      // server, so a failed revoke (e.g. offline) still leaves us signed out.
    }
    try {
      await _ensureGoogleSignInInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Not signed in with Google, or nothing to clear.
    }
  }

  @override
  Future<void> resetPasswordForEmail(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> verifyRecoveryOtp({
    required String email,
    required String token,
  }) async {
    await _client.auth.verifyOTP(
      type: OtpType.recovery,
      email: email,
      token: token,
    );
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
    await signOut();
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
  Future<FunctionResponse> invokeFunction(
    String functionName, {
    Map<String, dynamic>? body,
  }) {
    return _client.functions.invoke(functionName, body: body);
  }

  @override
  Future<AuthResponse> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();
    final GoogleSignInAccount googleUser;
    try {
      googleUser = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      // Google refuses the app itself (e.g. its signing key isn't registered
      // in the Sign-in project): sign in through the browser instead, which
      // doesn't depend on the app's signing key. Android only; iOS uses its
      // own client ID, which the key can't break.
      if (Platform.isAndroid && isGoogleSetupProblem(e)) {
        return _signInWithGoogleInBrowser();
      }
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw GoogleSignInCancelledException(e.description);
      }
      throw ServerException(
        'Google sign-in failed: ${e.description ?? e.code}',
      );
    }

    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw ServerException('Google sign-in did not return an ID token');
    }
    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      nonce: _googleRawNonce,
    );
  }

  /// Where the browser sign-in returns to the app. Also an intent filter in
  /// AndroidManifest.xml and a redirect URL allowed in Supabase Auth.
  static const googleRedirectUrl = 'com.sakk.app://login-callback';

  /// After the user comes back from the browser, how long to wait for the
  /// sign-in to finish before treating it as cancelled.
  static const _browserReturnGrace = Duration(seconds: 10);

  /// True when native sign-in failed because of how the app is set up with
  /// Google, not because the user cancelled. Google reports an unregistered
  /// signing key as a cancel ("[16] Account reauth failed"), so a cancel
  /// only counts when its description says so.
  @visibleForTesting
  static bool isGoogleSetupProblem(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return true;
      case GoogleSignInExceptionCode.canceled:
        final text = (e.description ?? '').toLowerCase();
        return text.contains('reauth failed') || text.startsWith('[10]');
      default:
        return false;
    }
  }

  /// Google sign-in in the browser (Supabase's OAuth flow). Completes when
  /// Supabase has the session from the redirect, or throws
  /// [GoogleSignInCancelledException] if the user comes back without one.
  Future<AuthResponse> _signInWithGoogleInBrowser() async {
    final signedIn = _client.auth.onAuthStateChange.firstWhere(
      (s) => s.event == AuthChangeEvent.signedIn && s.session != null,
    );
    final returned = Completer<void>();
    final lifecycle = AppLifecycleListener(
      onResume: () {
        if (!returned.isCompleted) returned.complete();
      },
    );
    try {
      final opened = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: googleRedirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      if (!opened) {
        throw ServerException('Google sign-in failed: no browser to open');
      }
      final state = await Future.any<AuthState?>([
        signedIn,
        returned.future
            .then((_) => Future<void>.delayed(_browserReturnGrace))
            .then((_) => null),
      ]).timeout(const Duration(minutes: 5), onTimeout: () => null);
      final session = state?.session;
      if (session == null) {
        throw GoogleSignInCancelledException('Browser sign-in not completed');
      }
      return AuthResponse(session: session, user: session.user);
    } finally {
      lifecycle.dispose();
    }
  }
}
