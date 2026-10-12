import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/subscription_category.dart';
import '../../domain/entities/user_subscription.dart';
import '../../domain/usecase/add_subscription_usecase.dart';
import '../../domain/usecase/delete_subscription_usecase.dart';
import '../../domain/usecase/update_subscription_usecase.dart';
import 'subscriptions_cubit.dart';

part 'subscription_form_state.dart';

/// Saves or deletes one subscription and updates the shared list.
class SubscriptionFormCubit extends Cubit<SubscriptionFormState> {
  SubscriptionFormCubit(
    this._addUseCase,
    this._updateUseCase,
    this._deleteUseCase,
    this._subscriptionsCubit,
  ) : super(const SubscriptionFormIdle());

  final AddSubscriptionUseCase _addUseCase;
  final UpdateSubscriptionUseCase _updateUseCase;
  final DeleteSubscriptionUseCase _deleteUseCase;
  final SubscriptionsCubit _subscriptionsCubit;

  void _safeEmit(SubscriptionFormState newState) {
    if (isClosed) return;
    emit(newState);
  }

  /// Adds a new subscription, or updates [id] when it's given.
  Future<void> save({
    String? id,
    String? catalogId,
    String? customName,
    String? planName,
    required SubscriptionCategory category,
    required double price,
    required String currency,
    required BillingCycle billingCycle,
    required DateTime nextRenewalDate,
    String? paymentMethod,
    String? notes,
  }) async {
    if (state is SubscriptionFormBusy) return;
    _safeEmit(const SubscriptionFormBusy());
    final result = id == null
        ? await _addUseCase(
            catalogId: catalogId,
            customName: customName,
            planName: planName,
            category: category,
            price: price,
            currency: currency,
            billingCycle: billingCycle,
            nextRenewalDate: nextRenewalDate,
            paymentMethod: paymentMethod,
            notes: notes,
          )
        : await _updateUseCase(
            id: id,
            catalogId: catalogId,
            customName: customName,
            planName: planName,
            category: category,
            price: price,
            currency: currency,
            billingCycle: billingCycle,
            nextRenewalDate: nextRenewalDate,
            paymentMethod: paymentMethod,
            notes: notes,
          );
    result.fold(
      (failure) => _safeEmit(SubscriptionFormFailure(failure.message)),
      (saved) {
        _subscriptionsCubit.upsert(saved);
        _safeEmit(SubscriptionFormSaved(saved));
      },
    );
  }

  Future<void> delete(String id) async {
    if (state is SubscriptionFormBusy) return;
    _safeEmit(const SubscriptionFormBusy());
    final result = await _deleteUseCase(id);
    result.fold(
      (failure) => _safeEmit(SubscriptionFormFailure(failure.message)),
      (_) {
        _subscriptionsCubit.remove(id);
        _safeEmit(const SubscriptionFormDeleted());
      },
    );
  }
}
