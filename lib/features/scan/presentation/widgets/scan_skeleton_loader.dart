import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A self-contained shimmer skeleton that mirrors the shape of
/// [ReviewProductView]'s form, so the loading state reads as "this screen
/// is materializing" rather than a generic blocking spinner.
class ScanSkeletonLoader extends StatefulWidget {
  const ScanSkeletonLoader({super.key});

  @override
  State<ScanSkeletonLoader> createState() => _ScanSkeletonLoaderState();
}

class _ScanSkeletonLoaderState extends State<ScanSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerRow(),
                  SizedBox(height: 24.h),
                  _block(height: 48.h, radius: 16.r),
                  SizedBox(height: 20.h),
                  _block(height: 180.h, radius: 20.r),
                  SizedBox(height: 28.h),
                  ..._field(width: 120.w),
                  ..._field(width: 90.w),
                  ..._field(width: 140.w),
                  ..._field(width: 130.w),
                  ..._field(width: 80.w),
                  ..._field(width: 100.w, fieldHeight: 90.h),
                  SizedBox(height: 12.h),
                  _block(height: 52.h, radius: 28.r),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _headerRow() {
    return Row(
      children: [
        _shimmerBox(width: 40.w, height: 40.w, radius: 12.r),
        SizedBox(width: 16.w),
        _shimmerBox(width: 140.w, height: 20.h, radius: 8.r),
      ],
    );
  }

  List<Widget> _field({required double width, double fieldHeight = 52}) {
    return [
      _shimmerBox(width: width, height: 14.h, radius: 6.r),
      SizedBox(height: 8.h),
      _block(height: fieldHeight, radius: 28.r),
      SizedBox(height: 20.h),
    ];
  }

  Widget _block({required double height, required double radius}) {
    return SizedBox(
      width: double.infinity,
      child: _shimmerBox(
        width: double.infinity,
        height: height,
        radius: radius,
      ),
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    required double radius,
  }) {
    // Sweep a soft highlight left-to-right across a base-colored box.
    final t = _controller.value;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) {
          return LinearGradient(
            begin: Alignment(-1.5 + 3 * t, 0),
            end: Alignment(-0.5 + 3 * t, 0),
            colors: const [
              Color(0xFFE9ECF1),
              Color(0xFFF6F7F9),
              Color(0xFFE9ECF1),
            ],
            stops: const [0.35, 0.5, 0.65],
          ).createShader(bounds);
        },
        child: Container(
          width: width,
          height: height,
          color: const Color(0xFFE9ECF1),
        ),
      ),
    );
  }
}