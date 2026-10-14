import 'package:sakk/features/auth/domain/entities/user_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.avatarUrl,
    super.isNewAccount,
  });

  /// Metadata key for a photo the user uploaded. Kept apart from
  /// 'avatar_url', which Google overwrites with its own photo on each sign-in.
  static const customAvatarKey = 'custom_avatar_url';

  factory UserModel.fromSupabaseUser(User user) {
    final metadata = user.userMetadata;
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      name: metadata?['name'] ?? '',
      avatarUrl: metadata?[customAvatarKey] as String? ??
          _fullSizeAvatar(metadata?['avatar_url'] as String?),
      isNewAccount: _isNewAccount(user.createdAt, user.lastSignInAt),
    );
  }

  /// A new account's first sign-in happens when it's created; a returning
  /// user's latest sign-in is long after. The margin covers the few seconds
  /// between Supabase creating the user and recording the sign-in.
  static bool _isNewAccount(String createdAt, String? lastSignInAt) {
    final created = DateTime.tryParse(createdAt);
    final signedIn = lastSignInAt == null ? null : DateTime.tryParse(lastSignInAt);
    if (created == null || signedIn == null) return false;
    return signedIn.difference(created).abs() < const Duration(minutes: 1);
  }

  /// Google profile photos come as 96px thumbnails (`…=s96-c`), which blur
  /// at avatar size on high-density screens; ask Google for 512px instead.
  static String? _fullSizeAvatar(String? url) {
    if (url == null || !url.contains('googleusercontent.com')) return url;
    return url.replaceFirst(RegExp(r'=s\d+-c$'), '=s512-c');
  }

}
