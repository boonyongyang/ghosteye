enum ScriptEntryType {
  slugline,
  action,
  character,
  dialogue,
  parenthetical,
}

class ScriptEntry {
  const ScriptEntry({
    required this.type,
    required this.text,
  });

  final ScriptEntryType type;
  final String text;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'type': type.name,
      'text': text,
    };
  }

  factory ScriptEntry.fromJson(Map<String, Object?> json) {
    final typeName = json['type'] as String? ?? ScriptEntryType.action.name;
    final type = ScriptEntryType.values.firstWhere(
      (candidate) => candidate.name == typeName,
      orElse: () => ScriptEntryType.action,
    );

    return ScriptEntry(
      type: type,
      text: json['text'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is ScriptEntry && other.type == type && other.text == text;
  }

  @override
  int get hashCode => Object.hash(type, text);
}
