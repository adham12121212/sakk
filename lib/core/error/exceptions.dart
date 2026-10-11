class ServerException implements Exception {
  final String message;
  ServerException(this.message);

  @override
  String toString() => 'ServerException: $message';
}

class AppAuthException implements Exception {
  final String message;
  AppAuthException(this.message);

  @override
  String toString() => 'AppAuthException: $message';
}

class GoogleSignInCancelledException implements Exception {
  /// Credential Manager reports some setup errors (e.g. an unregistered
  /// SHA-1) as cancellations too, so keep its description for the logs.
  final String? description;
  GoogleSignInCancelledException([this.description]);

  @override
  String toString() => 'GoogleSignInCancelledException: $description';
}

class EmailConfirmationRequiredException implements Exception {
  @override
  String toString() => 'EmailConfirmationRequiredException';
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}