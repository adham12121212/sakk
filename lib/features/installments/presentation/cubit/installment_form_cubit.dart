import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/installment_plan.dart';
import '../../domain/entities/installment_plan_draft.dart';
import '../../domain/usecase/add_installment_plan_usecase.dart';
import '../../domain/usecase/delete_installment_plan_usecase.dart';
import '../../domain/usecase/update_installment_plan_usecase.dart';
import 'installments_cubit.dart';

part 'installment_form_state.dart';

/// Saves or deletes one plan and updates the shared list.
class InstallmentFormCubit extends Cubit<InstallmentFormState> {
  InstallmentFormCubit(
    this._addUseCase,
    this._updateUseCase,
    this._deleteUseCase,
    this._installmentsCubit,
  ) : super(const InstallmentFormIdle());

  final AddInstallmentPlanUseCase _addUseCase;
  final UpdateInstallmentPlanUseCase _updateUseCase;
  final DeleteInstallmentPlanUseCase _deleteUseCase;
  final InstallmentsCubit _installmentsCubit;

  void _safeEmit(InstallmentFormState newState) {
    if (isClosed) return;
    emit(newState);
  }

  /// Adds a new plan, or saves [draft] over [current] when it's given.
  Future<void> save(
    InstallmentPlanDraft draft, {
    InstallmentPlan? current,
  }) async {
    if (state is InstallmentFormBusy) return;
    _safeEmit(const InstallmentFormBusy());
    final result = current == null
        ? await _addUseCase(draft)
        : await _updateUseCase(current, draft);
    result.fold(
      (failure) => _safeEmit(InstallmentFormFailure(failure.message)),
      (saved) {
        _installmentsCubit.upsert(saved);
        _safeEmit(InstallmentFormSaved(saved));
      },
    );
  }

  Future<void> delete(String id) async {
    if (state is InstallmentFormBusy) return;
    _safeEmit(const InstallmentFormBusy());
    final result = await _deleteUseCase(id);
    result.fold(
      (failure) => _safeEmit(InstallmentFormFailure(failure.message)),
      (_) {
        _installmentsCubit.remove(id);
        _safeEmit(const InstallmentFormDeleted());
      },
    );
  }
}
