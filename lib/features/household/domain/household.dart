import 'package:equatable/equatable.dart';

/// A family group whose members see each other's products.
class Household extends Equatable {
  const Household({required this.id, required this.name, required this.inviteCode});

  final String id;
  final String name;

  /// 10 characters others type to join (see the households migration).
  final String inviteCode;

  @override
  List<Object?> get props => [id, name, inviteCode];
}

class HouseholdMember extends Equatable {
  const HouseholdMember({required this.userId, required this.displayName, required this.isOwner});

  final String userId;
  final String displayName;

  /// The owner can remove members and make a new invite code.
  final bool isOwner;

  @override
  List<Object?> get props => [userId, displayName, isOwner];
}
