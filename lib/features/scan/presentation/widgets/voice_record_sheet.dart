import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';

/// Records what the user says about a purchase (Add by voice). Listening
/// starts as soon as the sheet opens; Done returns the recording's path,
/// Cancel or closing the sheet returns null and deletes it.
class VoiceRecordSheet extends StatefulWidget {
  const VoiceRecordSheet({super.key});

  /// The recording's path, or null if the user cancelled or the microphone
  /// isn't allowed (they're told why).
  static Future<String?> show(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const VoiceRecordSheet(),
  );

  /// Long enough for a full description; keeps the upload small (~250 KB).
  static const maxLength = Duration(seconds: 60);

  /// Shorter than this is a mis-tap, not a description.
  static const minLength = Duration(seconds: 1);

  @override
  State<VoiceRecordSheet> createState() => _VoiceRecordSheetState();
}

class _VoiceRecordSheetState extends State<VoiceRecordSheet> {
  final _recorder = AudioRecorder();
  StreamSubscription<Amplitude>? _amplitude;
  Timer? _ticker;
  final _clock = Stopwatch();

  bool _recording = false;
  bool _finished = false;

  /// 0 (silent) to 1 (loud), for the ring around the microphone.
  double _level = 0;

  @override
  void initState() {
    super.initState();
    // After the first frame: _start reads the localizations from context.
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) _close(null, message: l10n.voiceMicDenied);
        return;
      }
      final dir = await getTemporaryDirectory();
      // 16 kHz mono AAC: plenty for speech recognition, small to upload.
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 32000,
        ),
        path:
            '${dir.path}/sakk_voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );
    } catch (_) {
      if (mounted) _close(null, message: l10n.voiceRecordFailed);
      return;
    }
    if (!mounted) {
      await _recorder.cancel();
      return;
    }
    _clock.start();
    _amplitude = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 120))
        .listen((a) {
          // dBFS: about -45 is quiet speech, 0 is the loudest.
          setState(() => _level = ((a.current + 45) / 45).clamp(0.0, 1.0));
        });
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_clock.elapsed >= VoiceRecordSheet.maxLength) {
        _done();
      } else {
        setState(() {});
      }
    });
    setState(() => _recording = true);
  }

  Future<void> _done() async {
    if (_finished || !_recording) return;
    _finished = true;
    _stopTimers();
    final path = await _recorder.stop();
    if (mounted) _close(path);
  }

  void _stopTimers() {
    _clock.stop();
    _ticker?.cancel();
    _amplitude?.cancel();
  }

  void _close(String? path, {String? message}) {
    final navigator = Navigator.of(context);
    if (message != null) AppSnackBar.error(context, message);
    navigator.pop(path);
  }

  @override
  void dispose() {
    _stopTimers();
    // Closed without Done (Cancel, swipe down, back): the file isn't kept.
    if (!_finished) unawaited(_recorder.cancel().catchError((_) {}));
    unawaited(_recorder.dispose().catchError((_) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final elapsed = _clock.elapsed;
    final canFinish = _recording && elapsed >= VoiceRecordSheet.minLength;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.voiceTitle,
              style: textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.voiceExample,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            _MicRing(level: _level, active: _recording),
            const SizedBox(height: 16),
            Text(
              _recording ? l10n.voiceListening : '',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              _format(elapsed),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: canFinish ? _done : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                    child: Text(l10n.voiceDone),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _format(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

/// The microphone, with a ring that grows with the voice's loudness.
class _MicRing extends StatelessWidget {
  const _MicRing({required this.level, required this.active});

  final double level;
  final bool active;

  @override
  Widget build(BuildContext context) {
    const size = 96.0;
    final ring = size + 48 * math.sqrt(level);
    return SizedBox(
      width: size + 48,
      height: size + 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: active ? ring : size,
            height: active ? ring : size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.brandGradientColors,
              ),
            ),
            child: const Icon(
              AppIcons.microphone,
              size: 44,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
