part of 'scan_cubit.dart';

@immutable
sealed class ScanState {
  const ScanState();
}


final class ScanProcessing extends ScanState {
  const ScanProcessing();
}

final class ScanProcessingFailed extends ScanState {
  const ScanProcessingFailed(this.message);

  final String message;
}


sealed class ScanLoaded extends ScanState {
  const ScanLoaded({required this.scanned});

  final ScannedReceiptData scanned;
}

final class ScanEditing extends ScanLoaded {
  const ScanEditing({required super.scanned});
}

final class ScanSaving extends ScanLoaded {
  const ScanSaving({required super.scanned});
}

final class ScanSaveSuccess extends ScanLoaded {
  const ScanSaveSuccess({required super.scanned});
}

final class ScanSaveFailure extends ScanLoaded {
  const ScanSaveFailure({required super.scanned, required this.message});

  final String message;
}