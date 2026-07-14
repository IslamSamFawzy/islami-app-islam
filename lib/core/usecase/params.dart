import 'package:equatable/equatable.dart';

/// Params for cache-aware use cases. When [forceRefresh] is true the repository
/// bypasses the cache and hits the network, overwriting the cache with the
/// fresh result.
class RefreshParams extends Equatable {
  final bool forceRefresh;

  const RefreshParams({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}
