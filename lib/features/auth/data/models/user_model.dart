import 'package:sakk/features/auth/domain/entities/user_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.email,
    required super.name,
     super.phoneNumber,
    required super.avatarUrl,
  });

  factory UserModel.fromSupabaseUser(User user) {
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['name'] ?? '',
      phoneNumber: user.phone,
      avatarUrl: user.userMetadata?['avatar_url'] ?? '',
    );
  }

}
