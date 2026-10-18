import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/scanned_installment.dart';
import '../../domain/usecase/extract_installment_usecase.dart';

part 'installment_smart_add_state.dart';

/// Smart add for installments: reads a contract, screenshot or message with
/// the AI and hands the form what it found. Nothing is saved here: the user
/// reviews the filled-in form and saves it themselves.
class InstallmentSmartAddCubit extends Cubit<InstallmentSmartAddState> {
  InstallmentSmartAddCubit(this._extractUseCase) : super(const InstallmentSmartAddIdle());

  final ExtractInstallmentUseCase _extractUseCase;

  Future<void> read({String? imagePath, String? pdfText, String? text}) async {
    if (state is InstallmentSmartAddReading || isClosed) return;
    emit(const InstallmentSmartAddReading());
    final result = await _extractUseCase(imagePath: imagePath, pdfText: pdfText, text: text);
    if (isClosed) return;
    result.fold(
      (failure) => emit(InstallmentSmartAddFailure(failure.message)),
      (scan) => emit(InstallmentSmartAddReady(scan)),
    );
  }

  /// A PDF that couldn't be opened, reported like a failed read.
  void fail(String message) {
    if (!isClosed) emit(InstallmentSmartAddFailure(message));
  }

  /// Back to idle after the screen has acted on a result.
  void acknowledge() {
    if (!isClosed) emit(const InstallmentSmartAddIdle());
  }
}
