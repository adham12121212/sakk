import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:sakk/core/route/app_router.dart';
import 'package:sakk/core/service/share_intake.dart';
import 'package:sakk/features/scan/presentation/widgets/shared_receipt_listener.dart';

class _FakeSharing extends ReceiveSharingIntent
    with MockPlatformInterfaceMixin {
  List<SharedMediaFile> initial = [];
  final stream = StreamController<List<SharedMediaFile>>.broadcast();
  int resets = 0;

  @override
  Future<List<SharedMediaFile>> getInitialMedia() async => initial;

  @override
  Stream<List<SharedMediaFile>> getMediaStream() => stream.stream;

  @override
  Future<dynamic> reset() async => resets++;
}

SharedMediaFile _file(String path, SharedMediaType type, [String? mime]) =>
    SharedMediaFile(path: path, type: type, mimeType: mime);

void main() {
  group('SharedReceipt.from', () {
    test('takes the first photo or PDF', () {
      final photo = SharedReceipt.from([
        _file('/c/clip.mp4', SharedMediaType.video),
        _file('/c/receipt.jpg', SharedMediaType.image),
        _file('/c/other.jpg', SharedMediaType.image),
      ]);
      expect(photo?.path, '/c/receipt.jpg');
      expect(photo?.isPdf, isFalse);

      final pdf = SharedReceipt.from([
        _file('/c/invoice', SharedMediaType.file, 'application/pdf'),
      ]);
      expect(pdf?.path, '/c/invoice');
      expect(pdf?.isPdf, isTrue);
      expect(
        SharedReceipt.from([
          _file('/c/Invoice.PDF', SharedMediaType.file),
        ])?.isPdf,
        isTrue,
      );
    });

    test('anything else is not a receipt', () {
      expect(
        SharedReceipt.from([
          _file('hello', SharedMediaType.text),
          _file('https://x.com', SharedMediaType.url),
          _file('/c/notes.docx', SharedMediaType.file),
        ]),
        isNull,
      );
      expect(SharedReceipt.from([]), isNull);
    });
  });

  test(
    'a share that launched the app and later shares are held once',
    () async {
      final plugin = _FakeSharing()
        ..initial = [_file('/c/a.jpg', SharedMediaType.image)];
      final intake = ShareIntake(plugin: plugin);
      await intake.start();
      expect(intake.pending.value?.path, '/c/a.jpg');
      expect(plugin.resets, 1);

      expect(intake.take()?.path, '/c/a.jpg');
      expect(intake.take(), isNull);

      plugin.stream.add([_file('/c/b.pdf', SharedMediaType.file)]);
      await Future<void>.delayed(Duration.zero);
      expect(intake.pending.value?.isPdf, isTrue);
    },
  );

  group('SharedReceiptListener', () {
    late GoRouter router;
    late ShareIntake intake;
    SharedReceipt? opened;

    Future<void> pumpApp(WidgetTester tester, String start) async {
      opened = null;
      intake = ShareIntake(plugin: _FakeSharing());
      router = GoRouter(
        initialLocation: start,
        routes: [
          for (final path in [AppRoutes.biometricLock, AppRoutes.home])
            GoRoute(path: path, builder: (_, _) => Text(path)),
          GoRoute(
            path: AppRoutes.scan,
            builder: (_, state) {
              opened = state.extra as SharedReceipt?;
              return const Text('scan');
            },
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          builder: (_, child) => SharedReceiptListener(
            router: router,
            intake: intake,
            child: child!,
          ),
        ),
      );
    }

    testWidgets('opens Scan straight away on a signed-in screen', (
      tester,
    ) async {
      await pumpApp(tester, AppRoutes.home);
      intake.pending.value = const SharedReceipt(
        path: '/c/a.jpg',
        isPdf: false,
      );
      await tester.pumpAndSettle();

      expect(find.text('scan'), findsOneWidget);
      expect(opened?.path, '/c/a.jpg');
      expect(intake.pending.value, isNull);
    });

    testWidgets('waits on the lock screen, then opens Scan', (tester) async {
      await pumpApp(tester, AppRoutes.biometricLock);
      intake.pending.value = const SharedReceipt(path: '/c/a.pdf', isPdf: true);
      await tester.pumpAndSettle();
      expect(find.text('scan'), findsNothing);
      expect(intake.pending.value, isNotNull);

      router.go(AppRoutes.home);
      await tester.pumpAndSettle();
      expect(find.text('scan'), findsOneWidget);
      expect(opened?.isPdf, isTrue);
    });
  });
}
