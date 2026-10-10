import 'package:equatable/equatable.dart';

/// A warranty on top of the manufacturer's one, e.g. an extended warranty
/// bought from the store.
class ExtraWarranty extends Equatable {
  const ExtraWarranty({
    required this.id,
    required this.provider,
    required this.startDate,
    required this.months,
  });

  final String id;
  final String provider;
  final DateTime startDate;
  final int months;

  /// Same month arithmetic as the manufacturer warranty in ProductEntity.
  DateTime get endDate => DateTime(startDate.year, startDate.month + months, startDate.day);

  @override
  List<Object?> get props => [id, provider, startDate, months];
}
