/// Wraps a use-case payload with its provenance so the presentation layer can
/// tell whether it is showing cached or freshly-fetched data (used to drive the
/// offline indicator).
class CacheResult<T> {
  final T data;
  final bool fromCache;

  const CacheResult(this.data, {required this.fromCache});
}
