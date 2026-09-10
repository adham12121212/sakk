


import 'package:flutter/material.dart';

class Dots extends StatefulWidget {
  const Dots();

  @override
  State<Dots> createState() => _DotsState();
}

class _DotsState extends State<Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (i) {
            final t = (_controller.value - (i * 0.2)) % 1.0;
            final opacity = 0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2);
            return Opacity(
              opacity: opacity.clamp(0.3, 1.0),
              child: Container(
                width: 6,
                height: 6,
                decoration:  BoxDecoration(color: colorScheme.onSurface.withOpacity(0.5), shape: BoxShape.circle),
              ),
            );
          }),
        );
      },
    );
  }
}