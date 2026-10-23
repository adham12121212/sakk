import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakk/features/scan/presentation/views/reviewproduct_view.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/util/localized_number.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/domain/entities/scanned_receipt.dart';
import '../cubit/scan_cubit.dart';
import '../widgets/processing_field_spec.dart';
import '../widgets/processing_field_tile.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/constant/app_colors.dart';
import 'scan_failed_view.dart';

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
    _fakeProgressTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      final stillInProgress = context.read<ScanCubit>().state is ScanProcessing;
      if (!mounted || !stillInProgress) return;
      setState(() => _progress += (0.9 - _progress) * 0.06);
    });
  }

  Future<void> _revealAndNavigate(
    ScanCubit cubit,
    ScannedReceiptData scanned,
  ) async {
    if (_navigated) return;
    _navigated = true;

    _fakeProgressTimer?.cancel();
    setState(() => _progress = 1.0);

    final fieldCount = buildScanProcessingFields(context).length;
    for (var i = 0; i < fieldCount; i++) {
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
        builder: (_) =>
            BlocProvider.value(value: cubit, child: const ReviewProductView()),
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
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<ScanCubit, ScanState>(
          listener: (context, state) {
            if (state is ScanEditing) {
              _revealAndNavigate(context.read<ScanCubit>(), state.scanned);
            }
          },
          builder: (context, state) {
            // With the reason (unreadable, nothing heard, limit, offline...),
            // not a generic "couldn't load".
            if (state is ScanProcessingFailed) {
              return ScanFailedView(
                message: state.message,
                onBack: () {
                  context.read<ScanCubit>().close();
                  Navigator.of(context).pop();
                },
              );
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
    final l10n = AppLocalizations.of(context)!;
    final fields = buildScanProcessingFields(context);

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final palette = context.palette;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      children: [
        Center(
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.06).animate(
              CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
            ),
            // Brand-gradient tile with a soft glow, pulsing while it works.
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.brandGradientColors,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x404A5CFA),
                    blurRadius: 28,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Icon(
                _completed ? AppIcons.check : AppIcons.aiFilled,
                size: 44,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.aiIsProcessing,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          _completed ? l10n.extractionComplete : l10n.extractingData,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: _completed ? palette.success : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 28),
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.progressLabel,
                      style: textTheme.labelLarge,
                    ),
                  ),
                  Text(
                    '${formatLocalizedInt(Localizations.localeOf(context), (progress * 100).round())}%',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < fields.length; i++)
          ProcessingFieldTile(
            key: ValueKey('field-$i'),
            spec: fields[i],
            value: data == null ? null : fields[i].valueOf(data!),
            revealed: i < revealedCount,
            shimmerAnimation: shimmerController,
          ),
      ],
    );
  }
}
