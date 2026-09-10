import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/route/app_router.dart';
import '../../../../core/service/onboarding_service.dart';
import '../../../../l10n/app_localizations.dart';

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _controller = PageController();
  int _page = 0;

  List<_OnboardingPageData> _pages(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _OnboardingPageData(
        icon: Icons.document_scanner_outlined,
        title: l10n.onboardingScanTitle,
        description: l10n.onboardingScanDescription,
      ),
      _OnboardingPageData(
        icon: Icons.shield_outlined,
        title: l10n.onboardingTrackTitle,
        description: l10n.onboardingTrackDescription,
      ),
      _OnboardingPageData(
        icon: Icons.notifications_active_outlined,
        title: l10n.onboardingNotifyTitle,
        description: l10n.onboardingNotifyDescription,
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await getIt<OnboardingService>().markOnboardingSeen();
    if (mounted) context.go(AppRoutes.signin);
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = _pages(context);
    final isLast = _page == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    l10n.skip,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final page = pages[i];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140.w,
                          height: 140.w,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page.icon, size: 64.sp, color: AppColors.primary),
                        ),
                        SizedBox(height: 40.h),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600, height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                    (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  width: i == _page ? 22.w : 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: i == _page ? AppColors.primary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: SizedBox(
                width: double.infinity,
                height: 54.h,
                child: FilledButton(
                  onPressed: isLast ? _finish : _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  ),
                  child: Text(
                    isLast ? l10n.getStarted : l10n.next,
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}