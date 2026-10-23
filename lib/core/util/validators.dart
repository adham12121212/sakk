import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class AppValidators {
  AppValidators._();

  // Zero-width and bidi control characters. Keyboards (notably in RTL
  // locales) and copy-paste can slip these into a field invisibly; they
  // aren't whitespace, so trim() leaves them in place.
  static final _invisibleChars = RegExp(
    r'[\u200B-\u200F\u202A-\u202E\u2066-\u2069\uFEFF\u00AD]',
  );

  static final _emailRegex = RegExp(r'^[\w.+-]+@([\w-]+\.)+[A-Za-z]{2,}$');

  /// The email as it should be validated and sent to the backend.
  static String normalizeEmail(String value) =>
      value.replaceAll(_invisibleChars, '').trim();

  static String? email(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;
    final email = normalizeEmail(value ?? '');

    if (email.isEmpty) {
      return l10n.emailRequired;
    }

    if (!_emailRegex.hasMatch(email)) {
      return l10n.invalidEmail;
    }

    return null;
  }

  static String? password(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;

    if (value == null || value.isEmpty) {
      return l10n.passwordRequired;
    }

    if (value.length < 8) {
      return l10n.passwordTooShort;
    }

    return null;
  }

  static String? requiredField(
    BuildContext context,
    String? value, {
    required String fieldName,
  }) {
    if (value == null || value.trim().isEmpty) {
      return fieldName;
    }

    return null;
  }

  static String? phone(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;

    if (value == null || value.trim().isEmpty) {
      return l10n.phoneRequired;
    }

    final regex = RegExp(r'^\+?[0-9]{10,15}$');

    if (!regex.hasMatch(value.trim())) {
      return l10n.invalidPhone;
    }

    return null;
  }

  static String? confirmPassword(
    BuildContext context, {
    required String? value,
    required TextEditingController passwordController,
  }) {
    final l10n = AppLocalizations.of(context)!;

    if (value == null || value.isEmpty) {
      return l10n.confirmPasswordRequired;
    }

    if (value != passwordController.text) {
      return l10n.passwordsDoNotMatch;
    }

    return null;
  }
}
