import 'package:shared_preferences/shared_preferences.dart';

/// Verifying a password-reset code signs the user in. This remembers that a
/// reset was started but not finished, so the app can sign them back out
/// instead of letting the recovery session through (e.g. after the app was
/// killed on the new-password screen).
abstract class PasswordRecoveryService {
  Future<bool> isPending();
  Future<void> markPending();
  Future<void> clear();
}

class PasswordRecoveryServiceImpl implements PasswordRecoveryService {
  static const _key = 'password_recovery_pending';

  @override
  Future<bool> isPending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  @override
  Future<void> markPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
