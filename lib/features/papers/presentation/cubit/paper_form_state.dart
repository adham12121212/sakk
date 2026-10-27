part of 'paper_form_cubit.dart';

sealed class PaperFormState {
  const PaperFormState();
}

final class PaperFormIdle extends PaperFormState {
  const PaperFormIdle();
}

final class PaperFormBusy extends PaperFormState {
  const PaperFormBusy();
}

final class PaperFormSaved extends PaperFormState {
  const PaperFormSaved(this.paper);
  final Paper paper;
}

final class PaperFormDeleted extends PaperFormState {
  const PaperFormDeleted();
}

final class PaperFormFailure extends PaperFormState {
  const PaperFormFailure(this.message);
  final String message;
}
