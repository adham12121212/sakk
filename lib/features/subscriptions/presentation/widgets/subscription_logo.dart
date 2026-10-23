import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import '../util/subscription_format.dart';

/// Service logo in a rounded square. Tries, in order: a logo file bundled in
/// the app for [domain] (`assets/logos/<domain>.png|jpg|jpeg|webp|svg`),
/// [logoUrl], the favicon of [domain], then the name's first letter (also
/// shown while loading).
///
/// Bundled logos are mostly wordmarks on a transparent background, some with
/// near-black text, so they sit on white with a margin and are never
/// cropped. A [logoUrl] bitmap is a proper brand image and fills the tile;
/// SVGs and favicons sit on white with a margin too.
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

  /// Forgets loaded SVG logos (tests).
  @visibleForTesting
  static void clearSvgCache() => _SafeSvg._cache.clear();

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final remote = _remote(pixelRatio);
    final key = domain?.trim().toLowerCase();
    final Widget child;
    if (key == null || key.isEmpty) {
      child = remote;
    } else {
      final bundle = DefaultAssetBundle.of(context);
      final logos = _BundledLogos.of(bundle);
      final loaded = logos.byDomain;
      // Until the list of bundled files is read (once per launch, in a few
      // milliseconds), an empty tile: starting the remote logo meanwhile
      // would download what a bundled file replaces, and the letter would
      // flash.
      child = loaded != null
          ? _bundledOr(loaded[key], bundle, remote, pixelRatio)
          : FutureBuilder<Map<String, String>>(
              future: logos.loading,
              builder: (context, snapshot) => snapshot.hasData
                  ? _bundledOr(snapshot.data![key], bundle, remote, pixelRatio)
                  : SizedBox.square(dimension: size),
            );
    }

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: child,
      ),
    );
  }

  /// The bundled file at [asset], or [remote] when there is none (or it
  /// fails to load).
  Widget _bundledOr(
    String? asset,
    AssetBundle bundle,
    Widget remote,
    double pixelRatio,
  ) {
    if (asset == null) return remote;
    if (_isSvg(asset)) {
      return _SafeSvg(
        source: asset,
        read: () => bundle.loadString(asset, cache: false),
        framed: _framed,
        fallback: remote,
      );
    }
    return _framed(
      Image.asset(
        asset,
        bundle: bundle,
        fit: BoxFit.contain,
        // Decode at the tile's width, like network logos (width only, so
        // nothing is stretched; small files are never enlarged).
        cacheWidth: (size * pixelRatio).ceil(),
        errorBuilder: (_, error, _) {
          _logFailure(asset, error);
          return remote;
        },
      ),
    );
  }

  /// [logoUrl], else the favicon of [domain], else the letter.
  Widget _remote(double pixelRatio) {
    final letter = _LetterAvatar(name: name, size: size);
    final favicon = faviconUrl(domain);
    final fallback = favicon == null
        ? letter
        : _framed(_bitmap(favicon, BoxFit.contain, letter, pixelRatio));

    final logo = logoUrl;
    if (logo == null || logo.trim().isEmpty) return fallback;
    if (_isSvg(logo)) {
      return _SafeSvg(
        source: logo,
        read: () => _download(logo),
        framed: _framed,
        fallback: fallback,
      );
    }
    return SizedBox.square(
      dimension: size,
      child: _bitmap(logo, BoxFit.cover, fallback, pixelRatio),
    );
  }

  static Future<String> _download(String url) async {
    final uri = Uri.parse(url);
    final response = await fetch(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}', uri);
    }
    return response.body;
  }

  /// White tile with a margin, for bundled logos, favicons and SVGs.
  Widget _framed(Widget image) => Container(
    width: size,
    height: size,
    color: Colors.white,
    padding: EdgeInsets.all(size * 0.14),
    child: image,
  );

  Widget _bitmap(String url, BoxFit fit, Widget onError, double pixelRatio) =>
      CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        // Filling: the tile's size. Framed: whatever the margin leaves.
        width: fit == BoxFit.cover ? size : null,
        height: fit == BoxFit.cover ? size : null,
        // Decode at the size it's drawn, not the file's (a 1000px logo for a
        // 44pt tile drops frames when a list of them opens). Width only: giving
        // both stretches non-square images. Filling crops, so twice the width
        // keeps logos up to 2:1 sharp; small images are never enlarged.
        memCacheWidth: (size * pixelRatio * (fit == BoxFit.cover ? 2 : 1))
            .ceil(),
        // No fade: on a list, every row fading in at once is wasted work, and a
        // logo already in memory shows at once anyway.
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholderFadeInDuration: Duration.zero,
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

