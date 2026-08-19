import 'package:flutter/material.dart';

/// A shimmering skeleton shape, used as a loading placeholder while a
/// field's real value hasn't arrived yet.
class ShimmerShape extends StatelessWidget {
  const ShimmerShape({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final begin = Alignment(-1.6 + 3.2 * t, 0);
        final end = Alignment(-0.6 + 3.2 * t, 0);

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            colors: const [
              Color(0xFFE7E9EE),
              Color(0xFFF4F5F7),
              Color(0xFFE7E9EE),
            ],
            stops: const [0.35, 0.5, 0.65],
            begin: begin,
            end: end,
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

/// A shimmering skeleton bar, sized to match the text it's standing in for.
class ShimmerBar extends StatelessWidget {
  const ShimmerBar({super.key, required this.width, required this.animation});

  final double width;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return ShimmerShape(
      animation: animation,
      child: Container(
        width: width,
        height: 15,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

/// A shimmering skeleton circle, standing in for the "done" check icon.
class ShimmerCircle extends StatelessWidget {
  const ShimmerCircle({super.key, required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return ShimmerShape(
      animation: animation,
      child: Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}