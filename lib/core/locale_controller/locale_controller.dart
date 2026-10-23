import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ValueNotifier<Locale> {
  LocaleController() : super(const Locale('en')) {
    loaded = _loadSaved();
  }

  /// Completes once the saved language (if any) is applied.
  late final Future<void> loaded;

  static const _key = 'app_locale_code';

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == null) return;
    value = Locale(saved);
  }

  Future<void> setLocale(Locale locale) async {
    value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }
}
