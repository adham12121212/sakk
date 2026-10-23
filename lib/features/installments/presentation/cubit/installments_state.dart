import 'package:equatable/equatable.dart';

import '../../domain/entities/installment_plan.dart';
import '../../domain/installment_totals.dart';

class InstallmentsState extends Equatable {
  const InstallmentsState({
    this.plans = const [],
    this.isLoading = false,
    this.error,
    this.hasLoadedOnce = false,
    this.updatingPaymentIds = const {},
  });

  /// Active plans by next installment, then completed, then cancelled.
  final List<InstallmentPlan> plans;
  final bool isLoading;
  final String? error;
  final bool hasLoadedOnce;

  /// Payments being marked paid or unpaid right now.
  final Set<String> updatingPaymentIds;

  /// What's left on active plans, per currency; never adds different
  /// currencies together.
  Map<String, double> get remainingTotals => remainingByCurrency(plans);

  List<InstallmentPlan> get activePlans =>
      plans.where((p) => p.isActive).toList();

  InstallmentPlan? planById(String id) {
    for (final p in plans) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<InstallmentPlan> plansForProduct(String productId) =>
      plansForProductIn(plans, productId);

  /// Unpaid installments past their due date, across active plans.
  int overdueCount(DateTime today) =>
      activePlans.fold(0, (sum, p) => sum + p.overduePayments(today).length);

  InstallmentsState copyWith({
    List<InstallmentPlan>? plans,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? hasLoadedOnce,
    Set<String>? updatingPaymentIds,
  }) {
    return InstallmentsState(
      plans: plans ?? this.plans,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      updatingPaymentIds: updatingPaymentIds ?? this.updatingPaymentIds,
    );
  }

  @override
  List<Object?> get props => [
    plans,
    isLoading,
    error,
    hasLoadedOnce,
    updatingPaymentIds,
  ];
}
