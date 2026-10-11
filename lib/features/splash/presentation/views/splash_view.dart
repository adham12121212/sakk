import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/route/app_router.dart';
import '../../../../core/service/biometric_auth_service.dart';
import '../../../../core/service/onboarding_service.dart';
import '../../../../core/widgets/sakk_logo.dart';


class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {

    final minDelay = Future.delayed(const Duration(milliseconds: 1400));

    final session = Supabase.instance.client.auth.currentSession;
    final hasSeenOnboarding = await getIt<OnboardingService>().hasSeenOnboarding();

    // Only relevant when a session already exists — no point checking the
    // biometric preference at all if the user isn't signed in.
    final biometricLockRequired = session != null &&
        await getIt<BiometricAuthService>().isEnabled;

    await minDelay;
    if (!mounted) return;

    if (session != null) {
      context.go(biometricLockRequired ? AppRoutes.biometricLock : AppRoutes.home);
    } else if (!hasSeenOnboarding) {
      context.go(AppRoutes.onboarding);
    } else {
      context.go(AppRoutes.signin);
    }
  }

  /// Logo canvas size in logical pixels. Must equal the native splash icon
  /// (288dp/pt, see `flutter_native_splash` in pubspec.yaml) so the hand-off
  /// from the native launch screen is seamless — deliberately not `.w`-scaled.
  static const double _logoSize = 288;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: Stack(
        children: [
          const Center(child: SakkLogo(size: _logoSize)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 48.h,
            child: SafeArea(
              top: false,
              // Fades in so nothing pops over the native splash hand-off.
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeIn,
                builder: (context, opacity, child) =>
                    Opacity(opacity: opacity, child: child),
                child: const Center(child: _LoadingDots()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = (_controller.value - (index * 0.2)) % 1.0;
            final scale = _pulse(t);
            final opacity = 0.4 + (0.6 * _pulse(t));

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w),
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  double _pulse(double t) {
    if (t < 0) t += 1.0;
    if (t > 0.6) return 0.6;
    final normalized = t / 0.6;
    return 0.6 + 0.4 * (1 - (2 * normalized - 1).abs());
  }
}
