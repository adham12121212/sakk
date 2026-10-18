import '../installment_repo/installment_repo.dart';

abstract class ClearCachedInstallmentsUseCase {
  Future<void> call();
}

class ClearCachedInstallmentsUseCaseImpl
    implements ClearCachedInstallmentsUseCase {
  final InstallmentRepo _installmentRepo;
  ClearCachedInstallmentsUseCaseImpl(this._installmentRepo);

  @override
  Future<void> call() => _installmentRepo.clearCachedInstallments();
}
