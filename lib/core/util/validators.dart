import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class AppValidators {
  AppValidators._();

  static String? email(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;

    if (value == null || value.trim().isEmpty) {
      return l10n.emailRequired;
    }

    final emailRegex = RegExp(
      r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
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