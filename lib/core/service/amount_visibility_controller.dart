import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the user has hidden their total spent (the eye button on the
/// Analytics card). `true` means hidden, which is the default until the user
/// taps to show it. Saved per device, like the theme.
class AmountVisibilityController extends ValueNotifier<bool> {
  AmountVisibilityController() : super(true) {
    _loadSaved();
  }

  static const _key = 'hide_total_spent';

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    value = prefs.getBool(_key) ?? true;
  }

  Future<void> toggle() async {
    value = !value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
