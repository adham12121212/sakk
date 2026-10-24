import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/route/app_router.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/util/localized_number.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../scan/presentation/widgets/invoice_preview_dialog.dart';
import '../../domain/entities/paper.dart';
import '../cubit/papers_cubit.dart';
import '../cubit/papers_state.dart';
import '../util/paper_format.dart';
import '../util/paper_ui.dart';

/// One paper: its status, the photos large enough to read, the number
/// (with a copy button), the expiry date and notes. Edit is in the app bar.
class PaperDetailsView extends StatelessWidget {
  const PaperDetailsView({super.key, required this.paper});

  /// As it was when opened; the shared list's newer version wins, so an
  /// edit shows here straight away.
  final Paper paper;

  Future<void> _edit(BuildContext context, Paper current) async {
    final cubit = context.read<PapersCubit>();
    await context.push(AppRoutes.paperForm, extra: current);
    // Deleted from the form: nothing left to show.
    if (context.mounted && !cubit.state.papers.any((p) => p.id == paper.id)) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocSelector<PapersCubit, PapersState, Paper>(
      selector: (state) =>
          state.papers.firstWhere((p) => p.id == paper.id, orElse: () => paper),
      builder: (context, current) {
        final today = DateTime.now();
        return Scaffold(
          appBar: AppBar(
            title: Text(PaperUi.name(l10n, current)),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            actions: [
              IconButton(
                tooltip: l10n.edit,
                icon: const Icon(AppIcons.edit),
                onPressed: () => _edit(context, current),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _Header(paper: current, today: today),
                const SizedBox(height: 16),
                if (current.frontPath == null && current.backPath == null)
                  _NoPhotos(onTap: () => _edit(context, current))
                else ...[
                  if (current.frontPath != null)
                    _Photo(label: l10n.paperFront, url: current.frontUrl),
                  if (current.frontPath != null && current.backPath != null)
                    const SizedBox(height: 12),
                  if (current.backPath != null)
                    _Photo(label: l10n.paperBack, url: current.backUrl),
                ],
                const SizedBox(height: 16),
                _Details(paper: current, today: today),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The kind's icon, the name and a status chip.
class _Header extends StatelessWidget {
  const _Header({required this.paper, required this.today});

  final Paper paper;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final color = PaperUi.color(paper.kind);
    final name = PaperUi.name(l10n, paper);
    final kindName = PaperUi.kindName(l10n, paper.kind);
    final status = paper.status(today);
    final statusColor =
        paperStatusColor(context, status) ??
        Theme.of(context).colorScheme.primary;
    final statusText = switch (status) {
      PaperStatus.valid => l10n.paperStatusValid,
      PaperStatus.expiringSoon => l10n.paperStatusExpiringSoon,
      PaperStatus.expired => l10n.paperStatusExpired,
      PaperStatus.noExpiry => l10n.paperNoExpiryDate,
    };

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(PaperUi.icon(paper.kind), color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: textTheme.titleLarge),
                if (name != kindName)
                  Text(kindName, style: textTheme.bodySmall),
                const SizedBox(height: 6),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One side of the paper, full width; a tap opens it full screen to zoom.
class _Photo extends StatelessWidget {
  const _Photo({required this.label, required this.url});

  final String label;

  /// Null if the link couldn't be signed (pull to refresh on the list).
  final String? url;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final url = this.url;
    const broken = Center(child: Icon(AppIcons.brokenImage, size: 32));

    return Semantics(
      button: url != null,
      label: label,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: colorScheme.surfaceContainerHighest,
          child: InkWell(
            onTap: url == null
                ? null
                : () => showInvoicePreviewDialog(context, url),
            child: AspectRatio(
              // ID cards are about 1.6 wide for 1 high.
              aspectRatio: 1.6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (url == null)
                    broken
                  else
                    Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => broken,
                    ),
                  PositionedDirectional(
                    start: 10,
                    bottom: 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoPhotos extends StatelessWidget {
  const _NoPhotos({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(AppIcons.camera, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.paperNoPhotos,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Number, expiry date and notes, each on its own row when there is one.
class _Details extends StatelessWidget {
  const _Details({required this.paper, required this.today});

  final Paper paper;
  final DateTime today;

  /// "Expires in 412 days" or "Expires today"; nothing once it has expired
  /// (the header says so) or without an expiry date.
  String? _countdown(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final days = paper.daysLeft(today);
    if (days == null || days < 0) return null;
    if (days == 0) return l10n.paperExpiresToday;
    return l10n.paperExpiresInDays(
      days,
      formatLocalizedInt(Localizations.localeOf(context), days),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final number = paper.number;
    final notes = paper.notes;
    final expiry = paper.expiryDate;
    final statusColor = paperStatusColor(context, paper.status(today));

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          if (number != null)
            _Row(
              label: l10n.paperNumber,
              value: number,
              trailing: IconButton(
                tooltip: l10n.copyPaperNumber,
                icon: const Icon(AppIcons.copy, size: 20),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: number));
                  if (context.mounted) {
                    AppSnackBar.success(context, l10n.paperNumberCopied);
                  }
                },
              ),
            ),
          _Row(
            label: l10n.paperExpiryDate,
            value: expiry == null
                ? l10n.paperNoExpiryDate
                : formatPaperDate(context, expiry),
            detail: _countdown(context),
            detailColor: statusColor,
            divider: number != null,
          ),
          if (notes != null)
            _Row(label: l10n.notes, value: notes, divider: true),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.detail,
    this.detailColor,
    this.trailing,
    this.divider = false,
  });

  final String label;
  final String value;
  final String? detail;
  final Color? detailColor;
  final Widget? trailing;

  /// A hairline above, between rows.
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final detail = this.detail;
    return Column(
      children: [
        if (divider) Divider(height: 1, color: colorScheme.outlineVariant),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: textTheme.bodySmall),
                    const SizedBox(height: 2),
                    SelectableText(value, style: textTheme.titleMedium),
                    if (detail != null)
                      Text(
                        detail,
                        style: textTheme.bodySmall?.copyWith(
                          color: detailColor,
                          fontWeight: detailColor == null
                              ? null
                              : FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ],
    );
  }
}
