class AIDiagnosticEntry {
  final DateTime timestamp;
  final String scene;
  final String level;
  final String message;
  final Map<String, Object?> metadata;

  const AIDiagnosticEntry({
    required this.timestamp,
    required this.scene,
    required this.level,
    required this.message,
    this.metadata = const {},
  });
}

class AIDiagnosticsStore {
  AIDiagnosticsStore._();

  static final AIDiagnosticsStore instance = AIDiagnosticsStore._();
  static const int _maxEntries = 200;

  final List<AIDiagnosticEntry> _entries = [];

  List<AIDiagnosticEntry> get entries => List.unmodifiable(_entries);

  void record({
    required String scene,
    required String level,
    required String message,
    Map<String, Object?> metadata = const {},
  }) {
    _entries.insert(
      0,
      AIDiagnosticEntry(
        timestamp: DateTime.now(),
        scene: scene,
        level: level,
        message: message,
        metadata: metadata,
      ),
    );

    if (_entries.length > _maxEntries) {
      _entries.removeRange(_maxEntries, _entries.length);
    }
  }

  String dumpText() {
    final buffer = StringBuffer();
    for (final entry in _entries) {
      buffer.writeln(
        '[${entry.timestamp.toIso8601String()}][${entry.level}][${entry.scene}] ${entry.message} ${entry.metadata}',
      );
    }
    return buffer.toString();
  }

  List<Map<String, Object?>> dumpJson() {
    return _entries
        .map((entry) => {
              'timestamp': entry.timestamp.toIso8601String(),
              'scene': entry.scene,
              'level': entry.level,
              'message': entry.message,
              'metadata': entry.metadata,
            })
        .toList(growable: false);
  }

  void clear() {
    _entries.clear();
  }
}
