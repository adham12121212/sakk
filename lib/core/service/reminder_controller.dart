import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How many days before a warranty ends the user wants the "expiring soon"
/// reminder. Saved per device, like the theme.
class ReminderController extends ValueNotifier<int> {
  ReminderController() : super(defaultDays) {
    ready = _loadSaved();
  }

  /// The choices offered in Profile, longest first. 90 days matches the
  /// "Expiring" status, which was the only reminder before this setting.
  static const options = [90, 30, 7, 1];
  static const defaultDays = 90;

  static const _key = 'warranty_reminder_days';

  /// Completes once the saved choice is loaded; await it before scheduling.
  late final Future<void> ready;

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_key);
    if (saved != null && options.contains(saved)) value = saved;
  }

  Future<void> setDays(int days) async {
    value = days;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, days);
  }
}