/// An SVG logo (downloaded or bundled), drawn only once it has been read and
/// parsed.
///
/// Not SvgPicture.network or SvgPicture.asset: when an SVG fails to load or
/// parse, flutter_svg (via vector_graphics) leaves an unawaited future
/// failing, which reaches PlatformDispatcher.onError and is recorded in
/// Crashlytics as a fatal crash. Here every failure is caught and shows
/// [fallback] instead.
class _SafeSvg extends StatefulWidget {
  const _SafeSvg({
    required this.source,
    required this.read,
    required this.framed,
    required this.fallback,
  });

  /// The URL or asset path: the cache key and what failures are logged as.
  final String source;
  final Future<String> Function() read;
  final Widget Function(Widget image) framed;
  final Widget fallback;

  /// Per launch: each source is read once; null means it failed.
  static final _cache = <String, Future<String?>>{};

  static Future<String?> _load(String source, Future<String> Function() read) =>
      _cache.putIfAbsent(source, () async {
        try {
          final svg = await read();
          // Parse once here so a broken file fails inside this try.
          final info = await vg.loadPicture(SvgStringLoader(svg), null);
          info.picture.dispose();
          return svg;
        } catch (e) {
          _logFailure(source, e);
          return null;
        }
      });

  @override
  State<_SafeSvg> createState() => _SafeSvgState();
}

class _SafeSvgState extends State<_SafeSvg> {
  late Future<String?> _svg = _SafeSvg._load(widget.source, widget.read);

  @override
  void didUpdateWidget(_SafeSvg oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _svg = _SafeSvg._load(widget.source, widget.read);
    }
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

/// The logo files shipped in `assets/logos/`, by domain: `netflix.com.png`
/// is Netflix's. Read from the asset manifest once per bundle, so adding a
/// logo is just adding a file.
class _BundledLogos {
  _BundledLogos._(AssetBundle bundle) {
    loading = _read(bundle).then((logos) => byDomain = logos);
  }

  static const folder = 'assets/logos/';
  static const _extensions = {'png', 'jpg', 'jpeg', 'webp', 'svg'};
  static final _byBundle = Expando<_BundledLogos>();

  static _BundledLogos of(AssetBundle bundle) =>
      _byBundle[bundle] ??= _BundledLogos._(bundle);

  late final Future<Map<String, String>> loading;

  /// Null until [loading] completes.
  Map<String, String>? byDomain;

  static Future<Map<String, String>> _read(AssetBundle bundle) async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(bundle);
      final logos = <String, String>{};
      for (final path in manifest.listAssets()) {
        if (!path.startsWith(folder)) continue;
        final file = path.substring(folder.length);
        final dot = file.lastIndexOf('.');
        if (file.contains('/') || dot <= 0) continue;
        final extension = file.substring(dot + 1).toLowerCase();
        if (!_extensions.contains(extension)) continue;
        logos[file.substring(0, dot).toLowerCase()] = path;
      }
      return logos;
    } catch (e) {
      _logFailure('the asset manifest', e);
      return const {};
    }
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
  if (kDebugMode && _loggedFailures.add(url)) {
    debugPrint('[SubscriptionLogo] Failed to load $url: $error');
  }
}
