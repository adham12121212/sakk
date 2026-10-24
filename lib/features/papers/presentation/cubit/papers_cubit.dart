import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/service/paper_reminder_service.dart';
import '../../domain/entities/paper.dart';
import '../../domain/usecase/get_papers_usecase.dart';
import 'papers_state.dart';

/// The signed-in user's papers. App-wide: the Home card and the My papers
/// screen share it. Keeps this device's expiry reminders in step with the
/// list.
class PapersCubit extends Cubit<PapersState> {
  PapersCubit(
    this._getPapersUseCase, {
    PaperReminderService? reminders,
    DateTime Function() clock = DateTime.now,
  }) : _reminders = reminders,
       _clock = clock,
       super(const PapersState()) {
    _reminders?.followLanguage(() => state.papers);
  }

  final GetPapersUseCase _getPapersUseCase;
  final PaperReminderService? _reminders;
  final DateTime Function() _clock;

  void _safeEmit(PapersState newState) {
    if (isClosed) return;
    emit(newState);
  }

  /// Signed out (or switching accounts): forget the old account's papers
  /// and their reminders.
  void reset() {
    _safeEmit(const PapersState());
    unawaited(_reminders?.syncAll(const []));
  }

  Future<void> loadIfNeeded() {
    if (state.hasLoadedOnce || state.isLoading) return Future.value();
    return refresh();
  }

  Future<void> refresh() async {
    _safeEmit(state.copyWith(isLoading: true, clearError: true));
    final result = await _getPapersUseCase();
    result.fold(
      (failure) =>
          _safeEmit(state.copyWith(isLoading: false, error: failure.message)),
      (papers) {
        _safeEmit(
          state.copyWith(papers: papers, isLoading: false, hasLoadedOnce: true),
        );
        unawaited(_reminders?.checkAndNotify(papers, today: _clock()));
        unawaited(_reminders?.syncAll(papers));
      },
    );
  }

  /// Puts a just-saved paper in the list (replacing the old version).
  void upsert(Paper saved) {
    final current = sortedByExpiry([
      for (final p in state.papers)
        if (p.id != saved.id) p,
      saved,
    ]);
    _safeEmit(state.copyWith(papers: current, clearError: true));
    unawaited(_reminders?.syncAll(current));
  }

  void remove(String id) {
    final current = state.papers.where((p) => p.id != id).toList();
    _safeEmit(state.copyWith(papers: current));
    unawaited(_reminders?.syncAll(current));
  }
}
