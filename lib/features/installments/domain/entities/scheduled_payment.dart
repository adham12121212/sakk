import 'package:equatable/equatable.dart';

/// An installment that isn't saved yet: a row in the form's preview, or one
/// of the unpaid installments sent when a plan is saved.
class ScheduledPayment extends Equatable {
  /// Date only (no time of day).
  final DateTime dueDate;
  final double amount;

  const ScheduledPayment({required this.dueDate, required this.amount});

  @override
  List<Object?> get props => [dueDate, amount];
}
