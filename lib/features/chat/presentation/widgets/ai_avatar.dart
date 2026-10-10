import 'package:flutter/material.dart';

/// Brand-gradient circle with the assistant's sparkle icon.
class AiAvatar extends StatelessWidget {
  const AiAvatar({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3D7BFF), Color(0xFF5B3DF5)],
        ),
      ),
      child: Icon(Icons.auto_awesome_rounded, size: size * 0.5, color: Colors.white),
    );
  }
}
