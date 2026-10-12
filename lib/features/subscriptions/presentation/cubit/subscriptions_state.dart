import 'package:equatable/equatable.dart';

import '../../domain/entities/user_subscription.dart';
import '../../domain/subscription_totals.dart';

class SubscriptionsState extends Equatable {
  const SubscriptionsState({
    this.subscriptions = const [],
    this.isLoading = false,
    this.error,
    this.hasLoadedOnce = false,
  });

  /// Nearest renewal first.
  final List<UserSubscription> subscriptions;
  final bool isLoading;
  final String? error;
  final bool hasLoadedOnce;

  /// Monthly cost per currency; never adds different currencies together.
  Map<String, double> get monthlyTotals =>
      monthlyTotalsByCurrency(subscriptions);

  /// The next subscription to renew on or after [today], if any.
  UserSubscription? nextRenewal(DateTime today) {
    for (final s in subscriptions) {
      if (s.daysLeft(today) >= 0) return s;
    }
    return null;
  }

  SubscriptionsState copyWith({
    List<UserSubscription>? subscriptions,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? hasLoadedOnce,
  }) {
    return SubscriptionsState(
      subscriptions: subscriptions ?? this.subscriptions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
    );
  }

  @override
  List<Object?> get props => [subscriptions, isLoading, error, hasLoadedOnce];
}
