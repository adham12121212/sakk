import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/features/auth/data/models/user_model.dart';
import 'package:sakk/features/auth/presentation/widgets/welcome_message.dart';
import 'package:sakk/l10n/app_localizations_ar.dart';
import 'package:sakk/l10n/app_localizations_en.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A Supabase user as returned after a sign-in.
User supabaseUser({required String createdAt, String? lastSignInAt}) =>
    User.fromJson({
      'id': 'u1',
      'aud': 'authenticated',
      'email': 'adham@example.com',
      'app_metadata': {'provider': 'google'},
      'user_metadata': {'name': 'Adham'},
      'created_at': createdAt,
      'last_sign_in_at': ?lastSignInAt,
    })!;

void main() {
  group('UserModel.isNewAccount', () {
    test('a first Google sign-in, which creates the account, is new', () {
      final user = UserModel.fromSupabaseUser(
        supabaseUser(
          createdAt: '2026-10-13T09:00:00.000000Z',
          lastSignInAt: '2026-10-13T09:00:01.250000Z',
        ),
      );
      expect(user.isNewAccount, isTrue);
    });

    test('a returning user is not new', () {
      final user = UserModel.fromSupabaseUser(
        supabaseUser(
          createdAt: '2026-08-01T09:00:00Z',
          lastSignInAt: '2026-10-13T09:00:00Z',
        ),
      );
      expect(user.isNewAccount, isFalse);
    });

    test(
      'a few minutes later is no longer new (e.g. signed in again right away)',
      () {
        final user = UserModel.fromSupabaseUser(
          supabaseUser(
            createdAt: '2026-10-13T09:00:00Z',
            lastSignInAt: '2026-10-13T09:05:00Z',
          ),
        );
        expect(user.isNewAccount, isFalse);
      },
    );

    test('unknown sign-in time: not new, so the usual greeting', () {
      final user = UserModel.fromSupabaseUser(
        supabaseUser(createdAt: '2026-10-13T09:00:00Z'),
      );
      expect(user.isNewAccount, isFalse);
    });
  });

  test('new accounts are welcomed to Sakk, returning users welcomed back', () {
    final en = AppLocalizationsEn();
    const base = UserModel(
      id: 'u1',
      email: 'a@b.c',
      name: 'A',
      avatarUrl: null,
    );
    const fresh = UserModel(
      id: 'u1',
      email: 'a@b.c',
      name: 'A',
      avatarUrl: null,
      isNewAccount: true,
    );
    expect(welcomeMessage(en, fresh), 'Welcome to Sakk!');
    expect(welcomeMessage(en, base), 'Welcome back!');
    expect(welcomeMessage(AppLocalizationsAr(), fresh), 'أهلاً بكم في صك!');
  });
}
