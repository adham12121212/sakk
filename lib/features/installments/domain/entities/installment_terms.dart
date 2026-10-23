import 'package:equatable/equatable.dart';

/// The money and dates of a plan: everything its schedule is built from.
class InstallmentTerms extends Equatable {
  final double totalPrice;
  final double downPayment;

  /// Interest or fees on top of the price, when the provider charges any.
  final double? interestOrFees;
  final double installmentAmount;
  final int installmentsCount;

  /// The first installment's due date (date only).
  final DateTime startDate;

  /// 1–31; 29–31 fall on the last day of shorter months.
  final int dueDayOfMonth;

  const InstallmentTerms({
    required this.totalPrice,
    this.downPayment = 0,
    this.interestOrFees,
    required this.installmentAmount,
    required this.installmentsCount,
    required this.startDate,
    required this.dueDayOfMonth,
  });

  /// What's left to pay in installments: price less the down payment, plus
  /// any interest or fees.
  double get financedAmount => totalPrice - downPayment + (interestOrFees ?? 0);

  @override
  List<Object?> get props => [
    totalPrice,
    downPayment,
    interestOrFees,
    installmentAmount,
    installmentsCount,
    startDate,
    dueDayOfMonth,
  ];
}
