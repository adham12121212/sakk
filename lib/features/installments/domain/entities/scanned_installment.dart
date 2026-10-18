import 'package:equatable/equatable.dart';

/// What the AI read from a contract, screenshot or message. Every field may
/// be missing; the user reviews them in the form before saving.
class ScannedInstallment extends Equatable {
  /// What was bought.
  final String? title;
  final String? provider;
  final double? totalPrice;
  final double? downPayment;
  final double? installmentAmount;
  final int? installmentsCount;
  final DateTime? firstDueDate;
  final int? dueDayOfMonth;
  final double? interestOrFees;
  final String? currency;
  final double confidence;

  const ScannedInstallment({
    this.title,
    this.provider,
    this.totalPrice,
    this.downPayment,
    this.installmentAmount,
    this.installmentsCount,
    this.firstDueDate,
    this.dueDayOfMonth,
    this.interestOrFees,
    this.currency,
    this.confidence = 0,
  });

  @override
  List<Object?> get props => [
    title,
    provider,
    totalPrice,
    downPayment,
    installmentAmount,
    installmentsCount,
    firstDueDate,
    dueDayOfMonth,
    interestOrFees,
    currency,
    confidence,
  ];
}
