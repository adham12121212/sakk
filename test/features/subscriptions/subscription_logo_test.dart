import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sakk/features/subscriptions/presentation/widgets/subscription_logo.dart';

Future<void> show(WidgetTester tester, SubscriptionLogo logo) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: logo))));
}

/// The white, padded tile used for favicons and SVG wordmarks.
Finder framedTile() => find.byWidgetPredicate(
      (w) => w is Container && w.color == Colors.white && w.padding != null,
    );

void main() {
  testWidgets('a bitmap logo_url fills the tile, with no white frame', (tester) async {
    await show(tester, const SubscriptionLogo(name: 'Netflix', logoUrl: 'https://cdn.example.com/netflix.png', domain: 'netflix.com'));
    final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
    expect(image.imageUrl, 'https://cdn.example.com/netflix.png');
    expect(image.fit, BoxFit.cover);
    expect(image.width, 44);
    expect(framedTile(), findsNothing);
  });

  group('SVG logo_url', () {
    const svgUrl = 'https://x.supabase.co/storage/v1/object/public/logos/shahid.SVG?v=2';
    const validSvg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10"><rect width="10" height="10" fill="#0a0"/></svg>';

    setUp(SubscriptionLogo.clearSvgCache);
    tearDown(() => SubscriptionLogo.fetch = http.get);

    Future<void> showAndLoad(WidgetTester tester, SubscriptionLogo logo) async {
      await show(tester, logo);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump();
    }

    testWidgets('is drawn as SVG on a white frame, even with a query string', (tester) async {
      SubscriptionLogo.fetch = (_) async => http.Response(validSvg, 200);
      await showAndLoad(tester, const SubscriptionLogo(name: 'Shahid', logoUrl: svgUrl));
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(framedTile(), findsOneWidget);
    });

    testWidgets('a broken SVG falls back quietly, with no uncaught error', (tester) async {
      SubscriptionLogo.fetch = (_) async => http.Response('<html>Not found</html>', 200);
      await showAndLoad(tester, const SubscriptionLogo(name: 'Shahid', logoUrl: svgUrl));
      expect(find.byType(SvgPicture), findsNothing);
      expect(find.text('S'), findsOneWidget); // no domain: the letter
      expect(tester.takeException(), isNull);
    });

    testWidgets('a missing SVG falls back to the favicon', (tester) async {
      SubscriptionLogo.fetch = (_) async => http.Response('', 404);
      await showAndLoad(tester, const SubscriptionLogo(name: 'Shahid', logoUrl: svgUrl, domain: 'shahid.mbc.net'));
      final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(image.imageUrl, contains('domain=shahid.mbc.net'));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('without logo_url: the favicon, framed and contained', (tester) async {
    await show(tester, const SubscriptionLogo(name: 'Spotify', domain: 'spotify.com'));
    final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
    expect(image.imageUrl, contains('domain=spotify.com'));
    expect(image.fit, BoxFit.contain);
    expect(framedTile(), findsOneWidget);
  });

  testWidgets('a failing logo falls back to the favicon, not straight to the letter', (tester) async {
    await show(tester, const SubscriptionLogo(name: 'Netflix', logoUrl: 'https://cdn.example.com/netflix.png', domain: 'netflix.com'));
    final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
    final onError = image.errorWidget!(tester.element(find.byType(CachedNetworkImage)), image.imageUrl, Exception('404'));
    expect(onError, isA<Container>()); // the framed favicon tile
    expect(((onError as Container).child as CachedNetworkImage).imageUrl, contains('domain=netflix.com'));
  });

  testWidgets('nothing to load: the first letter', (tester) async {
    await show(tester, const SubscriptionLogo(name: 'gym club'));
    expect(find.text('G'), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);

    await show(tester, const SubscriptionLogo(name: 'Gym', logoUrl: '  '));
    expect(find.text('G'), findsOneWidget);
  });
}
