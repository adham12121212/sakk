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

class CacheException implements Exception {
  final String message;
  CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}