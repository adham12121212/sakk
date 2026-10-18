import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/service/installment_reminder_service.dart';
import '../../domain/entities/installment_plan.dart';
import '../../domain/installment_totals.dart';
import '../../domain/usecase/get_installment_plans_usecase.dart';
import '../../domain/usecase/set_payment_paid_usecase.dart';
import 'installments_state.dart';

/// The signed-in user's installment plans. App-wide: the Home card, the
/// Installments screens, product details and Analytics share it.
///
/// Keeps this device's installment reminders in step with the list: every
/// change (add, edit, delete, paid, unpaid) re-syncs them.
class InstallmentsCubit extends Cubit<InstallmentsState> {
  InstallmentsCubit(
    this._getPlansUseCase,
    this._setPaymentPaidUseCase, {
    InstallmentReminderService? reminders,
    DateTime Function() clock = DateTime.now,
  }) : _reminders = reminders,
       _clock = clock,
       super(const InstallmentsState()) {
    _reminders?.followLanguage(() => state.plans);
  }

  final GetInstallmentPlansUseCase _getPlansUseCase;
  final SetPaymentPaidUseCase _setPaymentPaidUseCase;
  final InstallmentReminderService? _reminders;
  final DateTime Function() _clock;

  void _syncReminders() => unawaited(_reminders?.syncAll(state.plans));

  void _safeEmit(InstallmentsState newState) {
    if (isClosed) return;
    emit(newState);
  }

  /// Signed out (or switching accounts): forget the old account's plans and
  /// their reminders.
  void reset() {
    _safeEmit(const InstallmentsState());
    unawaited(_reminders?.syncAll(const []));
  }

  Future<void> loadIfNeeded() {
    if (state.hasLoadedOnce || state.isLoading) return Future.value();
    return refresh();
  }

  Future<void> refresh() async {
    _safeEmit(state.copyWith(isLoading: true, clearError: true));
    final result = await _getPlansUseCase();
    result.fold(
      (failure) =>
          _safeEmit(state.copyWith(isLoading: false, error: failure.message)),
      (plans) {
        _safeEmit(
          state.copyWith(
            plans: sortedByNextDue(plans),
            isLoading: false,
            hasLoadedOnce: true,
          ),
        );
        unawaited(_reminders?.checkAndNotify(state.plans, today: _clock()));
        _syncReminders();
      },
    );
  }

  /// Puts a just-saved plan in the list (replacing the old version).
  void upsert(InstallmentPlan saved) {
    final others = state.plans.where((p) => p.id != saved.id);
    _safeEmit(
      state.copyWith(
        plans: sortedByNextDue([...others, saved]),
        clearError: true,
      ),
    );
    _syncReminders();
  }

  void remove(String id) {
    _safeEmit(
      state.copyWith(plans: state.plans.where((p) => p.id != id).toList()),
    );
    _syncReminders();
  }

  /// Marks [paymentId] of [planId] paid, or unpaid again. Returns the
  /// failure message, or null once it's saved.
  Future<String?> setPaymentPaid(
    String planId,
    String paymentId, {
    required bool paid,
  }) async {
    if (state.updatingPaymentIds.contains(paymentId)) return null;
    _safeEmit(
      state.copyWith(
        updatingPaymentIds: {...state.updatingPaymentIds, paymentId},
      ),
    );
    final result = await _setPaymentPaidUseCase(paymentId, paid: paid);
    final updating = {...state.updatingPaymentIds}..remove(paymentId);
    return result.fold(
      (failure) {
        _safeEmit(state.copyWith(updatingPaymentIds: updating));
        return failure.message;
      },
      (payment) {
        final plans = [
          for (final p in state.plans)
            p.id == planId ? p.withPayment(payment) : p,
        ];
        _safeEmit(
          state.copyWith(
            plans: sortedByNextDue(plans),
            updatingPaymentIds: updating,
          ),
        );
        _syncReminders();
        return null;
      },
    );
  }

  /// The "Mark as paid" button on a reminder: loads the plans if this is a
  /// fresh start, then marks the payment paid unless it already is (or is
  /// gone). Returns the failure message, or null.
  Future<String?> markPaidFromReminder(String planId, String paymentId) async {
    // A load already under way (e.g. Home's, on a cold start) has to finish.
    if (state.isLoading) await stream.firstWhere((s) => !s.isLoading);
    await loadIfNeeded();
    final payment = state
        .planById(planId)
        ?.payments
        .where((p) => p.id == paymentId)
        .firstOrNull;
    if (payment == null || payment.isPaid) return null;
    return setPaymentPaid(planId, paymentId, paid: true);
  }
}
