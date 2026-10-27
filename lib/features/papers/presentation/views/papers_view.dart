import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/route/app_router.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pro/domain/pro_limit.dart';
import '../../../pro/presentation/pro_actions.dart';
import '../../domain/entities/paper.dart';
import '../cubit/papers_cubit.dart';
import '../cubit/papers_state.dart';
import '../widgets/paper_tile.dart';

/// My papers: the user's IDs, licences and insurance cards, soonest expiry
/// first.
class PapersView extends StatefulWidget {
  const PapersView({super.key});

  @override
  State<PapersView> createState() => _PapersViewState();
}

class _PapersViewState extends State<PapersView> {
  @override
  void initState() {
    super.initState();
    // Always reload: the photo links only last an hour.
    context.read<PapersCubit>().refresh();
  }

  void _add() {
    if (!ProActions.ensureCanAdd(context, LimitedItem.papers)) return;
    context.push(AppRoutes.paperForm);
  }

  /// Needs renewing (expired or soon), valid, and without an expiry date;
  /// empty sections are left out. [papers] is soonest expiry first.
  List<(String, List<Paper>)> _sections(List<Paper> papers, DateTime today) {
    final l10n = AppLocalizations.of(context)!;
    List<Paper> withStatus(Set<PaperStatus> statuses) =>
        papers.where((p) => statuses.contains(p.status(today))).toList();
    return [
      (
        l10n.papersNeedRenewing,
        withStatus({PaperStatus.expired, PaperStatus.expiringSoon}),
      ),
      (l10n.paperStatusValid, withStatus({PaperStatus.valid})),
      (l10n.paperNoExpiryDate, withStatus({PaperStatus.noExpiry})),
    ].where((s) => s.$2.isNotEmpty).toList();
  }

  void _open(Paper paper) => context.push(AppRoutes.paperDetails, extra: paper);

  // Never shown as real data: Skeletonizer paints shimmer bones over it.
  List<Paper> _placeholders() {
    final now = DateTime.now();
    return List.generate(
      4,
      (i) => Paper(
        id: 'placeholder-$i',
        kind: PaperKind.values[i],
        expiryDate: now.add(Duration(days: 40 + i * 90)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myPapers),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButton: BlocSelector<PapersCubit, PapersState, bool>(
        selector: (state) => state.papers.isNotEmpty,
        builder: (context, hasAny) => hasAny
            ? FloatingActionButton.extended(
                onPressed: _add,
                icon: const Icon(AppIcons.add),
                label: Text(l10n.addPaper),
              )
            : const SizedBox.shrink(),
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<PapersCubit, PapersState>(
          builder: (context, state) => AppRefreshIndicator(
            onRefresh: context.read<PapersCubit>().refresh,
            child: _body(context, state),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, PapersState state) {
    final l10n = AppLocalizations.of(context)!;
    final isInitialLoading = state.isLoading && !state.hasLoadedOnce;

    if (state.error != null && state.papers.isEmpty && !isInitialLoading) {
      return AppErrorView(
        message: state.error,
        onRetry: context.read<PapersCubit>().refresh,
        fillRemaining: true,
      );
    }

    if (state.papers.isEmpty && !isInitialLoading) {
      return AppEmptyView(
        icon: AppIcons.papers,
        title: l10n.noPapersYet,
        message: l10n.noPapersBody,
        actionLabel: l10n.addPaper,
        onAction: _add,
        fillRemaining: true,
      );
    }

    final items = isInitialLoading ? _placeholders() : state.papers;
    final today = DateTime.now();

    return Skeletonizer(
      enabled: isInitialLoading,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Bottom room so the last row clears the floating button.
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
        children: [
          for (final (i, (title, papers)) in _sections(
            items,
            today,
          ).indexed) ...[
            if (i > 0) const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 2, bottom: 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            GroupedCard(
              children: [
                for (final paper in papers)
                  PaperTile(
                    paper: paper,
                    today: today,
                    onTap: isInitialLoading ? null : () => _open(paper),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const _PrivacyNote(),
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.locked, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.papersPrivacyNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
