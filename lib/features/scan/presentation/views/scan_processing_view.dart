import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakk/features/scan/presentation/views/reviewproduct_view.dart';
import '../../../products/domain/enties/scanned_receipt.dart';
import '../cubit/scan_cubit.dart';
import '../widgets/processing_field_spec.dart';
import '../widgets/processing_field_tile.dart';


class ScanProcessingView extends StatelessWidget {
  const ScanProcessingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ScanProcessingBody();
  }
}


class _ScanProcessingBody extends StatefulWidget {
  const _ScanProcessingBody();

  @override
  State<_ScanProcessingBody> createState() => _ScanProcessingBodyState();
}

class _ScanProcessingBodyState extends State<_ScanProcessingBody>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;
  Timer? _fakeProgressTimer;

  double _progress = 0.0;
  int _revealedCount = 0;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _startFakeProgress();
  }

  void _startFakeProgress() {
    _fakeProgressTimer =
        Timer.periodic(const Duration(milliseconds: 120), (_) {
          final stillInProgress =
          context.read<ScanCubit>().state is ScanProcessing;
          if (!mounted || !stillInProgress) return;
          setState(() => _progress += (0.9 - _progress) * 0.06);
        });
  }

  Future<void> _revealAndNavigate(ScanCubit cubit, ScannedReceiptData scanned) async {
    if (_navigated) return;
    _navigated = true;

    _fakeProgressTimer?.cancel();
    setState(() => _progress = 1.0);

    for (var i = 0; i < scanProcessingFields.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
      setState(() => _revealedCount = i + 1);
    }

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const ReviewProductView(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fakeProgressTimer?.cancel();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: SafeArea(
          child: BlocConsumer<ScanCubit, ScanState>(
            listener: (context, state) {
              if (state is ScanEditing) {
                _revealAndNavigate(context.read<ScanCubit>(), state.scanned);
              }
            },
            builder: (context, state) {
              if (state is ScanProcessingFailed) {
                return _ErrorView(message: state.message);
              }
              return _ProcessingBody(
                progress: _progress,
                data: state is ScanLoaded ? state.scanned : null,
                revealedCount: _revealedCount,
                pulseController: _pulseController,
                shimmerController: _shimmerController,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                context.read<ScanCubit>().close();
                Navigator.of(context).pop();
              },
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessingBody extends StatelessWidget {
  const _ProcessingBody({
    required this.progress,
    required this.data,
    required this.revealedCount,
    required this.pulseController,
    required this.shimmerController,
  });

  final double progress;
  final ScannedReceiptData? data;
  final int revealedCount;
  final AnimationController pulseController;
  final AnimationController shimmerController;

  bool get _completed => data != null;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      children: [
        Center(
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.06).animate(
              CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
            ),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3B82F6).withOpacity(0.16),
                    const Color(0xFF3B82F6).withOpacity(0.04),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.psychology, size: 42, color: Color(0xFF3B82F6)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'AI is Processing',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.3),
        ),
        const SizedBox(height: 6),
        Text(
          _completed ? 'Extraction Complete' : 'Extracting Data...',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _completed ? const Color(0xFF22C55E) : Colors.grey.shade500,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Progress', style: TextStyle(color: Colors.grey, fontSize: 13)),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 200),
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF3B82F6)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        for (var i = 0; i < scanProcessingFields.length; i++)
          ProcessingFieldTile(
            key: ValueKey('field-$i'),
            spec: scanProcessingFields[i],
            value: data == null ? null : scanProcessingFields[i].valueOf(data!),
            revealed: i < revealedCount,
            shimmerAnimation: shimmerController,
          ),
      ],
    );
  }
}