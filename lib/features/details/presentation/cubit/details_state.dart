part of 'details_cubit.dart';

sealed class DetailsState {
  const DetailsState();
}

final class DetailsIdle extends DetailsState {
  const DetailsIdle();
}

final class DetailsSaving extends DetailsState {
  const DetailsSaving();
}

final class DetailsSuccess extends DetailsState {
  const DetailsSuccess(this.product);
  final ProductEntity product;
}

final class DetailsFailure extends DetailsState {
  const DetailsFailure(this.message);
  final String message;
}

final class DetailsActionInProgress extends DetailsState {
  const DetailsActionInProgress();
}

final class DetailsShareReady extends DetailsState {
  const DetailsShareReady(this.text, this.subject);
  final String text;
  final String subject;
}

final class DetailsDownloadReady extends DetailsState {
  const DetailsDownloadReady(this.filePath, this.shareText);
  final String filePath;
  final String shareText;
}

final class DetailsDeleted extends DetailsState {
  const DetailsDeleted();
}

final class DetailsActionError extends DetailsState {
  const DetailsActionError(this.error); // raw error, not localized
  final Object error;
}