import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_subscription.dart';
import '../../domain/subscription_totals.dart';
import '../../domain/usecase/get_subscriptions_usecase.dart';
import 'subscriptions_state.dart';

/// The signed-in user's subscriptions. App-wide: the Home card and the
/// Subscriptions screen share it.
class SubscriptionsCubit extends Cubit<SubscriptionsState> {
  SubscriptionsCubit(this._getSubscriptionsUseCase)
    : super(const SubscriptionsState());

  final GetSubscriptionsUseCase _getSubscriptionsUseCase;

  void _safeEmit(SubscriptionsState newState) {
    if (isClosed) return;
    emit(newState);
  }

  /// Signed out (or switching accounts): forget the old account's list.
  void reset() => _safeEmit(const SubscriptionsState());

  Future<void> loadIfNeeded() {
    if (state.hasLoadedOnce || state.isLoading) return Future.value();
    return refresh();
  }

  Future<void> refresh() async {
    _safeEmit(state.copyWith(isLoading: true, clearError: true));
    final result = await _getSubscriptionsUseCase();
    result.fold(
      (failure) =>
          _safeEmit(state.copyWith(isLoading: false, error: failure.message)),
      (subscriptions) => _safeEmit(
        state.copyWith(
          subscriptions: sortedByRenewal(subscriptions),
          isLoading: false,
          hasLoadedOnce: true,
        ),
      ),
    );
  }

  /// Puts a just-saved subscription in the list (replacing the old version).
  void upsert(UserSubscription saved) {
    final others = state.subscriptions.where((s) => s.id != saved.id);
    _safeEmit(
      state.copyWith(
        subscriptions: sortedByRenewal([...others, saved]),
        clearError: true,
      ),
    );
  }

  void remove(String id) {
    _safeEmit(
      state.copyWith(
        subscriptions: state.subscriptions.where((s) => s.id != id).toList(),
      ),
    );
  }
}
