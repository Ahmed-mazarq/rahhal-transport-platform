class MemoryCache<T> {
  final Map<String, _CacheEntry<T>> _cache = {};
  final Duration expiration;

  MemoryCache({this.expiration = const Duration(minutes: 5)});

  void set(String key, T value) {
    _cache[key] = _CacheEntry(value, DateTime.now().add(expiration));
  }

  T? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(key);
      return null;
    }
    return entry.value;
  }

  void remove(String key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }
}

class _CacheEntry<T> {
  final T value;
  final DateTime expiresAt;
  _CacheEntry(this.value, this.expiresAt);
}
