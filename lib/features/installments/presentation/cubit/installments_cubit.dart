import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/installment_plan.dart';
import '../../domain/installment_totals.dart';
import '../../domain/usecase/get_installment_plans_usecase.dart';
import '../../domain/usecase/set_payment_paid_usecase.dart';
import 'installments_state.dart';

/// The signed-in user's installment plans. App-wide: the Home card, the
/// Installments screens, product details and Analytics share it.
class InstallmentsCubit extends Cubit<InstallmentsState> {
  InstallmentsCubit(this._getPlansUseCase, this._setPaymentPaidUseCase)
    : super(const InstallmentsState());

  final GetInstallmentPlansUseCase _getPlansUseCase;
  final SetPaymentPaidUseCase _setPaymentPaidUseCase;

  void _safeEmit(InstallmentsState newState) {
    if (isClosed) return;
    emit(newState);
  }

  /// Signed out (or switching accounts): forget the old account's plans.
  void reset() => _safeEmit(const InstallmentsState());

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
      (plans) => _safeEmit(
        state.copyWith(
          plans: sortedByNextDue(plans),
          isLoading: false,
          hasLoadedOnce: true,
        ),
      ),
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
  }

  void remove(String id) {
    _safeEmit(
      state.copyWith(plans: state.plans.where((p) => p.id != id).toList()),
    );
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
        return null;
      },
    );
  }
}
