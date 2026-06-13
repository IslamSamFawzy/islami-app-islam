/// Low-level exceptions thrown by the data layer (data sources).
/// These are caught in repository implementations and mapped to [Failure]s.

class ServerException implements Exception {
  final String message;

  ServerException([this.message = 'Unexpected server error']);

  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  final String message;

  CacheException([this.message = 'Unexpected cache error']);

  @override
  String toString() => 'CacheException: $message';
}

/// Thrown when reading bundled/local assets (sura files, hard-coded data) fails.
class LocalDataException implements Exception {
  final String message;

  LocalDataException([this.message = 'Unexpected local data error']);

  @override
  String toString() => 'LocalDataException: $message';
}

/// Thrown when device location cannot be obtained (disabled/denied).
class LocationException implements Exception {
  final String message;

  const LocationException([this.message = 'Unable to get location']);

  @override
  String toString() => 'LocationException: $message';
}
