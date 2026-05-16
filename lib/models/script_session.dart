import 'cinematic_mode.dart';
import 'script_entry.dart';

class ScriptSession {
  const ScriptSession({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.entries,
    this.mode,
    this.isFavorite = false,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ScriptEntry> entries;
  final CinematicMode? mode;
  final bool isFavorite;

  String get title {
    for (final entry in entries) {
      if (entry.type == ScriptEntryType.slugline) return entry.text;
    }
    for (final entry in entries) {
      if (entry.type == ScriptEntryType.character) return entry.text;
    }
    for (final entry in entries) {
      if (entry.type == ScriptEntryType.action && entry.text.length > 4) {
        final text = entry.text;
        return text.length > 50 ? '${text.substring(0, 50)}…' : text;
      }
    }
    return 'Untitled take';
  }

  String get preview {
    if (entries.isEmpty) {
      return 'Empty take';
    }

    return entries.take(2).map((entry) => entry.text).join(' ').trim();
  }

  int get lineCount => entries.length;

  ScriptSession copyWith({
    bool? isFavorite,
  }) {
    return ScriptSession(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      entries: entries,
      mode: mode,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
      'mode': mode?.name,
      'isFavorite': isFavorite,
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

    final modeName = json['mode'] as String?;
    CinematicMode? mode;
    if (modeName != null) {
      for (final candidate in CinematicMode.values) {
        if (candidate.name == modeName) {
          mode = candidate;
          break;
        }
      }
    }

    return ScriptSession(
      id: json['id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      entries: entriesJson,
      mode: mode,
      isFavorite: json['isFavorite'] as bool? ?? false,
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
        other.mode == mode &&
        other.isFavorite == isFavorite &&
        _listEquals(other.entries, entries);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      createdAt,
      updatedAt,
      mode,
      isFavorite,
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
