import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sakk/features/subscriptions/presentation/widgets/subscription_logo.dart';

/// Stands in for the app's assets: [files] are the bundled paths and bytes.
/// Always used, so the real logos in assets/logos/ never affect these tests.
class FakeBundle extends CachingAssetBundle {
  FakeBundle([this.files = const {}]);

  final Map<String, List<int>> files;

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage({
        for (final path in files.keys)
          path: [
            <String, Object>{'asset': path},
          ],
      })!;
    }
    final bytes = files[key];
    if (bytes == null) throw FlutterError('Unable to load asset: $key');
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

/// An asset bundle whose manifest never finishes loading.
class NeverLoads extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => Completer<ByteData>().future;
}

Future<void> show(
  WidgetTester tester,
  SubscriptionLogo logo, {
  AssetBundle? bundle,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DefaultAssetBundle(
          bundle: bundle ?? FakeBundle(),
          child: Center(child: logo),
        ),
      ),
    ),
  );
  // The (fake) asset manifest loads in microtasks.
  await tester.pump();
  await tester.pump();
}

// A 1×1 PNG.
final pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);
const svgText =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10"><rect width="10" height="10" fill="#0a0"/></svg>';

/// A logo drawn from a bundled file (CachedNetworkImage draws an Image too,
/// so look for the asset itself).
Finder bundledImage() => find.byWidgetPredicate(
  (w) =>
      w is Image &&
      (w.image is AssetImage ||
          (w.image is ResizeImage &&
              (w.image as ResizeImage).imageProvider is AssetImage)),
);

/// The white, padded tile used for bundled logos, favicons and SVGs.
Finder framedTile() => find.byWidgetPredicate(
  (w) => w is Container && w.color == Colors.white && w.padding != null,
);

