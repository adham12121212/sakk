import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/route/app_router.dart';
import '../widgets/blob.dart';


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

    await minDelay;
    if (!mounted) return;

    if (session != null) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.signin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.85),
              AppColors.primary,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60.w,
              left: -40.w,
              child: Blob(size: 220.w),
            ),
            Positioned(
              bottom: -80.w,
              right: -60.w,
              child: Blob(size: 260.w),
            ),

            Positioned.fill(
              child: SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 3),

                    Container(
                      width: 110.w,
                      height: 110.w,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(28.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'ص',
                          style: TextStyle(
                            fontSize: 52.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    Text(
                      'Sakk',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 44.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),

                    SizedBox(height: 8.h),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Text(
                        'Sakk — AI Warranty Manager',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.white.withOpacity(0.85),
                        ),
                      ),
                    ),

                    const Spacer(flex: 4),

                    const _LoadingDots(),

                    SizedBox(height: 48.h),
                  ],
                ),
              ),
            ),
          ],
        ),
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

  /// Smooth 0 -> 1 -> 0 pulse over the course of t in [0, 1].
  double _pulse(double t) {
    if (t < 0) t += 1.0;
    // Only pulse during the first 60% of the cycle, rest is idle low state.
    if (t > 0.6) return 0.6;
    final normalized = t / 0.6;
    return 0.6 + 0.4 * (1 - (2 * normalized - 1).abs());
  }
}