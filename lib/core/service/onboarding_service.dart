import 'package:shared_preferences/shared_preferences.dart';

abstract class OnboardingService {
  Future<bool> hasSeenOnboarding();
  Future<void> markOnboardingSeen();
}

class OnboardingServiceImpl implements OnboardingService {
  static const _key = 'has_seen_onboarding';

  @override
  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  @override
  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}