void main() {
  testWidgets('a bitmap logo_url fills the tile, with no white frame', (
    tester,
  ) async {
    await show(
      tester,
      const SubscriptionLogo(
        name: 'Netflix',
        logoUrl: 'https://cdn.example.com/netflix.png',
        domain: 'netflix.com',
      ),
    );
    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.imageUrl, 'https://cdn.example.com/netflix.png');
    expect(image.fit, BoxFit.cover);
    expect(image.width, 44);
    expect(framedTile(), findsNothing);
  });

  group('SVG logo_url', () {
    const svgUrl =
        'https://x.supabase.co/storage/v1/object/public/logos/shahid.SVG?v=2';
    const validSvg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10"><rect width="10" height="10" fill="#0a0"/></svg>';

    setUp(SubscriptionLogo.clearSvgCache);
    tearDown(() => SubscriptionLogo.fetch = http.get);

    Future<void> showAndLoad(WidgetTester tester, SubscriptionLogo logo) async {
      await show(tester, logo);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();
    }

    testWidgets('is drawn as SVG on a white frame, even with a query string', (
      tester,
    ) async {
      SubscriptionLogo.fetch = (_) async => http.Response(validSvg, 200);
      await showAndLoad(
        tester,
        const SubscriptionLogo(name: 'Shahid', logoUrl: svgUrl),
      );
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(framedTile(), findsOneWidget);
    });

    testWidgets('a broken SVG falls back quietly, with no uncaught error', (
      tester,
    ) async {
      SubscriptionLogo.fetch = (_) async =>
          http.Response('<html>Not found</html>', 200);
      await showAndLoad(
        tester,
        const SubscriptionLogo(name: 'Shahid', logoUrl: svgUrl),
      );
      expect(find.byType(SvgPicture), findsNothing);
      expect(find.text('S'), findsOneWidget); // no domain: the letter
      expect(tester.takeException(), isNull);
    });

    testWidgets('a missing SVG falls back to the favicon', (tester) async {
      SubscriptionLogo.fetch = (_) async => http.Response('', 404);
      await showAndLoad(
        tester,
        const SubscriptionLogo(
          name: 'Shahid',
          logoUrl: svgUrl,
          domain: 'shahid.mbc.net',
        ),
      );
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.imageUrl, contains('domain=shahid.mbc.net'));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('without logo_url: the favicon, framed and contained', (
    tester,
  ) async {
    await show(
      tester,
      const SubscriptionLogo(name: 'Spotify', domain: 'spotify.com'),
    );
    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.imageUrl, contains('domain=spotify.com'));
    expect(image.fit, BoxFit.contain);
    expect(framedTile(), findsOneWidget);
  });

  testWidgets(
    'a failing logo falls back to the favicon, not straight to the letter',
    (tester) async {
      await show(
        tester,
        const SubscriptionLogo(
          name: 'Netflix',
          logoUrl: 'https://cdn.example.com/netflix.png',
          domain: 'netflix.com',
        ),
      );
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      final onError = image.errorWidget!(
        tester.element(find.byType(CachedNetworkImage)),
        image.imageUrl,
        Exception('404'),
      );
      expect(onError, isA<Container>()); // the framed favicon tile
      expect(
        ((onError as Container).child as CachedNetworkImage).imageUrl,
        contains('domain=netflix.com'),
      );
    },
  );

  testWidgets('nothing to load: the first letter', (tester) async {
    await show(tester, const SubscriptionLogo(name: 'gym club'));
    expect(find.text('G'), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);

    await show(tester, const SubscriptionLogo(name: 'Gym', logoUrl: '  '));
    expect(find.text('G'), findsOneWidget);
  });

  group('performance', () {
    testWidgets('logos decode at the size they are drawn, not the file size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetDevicePixelRatio);

      // Filling a 44pt tile at 3x: 132px, doubled so cropping stays sharp.
      await show(
        tester,
        const SubscriptionLogo(
          name: 'Netflix',
          logoUrl: 'https://cdn.example.com/netflix.png',
        ),
      );
      expect(
        tester
            .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
            .memCacheWidth,
        264,
      );
      // Width only: both would stretch non-square images.
      expect(
        tester
            .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
            .memCacheHeight,
        isNull,
      );

      // A framed favicon: the tile's width.
      await show(
        tester,
        const SubscriptionLogo(
          name: 'Spotify',
          domain: 'spotify.com',
          size: 28,
        ),
      );
      expect(
        tester
            .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
            .memCacheWidth,
        84,
      );
    });

    testWidgets('logos appear without a fade', (tester) async {
      await show(
        tester,
        const SubscriptionLogo(
          name: 'Netflix',
          logoUrl: 'https://cdn.example.com/netflix.png',
          domain: 'netflix.com',
        ),
      );
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.fadeInDuration, Duration.zero);
      expect(image.fadeOutDuration, Duration.zero);
      expect(image.placeholderFadeInDuration, Duration.zero);
    });
  });

  group('bundled logo files', () {
    setUp(SubscriptionLogo.clearSvgCache);
    tearDown(() => SubscriptionLogo.fetch = http.get);

    testWidgets(
      'a bundled PNG for the domain wins: whole, on white, no network call',
      (tester) async {
        var fetched = false;
        SubscriptionLogo.fetch = (_) async {
          fetched = true;
          return http.Response('', 404);
        };
        final bundle = FakeBundle({'assets/logos/netflix.com.png': pngBytes});
        await show(
          tester,
          const SubscriptionLogo(
            name: 'Netflix',
            logoUrl: 'https://cdn.example.com/netflix.svg',
            domain: 'NetFlix.com',
          ),
          bundle: bundle,
        );

        final image = tester.widget<Image>(bundledImage());
        expect((image.image as ResizeImage).imageProvider, isA<AssetImage>());
        expect(
          ((image.image as ResizeImage).imageProvider as AssetImage).assetName,
          'assets/logos/netflix.com.png',
        );
        expect(image.fit, BoxFit.contain); // wordmarks are never cropped
        expect(
          framedTile(),
          findsOneWidget,
        ); // white, so dark text shows in dark mode
        expect(
          find.byType(CachedNetworkImage),
          findsNothing,
        ); // no logo_url, no favicon
        expect(fetched, isFalse);
      },
    );

    testWidgets('a bundled SVG is drawn on the framed tile', (tester) async {
      final bundle = FakeBundle({
        'assets/logos/vodafone.com.eg.svg': utf8.encode(svgText),
      });
      await show(
        tester,
        const SubscriptionLogo(name: 'Vodafone', domain: 'vodafone.com.eg'),
        bundle: bundle,
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(framedTile(), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('a broken bundled SVG falls back quietly to the favicon', (
      tester,
    ) async {
      final bundle = FakeBundle({
        'assets/logos/vodafone.com.eg.svg': utf8.encode('not an svg'),
      });
      await show(
        tester,
        const SubscriptionLogo(name: 'Vodafone', domain: 'vodafone.com.eg'),
        bundle: bundle,
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();

      expect(find.byType(SvgPicture), findsNothing);
      expect(
        tester
            .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
            .imageUrl,
        contains('domain=vodafone.com.eg'),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'no bundled file for the domain: logo_url, then favicon, then letter',
      (tester) async {
        final bundle = FakeBundle({'assets/logos/netflix.com.png': pngBytes});

        await show(
          tester,
          const SubscriptionLogo(
            name: 'Gym',
            logoUrl: 'https://cdn.example.com/gym.png',
            domain: 'gym.example',
          ),
          bundle: bundle,
        );
        expect(
          tester
              .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
              .imageUrl,
          'https://cdn.example.com/gym.png',
        );

        await show(
          tester,
          const SubscriptionLogo(name: 'Gym', domain: 'gym.example'),
          bundle: bundle,
        );
        expect(
          tester
              .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
              .imageUrl,
          contains('domain=gym.example'),
        );

        await show(tester, const SubscriptionLogo(name: 'gym'), bundle: bundle);
        expect(find.text('G'), findsOneWidget);
        expect(bundledImage(), findsNothing);
      },
    );

    testWidgets('only image files directly in assets/logos/ count', (
      tester,
    ) async {
      final bundle = FakeBundle({
        'assets/logos/README.md': utf8.encode('docs'),
        'assets/logos/old/spotify.com.png': pngBytes,
        'assets/icons/spotify.com.png': pngBytes,
      });
      await show(
        tester,
        const SubscriptionLogo(name: 'Spotify', domain: 'spotify.com'),
        bundle: bundle,
      );
      expect(bundledImage(), findsNothing);
      expect(
        tester
            .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
            .imageUrl,
        contains('domain=spotify.com'),
      );
    });

    testWidgets(
      'while the list of bundled files loads: an empty tile, no letter, no download',
      (tester) async {
        var fetched = false;
        SubscriptionLogo.fetch = (_) async {
          fetched = true;
          return http.Response('', 404);
        };
        await show(
          tester,
          const SubscriptionLogo(
            name: 'Netflix',
            logoUrl: 'https://cdn.example.com/n.svg',
            domain: 'netflix.com',
          ),
          bundle: NeverLoads(),
        );
        expect(find.text('N'), findsNothing);
        expect(find.byType(CachedNetworkImage), findsNothing);
        expect(fetched, isFalse);
      },
    );
  });

  test(
    'every catalog service has exactly one bundled logo, named by its domain',
    () {
      final seed = File(
        'supabase/migrations/20261012120000_subscriptions.sql',
      ).readAsStringSync();
      final domains = RegExp(
        r"\('[^']+', '[a-z]+', '([a-z0-9.-]+)', '\[",
      ).allMatches(seed).map((m) => m.group(1)!).toSet();
      expect(domains, hasLength(23));

      final files = Directory('assets/logos')
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .where((name) => RegExp(r'\.(png|jpe?g|webp|svg)$').hasMatch(name))
          .toList();
      final byDomain = <String, List<String>>{};
      for (final name in files) {
        byDomain
            .putIfAbsent(name.substring(0, name.lastIndexOf('.')), () => [])
            .add(name);
      }
      expect(byDomain.keys.toSet(), domains, reason: 'files: $files');
      expect(byDomain.values.where((v) => v.length > 1), isEmpty);
    },
  );
}
