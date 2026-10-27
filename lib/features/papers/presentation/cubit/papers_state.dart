import 'package:equatable/equatable.dart';

import '../../domain/entities/paper.dart';

class PapersState extends Equatable {
  const PapersState({
    this.papers = const [],
    this.isLoading = false,
    this.error,
    this.hasLoadedOnce = false,
  });

  /// Soonest expiry first.
  final List<Paper> papers;
  final bool isLoading;
  final String? error;
  final bool hasLoadedOnce;

  /// The first paper to expire that hasn't yet, or the most recently
  /// expired one if they all have; null if none has an expiry date.
  Paper? nextExpiry(DateTime today) {
    Paper? expired;
    for (final p in papers) {
      final days = p.daysLeft(today);
      if (days == null) continue;
      if (days >= 0) return p;
      expired = p;
    }
    return expired;
  }

  /// Papers that have expired or expire within [Paper.soonDays].
  int needsAttention(DateTime today) => papers.where((p) {
    final status = p.status(today);
    return status == PaperStatus.expired || status == PaperStatus.expiringSoon;
  }).length;

  PapersState copyWith({
    List<Paper>? papers,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? hasLoadedOnce,
  }) {
    return PapersState(
      papers: papers ?? this.papers,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
    );
  }

  @override
  List<Object?> get props => [papers, isLoading, error, hasLoadedOnce];
}
