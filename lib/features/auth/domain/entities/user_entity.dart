import 'package:equatable/equatable.dart';

class UserEntity extends Equatable{
  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? avatarUrl;

  UserEntity({
    required this.id,
    required this.email,
    required this.name,
     this.avatarUrl,
    this.phoneNumber,
 });

  @override
  List<Object?> get props => [id, email, name, avatarUrl, phoneNumber];
}
