import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../util/subscription_format.dart';

/// Service logo in a rounded square: [logoUrl], else the favicon of
/// [domain], else (or while loading, or if it fails) the name's first letter.
class SubscriptionLogo extends StatelessWidget {
  const SubscriptionLogo({
    super.key,
    required this.name,
    this.logoUrl,
    this.domain,
    this.size = 44,
  });

  final String name;
  final String? logoUrl;
  final String? domain;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = logoUrl ?? faviconUrl(domain);
    final radius = BorderRadius.circular(size * 0.28);
    final letter = _LetterAvatar(name: name, size: size);

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: radius,
        child: url == null
            ? letter
            : Container(
                width: size,
                height: size,
                // Favicons are often transparent and dark: always on white.
                color: Colors.white,
                padding: EdgeInsets.all(size * 0.14),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  fadeInDuration: const Duration(milliseconds: 150),
                  placeholder: (_, _) => const SizedBox.shrink(),
                  errorWidget: (_, _, _) => letter,
                ),
              ),
      ),
    );
  }
}

class _LetterAvatar extends StatelessWidget {
  const _LetterAvatar({required this.name, required this.size});

  final String name;
  final double size;

  static const _colors = [
    Color(0xFF4A5CFA),
    Color(0xFF0EA5E9),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
  ];

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final letter = trimmed.isEmpty
        ? '?'
        : trimmed.characters.first.toUpperCase();
    // Same name, same colour, on every screen and launch.
    final color =
        _colors[trimmed.codeUnits.fold<int>(0, (sum, c) => sum + c) %
            _colors.length];

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: color.withValues(alpha: 0.15),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
