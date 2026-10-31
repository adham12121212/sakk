import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logger/app_logger.dart';
import '../../data/purchases_gateway.dart';
import 'pro_cubit.dart';

/// One-off results the paywall shows as a snackbar.
enum PaywallMessage {
  purchased,
  purchaseFailed,

  /// The store took the order but hasn't confirmed the payment yet.
  purchasePending,
  restored,
  nothingToRestore,
  restoreFailed,
  unavailable,
}

class PaywallState extends Equatable {
  const PaywallState({
    this.offer,
    this.isLoading = true,
    this.isUnavailable = false,
    this.yearlySelected = true,
    this.isPurchasing = false,
    this.isRestoring = false,
    this.message,
    this.messageId = 0,
  });

  final ProOffer? offer;
  final bool isLoading;

  /// No RevenueCat key, no store, or the offering couldn't be loaded.
  final bool isUnavailable;

  /// The yearly plan is picked by default (best value).
  final bool yearlySelected;
  final bool isPurchasing;
  final bool isRestoring;

  final PaywallMessage? message;

  /// Bumped with each [message], so the same message twice still shows.
  final int messageId;

  ProPackage? get selected => yearlySelected
      ? offer?.yearly ?? offer?.monthly
      : offer?.monthly ?? offer?.yearly;
  bool get isBusy => isPurchasing || isRestoring;

  PaywallState copyWith({
    ProOffer? offer,
    bool? isLoading,
    bool? isUnavailable,
    bool? yearlySelected,
    bool? isPurchasing,
    bool? isRestoring,
    PaywallMessage? message,
  }) {
    return PaywallState(
      offer: offer ?? this.offer,
      isLoading: isLoading ?? this.isLoading,
      isUnavailable: isUnavailable ?? this.isUnavailable,
      yearlySelected: yearlySelected ?? this.yearlySelected,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      isRestoring: isRestoring ?? this.isRestoring,
      message: message ?? this.message,
      messageId: message != null ? messageId + 1 : messageId,
    );
  }

  @override
  List<Object?> get props => [
    offer,
    isLoading,
    isUnavailable,
    yearlySelected,
    isPurchasing,
    isRestoring,
    message,
    messageId,
  ];
}

/// The paywall: loads the plans and their store prices, buys and restores.
/// A completed purchase goes to [ProCubit], which unlocks Pro straight away.
class PaywallCubit extends Cubit<PaywallState> {
  PaywallCubit(this._gateway, this._pro, this._logger)
    : super(const PaywallState());

  final PurchasesGateway _gateway;
  final ProCubit _pro;
  final AppLogger _logger;

  Future<void> load() async {
    if (!_gateway.isAvailable) {
      _safeEmit(state.copyWith(isLoading: false, isUnavailable: true));
      return;
    }
    try {
      final offer = await _gateway.loadOffer();
      final empty = offer == null || offer.isEmpty;
      _safeEmit(
        state.copyWith(
          offer: offer,
          isLoading: false,
          isUnavailable: empty,
          yearlySelected: offer?.yearly != null,
        ),
      );
    } catch (e, st) {
      _logger.error(
        'Loading the Pro offering failed',
        error: e,
        stackTrace: st,
      );
      _safeEmit(state.copyWith(isLoading: false, isUnavailable: true));
    }
  }

  void select({required bool yearly}) =>
      _safeEmit(state.copyWith(yearlySelected: yearly));

  Future<void> purchase() async {
    final package = state.selected;
    if (package == null || state.isBusy) return;
    _safeEmit(state.copyWith(isPurchasing: true));
    try {
      final entitlement = await _gateway.purchase(package);
      _safeEmit(
        state.copyWith(
          isPurchasing: false,
          // Bought but not active yet: the payment is still clearing.
          // Saying it failed would invite paying twice.
          message: entitlement.isActive
              ? PaywallMessage.purchased
              : PaywallMessage.purchasePending,
        ),
      );
      // Not awaited: it keeps re-reading the server for a few seconds.
      _pro.applyPurchase(entitlement);
    } on PurchaseCancelledException {
      _safeEmit(state.copyWith(isPurchasing: false));
    } on PurchasePendingException {
      _safeEmit(
        state.copyWith(
          isPurchasing: false,
          message: PaywallMessage.purchasePending,
        ),
      );
    } catch (e, st) {
      _logger.error('Pro purchase failed', error: e, stackTrace: st);
      _safeEmit(
        state.copyWith(
          isPurchasing: false,
          message: PaywallMessage.purchaseFailed,
        ),
      );
    }
  }

  Future<void> restore() async {
    if (state.isBusy) return;
    if (!_gateway.isAvailable) {
      _safeEmit(state.copyWith(message: PaywallMessage.unavailable));
      return;
    }
    _safeEmit(state.copyWith(isRestoring: true));
    try {
      final entitlement = await _gateway.restore();
      _safeEmit(
        state.copyWith(
          isRestoring: false,
          message: entitlement.isActive
              ? PaywallMessage.restored
              : PaywallMessage.nothingToRestore,
        ),
      );
      _pro.applyPurchase(entitlement);
    } catch (e, st) {
      _logger.error('Restoring purchases failed', error: e, stackTrace: st);
      _safeEmit(
        state.copyWith(
          isRestoring: false,
          message: PaywallMessage.restoreFailed,
        ),
      );
    }
  }

  void _safeEmit(PaywallState newState) {
    if (!isClosed) emit(newState);
  }
}
