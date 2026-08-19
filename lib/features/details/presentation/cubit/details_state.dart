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