part of 'installment_smart_add_cubit.dart';

sealed class InstallmentSmartAddState {
  const InstallmentSmartAddState();
}

final class InstallmentSmartAddIdle extends InstallmentSmartAddState {
  const InstallmentSmartAddIdle();
}

final class InstallmentSmartAddReading extends InstallmentSmartAddState {
  const InstallmentSmartAddReading();
}

final class InstallmentSmartAddReady extends InstallmentSmartAddState {
  const InstallmentSmartAddReady(this.scan);
  final ScannedInstallment scan;
}

final class InstallmentSmartAddFailure extends InstallmentSmartAddState {
  const InstallmentSmartAddFailure(this.message);
  final String message;
}
