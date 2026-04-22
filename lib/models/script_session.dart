import 'script_entry.dart';

class ScriptSession {
  const ScriptSession({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.entries,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ScriptEntry> entries;

  String get preview {
    if (entries.isEmpty) {
      return 'Empty take';
    }

    return entries.take(2).map((entry) => entry.text).join(' ').trim();
  }

  int get lineCount => entries.length;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
    };
  }

  factory ScriptSession.fromJson(Map<String, Object?> json) {
    final entriesJson = (json['entries'] as List<Object?>? ?? <Object?>[])
        .whereType<Map<Object?, Object?>>()
        .map(
          (entry) => ScriptEntry.fromJson(
            Map<String, Object?>.from(entry),
          ),
        )
        .toList(growable: false);

    return ScriptSession(
      id: json['id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      entries: entriesJson,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is ScriptSession &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        _listEquals(other.entries, entries);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      createdAt,
      updatedAt,
      Object.hashAll(entries),
    );
  }
}

bool _listEquals(List<ScriptEntry> a, List<ScriptEntry> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }

  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}
