part of 'installment_form_cubit.dart';

sealed class InstallmentFormState {
  const InstallmentFormState();
}

final class InstallmentFormIdle extends InstallmentFormState {
  const InstallmentFormIdle();
}

final class InstallmentFormBusy extends InstallmentFormState {
  const InstallmentFormBusy();
}

final class InstallmentFormSaved extends InstallmentFormState {
  const InstallmentFormSaved(this.plan);
  final InstallmentPlan plan;
}

final class InstallmentFormDeleted extends InstallmentFormState {
  const InstallmentFormDeleted();
}

final class InstallmentFormFailure extends InstallmentFormState {
  const InstallmentFormFailure(this.message);
  final String message;
}
