import 'package:sakk/core/error/Exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart' ;

class SupabaseErrorMapper {
  static Never handle(Object error, StackTrace stackTrace) {
    if (error is AuthException) {
      throw ServerException(_mapAuthError(error));
    } else if (error is PostgrestException) {
      throw ServerException(_mapPostgrestError(error));
    } else if (error is StorageException) {
      throw ServerException(error.message);
    } else {
      throw ServerException('Unexpected error: $error');
    }
  }

  static String _mapAuthError(AuthException e) {
    switch (e.message) {
      case 'Invalid login credentials':
        return 'Incorrect email or password';
      case 'Email not confirmed':
        return 'Please confirm your email before logging in';
      case 'email rate limit exceeded':
        return 'Too many attempts. Please wait a few minutes and try again.';
      default:
        return e.message;
    }
  }

  static String _mapPostgrestError(PostgrestException e) {
    if (e.code == '23505') return 'This record already exists';
    if (e.code == '42501') return 'You do not have permission for this action';
    return e.message;
  }
}