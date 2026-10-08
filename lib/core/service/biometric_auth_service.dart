import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';


abstract class BiometricAuthService {

  Future<bool> get isAvailable;

  Future<bool> get isEnabled;

  Future<void> setEnabled(bool enabled);

  Future<bool> authenticate({required String reason});
}

class BiometricAuthServiceImpl implements BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  static const _prefsKey = 'biometric_login_enabled';

  @override
  Future<bool> get isAvailable async {
    try {
      final deviceSupported = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      return deviceSupported && canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
  }

  @override
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {

      return false;
    }
  }
}
