import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/catalog_service.dart';
import '../../domain/smart_add_match.dart';
import '../../domain/usecase/extract_subscription_usecase.dart';
import '../views/subscription_form_view.dart';

part 'smart_add_state.dart';

/// Smart add: reads a screenshot or pasted message with the AI, matches it
/// to the catalog, and hands the form what it found.
class SmartAddCubit extends Cubit<SmartAddState> {
  SmartAddCubit(this._extractUseCase) : super(const SmartAddIdle());

  final ExtractSubscriptionUseCase _extractUseCase;

  Future<void> read({
    String? imagePath,
    String? text,
    required List<CatalogService> catalog,
  }) async {
    if (state is SmartAddReading || isClosed) return;
    emit(const SmartAddReading());
    final result = await _extractUseCase(
      imagePath: imagePath,
      text: text,
      knownServices: [for (final s in catalog) s.name],
    );
    if (isClosed) return;
    result.fold((failure) => emit(SmartAddFailure(failure.message)), (scan) {
      final service = matchCatalogService(scan.serviceName, catalog);
      emit(
        SmartAddReady(
          SubscriptionFormArgs.fromScan(
            scan,
            service: service,
            plan: service == null ? null : matchPlan(service, scan),
          ),
        ),
      );
    });
  }

  /// Back to idle after the screen has acted on a result.
  void acknowledge() {
    if (!isClosed) emit(const SmartAddIdle());
  }
}
