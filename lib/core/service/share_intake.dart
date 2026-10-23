import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// A receipt photo or PDF invoice shared to Sakk from another app.
class SharedReceipt {
  const SharedReceipt({required this.path, required this.isPdf});

  /// A local copy the sharing plugin made in the app's own storage.
  final String path;
  final bool isPdf;

  /// The receipt among [files]: the first photo or PDF. Anything else
  /// (video, text, links, other files) isn't a receipt. Null if none is.
  static SharedReceipt? from(List<SharedMediaFile> files) {
    for (final file in files) {
      if (file.type == SharedMediaType.image) {
        return SharedReceipt(path: file.path, isPdf: false);
      }
      final pdf =
          file.mimeType == 'application/pdf' ||
          file.path.toLowerCase().endsWith('.pdf');
      if (file.type == SharedMediaType.file && pdf) {
        return SharedReceipt(path: file.path, isPdf: true);
      }
    }
    return null;
  }
}

/// Receives files shared to Sakk ("Share → Sakk" in Gmail, WhatsApp, Files,
/// Photos...) and holds the receipt until a signed-in screen takes it (see
/// SharedReceiptListener), so a share that opens the app waits for the
/// splash, sign-in and lock screens.
class ShareIntake {
  ShareIntake({ReceiveSharingIntent? plugin})
    : _plugin = plugin ?? ReceiveSharingIntent.instance;

  final ReceiveSharingIntent _plugin;
  StreamSubscription<List<SharedMediaFile>>? _subscription;

  /// The receipt waiting to be scanned.
  final pending = ValueNotifier<SharedReceipt?>(null);

  /// Picks up a share that launched the app and listens for shares while
  /// it runs.
  Future<void> start() async {
    _subscription ??= _plugin.getMediaStream().listen(
      _receive,
      onError: (_) {},
    );
    try {
      _receive(await _plugin.getInitialMedia());
    } catch (_) {
      // No share, or the platform side isn't set up (e.g. iOS without the
      // Share Extension yet).
    }
  }

  /// Removes and returns the pending receipt.
  SharedReceipt? take() {
    final receipt = pending.value;
    pending.value = null;
    return receipt;
  }

  void _receive(List<SharedMediaFile> files) {
    final receipt = SharedReceipt.from(files);
    if (receipt != null) pending.value = receipt;
    // Handled: the plugin shouldn't hand the same share over again.
    unawaited(_plugin.reset().catchError((_) {}));
  }
}
