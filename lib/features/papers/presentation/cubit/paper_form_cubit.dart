import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/paper.dart';
import '../../domain/usecase/delete_paper_usecase.dart';
import '../../domain/usecase/save_paper_usecase.dart';
import 'papers_cubit.dart';

part 'paper_form_state.dart';

/// Saves or deletes one paper and updates the shared list.
class PaperFormCubit extends Cubit<PaperFormState> {
  PaperFormCubit(this._saveUseCase, this._deleteUseCase, this._papersCubit)
    : super(const PaperFormIdle());

  final SavePaperUseCase _saveUseCase;
  final DeletePaperUseCase _deleteUseCase;
  final PapersCubit _papersCubit;

  void _safeEmit(PaperFormState newState) {
    if (isClosed) return;
    emit(newState);
  }

  Future<void> save(PaperDraft draft) async {
    if (state is PaperFormBusy) return;
    _safeEmit(const PaperFormBusy());
    final result = await _saveUseCase(draft);
    result.fold((failure) => _safeEmit(PaperFormFailure(failure.message)), (
      saved,
    ) {
      _papersCubit.upsert(saved);
      _safeEmit(PaperFormSaved(saved));
    });
  }

  Future<void> delete(Paper paper) async {
    if (state is PaperFormBusy) return;
    _safeEmit(const PaperFormBusy());
    final result = await _deleteUseCase(paper);
    result.fold((failure) => _safeEmit(PaperFormFailure(failure.message)), (_) {
      _papersCubit.remove(paper.id);
      _safeEmit(const PaperFormDeleted());
    });
  }
}
