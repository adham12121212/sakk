import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import '../util/subscription_format.dart';

/// Service logo in a rounded square. Tries, in order: [logoUrl], the favicon
/// of [domain], then the name's first letter (also shown while loading).
///
/// A [logoUrl] is a proper brand image: bitmaps fill the tile, SVGs (often
/// wide wordmarks) sit on white with a margin. Favicons are small and often
/// transparent, so they always sit on white with a margin too.
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

  /// How SVG logos are downloaded; tests swap it for a fake.
  @visibleForTesting
  static Future<http.Response> Function(Uri url) fetch = http.get;

  /// Forgets downloaded SVG logos (tests).
  @visibleForTesting
  static void clearSvgCache() => _NetworkSvg._cache.clear();

  @override
  Widget build(BuildContext context) {
    final letter = _LetterAvatar(name: name, size: size);
    final favicon = faviconUrl(domain);
    final fallback = favicon == null
        ? letter
        : _framed(_bitmap(favicon, BoxFit.contain, letter));

    final logo = logoUrl;
    final Widget child;
    if (logo == null || logo.trim().isEmpty) {
      child = fallback;
    } else if (_isSvg(logo)) {
      child = _NetworkSvg(url: logo, framed: _framed, fallback: fallback);
    } else {
      child = SizedBox.square(
        dimension: size,
        child: _bitmap(logo, BoxFit.cover, fallback),
      );
    }

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: child,
      ),
    );
  }

  /// White tile with a margin, for favicons and SVG wordmarks.
  Widget _framed(Widget image) => Container(
    width: size,
    height: size,
    color: Colors.white,
    padding: EdgeInsets.all(size * 0.14),
    child: image,
  );

  Widget _bitmap(String url, BoxFit fit, Widget onError) => CachedNetworkImage(
    imageUrl: url,
    fit: fit,
    // Filling: the tile's size. Framed: whatever the margin leaves.
    width: fit == BoxFit.cover ? size : null,
    height: fit == BoxFit.cover ? size : null,
    fadeInDuration: const Duration(milliseconds: 150),
    placeholder: (_, _) => const SizedBox.shrink(),
    errorWidget: (_, failedUrl, error) {
      _logFailure(failedUrl, error);
      return onError;
    },
  );

  /// By the path's extension, ignoring any query string (signed URLs).
  static bool _isSvg(String url) {
    final path = Uri.tryParse(url)?.path ?? url;
    return path.toLowerCase().endsWith('.svg');
  }
}

/// An SVG logo, drawn only once it has downloaded and parsed.
///
/// Not SvgPicture.network: when an SVG fails to load or parse, flutter_svg
/// (via vector_graphics) leaves an unawaited future failing, which reaches
/// PlatformDispatcher.onError and is recorded in Crashlytics as a fatal
/// crash. Here every failure is caught and shows [fallback] instead.
class _NetworkSvg extends StatefulWidget {
  const _NetworkSvg({
    required this.url,
    required this.framed,
    required this.fallback,
  });

  final String url;
  final Widget Function(Widget image) framed;
  final Widget fallback;

  /// Per launch: each URL is fetched once; null means it failed.
  static final _cache = <String, Future<String?>>{};

  static Future<String?> _load(String url) => _cache.putIfAbsent(url, () async {
    try {
      final response = await SubscriptionLogo.fetch(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        _logFailure(url, 'HTTP ${response.statusCode}');
        return null;
      }
      final svg = response.body;
      // Parse once here so a broken file fails inside this try.
      final info = await vg.loadPicture(SvgStringLoader(svg), null);
      info.picture.dispose();
      return svg;
    } catch (e) {
      _logFailure(url, e);
      return null;
    }
  });

  @override
  State<_NetworkSvg> createState() => _NetworkSvgState();
}

class _NetworkSvgState extends State<_NetworkSvg> {
  late Future<String?> _svg = _NetworkSvg._load(widget.url);

  @override
  void didUpdateWidget(_NetworkSvg oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _svg = _NetworkSvg._load(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _svg,
      builder: (context, snapshot) {
        final svg = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.framed(const SizedBox.shrink());
        }
        if (svg == null) return widget.fallback;
        return widget.framed(SvgPicture.string(svg, fit: BoxFit.contain));
      },
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

/// Logos fall back silently, so say why in the debug console (like
/// ProfileAvatar does for profile photos). Once per URL per launch.
final _loggedFailures = <String>{};

void _logFailure(String url, Object error) {
  if (_loggedFailures.add(url)) {
    debugPrint('[SubscriptionLogo] Failed to load $url: $error');
  }
}
