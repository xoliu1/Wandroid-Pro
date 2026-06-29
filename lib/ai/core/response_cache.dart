import '../models/ai_contract.dart';

class AIResponseCacheEntry {
  final AIResponse value;
  final DateTime createdAt;
  final Duration ttl;

  const AIResponseCacheEntry({
    required this.value,
    required this.createdAt,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().isAfter(createdAt.add(ttl));
}

class AIResponseCacheStore {
  AIResponseCacheStore._();

  static final AIResponseCacheStore instance = AIResponseCacheStore._();
  static const int _maxEntries = 100;

  final Map<String, AIResponseCacheEntry> _entries = {};

  AIResponse? get(String key) {
    final entry = _entries[key];
    if (entry == null) {
      return null;
    }
    if (entry.isExpired) {
      _entries.remove(key);
      return null;
    }
    return entry.value;
  }

  void put(
    String key,
    AIResponse value, {
      required Duration ttl,
    }) {
    _evictExpired();
    if (_entries.length >= _maxEntries) {
      final oldestKey = _entries.entries.reduce((a, b) {
        return a.value.createdAt.isBefore(b.value.createdAt) ? a : b;
      }).key;
      _entries.remove(oldestKey);
    }

    _entries[key] = AIResponseCacheEntry(
      value: value,
      createdAt: DateTime.now(),
      ttl: ttl,
    );
  }

  void clear() {
    _entries.clear();
  }

  void _evictExpired() {
    final expiredKeys = _entries.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();
    for (final key in expiredKeys) {
      _entries.remove(key);
    }
  }
}
