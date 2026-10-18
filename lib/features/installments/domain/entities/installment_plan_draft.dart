import 'package:equatable/equatable.dart';

import 'installment_terms.dart';

/// What the user enters for a plan: the fields a save writes. The schedule
/// comes from [terms].
class InstallmentPlanDraft extends Equatable {
  /// One of the user's products, or null for a purchase typed by name.
  final String? productId;

  /// The product's name when one is linked, otherwise what the user typed.
  final String title;

  /// Bank, Valu, Contact, Sympl, the store...
  final String? provider;
  final String currency;
  final InstallmentTerms terms;
  final String? notes;
  final bool isCancelled;

  const InstallmentPlanDraft({
    this.productId,
    required this.title,
    this.provider,
    this.currency = 'EGP',
    required this.terms,
    this.notes,
    this.isCancelled = false,
  });

  @override
  List<Object?> get props => [
    productId,
    title,
    provider,
    currency,
    terms,
    notes,
    isCancelled,
  ];
}
