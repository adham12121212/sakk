import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;

  /// True when this sign-in created the account (e.g. a first Google
  /// sign-in), so the app says "Welcome to Sakk" rather than "Welcome back".
  final bool isNewAccount;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.isNewAccount = false,
  });

  @override
  List<Object?> get props => [id, email, name, avatarUrl, isNewAccount];
}
