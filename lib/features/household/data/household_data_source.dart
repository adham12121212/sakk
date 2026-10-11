import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/Exceptions.dart';
import '../domain/household.dart';

/// Household reads go through RLS (members only see their own household);
/// every change goes through the database functions, which check the caller.
class HouseholdDataSource {
  HouseholdDataSource(this._client);

  final SupabaseClient _client;

  /// Error codes raised by the database functions; passed up as the failure
  /// message so the UI can explain them (see userFacingError).
  static const alreadyInHousehold = 'already_in_household';
  static const invalidInviteCode = 'invalid_invite_code';
  static const householdFull = 'household_full';
  static const notAllowed = 'not_allowed';
  static const _codes = [alreadyInHousehold, invalidInviteCode, householdFull, notAllowed];

  Future<(Household?, List<HouseholdMember>)> load() => _guard(() async {
        final row = await _client.from('households').select().maybeSingle();
        if (row == null) return (null, const <HouseholdMember>[]);
        final members = await _client.from('household_members').select().order('joined_at');
        return (
          _household(row),
          [
            for (final m in members)
              HouseholdMember(
                userId: m['user_id'] as String,
                displayName: m['display_name'] as String,
                isOwner: m['role'] == 'owner',
              ),
          ],
        );
      });

  Future<void> create({required String name, required String displayName}) => _guard(() =>
      _client.rpc('create_household', params: {'p_name': name, 'p_display_name': displayName}));

  Future<void> join({required String inviteCode, required String displayName}) => _guard(() =>
      _client.rpc('join_household', params: {'p_invite_code': inviteCode, 'p_display_name': displayName}));

  Future<void> leave() => _guard(() => _client.rpc('leave_household'));

  Future<void> removeMember(String userId) =>
      _guard(() => _client.rpc('remove_household_member', params: {'p_user_id': userId}));

  Future<void> regenerateInviteCode() => _guard(() => _client.rpc('regenerate_invite_code'));

  Household _household(Map<String, dynamic> row) => Household(
        id: row['id'] as String,
        name: row['name'] as String,
        inviteCode: row['invite_code'] as String,
      );

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      final code = _codes.where((c) => e.message.contains(c)).firstOrNull;
      throw ServerException(code ?? 'Household request failed: ${e.message}');
    } catch (e) {
      throw ServerException('Household request failed: $e');
    }
  }
}
