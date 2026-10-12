import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/service/subscription_reminder_service.dart';
import '../../domain/entities/user_subscription.dart';
import '../../domain/renewal_schedule.dart';
import '../../domain/subscription_totals.dart';
import '../../domain/usecase/get_subscriptions_usecase.dart';
import '../../domain/usecase/update_renewal_date_usecase.dart';
import 'subscriptions_state.dart';

/// The signed-in user's subscriptions. App-wide: the Home card, the
/// Subscriptions screen and Analytics share it.
///
/// Keeps renewal dates current (a passed renewal moves to the next one and
/// is saved) and keeps this device's renewal reminders in step with the list.
class SubscriptionsCubit extends Cubit<SubscriptionsState> {
  SubscriptionsCubit(
    this._getSubscriptionsUseCase, {
    UpdateRenewalDateUseCase? updateRenewalDateUseCase,
    SubscriptionReminderService? reminders,
    DateTime Function() clock = DateTime.now,
  }) : _updateRenewalDateUseCase = updateRenewalDateUseCase,
       _reminders = reminders,
       _clock = clock,
       super(const SubscriptionsState()) {
    _reminders?.followLanguage(() => state.subscriptions);
  }

  final GetSubscriptionsUseCase _getSubscriptionsUseCase;
  final UpdateRenewalDateUseCase? _updateRenewalDateUseCase;
  final SubscriptionReminderService? _reminders;
  final DateTime Function() _clock;

  void _safeEmit(SubscriptionsState newState) {
    if (isClosed) return;
    emit(newState);
  }

  /// Signed out (or switching accounts): forget the old account's list and
  /// its reminders.
  void reset() {
    _safeEmit(const SubscriptionsState());
    unawaited(_reminders?.syncAll(const []));
  }

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
      (subscriptions) {
        final current = _advance(subscriptions);
        _safeEmit(
          state.copyWith(
            subscriptions: current,
            isLoading: false,
            hasLoadedOnce: true,
          ),
        );
        unawaited(_reminders?.checkAndNotify(current, today: _clock()));
        unawaited(_reminders?.syncAll(current));
      },
    );
  }

  /// Puts a just-saved subscription in the list (replacing the old version).
  void upsert(UserSubscription saved) {
    final others = state.subscriptions.where((s) => s.id != saved.id);
    final current = _advance([...others, saved]);
    _safeEmit(state.copyWith(subscriptions: current, clearError: true));
    unawaited(_reminders?.syncAll(current));
  }

  void remove(String id) {
    final current = state.subscriptions.where((s) => s.id != id).toList();
    _safeEmit(state.copyWith(subscriptions: current));
    unawaited(_reminders?.syncAll(current));
  }

  /// Moves passed renewals to their next date, sorted by nearest renewal.
  /// Moved dates are saved in the background; if that fails (e.g. offline)
  /// the list still shows the right date and the next load tries again.
  List<UserSubscription> _advance(Iterable<UserSubscription> subscriptions) {
    final before = {for (final s in subscriptions) s.id: s.nextRenewalDate};
    final advanced = advancePassedRenewals(subscriptions, _clock());
    for (final s in advanced) {
      if (s.nextRenewalDate != before[s.id]) {
        unawaited(_updateRenewalDateUseCase?.call(s.id, s.nextRenewalDate));
      }
    }
    return sortedByRenewal(advanced);
  }
}
