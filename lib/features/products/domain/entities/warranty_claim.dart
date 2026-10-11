import 'package:equatable/equatable.dart';

/// Where a claim stands. The names match the `status` values the database
/// accepts (see the warranty_claims migration), in snake_case there.
enum ClaimStatus { submitted, inRepair, resolved, rejected }

extension ClaimStatusX on ClaimStatus {
  String get dbValue => this == ClaimStatus.inRepair ? 'in_repair' : name;

  static ClaimStatus fromDb(String? value) => ClaimStatus.values.firstWhere(
        (s) => s.dbValue == value,
        orElse: () => ClaimStatus.submitted,
      );

  /// Still waiting on the store or maker.
  bool get isOpen => this == ClaimStatus.submitted || this == ClaimStatus.inRepair;
}

/// One request to the store or maker to repair or replace a product.
class WarrantyClaim extends Equatable {
  const WarrantyClaim({
    required this.id,
    required this.issue,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String issue;
  final ClaimStatus status;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, issue, status, createdAt];
}
